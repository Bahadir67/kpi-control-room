-- KPI calculations for a period. Uses psql variables.
-- Set values before running:
-- \set period_start '2026-01-01'
-- \set period_end   '2026-01-31'
-- \set owner_person_id ''
-- \set department_id   ''

\set period_start '2026-01-01'
\set period_end '2026-01-31'
\set owner_person_id ''
\set department_id ''

-- KPI01: Profit Margin
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    sum(pf.revenue) AS revenue,
    sum(pf.direct_costs) AS direct_costs
  FROM project_financials pf
  JOIN projects p ON p.project_id = pf.project_id
  CROSS JOIN params prm
  WHERE pf.period_start >= prm.period_start
    AND pf.period_end <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI01_PROFIT_MARGIN',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  ((base.revenue - base.direct_costs) / base.revenue) * 100,
  'percent',
  jsonb_build_object('revenue', base.revenue, 'direct_costs', base.direct_costs)
FROM base
CROSS JOIN params prm
WHERE base.revenue > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI02: Innovation Revenue Share (score weighted)
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    sum(pf.revenue) AS revenue_total,
    sum(
      pf.revenue * CASE
        WHEN pi.innovation_flag_manual THEN COALESCE(pi.innovation_score, 0) / 100
        ELSE 0
      END
    ) AS revenue_weighted
  FROM project_financials pf
  JOIN projects p ON p.project_id = pf.project_id
  LEFT JOIN project_innovation pi
    ON pi.project_id = pf.project_id
   AND pi.period_start = pf.period_start
   AND pi.period_end = pf.period_end
  CROSS JOIN params prm
  WHERE pf.period_start >= prm.period_start
    AND pf.period_end <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI02_INNOVATION_SHARE',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (base.revenue_weighted / base.revenue_total) * 100,
  'percent',
  jsonb_build_object('revenue_total', base.revenue_total, 'revenue_weighted', base.revenue_weighted)
