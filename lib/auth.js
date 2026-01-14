export function requireReportAuth(req, res) {
  const apiKey = process.env.REPORT_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: 'REPORT_API_KEY not configured' });
    return false;
  }
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : '';
  if (token !== apiKey) {
    res.status(401).json({ error: 'Unauthorized' });
    return false;
  }
  return true;
}
