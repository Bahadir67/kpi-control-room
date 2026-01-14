-- Sample data for KPI demo. Uses fixed UUIDs.
BEGIN;

INSERT INTO departments (department_id, name, active)
VALUES ('11111111-1111-1111-1111-111111111111', 'Automation', true)
ON CONFLICT DO NOTHING;

INSERT INTO people (person_id, full_name, department_id, title, active)
VALUES ('22222222-2222-2222-2222-222222222222', 'Bahadir Atilgan', '11111111-1111-1111-1111-111111111111', 'Automation Project Manager', true)
ON CONFLICT DO NOTHING;

INSERT INTO projects (project_id, project_code, project_name, owner_person_id, department_id, start_date, end_date)
VALUES ('33333333-3333-3333-3333-333333333333', 'AUTO-2026-001', 'Demo Automation Project', '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', '2026-01-01', '2026-01-31')
ON CONFLICT DO NOTHING;

INSERT INTO roles (role_id, role_name, hourly_rate, currency, effective_from)
VALUES ('44444444-4444-4444-4444-444444444444', 'Automation Engineer', 250, 'TRY', '2025-01-01')
ON CONFLICT DO NOTHING;

INSERT INTO project_financials (project_id, period_start, period_end, revenue, direct_costs, currency, invoice_total)
VALUES ('33333333-3333-3333-3333-333333333333', '2026-01-01', '2026-01-31', 1000000, 700000, 'TRY', 1000000)
ON CONFLICT DO NOTHING;

INSERT INTO project_innovation (project_id, period_start, period_end, innovation_flag_manual, innovation_description, innovation_tags, innovation_score, innovation_score_reason, innovation_score_model, innovation_score_status, innovation_scored_at)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  '2026-01-01',
  '2026-01-31',
  true,
  'AI vision inspection for defect detection',
  ARRAY['AI','Vision'],
  80,
  'Clear AI usage in production workflow',
  'gpt-4o-mini',
  'scored',
  '2026-02-01T10:00:00Z'
)
ON CONFLICT DO NOTHING;

INSERT INTO project_deliveries (
  project_id, effective_committed_date, final_delivery_date, delivered_scope_fully_accepted,
  delivery_status, excused_delay, cancellation_flag, partial_delivery_flag,
  documentation_complete_flag, training_complete_flag, punch_list_open_items_count, excluded_for_data_quality
)
SELECT
  '33333333-3333-3333-3333-333333333333',
  '2026-01-20T00:00:00Z',
  '2026-01-18T00:00:00Z',
  true,
  'DELIVERED',
  false,
  false,
  false,
  true,
  true,
  0,
  false
WHERE NOT EXISTS (
  SELECT 1
  FROM project_deliveries
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND effective_committed_date = '2026-01-20T00:00:00Z'
);

INSERT INTO audit_records (audit_type, iso_standard, audit_date, audit_score, nonconformity_count, closed_on_time_count, critical_findings_count, scope, department_id)
SELECT 'ISG', NULL, DATE '2026-01-10', 92, 0, 0, 0, 'Automation dept', '11111111-1111-1111-1111-111111111111'::uuid
WHERE NOT EXISTS (
  SELECT 1
  FROM audit_records
  WHERE audit_type = 'ISG'
    AND audit_date = '2026-01-10'
    AND department_id = '11111111-1111-1111-1111-111111111111'
)
UNION ALL
SELECT 'ISO', 'ISO9001', DATE '2026-01-12', 88, 5, 4, 0, 'Automation dept', '11111111-1111-1111-1111-111111111111'::uuid
WHERE NOT EXISTS (
  SELECT 1
  FROM audit_records
  WHERE audit_type = 'ISO'
    AND iso_standard = 'ISO9001'
    AND audit_date = '2026-01-12'
    AND department_id = '11111111-1111-1111-1111-111111111111'
);

INSERT INTO rework_entries (project_id, person_id, role_id, work_date, rework_hours, rework_reason)
SELECT '33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', '2026-01-15', 10, 'Wiring changes after review'
WHERE NOT EXISTS (
  SELECT 1
  FROM rework_entries
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND role_id = '44444444-4444-4444-4444-444444444444'
    AND work_date = '2026-01-15'
    AND rework_hours = 10
);

INSERT INTO standardization_scores (project_id, period_start, period_end, standardization_score, code_review_coverage, ci_pass_rate, standard_libs_usage, lint_rule_compliance)
VALUES ('33333333-3333-3333-3333-333333333333', '2026-01-01', '2026-01-31', 85, 90, 95, 80, 88)
ON CONFLICT DO NOTHING;

INSERT INTO training_records (person_id, training_course, training_completed_date, hours)
SELECT '22222222-2222-2222-2222-222222222222', 'PLC Advanced', '2026-01-22', 8
WHERE NOT EXISTS (
  SELECT 1
  FROM training_records
  WHERE person_id = '22222222-2222-2222-2222-222222222222'
    AND training_course = 'PLC Advanced'
    AND training_completed_date = '2026-01-22'
);

INSERT INTO headcount_snapshots (department_id, snapshot_date, headcount)
VALUES
  ('11111111-1111-1111-1111-111111111111', '2026-01-01', 10),
  ('11111111-1111-1111-1111-111111111111', '2026-01-31', 10)
ON CONFLICT DO NOTHING;

INSERT INTO project_technology (project_id, tech_tag, implementation_date, status, notes)
SELECT '33333333-3333-3333-3333-333333333333', 'AI', '2026-01-15', 'PROD', 'Vision inspection'
WHERE NOT EXISTS (
  SELECT 1
  FROM project_technology
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND tech_tag = 'AI'
    AND implementation_date = '2026-01-15'
);

