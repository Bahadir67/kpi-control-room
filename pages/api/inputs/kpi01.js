import pool from '../../../lib/db';

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
    const revenue = parseNumber(body.revenue, 'Gelir');
    const directCosts = parseNumber(body.direct_costs ?? body.directCosts, 'Dogrudan maliyet');
    const currency = normalizeCurrency(body.currency || '');

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

      const financialResult = await client.query(
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
          RETURNING financial_id
        `,
        [projectId, periodStart, periodEnd, revenue, directCosts, currency]
      );

      await client.query('COMMIT');

      res.status(200).json({
        ok: true,
        project_id: projectId,
        financial_id: financialResult.rows[0].financial_id
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
