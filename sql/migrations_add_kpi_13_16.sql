-- Migration: add KPI 13-16 supporting tables

CREATE TABLE IF NOT EXISTS csat_surveys (
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

CREATE TABLE IF NOT EXISTS engagement_surveys (
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

CREATE TABLE IF NOT EXISTS project_risks (
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

CREATE TABLE IF NOT EXISTS innovation_roi (
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

CREATE INDEX IF NOT EXISTS idx_csat_surveys_project_date ON csat_surveys (project_id, survey_date);
CREATE INDEX IF NOT EXISTS idx_engagement_surveys_dept_date ON engagement_surveys (department_id, survey_date);
CREATE INDEX IF NOT EXISTS idx_project_risks_project_date ON project_risks (project_id, identified_date);
CREATE INDEX IF NOT EXISTS idx_project_risks_safety_score ON project_risks (safety_related, initial_score);
CREATE INDEX IF NOT EXISTS idx_innovation_roi_period ON innovation_roi (period_start, period_end);
