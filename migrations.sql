-- Migration: initial KPI schema for Railway/Postgres
-- Uses uuid_v4() wrapper to support pgcrypto or uuid-ossp when available.

DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
  EXCEPTION WHEN OTHERS THEN
    BEGIN
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'No UUID extension available; application must supply UUIDs.';
    END;
  END;
END;
$$;

CREATE OR REPLACE FUNCTION public.uuid_v4()
RETURNS uuid AS $$
DECLARE
  result uuid;
BEGIN
  IF to_regproc('gen_random_uuid') IS NOT NULL THEN
    EXECUTE 'SELECT gen_random_uuid()' INTO result;
    RETURN result;
  ELSIF to_regproc('uuid_generate_v4') IS NOT NULL THEN
    EXECUTE 'SELECT uuid_generate_v4()' INTO result;
    RETURN result;
  ELSE
    RAISE EXCEPTION 'No UUID generator available';
  END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE TABLE departments (
  department_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  name text NOT NULL UNIQUE,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE people (
  person_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  full_name text NOT NULL,
  department_id uuid REFERENCES departments(department_id),
  title text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE projects (
  project_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_code text NOT NULL UNIQUE,
  project_name text,
  owner_person_id uuid REFERENCES people(person_id),
  department_id uuid REFERENCES departments(department_id),
  start_date date,
  end_date date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE roles (
  role_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  role_name text NOT NULL UNIQUE,
  hourly_rate numeric(12,2) NOT NULL,
  currency char(3) NOT NULL,
  effective_from date NOT NULL,
  effective_to date,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (hourly_rate >= 0),
  CHECK (currency ~ '^[A-Z]{3}$'),
  CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE TABLE project_financials (
  financial_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  period_start date NOT NULL,
  period_end date NOT NULL,
  revenue numeric(14,2) NOT NULL,
  direct_costs numeric(14,2) NOT NULL,
  currency char(3) NOT NULL,
  invoice_total numeric(14,2),
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (period_end >= period_start),
  CHECK (revenue >= 0),
  CHECK (direct_costs >= 0),
  CHECK (invoice_total IS NULL OR invoice_total >= 0),
  CHECK (currency ~ '^[A-Z]{3}$'),
  UNIQUE (project_id, period_start, period_end)
);

CREATE TABLE project_innovation (
  innovation_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  period_start date NOT NULL,
  period_end date NOT NULL,
  innovation_flag_manual boolean NOT NULL DEFAULT false,
  innovation_description text,
  innovation_tags text[] NOT NULL DEFAULT '{}'::text[],
  innovation_score numeric(5,2),
  innovation_score_reason text,
  innovation_score_model text,
  innovation_score_status text,
  innovation_scored_at timestamptz,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (period_end >= period_start),
  CHECK (innovation_score IS NULL OR (innovation_score >= 0 AND innovation_score <= 100)),
  CHECK (innovation_score_status IS NULL OR innovation_score_status IN ('pending','scored','failed')),
  CHECK (innovation_flag_manual = false OR (innovation_description IS NOT NULL AND length(btrim(innovation_description)) > 0)),
  UNIQUE (project_id, period_start, period_end)
);

CREATE TABLE project_deliveries (
  delivery_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  effective_committed_date timestamptz NOT NULL,
  final_delivery_date timestamptz,
  delivered_scope_fully_accepted boolean,
  delivery_status text,
  excused_delay boolean NOT NULL DEFAULT false,
  cancellation_flag boolean NOT NULL DEFAULT false,
  partial_delivery_flag boolean NOT NULL DEFAULT false,
  documentation_complete_flag boolean,
  training_complete_flag boolean,
  punch_list_open_items_count int,
  excluded_for_data_quality boolean NOT NULL DEFAULT false,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (punch_list_open_items_count IS NULL OR punch_list_open_items_count >= 0),
  CHECK (delivery_status IS NULL OR delivery_status IN ('DELIVERED','IN_PROGRESS','CANCELLED','ON_HOLD'))
);

CREATE TABLE audit_records (
  audit_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  audit_type text NOT NULL,
  iso_standard text,
  audit_date date NOT NULL,
  audit_score numeric(5,2),
  nonconformity_count int NOT NULL DEFAULT 0,
  closed_on_time_count int NOT NULL DEFAULT 0,
  critical_findings_count int NOT NULL DEFAULT 0,
  scope text,
  department_id uuid REFERENCES departments(department_id),
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (audit_type IN ('ISG','ISO','OTHER')),
  CHECK (audit_score IS NULL OR (audit_score >= 0 AND audit_score <= 100)),
  CHECK (nonconformity_count >= 0),
  CHECK (closed_on_time_count >= 0),
  CHECK (critical_findings_count >= 0),
  CHECK (closed_on_time_count <= nonconformity_count)
);

CREATE TABLE rework_entries (
  rework_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  person_id uuid REFERENCES people(person_id),
  role_id uuid NOT NULL REFERENCES roles(role_id),
  work_date date NOT NULL,
  rework_hours numeric(8,2) NOT NULL,
  rework_reason text,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (rework_hours > 0)
);

CREATE TABLE standardization_scores (
  standardization_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  period_start date NOT NULL,
  period_end date NOT NULL,
  standardization_score numeric(5,2) NOT NULL,
  code_review_coverage numeric(5,2),
  ci_pass_rate numeric(5,2),
  standard_libs_usage numeric(5,2),
  lint_rule_compliance numeric(5,2),
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (period_end >= period_start),
  CHECK (standardization_score BETWEEN 0 AND 100),
  CHECK (code_review_coverage IS NULL OR code_review_coverage BETWEEN 0 AND 100),
  CHECK (ci_pass_rate IS NULL OR ci_pass_rate BETWEEN 0 AND 100),
  CHECK (standard_libs_usage IS NULL OR standard_libs_usage BETWEEN 0 AND 100),
  CHECK (lint_rule_compliance IS NULL OR lint_rule_compliance BETWEEN 0 AND 100),
  UNIQUE (project_id, period_start, period_end)
);

CREATE TABLE training_records (
  training_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  person_id uuid NOT NULL REFERENCES people(person_id),
  training_course text NOT NULL,
  training_completed_date date NOT NULL,
  hours numeric(6,2) NOT NULL,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (hours >= 0)
);

CREATE TABLE headcount_snapshots (
  snapshot_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  department_id uuid NOT NULL REFERENCES departments(department_id),
  snapshot_date date NOT NULL,
  headcount int NOT NULL,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (headcount >= 0),
  UNIQUE (department_id, snapshot_date)
);

CREATE TABLE project_technology (
  technology_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  tech_tag text NOT NULL,
  implementation_date date NOT NULL,
  status text,
  notes text,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (status IS NULL OR status IN ('POC','PILOT','PROD','RETIRED'))
);

CREATE TABLE project_tests (
  test_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  test_type text NOT NULL,
  attempt_no int NOT NULL,
  result text NOT NULL,
  test_date date NOT NULL,
  first_pass_flag boolean NOT NULL DEFAULT false,
  notes text,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (test_type IN ('FAT','SAT')),
  CHECK (attempt_no > 0),
  CHECK (result IN ('PASS','FAIL','CANCELLED'))
);

CREATE TABLE project_cost_estimates (
  estimate_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  estimate_date date NOT NULL,
  estimated_cost numeric(14,2) NOT NULL,
  currency char(3) NOT NULL,
  estimate_version text,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (estimated_cost >= 0),
  CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE TABLE project_cost_actuals (
  actual_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  period_start date NOT NULL,
  period_end date NOT NULL,
  actual_cost numeric(14,2) NOT NULL,
  currency char(3) NOT NULL,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (period_end >= period_start),
  CHECK (actual_cost >= 0),
  CHECK (currency ~ '^[A-Z]{3}$'),
  UNIQUE (project_id, period_start, period_end)
);

CREATE TABLE csat_surveys (
  csat_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  survey_date date NOT NULL,
  score_raw numeric(5,2) NOT NULL,
  scale_max numeric(5,2) NOT NULL DEFAULT 5,
  respondent_type text,
  comment text,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (score_raw >= 0),
  CHECK (scale_max > 0),
  CHECK (score_raw <= scale_max)
);

CREATE TABLE engagement_surveys (
  engagement_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  department_id uuid NOT NULL REFERENCES departments(department_id),
  survey_cycle_id uuid,
  survey_date date NOT NULL,
  score_raw numeric(5,2) NOT NULL,
  scale_max numeric(5,2) NOT NULL DEFAULT 5,
  response_count int NOT NULL DEFAULT 1,
  person_id uuid REFERENCES people(person_id),
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (score_raw >= 0),
  CHECK (scale_max > 0),
  CHECK (score_raw <= scale_max),
  CHECK (response_count >= 1)
);

CREATE TABLE project_risks (
  risk_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  risk_code text,
  identified_date date NOT NULL,
  last_review_date date,
  safety_related boolean NOT NULL DEFAULT false,
  initial_score int NOT NULL,
  current_score int,
  status text,
  mitigation_actions text,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (initial_score BETWEEN 1 AND 25),
  CHECK (current_score IS NULL OR current_score BETWEEN 0 AND 25),
  CHECK (last_review_date IS NULL OR last_review_date >= identified_date),
  CHECK (status IS NULL OR status IN ('OPEN','MITIGATED','CLOSED'))
);

CREATE TABLE innovation_roi (
  roi_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  project_id uuid NOT NULL REFERENCES projects(project_id),
  period_start date NOT NULL,
  period_end date NOT NULL,
  investment_cost numeric(14,2) NOT NULL,
  incremental_revenue numeric(14,2) NOT NULL DEFAULT 0,
  cost_savings numeric(14,2) NOT NULL DEFAULT 0,
  incremental_costs numeric(14,2) NOT NULL DEFAULT 0,
  currency char(3) NOT NULL,
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (period_end >= period_start),
  CHECK (investment_cost >= 0),
  CHECK (incremental_revenue >= 0),
  CHECK (cost_savings >= 0),
  CHECK (incremental_costs >= 0),
  CHECK (currency ~ '^[A-Z]{3}$'),
  UNIQUE (project_id, period_start, period_end)
);

CREATE TABLE skill_assessments (
  assessment_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  person_id uuid NOT NULL REFERENCES people(person_id),
  assessment_date date NOT NULL,
  assessment_type text NOT NULL,
  assessment_cycle_id uuid,
  skill_domain text,
  skill_score numeric(5,2) NOT NULL,
  evaluator_id uuid REFERENCES people(person_id),
  entered_by uuid REFERENCES people(person_id),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notes text,
  data_quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (assessment_type IN ('baseline','current')),
  CHECK (skill_score BETWEEN 0 AND 100)
);

CREATE TABLE kpi_definitions (
  kpi_code text PRIMARY KEY,
  kpi_name text NOT NULL,
  unit text NOT NULL,
  formula_text text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE kpi_compute_audit (
  run_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  run_type text NOT NULL,
  triggered_by uuid REFERENCES people(person_id),
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  status text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  CHECK (run_type IN ('scheduled','event','manual')),
  CHECK (status IN ('running','success','failed'))
);

CREATE TABLE kpi_results (
  result_id uuid PRIMARY KEY DEFAULT public.uuid_v4(),
  kpi_code text NOT NULL REFERENCES kpi_definitions(kpi_code),
  period_start date NOT NULL,
  period_end date NOT NULL,
  scope_type text NOT NULL DEFAULT 'global',
  scope_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  value numeric(14,4) NOT NULL,
  unit text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  computed_at timestamptz NOT NULL DEFAULT now(),
  computed_by uuid REFERENCES people(person_id),
  compute_run_id uuid REFERENCES kpi_compute_audit(run_id),
  status text NOT NULL DEFAULT 'computed',
  CHECK (period_end >= period_start),
  CHECK (scope_type IN ('global','person','department')),
  CHECK (status IN ('computed','overridden','invalid'))
);

CREATE INDEX idx_project_financials_period ON project_financials (period_start, period_end);
CREATE INDEX idx_project_innovation_flag ON project_innovation (innovation_flag_manual);
CREATE INDEX idx_project_deliveries_final ON project_deliveries (final_delivery_date);
CREATE INDEX idx_audit_records_type_date ON audit_records (audit_type, audit_date);
CREATE INDEX idx_rework_entries_project_date ON rework_entries (project_id, work_date);
CREATE INDEX idx_standardization_scores_period ON standardization_scores (project_id, period_start, period_end);
CREATE INDEX idx_training_records_person_date ON training_records (person_id, training_completed_date);
CREATE INDEX idx_project_technology_tag_date ON project_technology (tech_tag, implementation_date);
CREATE INDEX idx_project_tests_type_date ON project_tests (project_id, test_type, test_date);
CREATE INDEX idx_project_cost_estimates_date ON project_cost_estimates (project_id, estimate_date);
CREATE INDEX idx_project_cost_actuals_period ON project_cost_actuals (project_id, period_start, period_end);
CREATE INDEX idx_csat_surveys_project_date ON csat_surveys (project_id, survey_date);
CREATE INDEX idx_engagement_surveys_dept_date ON engagement_surveys (department_id, survey_date);
CREATE INDEX idx_project_risks_project_date ON project_risks (project_id, identified_date);
CREATE INDEX idx_project_risks_safety_score ON project_risks (safety_related, initial_score);
CREATE INDEX idx_innovation_roi_period ON innovation_roi (period_start, period_end);
CREATE INDEX idx_skill_assessments_person_date ON skill_assessments (person_id, assessment_date);
CREATE INDEX idx_kpi_results_code_period ON kpi_results (kpi_code, period_start, period_end);
CREATE UNIQUE INDEX kpi_results_unique_scope ON kpi_results (
  kpi_code,
  period_start,
  period_end,
  scope_type,
  scope_id
);
