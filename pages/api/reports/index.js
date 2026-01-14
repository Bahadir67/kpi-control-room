import { reports } from '../../../lib/reports';
import { requireReportAuth } from '../../../lib/auth';

export default function handler(req, res) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  if (!requireReportAuth(req, res)) {
    return;
  }

  res.status(200).json({ reports });
}
