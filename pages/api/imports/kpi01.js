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

function requireField(value, label) {
  const text = normalizeText(value);
  if (!text) {
    throw badRequest(`${label} zorunlu.`);
  }
  return text;
}

function parseNumber(value, label) {
  if (value === null || value === undefined || value === '') {
    throw badRequest(`${label} zorunlu.`);
  }
  const normalized = String(value).trim().replace(',', '.');
  const parsed = Number(normalized);
  if (!Number.isFinite(parsed)) {
    throw badRequest(`${label} sayi olmalidir.`);
  }
  return parsed;
}

function normalizeCurrency(value) {
  const currency = normalizeText(value).toUpperCase();
  if (!currency || !/^[A-Z]{3}$/.test(currency)) {
    throw badRequest('Para birimi 3 harfli olmalidir.');
  }
  return currency;
}

async function upsertRow(client, row) {
  const projectCode = requireField(row.project_code || row.projectCode, 'Proje kodu');
  const periodStart = requireField(row.period_start || row.periodStart, 'Donem baslangici');
  const periodEnd = requireField(row.period_end || row.periodEnd, 'Donem bitisi');
  const revenue = parseNumber(row.revenue, 'Gelir');
  const directCosts = parseNumber(row.direct_costs ?? row.directCosts, 'Dogrudan maliyet');
  const currency = normalizeCurrency(row.currency || '');

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
      INSERT INTO project_financials (
        project_id,
        period_start,
        period_end,
        revenue,
        direct_costs,
        currency
      )
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (project_id, period_start, period_end)
      DO UPDATE SET
        revenue = EXCLUDED.revenue,
        direct_costs = EXCLUDED.direct_costs,
        currency = EXCLUDED.currency
    `,
    [projectId, periodStart, periodEnd, revenue, directCosts, currency]
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
