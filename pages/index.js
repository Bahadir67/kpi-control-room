import Head from 'next/head';

const coreKpis = [
  {
    id: 'KPI01',
    title: 'Profit Margin',
    subtitle: 'Project financials',
    groups: [
      {
        name: 'Financials',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Period start', type: 'date' },
          { label: 'Period end', type: 'date' },
          { label: 'Revenue', type: 'number', placeholder: '0.00' },
          { label: 'Direct costs', type: 'number', placeholder: '0.00' },
          { label: 'Currency', type: 'text', placeholder: 'USD' }
        ]
      }
    ],
    action: 'Save financials'
  },
  {
    id: 'KPI02',
    title: 'Innovation Share',
    subtitle: 'Manual flag with AI score',
    groups: [
      {
        name: 'Manual input',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Period start', type: 'date' },
          { label: 'Period end', type: 'date' },
          { label: 'Innovation flag', type: 'select', options: ['Yes', 'No'] },
          { label: 'Innovation description', type: 'textarea', placeholder: 'Describe the innovation' },
          { label: 'Tags (comma)', type: 'text', placeholder: 'automation, ai' }
        ]
      },
      {
        name: 'AI scoring',
        fields: [
          { label: 'AI score', type: 'number', placeholder: '0-100' },
          { label: 'Score status', type: 'select', options: ['pending', 'scored', 'failed'] }
        ]
      }
    ],
    action: 'Save innovation input',
    secondaryAction: 'Request AI score'
  },
  {
    id: 'KPI03',
    title: 'ISG Compliance',
    subtitle: 'Safety audit score',
    groups: [
      {
        name: 'Audit record',
        fields: [
          { label: 'Audit date', type: 'date' },
          { label: 'Department id', type: 'text', placeholder: 'UUID' },
          { label: 'Audit score', type: 'number', placeholder: '0-100' },
          { label: 'Scope', type: 'text', placeholder: 'Plant, line, site' }
        ]
      }
    ],
    action: 'Save audit'
  },
  {
    id: 'KPI04',
    title: 'ISO Compliance',
    subtitle: 'Audit quality and closure',
    groups: [
      {
        name: 'Audit record',
        fields: [
          { label: 'Audit date', type: 'date' },
          { label: 'Department id', type: 'text', placeholder: 'UUID' },
          { label: 'ISO standard', type: 'text', placeholder: 'ISO-9001' },
          { label: 'Audit score', type: 'number', placeholder: '0-100' },
          { label: 'Nonconformity count', type: 'number', placeholder: '0' },
          { label: 'Closed on time', type: 'number', placeholder: '0' },
          { label: 'Critical findings', type: 'number', placeholder: '0' }
        ]
      }
    ],
    action: 'Save audit'
  },
  {
    id: 'KPI05',
    title: 'OTIF Delivery',
    subtitle: 'On time and in full',
    groups: [
      {
        name: 'Delivery record',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Committed date', type: 'datetime-local' },
          { label: 'Final delivery date', type: 'datetime-local' },
          { label: 'Delivered fully', type: 'select', options: ['Yes', 'No'] },
          { label: 'Delivery status', type: 'select', options: ['DELIVERED', 'IN_PROGRESS', 'CANCELLED', 'ON_HOLD'] },
          { label: 'Excused delay', type: 'select', options: ['No', 'Yes'] },
          { label: 'Cancellation flag', type: 'select', options: ['No', 'Yes'] }
        ]
      }
    ],
    action: 'Save delivery'
  },
  {
    id: 'KPI06',
    title: 'Rework Cost',
    subtitle: 'Hours by role',
    groups: [
      {
        name: 'Rework entry',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Work date', type: 'date' },
          { label: 'Rework hours', type: 'number', placeholder: '0.0' },
          { label: 'Role name', type: 'text', placeholder: 'Engineer' },
          { label: 'Rework reason', type: 'textarea', placeholder: 'Root cause summary' }
        ]
      }
    ],
    action: 'Save rework'
  },
  {
    id: 'KPI07',
    title: 'Standardization Score',
    subtitle: 'Code quality and coverage',
    groups: [
      {
        name: 'Score entry',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Period start', type: 'date' },
          { label: 'Period end', type: 'date' },
          { label: 'Standard score', type: 'number', placeholder: '0-100' },
          { label: 'Code review coverage', type: 'number', placeholder: '0-100' },
          { label: 'CI pass rate', type: 'number', placeholder: '0-100' },
          { label: 'Lint compliance', type: 'number', placeholder: '0-100' }
        ]
      }
    ],
    action: 'Save score'
  },
  {
    id: 'KPI08',
    title: 'Training Hours',
    subtitle: 'Training records and headcount',
    groups: [
      {
        name: 'Training record',
        fields: [
          { label: 'Person id', type: 'text', placeholder: 'UUID' },
          { label: 'Course', type: 'text', placeholder: 'Safety basics' },
          { label: 'Completed date', type: 'date' },
          { label: 'Hours', type: 'number', placeholder: '0.0' }
        ]
      },
      {
        name: 'Headcount snapshot',
        fields: [
          { label: 'Department id', type: 'text', placeholder: 'UUID' },
          { label: 'Snapshot date', type: 'date' },
          { label: 'Headcount', type: 'number', placeholder: '0' }
        ]
      }
    ],
    action: 'Save training'
  },
  {
    id: 'KPI09',
    title: 'New Technology',
    subtitle: 'Automation and new tech',
    groups: [
      {
        name: 'Technology entry',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Tech tag', type: 'text', placeholder: 'robotics' },
          { label: 'Implementation date', type: 'date' },
          { label: 'Status', type: 'select', options: ['POC', 'PILOT', 'PROD', 'RETIRED'] },
          { label: 'Notes', type: 'textarea', placeholder: 'Impact summary' }
        ]
      }
    ],
    action: 'Save technology'
  },
  {
    id: 'KPI10',
    title: 'Test Coverage',
    subtitle: 'FAT and SAT results',
    groups: [
      {
        name: 'Test record',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Test type', type: 'select', options: ['FAT', 'SAT'] },
          { label: 'Attempt no', type: 'number', placeholder: '1' },
          { label: 'Result', type: 'select', options: ['PASS', 'FAIL', 'CANCELLED'] },
          { label: 'Test date', type: 'date' },
          { label: 'First pass', type: 'select', options: ['No', 'Yes'] }
        ]
      }
    ],
    action: 'Save test'
  },
  {
    id: 'KPI11',
    title: 'Cost Accuracy',
    subtitle: 'Estimate vs actual',
    groups: [
      {
        name: 'Estimate',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Estimate date', type: 'date' },
          { label: 'Estimated cost', type: 'number', placeholder: '0.00' },
          { label: 'Currency', type: 'text', placeholder: 'USD' },
          { label: 'Estimate version', type: 'text', placeholder: 'v1' }
        ]
      },
      {
        name: 'Actual cost',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Period start', type: 'date' },
          { label: 'Period end', type: 'date' },
          { label: 'Actual cost', type: 'number', placeholder: '0.00' },
          { label: 'Currency', type: 'text', placeholder: 'USD' }
        ]
      }
    ],
    action: 'Save costs'
  },
  {
    id: 'KPI12',
    title: 'Skill Growth',
    subtitle: 'Baseline vs current',
    groups: [
      {
        name: 'Assessment',
        fields: [
          { label: 'Person id', type: 'text', placeholder: 'UUID' },
          { label: 'Assessment type', type: 'select', options: ['baseline', 'current'] },
          { label: 'Assessment cycle id', type: 'text', placeholder: 'UUID' },
          { label: 'Assessment date', type: 'date' },
          { label: 'Skill score', type: 'number', placeholder: '0-100' },
          { label: 'Skill domain', type: 'text', placeholder: 'Controls' }
        ]
      }
    ],
    action: 'Save assessment'
  }
];

