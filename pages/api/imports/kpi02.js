import pool from '../../../lib/db';

const MAX_ROWS = 1000;

function badRequest(message) {
  const error = new Error(message);
  error.status = 400;
  return error;
}

function normalizeText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizeAscii(value) {
  return value
    .replace(/ı/g, 'i')
    .replace(/İ/g, 'i')
    .replace(/ş/g, 's')
    .replace(/Ş/g, 's')
    .replace(/ğ/g, 'g')
    .replace(/Ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/Ü/g, 'u')
    .replace(/ö/g, 'o')
    .replace(/Ö/g, 'o')
    .replace(/ç/g, 'c')
    .replace(/Ç/g, 'c');
}

function requireField(value, label) {
  const text = normalizeText(value);
  if (!text) {
    throw badRequest(`${label} zorunlu.`);
  }
  return text;
}

function parseFlag(value) {
  if (typeof value === 'boolean') {
    return value;
  }
  const text = normalizeAscii(normalizeText(value)).toLowerCase();
  if (['evet', 'yes', 'true', '1'].includes(text)) {
    return true;
  }
  if (['hayir', 'no', 'false', '0'].includes(text)) {
    return false;
  }
  return null;
}

function parseScore(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const normalized = String(value).trim().replace(',', '.');
  const parsed = Number(normalized);
  if (!Number.isFinite(parsed)) {
    throw badRequest('AI puani sayi olmalidir.');
  }
  if (parsed < 0 || parsed > 100) {
    throw badRequest('AI puani 0-100 araliginda olmalidir.');
  }
  return parsed;
}

function normalizeStatus(value, score) {
  const text = normalizeAscii(normalizeText(value)).toLowerCase();
  if (!text) {
    return score !== null ? 'scored' : null;
  }
  const map = {
    beklemede: 'pending',
    pending: 'pending',
    puanlandi: 'scored',
    scored: 'scored',
    hata: 'failed',
    failed: 'failed',
    basarisiz: 'failed'
  };
  const normalized = map[text];
  if (!normalized) {
    throw badRequest('Puan durumu gecersiz.');
  }
  return normalized;
}

function normalizeTags(value) {
  if (Array.isArray(value)) {
    return value.map((item) => String(item).trim()).filter(Boolean);
  }
  const text = normalizeText(value);
  if (!text) {
    return [];
  }
  return text
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

async function upsertRow(client, row) {
  const projectCode = requireField(row.project_code || row.projectCode, 'Proje kodu');
  const periodStart = requireField(row.period_start || row.periodStart, 'Donem baslangici');
  const periodEnd = requireField(row.period_end || row.periodEnd, 'Donem bitisi');
  const flagValue = parseFlag(row.innovation_flag_manual ?? row.innovation_flag ?? row.innovationFlag);
  if (flagValue === null) {
    throw badRequest('Inovasyon bayragi zorunlu.');
  }

  const description = normalizeText(
    row.innovation_description ?? row.innovationDescription ?? ''
  );
  if (flagValue && !description) {
    throw badRequest('Inovasyon aciklamasi zorunlu.');
  }

  const tags = normalizeTags(row.innovation_tags ?? row.innovationTags ?? row.tags);
  const score = parseScore(row.innovation_score ?? row.ai_score ?? row.innovationScore);
  const status = normalizeStatus(
    row.score_status ?? row.innovation_score_status ?? row.innovationScoreStatus,
    score
  );

  if (status === 'scored' && score === null) {
    throw badRequest('Puanlanan kayit icin AI puani zorunlu.');
  }

  const scoredAt = status === 'scored' ? new Date().toISOString() : null;

  const projectResult = await client.query(
    `
      INSERT INTO projects (project_code)
      VALUES ($1)
      ON CONFLICT (project_code)
      DO UPDATE SET project_code = EXCLUDED.project_code
      RETURNING project_id
    `,
    [projectCode]
  );

  const projectId = projectResult.rows[0].project_id;

  await client.query(
    `
      INSERT INTO project_innovation (
        project_id,
        period_start,
        period_end,
        innovation_flag_manual,
        innovation_description,
        innovation_tags,
        innovation_score,
        innovation_score_status,
        innovation_scored_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ON CONFLICT (project_id, period_start, period_end)
      DO UPDATE SET
        innovation_flag_manual = EXCLUDED.innovation_flag_manual,
        innovation_description = EXCLUDED.innovation_description,
        innovation_tags = EXCLUDED.innovation_tags,
        innovation_score = EXCLUDED.innovation_score,
        innovation_score_status = EXCLUDED.innovation_score_status,
        innovation_scored_at = EXCLUDED.innovation_scored_at
    `,
    [
      projectId,
      periodStart,
      periodEnd,
      flagValue,
      description || null,
      tags,
      score,
      status,
      scoredAt
    ]
  );

  return projectId;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const body = req.body || {};
    const rows = Array.isArray(body.rows) ? body.rows : [];
    if (!rows.length) {
      throw badRequest('Aktarim icin satir bulunamadi.');
    }
    if (rows.length > MAX_ROWS) {
      throw badRequest(`En fazla ${MAX_ROWS} satir aktarilabilir.`);
    }

    const client = await pool.connect();
    const failures = [];
    let imported = 0;

    try {
      for (let i = 0; i < rows.length; i += 1) {
        try {
          await upsertRow(client, rows[i]);
          imported += 1;
        } catch (error) {
          failures.push({
            row: i + 1,
            error: error.message || 'Satir islenemedi.'
          });
        }
      }
    } finally {
      client.release();
    }

    res.status(200).json({
      ok: failures.length === 0,
      imported,
      failed: failures.length,
      failures: failures.slice(0, 20)
    });
  } catch (error) {
    res.status(error.status || 500).json({
      error: error.message || 'Aktarim basarisiz.'
    });
  }
}
