-- Migration: add scope columns and idempotent uniqueness to kpi_results

ALTER TABLE kpi_results
  ADD COLUMN IF NOT EXISTS scope_type text NOT NULL DEFAULT 'global',
  ADD COLUMN IF NOT EXISTS scope_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

ALTER TABLE kpi_results
  DROP CONSTRAINT IF EXISTS kpi_results_scope_type_check;

ALTER TABLE kpi_results
  ADD CONSTRAINT kpi_results_scope_type_check CHECK (scope_type IN ('global','person','department'));

-- Remove duplicates that would violate the unique index
WITH ranked AS (
  SELECT
    ctid,
    kpi_code,
    period_start,
    period_end,
    scope_type,
    scope_id,
    row_number() OVER (
      PARTITION BY kpi_code, period_start, period_end, scope_type, scope_id
      ORDER BY computed_at DESC NULLS LAST
    ) AS rn
  FROM kpi_results
)
DELETE FROM kpi_results
WHERE ctid IN (SELECT ctid FROM ranked WHERE rn > 1);

CREATE UNIQUE INDEX IF NOT EXISTS kpi_results_unique_scope ON kpi_results (
  kpi_code,
  period_start,
  period_end,
  scope_type,
  scope_id
);
