\set ON_ERROR_STOP on
\set period_start '2026-01-01'
\set period_end '2026-01-31'
\set owner_person_id ''
\set department_id ''

\ir kpi_sample_data.sql
\ir ../kpi_calculations.sql

SELECT kpi_code, value, unit, details
FROM kpi_results
WHERE period_start = :'period_start'::date
  AND period_end = :'period_end'::date
ORDER BY kpi_code;
