BEGIN;

-- Remove legacy FAT/SAT KPI results
DELETE FROM kpi_results
WHERE kpi_code IN ('KPI10_FAT_FIRST_PASS','KPI11_SAT_FIRST_PASS');

-- Renumber cost accuracy and skill growth to keep 12 KPIs
UPDATE kpi_results SET kpi_code = 'KPI11_COST_ACCURACY'
WHERE kpi_code = 'KPI12_COST_ACCURACY';

UPDATE kpi_results SET kpi_code = 'KPI12_SKILL_GROWTH'
WHERE kpi_code = 'KPI13_SKILL_GROWTH';

-- Remove legacy definitions
DELETE FROM kpi_definitions
WHERE kpi_code IN (
  'KPI10_FAT_FIRST_PASS',
  'KPI11_SAT_FIRST_PASS',
  'KPI12_COST_ACCURACY',
  'KPI13_SKILL_GROWTH'
);

-- Upsert 16 KPI definitions
INSERT INTO kpi_definitions (kpi_code, kpi_name, unit, formula_text) VALUES
('KPI01_PROFIT_MARGIN','Otomasyon Proje Karlilik Orani','percent',$$project_financials: ((sum(revenue)-sum(direct_costs))/nullif(sum(revenue),0))*100; filter by period/owner as needed$$),
('KPI02_INNOVATION_SHARE','Innovatif Ciro Payi (Skor Agirlikli)','percent',$$project_financials + project_innovation: sum(revenue*coalesce(innovation_score,0)/100)/nullif(sum(revenue),0)*100 where innovation_flag_manual=true$$),
('KPI03_ISG_COMPLIANCE','ISG Uyum Skoru','percent',$$audit_records: avg(audit_score) where audit_type='ISG' and audit_date in period$$),
('KPI04_ISO_COMPLIANCE','ISO Uyum Skoru','percent',$$audit_records: iso_score=0.7*avg(audit_score)+0.3*(sum(closed_on_time_count)/nullif(sum(nonconformity_count),0)*100); if sum(critical_findings_count)>0 then min(iso_score,60)$$),
('KPI05_OTIF','OTIF On Time In Full','percent',$$project_deliveries: on_time_in_full/eligible_delivered*100; on_time_in_full=final_delivery_date<=effective_committed_date AND delivered_scope_fully_accepted=true; eligible excludes excused_delay,cancellation,excluded_for_data_quality$$),
('KPI06_REWORK_RATE','Rework Orani (Maliyet)','percent',$$rework_entries+roles+project_financials: sum(rework_hours*role_hourly_rate)/nullif(sum(direct_costs),0)*100$$),
('KPI07_SW_STANDARD_SCORE','Yazilim Standartizasyon Skoru','percent',$$standardization_scores: avg(standardization_score)$$),
('KPI08_TRAINING_HOURS','Kisi Basi Egitim Saati','hours_per_person',$$training_records+headcount_snapshots: sum(hours)/nullif(avg_headcount,0)$$),
('KPI09_NEW_TECH_COUNT','Yeni Teknoloji Proje Sayisi','count',$$project_technology: count(distinct project_id) where implementation_date in period$$),
('KPI10_TEST_FIRST_PASS','Test First-Pass Orani (FAT+SAT)','percent',$$project_tests: total first-pass rate across FAT+SAT; details include FAT/SAT breakdown$$),
('KPI11_COST_ACCURACY','Maliyet Analizi Dogrulugu','percent',$$project_cost_estimates+project_cost_actuals: 100-avg(abs(estimated_cost-actual_cost)/nullif(estimated_cost,0)*100)$$),
('KPI12_SKILL_GROWTH','Alt Kadro Yetkinlik Artisi','points',$$skill_assessments: avg(current.skill_score - baseline.skill_score) matched by person_id and assessment_cycle_id$$),
('KPI13_CSAT','CSAT Otomasyon','percent',$$csat_surveys: avg(score_raw/scale_max*100) by period and project$$),
('KPI14_ENGAGEMENT','Ekip Motivasyon ve Baglilik Skoru','percent',$$engagement_surveys: weighted avg(score_raw/scale_max*100) by response_count$$),
('KPI15_RISK_REDUCTION','Kritik Proje Risk Azaltma Orani','percent',$$project_risks: sum(initial-current)/sum(initial)*100 for safety_related initial_score>=16$$),
('KPI16_INNOVATION_ROI','Inovasyon ROI','percent',$$innovation_roi: (incremental_revenue+cost_savings-incremental_costs)/investment_cost*100$$)
ON CONFLICT (kpi_code) DO UPDATE
SET kpi_name = EXCLUDED.kpi_name,
    unit = EXCLUDED.unit,
    formula_text = EXCLUDED.formula_text,
    active = true;

COMMIT;
