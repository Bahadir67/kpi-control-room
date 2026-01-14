import pool from '../../../lib/db';

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
  const parsed = Number(value);
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

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const body = req.body || {};
    const projectCode = requireField(body.project_code || body.projectCode, 'Proje kodu');
    const periodStart = requireField(body.period_start || body.periodStart, 'Donem baslangici');
    const periodEnd = requireField(body.period_end || body.periodEnd, 'Donem bitisi');
    const flagValue = parseFlag(body.innovation_flag_manual ?? body.innovation_flag ?? body.innovationFlag);
    if (flagValue === null) {
      throw badRequest('Inovasyon bayragi zorunlu.');
    }

    const description = normalizeText(
      body.innovation_description ?? body.innovationDescription ?? ''
    );
    if (flagValue && !description) {
      throw badRequest('Inovasyon aciklamasi zorunlu.');
    }

    const tags = normalizeTags(
      body.innovation_tags ?? body.innovationTags ?? body.tags
    );
    const score = parseScore(
      body.innovation_score ?? body.ai_score ?? body.innovationScore
    );
    const status = normalizeStatus(
      body.score_status ?? body.innovation_score_status ?? body.innovationScoreStatus,
      score
    );

    if (status === 'scored' && score === null) {
      throw badRequest('Puanlanan kayit icin AI puani zorunlu.');
    }

    const scoredAt = status === 'scored' ? new Date().toISOString() : null;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

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

      const innovationResult = await client.query(
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
          RETURNING innovation_id
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

      await client.query('COMMIT');

      res.status(200).json({
        ok: true,
        project_id: projectId,
        innovation_id: innovationResult.rows[0].innovation_id
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    res.status(error.status || 500).json({
      error: error.message || 'Kayit basarisiz.'
    });
  }
}
