# KPI Project Handoff

This file summarizes the current state of the KPI project so work can continue later.

## Decisions and policies
- KPI count expanded to 16 (12 core + 4 new). KPI10 is a combined FAT+SAT test first-pass KPI with FAT/SAT breakdown in `details`.
- KPI results must support both person-level and department-level filtering.
- Manual entry is the primary input path; CSV/Excel bulk import is required.
- Innovation is manually flagged; AI scoring is on-demand (triggered manually). KPI02 uses score-weighted revenue.
- ISO KPI uses composite score: 0.7 * avg(audit_score) + 0.3 * closure rate; cap at 60 if critical findings > 0.
- Rework KPI uses role-based hourly rate (cost-based KPI), with hours as a supporting metric.
- Reporting is monthly by default but must support instant (on-demand) refresh.
- New KPI defaults:
  - CSAT: 1-5 scale, normalized to 0-100.
  - Engagement: quarterly, 1-5 scale, weighted by response_count.
  - Risk reduction: safety-related, critical threshold initial_score >= 16, score reduction ratio.
  - Innovation ROI: 12-month window, net benefit / investment * 100.

## Railway Postgres connection (no secrets)
- Use the TCP proxy host/port (not the public HTTP domain).
- Template connection:
  - Host: `caboose.proxy.rlwy.net`
  - Port: `55871`
  - DB: `railway`
  - User: `postgres`
  - SSL: `require`
- Example (set password first):
  - `PGPASSWORD=...`
  - `psql "host=caboose.proxy.rlwy.net port=55871 dbname=railway user=postgres sslmode=require"`

## Applied to DB
- `migrations.sql` applied (schema + indexes).
- `sql/migrations_add_kpi_13_16.sql` applied (new KPI tables).
- `sql/kpi_definitions_seed.sql` applied (16 KPI definitions).
- Demo data + calculation run executed (see below).

## Files created/updated
- `migrations.sql` - Railway/Postgres schema, UUID fallback function.
- `kpi_calculations.sql` - KPI compute script (16 KPIs, KPI15 risk reduction uses numeric division).
- `sql/kpi_definitions_seed.sql` - 16 KPI seed script, removes legacy FAT/SAT codes.
- `sql/migrations_add_kpi_13_16.sql` - incremental migration for new KPI tables.
- `spec/api_schemas.json` - JSON Schema for API payloads + examples.
- `sql/kpi_sample_data.sql` - sample data (idempotent inserts).
- `sql/kpi_demo_run.sql` - sample data load + KPI calculation + results query.

## Demo run (already executed once)
- Command:
  - `PGPASSWORD=...`
  - `psql "host=caboose.proxy.rlwy.net port=55871 dbname=railway user=postgres sslmode=require" -f sql/kpi_demo_run.sql`
- Script does:
  1) Load sample data (fixed UUIDs, guarded by `WHERE NOT EXISTS`).
  2) Run KPI calculations for 2026-01-01 .. 2026-01-31.
  3) Select KPI results for the period.
- Notes:
  - `kpi_results` will accumulate new rows each run. Clean or add idempotent logic if you want a single row per period.

## KPI10 combined test KPI
- Code: `KPI10_TEST_FIRST_PASS`
- Value: total first-pass rate across FAT+SAT.
- `details` includes: `fat_rate`, `sat_rate`, `fat_numerator/denominator`, `sat_numerator/denominator`.

## Pending work (next steps)
1) OpenAPI spec based on `spec/api_schemas.json`.
2) API endpoints for CRUD + CSV/Excel uploads + compute trigger + AI-score trigger.
3) CSV/Excel staging tables (optional) + import validation rules.
4) Compute pipeline: scheduled monthly runs + on-demand runs, idempotent writes, audit log integration.
5) Frontend flows: grouped manual forms, bulk upload UI, data-quality flags, attachments.
6) Reporting: monthly dashboard + instant refresh, thresholds, exports.
