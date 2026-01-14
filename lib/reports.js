import pool from './db';

const DEFAULT_SCOPE_ID = '00000000-0000-0000-0000-000000000000';
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const reports = [
  {
    id: 'kpi_summary',
    title: 'KPI Summary',
    description: 'Computed KPI results for a single period and scope.',
    scopes: ['global', 'department', 'person'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'kpi_timeseries',
    title: 'KPI Timeseries',
    description: 'KPI values over a date range for one KPI code.',
    scopes: ['global', 'department', 'person'],
    params: [
      { name: 'kpi_code', type: 'string', required: true },
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'kpi_inputs_innovation',
    title: 'Innovation Inputs',
    description: 'Raw innovation flags, notes, and scores.',
    scopes: ['global', 'department', 'person'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'risk_register',
    title: 'Risk Register',
    description: 'Safety-related risks and mitigation status.',
    scopes: ['global', 'department', 'person'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'delivery_otif_details',
    title: 'OTIF Details',
    description: 'Delivery records for OTIF calculations.',
    scopes: ['global', 'department', 'person'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'training_hours_details',
    title: 'Training Hours Details',
    description: 'Training records and hours.',
    scopes: ['global', 'department', 'person'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'iso_audit_details',
    title: 'ISO Audit Details',
    description: 'Audit records for ISO compliance.',
    scopes: ['global', 'department'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'isg_audit_details',
    title: 'ISG Audit Details',
    description: 'Audit records for ISG compliance.',
    scopes: ['global', 'department'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'csat_details',
    title: 'CSAT Details',
    description: 'Customer satisfaction survey responses.',
    scopes: ['global', 'department', 'person'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  },
  {
    id: 'engagement_details',
    title: 'Engagement Details',
    description: 'Engagement survey results.',
    scopes: ['global', 'department'],
    params: [
      { name: 'period_start', type: 'date', required: true },
      { name: 'period_end', type: 'date', required: true },
      { name: 'scope_type', type: 'string', required: false },
      { name: 'scope_id', type: 'uuid', required: false },
      { name: 'limit', type: 'integer', required: false }
    ]
  }
];

const reportMap = reports.reduce((acc, report) => {
  acc[report.id] = report;
  return acc;
}, {});

function clampLimit(limit) {
  const parsed = Number(limit ?? 500);
  if (Number.isNaN(parsed) || parsed <= 0) {
    return 500;
  }
  return Math.min(parsed, 2000);
}

function normalizeScope(scopeType, scopeId) {
  const type = scopeType || 'global';
  if (!['global', 'department', 'person'].includes(type)) {
    throw { status: 400, message: 'Invalid scope_type' };
  }
  if (type === 'global') {
    return { scopeType: type, scopeId: DEFAULT_SCOPE_ID };
  }
  if (!scopeId || !UUID_RE.test(scopeId)) {
    throw { status: 400, message: 'scope_id must be a UUID for department or person scope' };
  }
  return { scopeType: type, scopeId };
}

function normalizeDateRange(periodStart, periodEnd) {
  if (!periodStart || !periodEnd) {
    throw { status: 400, message: 'period_start and period_end are required' };
  }
  return { periodStart, periodEnd };
}

function addProjectScope(values, scope, alias) {
  if (scope.scopeType === 'department') {
    values.push(scope.scopeId);
    return `AND ${alias}.department_id = $${values.length}`;
  }
  if (scope.scopeType === 'person') {
    values.push(scope.scopeId);
    return `AND ${alias}.owner_person_id = $${values.length}`;
  }
  return '';
}

function addDepartmentScope(values, scope, column) {
  if (scope.scopeType === 'department') {
    values.push(scope.scopeId);
    return `AND ${column} = $${values.length}`;
  }
  return '';
}

function addTrainingScope(values, scope) {
  if (scope.scopeType === 'department') {
    values.push(scope.scopeId);
    return `AND pe.department_id = $${values.length}`;
  }
  if (scope.scopeType === 'person') {
    values.push(scope.scopeId);
    return `AND tr.person_id = $${values.length}`;
  }
  return '';
}

function buildQuery(reportId, params) {
  const { periodStart, periodEnd, scope, limit } = params;

  if (reportId === 'kpi_summary') {
    const values = [periodStart, periodEnd, scope.scopeType, scope.scopeId, limit];
    return {
      text: `
        SELECT kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details, computed_at, status
        FROM kpi_results
        WHERE period_start = $1 AND period_end = $2
          AND scope_type = $3 AND scope_id = $4
        ORDER BY kpi_code
        LIMIT $5
      `,
      values
    };
  }

  if (reportId === 'kpi_timeseries') {
    if (!params.kpi_code) {
      throw { status: 400, message: 'kpi_code is required for kpi_timeseries' };
    }
    const values = [params.kpi_code, periodStart, periodEnd, scope.scopeType, scope.scopeId, limit];
    return {
      text: `
        SELECT kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details, computed_at, status
        FROM kpi_results
        WHERE kpi_code = $1
          AND period_start >= $2 AND period_end <= $3
          AND scope_type = $4 AND scope_id = $5
        ORDER BY period_start, period_end
        LIMIT $6
      `,
      values
    };
  }

  if (reportId === 'kpi_inputs_innovation') {
    const values = [periodStart, periodEnd];
    const scopeClause = addProjectScope(values, scope, 'p');
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT pi.project_id, p.project_code, p.project_name, pi.period_start, pi.period_end,
               pi.innovation_flag_manual, pi.innovation_description, pi.innovation_tags,
               pi.innovation_score, pi.innovation_score_status, pi.innovation_scored_at
        FROM project_innovation pi
        JOIN projects p ON p.project_id = pi.project_id
        WHERE pi.period_start >= $1 AND pi.period_end <= $2
        ${scopeClause}
        ORDER BY pi.period_start DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  if (reportId === 'risk_register') {
    const values = [periodStart, periodEnd];
    const scopeClause = addProjectScope(values, scope, 'p');
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT pr.risk_id, p.project_code, p.project_name, pr.risk_code,
               pr.identified_date, pr.last_review_date, pr.safety_related,
               pr.initial_score, pr.current_score, pr.status, pr.mitigation_actions
        FROM project_risks pr
        JOIN projects p ON p.project_id = pr.project_id
        WHERE COALESCE(pr.last_review_date, pr.identified_date) >= $1
          AND COALESCE(pr.last_review_date, pr.identified_date) <= $2
        ${scopeClause}
        ORDER BY COALESCE(pr.last_review_date, pr.identified_date) DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  if (reportId === 'delivery_otif_details') {
    const values = [periodStart, periodEnd];
    const scopeClause = addProjectScope(values, scope, 'p');
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT pd.delivery_id, p.project_code, p.project_name,
               pd.effective_committed_date, pd.final_delivery_date,
               pd.delivered_scope_fully_accepted, pd.delivery_status,
               pd.excused_delay, pd.cancellation_flag, pd.partial_delivery_flag,
               pd.excluded_for_data_quality
        FROM project_deliveries pd
        JOIN projects p ON p.project_id = pd.project_id
        WHERE pd.final_delivery_date IS NOT NULL
          AND pd.final_delivery_date::date >= $1
          AND pd.final_delivery_date::date <= $2
        ${scopeClause}
        ORDER BY pd.final_delivery_date DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  if (reportId === 'training_hours_details') {
    const values = [periodStart, periodEnd];
    const scopeClause = addTrainingScope(values, scope);
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT tr.training_id, tr.person_id, pe.full_name, pe.department_id,
               tr.training_course, tr.training_completed_date, tr.hours, tr.notes
        FROM training_records tr
        JOIN people pe ON pe.person_id = tr.person_id
        WHERE tr.training_completed_date >= $1
          AND tr.training_completed_date <= $2
        ${scopeClause}
        ORDER BY tr.training_completed_date DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  if (reportId === 'iso_audit_details') {
    const values = [periodStart, periodEnd];
    const scopeClause = addDepartmentScope(values, scope, 'ar.department_id');
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT ar.audit_id, ar.audit_type, ar.iso_standard, ar.audit_date,
               ar.audit_score, ar.nonconformity_count, ar.closed_on_time_count,
               ar.critical_findings_count, ar.scope, ar.department_id
        FROM audit_records ar
        WHERE ar.audit_type = 'ISO'
          AND ar.audit_date >= $1
          AND ar.audit_date <= $2
        ${scopeClause}
        ORDER BY ar.audit_date DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  if (reportId === 'isg_audit_details') {
    const values = [periodStart, periodEnd];
    const scopeClause = addDepartmentScope(values, scope, 'ar.department_id');
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT ar.audit_id, ar.audit_type, ar.iso_standard, ar.audit_date,
               ar.audit_score, ar.nonconformity_count, ar.closed_on_time_count,
               ar.critical_findings_count, ar.scope, ar.department_id
        FROM audit_records ar
        WHERE ar.audit_type = 'ISG'
          AND ar.audit_date >= $1
          AND ar.audit_date <= $2
        ${scopeClause}
        ORDER BY ar.audit_date DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  if (reportId === 'csat_details') {
    const values = [periodStart, periodEnd];
    const scopeClause = addProjectScope(values, scope, 'p');
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT cs.csat_id, p.project_code, p.project_name, cs.survey_date,
               cs.score_raw, cs.scale_max, cs.respondent_type, cs.comment
        FROM csat_surveys cs
        JOIN projects p ON p.project_id = cs.project_id
        WHERE cs.survey_date >= $1
          AND cs.survey_date <= $2
        ${scopeClause}
        ORDER BY cs.survey_date DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  if (reportId === 'engagement_details') {
    const values = [periodStart, periodEnd];
    const scopeClause = addDepartmentScope(values, scope, 'es.department_id');
    values.push(limit);
    const limitIndex = values.length;
    return {
      text: `
        SELECT es.engagement_id, es.department_id, es.survey_cycle_id, es.survey_date,
               es.score_raw, es.scale_max, es.response_count, es.person_id
        FROM engagement_surveys es
        WHERE es.survey_date >= $1
          AND es.survey_date <= $2
        ${scopeClause}
        ORDER BY es.survey_date DESC
        LIMIT $${limitIndex}
      `,
      values
    };
  }

  throw { status: 400, message: 'Unknown report_id' };
}

export async function runReport(reportId, rawParams) {
  const report = reportMap[reportId];
  if (!report) {
    throw { status: 400, message: 'Unknown report_id' };
  }

  const scope = normalizeScope(rawParams.scope_type, rawParams.scope_id);
  if (!report.scopes.includes(scope.scopeType)) {
    throw { status: 400, message: `scope_type ${scope.scopeType} not allowed for ${reportId}` };
  }

  const { periodStart, periodEnd } = normalizeDateRange(rawParams.period_start, rawParams.period_end);
  const limit = clampLimit(rawParams.limit);

  const query = buildQuery(reportId, {
    periodStart,
    periodEnd,
    scope,
    limit,
    kpi_code: rawParams.kpi_code
  });

  const { rows } = await pool.query(query.text, query.values);

  return {
    report_id: reportId,
    rows,
    meta: {
      row_count: rows.length,
      period_start: periodStart,
      period_end: periodEnd,
      scope_type: scope.scopeType,
      scope_id: scope.scopeId,
      limit
    }
  };
}
