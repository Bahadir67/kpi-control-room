import { runReport } from '../../../lib/reports';
import { requireReportAuth } from '../../../lib/auth';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  if (!requireReportAuth(req, res)) {
    return;
  }

  try {
    const body = req.body || {};
    const result = await runReport(body.report_id, body);
    res.status(200).json(result);
  } catch (err) {
    res.status(err.status || 500).json({ error: err.message || 'Report failed' });
  }
}