const extraKpis = [
  {
    id: 'KPI13',
    title: 'CSAT',
    subtitle: 'Client satisfaction',
    groups: [
      {
        name: 'Survey',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Survey date', type: 'date' },
          { label: 'Score raw', type: 'number', placeholder: '1-5' },
          { label: 'Scale max', type: 'number', placeholder: '5' },
          { label: 'Respondent type', type: 'text', placeholder: 'Customer' },
          { label: 'Comment', type: 'textarea', placeholder: 'Short feedback' }
        ]
      }
    ],
    action: 'Save CSAT'
  },
  {
    id: 'KPI14',
    title: 'Engagement',
    subtitle: 'Team engagement score',
    groups: [
      {
        name: 'Survey',
        fields: [
          { label: 'Department id', type: 'text', placeholder: 'UUID' },
          { label: 'Survey date', type: 'date' },
          { label: 'Score raw', type: 'number', placeholder: '1-5' },
          { label: 'Scale max', type: 'number', placeholder: '5' },
          { label: 'Response count', type: 'number', placeholder: '1' },
          { label: 'Survey cycle id', type: 'text', placeholder: 'UUID' }
        ]
      }
    ],
    action: 'Save engagement'
  },
  {
    id: 'KPI15',
    title: 'Risk Register',
    subtitle: 'Critical safety risks',
    groups: [
      {
        name: 'Risk entry',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Risk code', type: 'text', placeholder: 'R-001' },
          { label: 'Identified date', type: 'date' },
          { label: 'Last review date', type: 'date' },
          { label: 'Safety related', type: 'select', options: ['Yes', 'No'] },
          { label: 'Initial score', type: 'number', placeholder: '1-25' },
          { label: 'Current score', type: 'number', placeholder: '0-25' },
          { label: 'Status', type: 'select', options: ['OPEN', 'MITIGATED', 'CLOSED'] },
          { label: 'Mitigation actions', type: 'textarea', placeholder: 'Action plan' }
        ]
      }
    ],
    action: 'Save risk'
  },
  {
    id: 'KPI16',
    title: 'Innovation ROI',
    subtitle: 'Investment and benefits',
    groups: [
      {
        name: 'ROI entry',
        fields: [
          { label: 'Project code', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Period start', type: 'date' },
          { label: 'Period end', type: 'date' },
          { label: 'Investment cost', type: 'number', placeholder: '0.00' },
          { label: 'Incremental revenue', type: 'number', placeholder: '0.00' },
          { label: 'Cost savings', type: 'number', placeholder: '0.00' },
          { label: 'Incremental costs', type: 'number', placeholder: '0.00' },
          { label: 'Currency', type: 'text', placeholder: 'USD' }
        ]
      }
    ],
    action: 'Save ROI'
  }
];