FROM base
CROSS JOIN params prm
WHERE base.revenue_total > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI03: ISG Compliance
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    avg(audit_score) AS avg_score,
    count(*) AS record_count
  FROM audit_records ar
  CROSS JOIN params prm
  WHERE ar.audit_type = 'ISG'
    AND ar.audit_score IS NOT NULL
    AND ar.audit_date >= prm.period_start
    AND ar.audit_date <= prm.period_end
    AND (prm.department_id IS NULL OR ar.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI03_ISG_COMPLIANCE',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  base.avg_score,
  'percent',
  jsonb_build_object('record_count', base.record_count)
FROM base
CROSS JOIN params prm
WHERE base.record_count > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI13: CSAT (Automation)
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    avg((cs.score_raw / NULLIF(COALESCE(cs.scale_max, 5), 0)) * 100) AS avg_score,
    count(*) AS response_count
  FROM csat_surveys cs
  JOIN projects p ON p.project_id = cs.project_id
  CROSS JOIN params prm
  WHERE cs.survey_date >= prm.period_start
    AND cs.survey_date <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI13_CSAT',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  base.avg_score,
  'percent',
  jsonb_build_object('response_count', base.response_count)
FROM base
CROSS JOIN params prm
WHERE base.response_count > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI14: Team Engagement (Motivation/Commitment)
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    sum(
      (es.score_raw / NULLIF(COALESCE(es.scale_max, 5), 0)) * 100
      * COALESCE(es.response_count, 1)
    ) AS weighted_sum,
    sum(COALESCE(es.response_count, 1)) AS response_sum
  FROM engagement_surveys es
  CROSS JOIN params prm
  WHERE es.survey_date >= prm.period_start
    AND es.survey_date <= prm.period_end
    AND (prm.department_id IS NULL OR es.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI14_ENGAGEMENT',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (base.weighted_sum / base.response_sum),
  'percent',
  jsonb_build_object('response_count', base.response_sum)
FROM base
CROSS JOIN params prm
WHERE base.response_sum > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI15: Critical Safety Risk Reduction
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    sum(pr.initial_score) AS initial_sum,
    sum(pr.initial_score - COALESCE(pr.current_score, pr.initial_score)) AS reduced_sum,
    count(*) AS total_count,
    count(*) FILTER (WHERE pr.status IN ('MITIGATED','CLOSED')) AS mitigated_count
  FROM project_risks pr
  JOIN projects p ON p.project_id = pr.project_id
  CROSS JOIN params prm
  WHERE pr.safety_related = true
    AND pr.initial_score >= 16
    AND COALESCE(pr.last_review_date, pr.identified_date) >= prm.period_start
    AND COALESCE(pr.last_review_date, pr.identified_date) <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI15_RISK_REDUCTION',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (base.reduced_sum::numeric / base.initial_sum) * 100,
  'percent',
  jsonb_build_object(
    'initial_sum', base.initial_sum,
    'reduced_sum', base.reduced_sum,
    'total_count', base.total_count,
    'mitigation_coverage', CASE WHEN base.total_count > 0 THEN (base.mitigated_count::numeric / base.total_count) * 100 ELSE NULL END
  )
FROM base
CROSS JOIN params prm
WHERE base.initial_sum > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI16: Innovation ROI
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    sum(ir.investment_cost) AS investment_cost,
    sum(ir.incremental_revenue) AS incremental_revenue,
    sum(ir.cost_savings) AS cost_savings,
    sum(ir.incremental_costs) AS incremental_costs
  FROM innovation_roi ir
  JOIN projects p ON p.project_id = ir.project_id
  CROSS JOIN params prm
  WHERE ir.period_start >= prm.period_start
    AND ir.period_end <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI16_INNOVATION_ROI',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  ((base.incremental_revenue + base.cost_savings - base.incremental_costs) / base.investment_cost) * 100,
  'percent',
  jsonb_build_object(
    'investment_cost', base.investment_cost,
    'incremental_revenue', base.incremental_revenue,
    'cost_savings', base.cost_savings,
    'incremental_costs', base.incremental_costs,
    'net_benefit', (base.incremental_revenue + base.cost_savings - base.incremental_costs)
  )
FROM base
CROSS JOIN params prm
WHERE base.investment_cost > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI04: ISO Compliance (composite with critical cap)
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    avg(audit_score) AS avg_score,
    sum(nonconformity_count) AS nonconf_sum,
    sum(closed_on_time_count) AS closed_sum,
    sum(critical_findings_count) AS critical_sum,
    count(*) AS record_count
  FROM audit_records ar
  CROSS JOIN params prm
  WHERE ar.audit_type = 'ISO'
    AND ar.audit_score IS NOT NULL
    AND ar.audit_date >= prm.period_start
    AND ar.audit_date <= prm.period_end
    AND (prm.department_id IS NULL OR ar.department_id = prm.department_id)
), score AS (
  SELECT
    avg_score,
    nonconf_sum,
    closed_sum,
    critical_sum,
    record_count,
    (0.7 * avg_score) + (0.3 * CASE WHEN nonconf_sum = 0 THEN 100 ELSE (closed_sum::numeric / nonconf_sum) * 100 END) AS raw_score
  FROM base
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI04_ISO_COMPLIANCE',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  CASE WHEN score.critical_sum > 0 THEN LEAST(score.raw_score, 60) ELSE score.raw_score END,
  'percent',
  jsonb_build_object(
    'avg_score', score.avg_score,
    'nonconf_sum', score.nonconf_sum,
    'closed_sum', score.closed_sum,
    'critical_sum', score.critical_sum,
    'raw_score', score.raw_score
  )
FROM score
CROSS JOIN params prm
WHERE score.record_count > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI05: OTIF
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    count(*) FILTER (
      WHERE pd.final_delivery_date <= pd.effective_committed_date
        AND pd.delivered_scope_fully_accepted = true
    ) AS numerator,
    count(*) AS denominator
  FROM project_deliveries pd
  JOIN projects p ON p.project_id = pd.project_id
  CROSS JOIN params prm
  WHERE pd.final_delivery_date IS NOT NULL
    AND pd.final_delivery_date::date >= prm.period_start
    AND pd.final_delivery_date::date <= prm.period_end
    AND (pd.delivery_status = 'DELIVERED' OR pd.delivery_status IS NULL)
    AND pd.delivered_scope_fully_accepted IS NOT NULL
    AND NOT pd.excused_delay
    AND NOT pd.cancellation_flag
    AND NOT pd.excluded_for_data_quality
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI05_OTIF',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (base.numerator::numeric / base.denominator) * 100,
  'percent',
  jsonb_build_object('numerator', base.numerator, 'denominator', base.denominator)
FROM base
CROSS JOIN params prm
WHERE base.denominator > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI06: Rework Rate (cost)
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), rework_costs AS (
  SELECT
    sum(re.rework_hours * COALESCE(r.hourly_rate, 0)) AS rework_cost
  FROM rework_entries re
  JOIN projects p ON p.project_id = re.project_id
  LEFT JOIN roles r
    ON r.role_id = re.role_id
   AND re.work_date >= r.effective_from
   AND (r.effective_to IS NULL OR re.work_date <= r.effective_to)
  CROSS JOIN params prm
  WHERE re.work_date >= prm.period_start
    AND re.work_date <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
), costs AS (
  SELECT
    sum(pf.direct_costs) AS direct_costs
  FROM project_financials pf
  JOIN projects p ON p.project_id = pf.project_id
  CROSS JOIN params prm
  WHERE pf.period_start >= prm.period_start
    AND pf.period_end <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI06_REWORK_RATE',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (rework_costs.rework_cost / costs.direct_costs) * 100,
  'percent',
  jsonb_build_object('rework_cost', rework_costs.rework_cost, 'direct_costs', costs.direct_costs)
FROM rework_costs
CROSS JOIN costs
CROSS JOIN params prm
WHERE costs.direct_costs > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI07: Software Standardization Score
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    avg(standardization_score) AS avg_score,
    count(*) AS record_count
  FROM standardization_scores ss
  JOIN projects p ON p.project_id = ss.project_id
  CROSS JOIN params prm
  WHERE ss.period_start >= prm.period_start
    AND ss.period_end <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI07_SW_STANDARD_SCORE',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  base.avg_score,
  'percent',
  jsonb_build_object('record_count', base.record_count)
FROM base
CROSS JOIN params prm
WHERE base.record_count > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI08: Training Hours per Person
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), training AS (
  SELECT
    sum(tr.hours) AS total_hours
  FROM training_records tr
  JOIN people pe ON pe.person_id = tr.person_id
  CROSS JOIN params prm
  WHERE tr.training_completed_date >= prm.period_start
    AND tr.training_completed_date <= prm.period_end
    AND (prm.department_id IS NULL OR pe.department_id = prm.department_id)
), headcount_by_date AS (
  SELECT
    hs.snapshot_date,
    sum(hs.headcount) AS headcount
  FROM headcount_snapshots hs
  CROSS JOIN params prm
  WHERE hs.snapshot_date >= prm.period_start
    AND hs.snapshot_date <= prm.period_end
    AND (prm.department_id IS NULL OR hs.department_id = prm.department_id)
  GROUP BY hs.snapshot_date
), headcount_avg AS (
  SELECT avg(headcount) AS avg_headcount FROM headcount_by_date
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI08_TRAINING_HOURS',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (training.total_hours / headcount_avg.avg_headcount),
  'hours_per_person',
  jsonb_build_object('total_hours', training.total_hours, 'avg_headcount', headcount_avg.avg_headcount)
FROM training
CROSS JOIN headcount_avg
CROSS JOIN params prm
WHERE headcount_avg.avg_headcount > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI09: New Technology Project Count
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    count(DISTINCT pt.project_id) AS project_count
  FROM project_technology pt
  JOIN projects p ON p.project_id = pt.project_id
  CROSS JOIN params prm
  WHERE pt.implementation_date >= prm.period_start
    AND pt.implementation_date <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI09_NEW_TECH_COUNT',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  base.project_count,
  'count',
  jsonb_build_object('project_count', base.project_count)
FROM base
CROSS JOIN params prm
WHERE base.project_count > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI10: Test First-Pass (FAT + SAT)
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), base AS (
  SELECT
    count(*) FILTER (WHERE pt.test_type = 'FAT' AND pt.first_pass_flag = true) AS fat_numerator,
    count(*) FILTER (WHERE pt.test_type = 'FAT') AS fat_denominator,
    count(*) FILTER (WHERE pt.test_type = 'SAT' AND pt.first_pass_flag = true) AS sat_numerator,
    count(*) FILTER (WHERE pt.test_type = 'SAT') AS sat_denominator,
    count(*) FILTER (WHERE pt.first_pass_flag = true) AS total_numerator,
    count(*) AS total_denominator
  FROM project_tests pt
  JOIN projects p ON p.project_id = pt.project_id
  CROSS JOIN params prm
  WHERE pt.test_type IN ('FAT','SAT')
    AND pt.test_date >= prm.period_start
    AND pt.test_date <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI10_TEST_FIRST_PASS',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (base.total_numerator::numeric / base.total_denominator) * 100,
  'percent',
  jsonb_build_object(
    'total_numerator', base.total_numerator,
    'total_denominator', base.total_denominator,
    'fat_numerator', base.fat_numerator,
    'fat_denominator', base.fat_denominator,
    'fat_rate', CASE WHEN base.fat_denominator > 0 THEN (base.fat_numerator::numeric / base.fat_denominator) * 100 ELSE NULL END,
    'sat_numerator', base.sat_numerator,
    'sat_denominator', base.sat_denominator,
    'sat_rate', CASE WHEN base.sat_denominator > 0 THEN (base.sat_numerator::numeric / base.sat_denominator) * 100 ELSE NULL END
  )
FROM base
CROSS JOIN params prm
WHERE base.total_denominator > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI11: Cost Estimate Accuracy
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'owner_person_id','')::uuid AS owner_person_id,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'owner_person_id','')::uuid IS NOT NULL THEN 'person'
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'owner_person_id','')::uuid,
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), latest_estimate AS (
  SELECT DISTINCT ON (pce.project_id)
    pce.project_id,
    pce.estimated_cost
  FROM project_cost_estimates pce
  JOIN projects p ON p.project_id = pce.project_id
  CROSS JOIN params prm
  WHERE pce.estimate_date <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
  ORDER BY pce.project_id, pce.estimate_date DESC
), actuals AS (
  SELECT
    pca.project_id,
    sum(pca.actual_cost) AS actual_cost
  FROM project_cost_actuals pca
  JOIN projects p ON p.project_id = pca.project_id
  CROSS JOIN params prm
  WHERE pca.period_start >= prm.period_start
    AND pca.period_end <= prm.period_end
    AND (prm.owner_person_id IS NULL OR p.owner_person_id = prm.owner_person_id)
    AND (prm.department_id IS NULL OR p.department_id = prm.department_id)
  GROUP BY pca.project_id
), pairs AS (
  SELECT
    le.project_id,
    le.estimated_cost,
    a.actual_cost
  FROM latest_estimate le
  JOIN actuals a ON a.project_id = le.project_id
  WHERE le.estimated_cost > 0
), base AS (
  SELECT
    avg(abs(estimated_cost - actual_cost) / estimated_cost * 100) AS avg_error,
    count(*) AS record_count
  FROM pairs
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI11_COST_ACCURACY',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  (100 - base.avg_error),
  'percent',
  jsonb_build_object('avg_error', base.avg_error, 'record_count', base.record_count)
FROM base
CROSS JOIN params prm
WHERE base.record_count > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;

-- KPI12: Skill Growth
WITH params AS (
  SELECT
    :'period_start'::date AS period_start,
    :'period_end'::date AS period_end,
    NULLIF(:'department_id','')::uuid AS department_id,
    CASE
      WHEN NULLIF(:'department_id','')::uuid IS NOT NULL THEN 'department'
      ELSE 'global'
    END AS scope_type,
    COALESCE(
      NULLIF(:'department_id','')::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS scope_id
), baseline AS (
  SELECT
    sa.person_id,
    sa.assessment_cycle_id,
    sa.skill_score
  FROM skill_assessments sa
  JOIN people pe ON pe.person_id = sa.person_id
  CROSS JOIN params prm
  WHERE sa.assessment_type = 'baseline'
    AND (prm.department_id IS NULL OR pe.department_id = prm.department_id)
), current AS (
  SELECT
    sa.person_id,
    sa.assessment_cycle_id,
    sa.skill_score
  FROM skill_assessments sa
  JOIN people pe ON pe.person_id = sa.person_id
  CROSS JOIN params prm
  WHERE sa.assessment_type = 'current'
    AND sa.assessment_date >= prm.period_start
    AND sa.assessment_date <= prm.period_end
    AND (prm.department_id IS NULL OR pe.department_id = prm.department_id)
), pairs AS (
  SELECT
    c.person_id,
    c.skill_score - b.skill_score AS delta
  FROM current c
  JOIN baseline b
    ON b.person_id = c.person_id
   AND b.assessment_cycle_id = c.assessment_cycle_id
), base AS (
  SELECT
    avg(delta) AS avg_growth,
    count(*) AS record_count
  FROM pairs
)
INSERT INTO kpi_results (kpi_code, period_start, period_end, scope_type, scope_id, value, unit, details)
SELECT
  'KPI12_SKILL_GROWTH',
  prm.period_start,
  prm.period_end,
  prm.scope_type,
  prm.scope_id,
  base.avg_growth,
  'points',
  jsonb_build_object('record_count', base.record_count)
FROM base
CROSS JOIN params prm
WHERE base.record_count > 0
ON CONFLICT (kpi_code, period_start, period_end, scope_type, scope_id)
DO UPDATE SET
  value = EXCLUDED.value,
  unit = EXCLUDED.unit,
  details = EXCLUDED.details,
  computed_at = now(),
  status = 'computed'
WHERE kpi_results.status <> 'overridden'
;