INSERT INTO project_tests (project_id, test_type, attempt_no, result, test_date, first_pass_flag)
SELECT '33333333-3333-3333-3333-333333333333'::uuid, 'FAT', 1, 'PASS', DATE '2026-01-18', true
WHERE NOT EXISTS (
  SELECT 1
  FROM project_tests
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND test_type = 'FAT'
    AND attempt_no = 1
    AND test_date = '2026-01-18'
)
UNION ALL
SELECT '33333333-3333-3333-3333-333333333333'::uuid, 'SAT', 1, 'FAIL', DATE '2026-01-20', false
WHERE NOT EXISTS (
  SELECT 1
  FROM project_tests
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND test_type = 'SAT'
    AND attempt_no = 1
    AND test_date = '2026-01-20'
)
UNION ALL
SELECT '33333333-3333-3333-3333-333333333333'::uuid, 'SAT', 2, 'PASS', DATE '2026-01-25', false
WHERE NOT EXISTS (
  SELECT 1
  FROM project_tests
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND test_type = 'SAT'
    AND attempt_no = 2
    AND test_date = '2026-01-25'
);

INSERT INTO project_cost_estimates (project_id, estimate_date, estimated_cost, currency, estimate_version)
SELECT '33333333-3333-3333-3333-333333333333', '2025-12-20', 900000, 'TRY', 'v1'
WHERE NOT EXISTS (
  SELECT 1
  FROM project_cost_estimates
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND estimate_date = '2025-12-20'
    AND estimate_version = 'v1'
);

INSERT INTO project_cost_actuals (project_id, period_start, period_end, actual_cost, currency)
VALUES ('33333333-3333-3333-3333-333333333333', '2026-01-01', '2026-01-31', 880000, 'TRY')
ON CONFLICT DO NOTHING;

INSERT INTO skill_assessments (person_id, assessment_date, assessment_type, assessment_cycle_id, skill_domain, skill_score, evaluator_id)
SELECT '22222222-2222-2222-2222-222222222222'::uuid, DATE '2025-12-15', 'baseline', '55555555-5555-5555-5555-555555555555'::uuid, 'automation', 70, '22222222-2222-2222-2222-222222222222'::uuid
WHERE NOT EXISTS (
  SELECT 1
  FROM skill_assessments
  WHERE person_id = '22222222-2222-2222-2222-222222222222'
    AND assessment_type = 'baseline'
    AND assessment_cycle_id = '55555555-5555-5555-5555-555555555555'
    AND assessment_date = '2025-12-15'
)
UNION ALL
SELECT '22222222-2222-2222-2222-222222222222'::uuid, DATE '2026-01-25', 'current', '55555555-5555-5555-5555-555555555555'::uuid, 'automation', 78, '22222222-2222-2222-2222-222222222222'::uuid
WHERE NOT EXISTS (
  SELECT 1
  FROM skill_assessments
  WHERE person_id = '22222222-2222-2222-2222-222222222222'
    AND assessment_type = 'current'
    AND assessment_cycle_id = '55555555-5555-5555-5555-555555555555'
    AND assessment_date = '2026-01-25'
);

INSERT INTO csat_surveys (project_id, survey_date, score_raw, scale_max, respondent_type, comment)
SELECT '33333333-3333-3333-3333-333333333333'::uuid, DATE '2026-01-22', 4, 5, 'end_user', 'Delivery met expectations'
WHERE NOT EXISTS (
  SELECT 1
  FROM csat_surveys
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND survey_date = '2026-01-22'
    AND score_raw = 4
)
UNION ALL
SELECT '33333333-3333-3333-3333-333333333333'::uuid, DATE '2026-01-23', 5, 5, 'end_user', 'Excellent collaboration'
WHERE NOT EXISTS (
  SELECT 1
  FROM csat_surveys
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND survey_date = '2026-01-23'
    AND score_raw = 5
);

INSERT INTO engagement_surveys (department_id, survey_cycle_id, survey_date, score_raw, scale_max, response_count, notes)
SELECT '11111111-1111-1111-1111-111111111111'::uuid, '66666666-6666-6666-6666-666666666666'::uuid, DATE '2026-01-31', 4.1, 5, 10, 'Quarterly engagement pulse'
WHERE NOT EXISTS (
  SELECT 1
  FROM engagement_surveys
  WHERE department_id = '11111111-1111-1111-1111-111111111111'
    AND survey_cycle_id = '66666666-6666-6666-6666-666666666666'
    AND survey_date = '2026-01-31'
);

INSERT INTO project_risks (project_id, risk_code, identified_date, last_review_date, safety_related, initial_score, current_score, status, mitigation_actions)
SELECT '33333333-3333-3333-3333-333333333333'::uuid, 'RISK-001', DATE '2026-01-05', DATE '2026-01-25', true, 20, 12, 'MITIGATED', 'Add safety interlock and training'
WHERE NOT EXISTS (
  SELECT 1
  FROM project_risks
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND risk_code = 'RISK-001'
);

INSERT INTO innovation_roi (project_id, period_start, period_end, investment_cost, incremental_revenue, cost_savings, incremental_costs, currency, notes)
SELECT '33333333-3333-3333-3333-333333333333'::uuid, DATE '2026-01-01', DATE '2026-01-31', 200000, 400000, 50000, 50000, 'TRY', '12-month ROI window'
WHERE NOT EXISTS (
  SELECT 1
  FROM innovation_roi
  WHERE project_id = '33333333-3333-3333-3333-333333333333'
    AND period_start = '2026-01-01'
    AND period_end = '2026-01-31'
);

COMMIT;