function Field({ field }) {
  if (field.type === 'select') {
    return (
      <label className="field">
        <span>{field.label}</span>
        <select defaultValue="">
          <option value="" disabled>
            Select
          </option>
          {field.options.map((option) => (
            <option key={option} value={option}>
              {option}
            </option>
          ))}
        </select>
      </label>
    );
  }
  if (field.type === 'textarea') {
    return (
      <label className="field field-full">
        <span>{field.label}</span>
        <textarea placeholder={field.placeholder || ''} rows={3} />
      </label>
    );
  }
  return (
    <label className="field">
      <span>{field.label}</span>
      <input type={field.type || 'text'} placeholder={field.placeholder || ''} />
    </label>
  );
}

function KpiCard({ kpi, index }) {
  return (
    <div className="card" style={{ '--delay': `${index * 0.04}s` }}>
      <div className="card-header">
        <span className="tag">{kpi.id}</span>
        <div>
          <h3>{kpi.title}</h3>
          <p>{kpi.subtitle}</p>
        </div>
      </div>
      <div className="card-body">
        {kpi.groups.map((group) => (
          <div className="field-group" key={group.name}>
            <div className="group-title">{group.name}</div>
            <div className="field-grid">
              {group.fields.map((field) => (
                <Field key={`${group.name}-${field.label}`} field={field} />
              ))}
            </div>
          </div>
        ))}
      </div>
      <div className="card-actions">
        <button className="btn" type="button">
          {kpi.action}
        </button>
        {kpi.secondaryAction ? (
          <button className="btn ghost" type="button">
            {kpi.secondaryAction}
          </button>
        ) : null}
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <>
      <Head>
        <title>KPI Control Room</title>
        <meta name="description" content="KPI data entry and reporting" />
      </Head>
      <div className="page">
        <header className="topbar">
          <div className="brand">
            <span className="brand-mark" />
            <div>
              <div className="brand-title">KPI Control Room</div>
              <div className="brand-sub">Railway + Postgres + GPT Actions</div>
            </div>
          </div>
          <div className="top-actions">
            <button className="btn ghost" type="button">Help</button>
            <button className="btn" type="button">New Project</button>
          </div>
        </header>

        <div className="layout">
          <aside className="side-nav">
            <div className="nav-section">
              <div className="nav-title">Workspace</div>
              <button className="nav-item active" type="button">Data Entry</button>
              <button className="nav-item" type="button">CSV Import</button>
              <button className="nav-item" type="button">Reports</button>
              <button className="nav-item" type="button">Settings</button>
            </div>
            <div className="nav-section">
              <div className="nav-title">Scope</div>
              <div className="nav-chip">Global</div>
              <div className="nav-chip">Department</div>
              <div className="nav-chip">Person</div>
            </div>
          </aside>

          <main className="main">
            <section className="hero">
              <div>
                <h1>Manual KPI input with instant report hooks.</h1>
                <p>
                  Enter the raw signals once, compute KPIs per period, and let GPT
                  fetch the exact report payloads on demand.
                </p>
              </div>
              <div className="hero-panel">
                <div className="hero-title">Period and scope</div>
                <div className="hero-grid">
                  <label className="field">
                    <span>Period start</span>
                    <input type="date" />
                  </label>
                  <label className="field">
                    <span>Period end</span>
                    <input type="date" />
                  </label>
                  <label className="field">
                    <span>Scope type</span>
                    <select defaultValue="global">
                      <option value="global">Global</option>
                      <option value="department">Department</option>
                      <option value="person">Person</option>
                    </select>
                  </label>
                  <label className="field">
                    <span>Scope id</span>
                    <input type="text" placeholder="UUID (optional for global)" />
                  </label>
                </div>
                <div className="hero-actions">
                  <button className="btn" type="button">Compute KPIs</button>
                  <button className="btn ghost" type="button">Run KPI summary</button>
                </div>
              </div>
            </section>

            <section className="section">
              <div className="section-header">
                <h2>Core KPI inputs</h2>
                <p>Manual entry modules aligned to the KPI formulas.</p>
              </div>
              <div className="card-grid">
                {coreKpis.map((kpi, index) => (
                  <KpiCard key={kpi.id} kpi={kpi} index={index} />
                ))}
              </div>
            </section>

            <section className="section alt">
              <div className="section-header">
                <h2>Additional KPI inputs</h2>
                <p>Optional modules for CSAT, engagement, risks, and ROI.</p>
              </div>
              <div className="card-grid">
                {extraKpis.map((kpi, index) => (
                  <KpiCard key={kpi.id} kpi={kpi} index={index + coreKpis.length} />
                ))}
              </div>
            </section>

            <section className="section">
              <div className="section-header">
                <h2>CSV or Excel import</h2>
                <p>Drop your files, map columns, and push into the tables.</p>
              </div>
              <div className="dropzone">
                <div>
                  <strong>Drag and drop files here</strong>
                  <span>Accepted: CSV, XLSX</span>
                </div>
                <button className="btn" type="button">Upload file</button>
              </div>
            </section>
          </main>

          <aside className="right-rail">
            <div className="panel">
              <div className="panel-title">Live KPI snapshot</div>
              <div className="metric">
                <span>KPI01 Profit Margin</span>
                <span className="metric-value">--</span>
              </div>
              <div className="metric">
                <span>KPI02 Innovation Share</span>
                <span className="metric-value">--</span>
              </div>
              <div className="metric">
                <span>KPI05 OTIF</span>
                <span className="metric-value">--</span>
              </div>
              <div className="metric">
                <span>KPI15 Risk Reduction</span>
                <span className="metric-value">--</span>
              </div>
              <button className="btn" type="button">Refresh results</button>
            </div>

            <div className="panel">
              <div className="panel-title">GPT Actions ready</div>
              <p className="panel-text">
                Reports are exposed via /api/reports and /api/reports/run. Keep the
                API key in Railway variables and wire the schema into GPT Actions.
              </p>
              <button className="btn ghost" type="button">Copy OpenAPI schema</button>
            </div>

            <div className="panel">
              <div className="panel-title">Quick reports</div>
              <button className="btn ghost" type="button">kpi_summary</button>
              <button className="btn ghost" type="button">kpi_timeseries</button>
              <button className="btn ghost" type="button">risk_register</button>
              <button className="btn ghost" type="button">csat_details</button>
            </div>
          </aside>
        </div>
      </div>
    </>
  );
}
