import Head from 'next/head';

const coreKpis = [
  {
    id: 'KPI01',
    title: 'Kar Marjı',
    subtitle: 'Proje finansalları',
    groups: [
      {
        name: 'Finansallar',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Dönem başlangıcı', type: 'date' },
          { label: 'Dönem bitişi', type: 'date' },
          { label: 'Gelir', type: 'number', placeholder: '0.00' },
          { label: 'Doğrudan maliyet', type: 'number', placeholder: '0.00' },
          { label: 'Para birimi', type: 'text', placeholder: 'USD' }
        ]
      }
    ],
    action: 'Finansalları kaydet'
  },
  {
    id: 'KPI02',
    title: 'İnovasyon Payı',
    subtitle: 'Manuel bayrak ve AI puanı',
    groups: [
      {
        name: 'Manuel giriş',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Dönem başlangıcı', type: 'date' },
          { label: 'Dönem bitişi', type: 'date' },
          { label: 'İnovasyon bayrağı', type: 'select', options: ['Evet', 'Hayır'] },
          { label: 'İnovasyon açıklaması', type: 'textarea', placeholder: 'İnovasyonu açıklayın' },
          { label: 'Etiketler (virgülle)', type: 'text', placeholder: 'otomasyon, ai' }
        ]
      },
      {
        name: 'AI puanlama',
        fields: [
          { label: 'AI puanı', type: 'number', placeholder: '0-100' },
          { label: 'Puan durumu', type: 'select', options: ['Beklemede', 'Puanlandı', 'Hata'] }
        ]
      }
    ],
    action: 'İnovasyon girdisini kaydet',
    secondaryAction: 'AI puanı iste'
  },
  {
    id: 'KPI03',
    title: 'İSG Uyum',
    subtitle: 'İş güvenliği denetim skoru',
    groups: [
      {
        name: 'Denetim kaydı',
        fields: [
          { label: 'Denetim tarihi', type: 'date' },
          { label: 'Departman ID', type: 'text', placeholder: 'UUID' },
          { label: 'Denetim skoru', type: 'number', placeholder: '0-100' },
          { label: 'Kapsam', type: 'text', placeholder: 'Tesis, hat, saha' }
        ]
      }
    ],
    action: 'Denetimi kaydet'
  },
  {
    id: 'KPI04',
    title: 'ISO Uyum',
    subtitle: 'Denetim kalitesi ve kapanış',
    groups: [
      {
        name: 'Denetim kaydı',
        fields: [
          { label: 'Denetim tarihi', type: 'date' },
          { label: 'Departman ID', type: 'text', placeholder: 'UUID' },
          { label: 'ISO standardı', type: 'text', placeholder: 'ISO-9001' },
          { label: 'Denetim skoru', type: 'number', placeholder: '0-100' },
          { label: 'Uygunsuzluk sayısı', type: 'number', placeholder: '0' },
          { label: 'Zamanında kapanan sayısı', type: 'number', placeholder: '0' },
          { label: 'Kritik bulgu sayısı', type: 'number', placeholder: '0' }
        ]
      }
    ],
    action: 'Denetimi kaydet'
  },
  {
    id: 'KPI05',
    title: 'OTIF Teslimat',
    subtitle: 'Zamanında ve eksiksiz',
    groups: [
      {
        name: 'Teslimat kaydı',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Taahhüt tarihi', type: 'datetime-local' },
          { label: 'Nihai teslim tarihi', type: 'datetime-local' },
          { label: 'Eksiksiz teslim', type: 'select', options: ['Evet', 'Hayır'] },
          { label: 'Teslimat durumu', type: 'select', options: ['Teslim edildi', 'Devam ediyor', 'İptal', 'Beklemede'] },
          { label: 'Mazeretli gecikme', type: 'select', options: ['Hayır', 'Evet'] },
          { label: 'İptal işareti', type: 'select', options: ['Hayır', 'Evet'] }
        ]
      }
    ],
    action: 'Teslimatı kaydet'
  },
  {
    id: 'KPI06',
    title: 'Yeniden İşleme Maliyeti',
    subtitle: 'Role göre saat',
    groups: [
      {
        name: 'Yeniden işleme kaydı',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Çalışma tarihi', type: 'date' },
          { label: 'Yeniden işleme saati', type: 'number', placeholder: '0.0' },
          { label: 'Rol adı', type: 'text', placeholder: 'Mühendis' },
          { label: 'Yeniden işleme nedeni', type: 'textarea', placeholder: 'Kök neden özeti' }
        ]
      }
    ],
    action: 'Yeniden işleme kaydet'
  },
  {
    id: 'KPI07',
    title: 'Standardizasyon Skoru',
    subtitle: 'Kod kalitesi ve kapsama',
    groups: [
      {
        name: 'Skor girişi',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Dönem başlangıcı', type: 'date' },
          { label: 'Dönem bitişi', type: 'date' },
          { label: 'Standardizasyon skoru', type: 'number', placeholder: '0-100' },
          { label: 'Kod inceleme kapsaması', type: 'number', placeholder: '0-100' },
          { label: 'CI geçiş oranı', type: 'number', placeholder: '0-100' },
          { label: 'Lint uyumluluğu', type: 'number', placeholder: '0-100' }
        ]
      }
    ],
    action: 'Skoru kaydet'
  },
  {
    id: 'KPI08',
    title: 'Eğitim Saatleri',
    subtitle: 'Eğitim kayıtları ve kadro',
    groups: [
      {
        name: 'Eğitim kaydı',
        fields: [
          { label: 'Kişi ID', type: 'text', placeholder: 'UUID' },
          { label: 'Kurs', type: 'text', placeholder: 'İş güvenliği temelleri' },
          { label: 'Tamamlanma tarihi', type: 'date' },
          { label: 'Saat', type: 'number', placeholder: '0.0' }
        ]
      },
      {
        name: 'Kadro anlık görüntüsü',
        fields: [
          { label: 'Departman ID', type: 'text', placeholder: 'UUID' },
          { label: 'Anlık tarih', type: 'date' },
          { label: 'Kadro', type: 'number', placeholder: '0' }
        ]
      }
    ],
    action: 'Eğitimi kaydet'
  },
  {
    id: 'KPI09',
    title: 'Yeni Teknoloji',
    subtitle: 'Otomasyon ve yeni teknoloji',
    groups: [
      {
        name: 'Teknoloji girişi',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Teknoloji etiketi', type: 'text', placeholder: 'robotik' },
          { label: 'Uygulama tarihi', type: 'date' },
          { label: 'Durum', type: 'select', options: ['POC', 'Pilot', 'Prod', 'Emekli'] },
          { label: 'Notlar', type: 'textarea', placeholder: 'Etki özeti' }
        ]
      }
    ],
    action: 'Teknolojiyi kaydet'
  },
  {
    id: 'KPI10',
    title: 'Test Kapsaması',
    subtitle: 'FAT ve SAT sonuçları',
    groups: [
      {
        name: 'Test kaydı',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Test tipi', type: 'select', options: ['FAT', 'SAT'] },
          { label: 'Deneme no', type: 'number', placeholder: '1' },
          { label: 'Sonuç', type: 'select', options: ['Geçti', 'Kaldı', 'İptal'] },
          { label: 'Test tarihi', type: 'date' },
          { label: 'İlk seferde geçti', type: 'select', options: ['Hayır', 'Evet'] }
        ]
      }
    ],
    action: 'Testi kaydet'
  },
  {
    id: 'KPI11',
    title: 'Maliyet Doğruluğu',
    subtitle: 'Tahmin ve gerçekleşen',
    groups: [
      {
        name: 'Tahmin',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Tahmin tarihi', type: 'date' },
          { label: 'Tahmini maliyet', type: 'number', placeholder: '0.00' },
          { label: 'Para birimi', type: 'text', placeholder: 'USD' },
          { label: 'Tahmin versiyonu', type: 'text', placeholder: 'v1' }
        ]
      },
      {
        name: 'Gerçekleşen maliyet',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Dönem başlangıcı', type: 'date' },
          { label: 'Dönem bitişi', type: 'date' },
          { label: 'Gerçekleşen maliyet', type: 'number', placeholder: '0.00' },
          { label: 'Para birimi', type: 'text', placeholder: 'USD' }
        ]
      }
    ],
    action: 'Maliyetleri kaydet'
  },
  {
    id: 'KPI12',
    title: 'Yetkinlik Artışı',
    subtitle: 'Başlangıç ve mevcut',
    groups: [
      {
        name: 'Değerlendirme',
        fields: [
          { label: 'Kişi ID', type: 'text', placeholder: 'UUID' },
          { label: 'Değerlendirme tipi', type: 'select', options: ['Başlangıç', 'Mevcut'] },
          { label: 'Değerlendirme döngüsü ID', type: 'text', placeholder: 'UUID' },
          { label: 'Değerlendirme tarihi', type: 'date' },
          { label: 'Yetkinlik skoru', type: 'number', placeholder: '0-100' },
          { label: 'Yetkinlik alanı', type: 'text', placeholder: 'Kontrol' }
        ]
      }
    ],
    action: 'Değerlendirmeyi kaydet'
  }
];

const extraKpis = [
  {
    id: 'KPI13',
    title: 'CSAT',
    subtitle: 'Müşteri memnuniyeti',
    groups: [
      {
        name: 'Anket',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Anket tarihi', type: 'date' },
          { label: 'Ham skor', type: 'number', placeholder: '1-5' },
          { label: 'Maks ölçek', type: 'number', placeholder: '5' },
          { label: 'Katılımcı tipi', type: 'text', placeholder: 'Müşteri' },
          { label: 'Yorum', type: 'textarea', placeholder: 'Kısa geri bildirim' }
        ]
      }
    ],
    action: 'CSAT kaydet'
  },
  {
    id: 'KPI14',
    title: 'Ekip Bağlılığı',
    subtitle: 'Ekip bağlılık skoru',
    groups: [
      {
        name: 'Anket',
        fields: [
          { label: 'Departman ID', type: 'text', placeholder: 'UUID' },
          { label: 'Anket tarihi', type: 'date' },
          { label: 'Ham skor', type: 'number', placeholder: '1-5' },
          { label: 'Maks ölçek', type: 'number', placeholder: '5' },
          { label: 'Yanıt sayısı', type: 'number', placeholder: '1' },
          { label: 'Anket döngüsü ID', type: 'text', placeholder: 'UUID' }
        ]
      }
    ],
    action: 'Bağlılığı kaydet'
  },
  {
    id: 'KPI15',
    title: 'Risk Envanteri',
    subtitle: 'Kritik emniyet riskleri',
    groups: [
      {
        name: 'Risk kaydı',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Risk kodu', type: 'text', placeholder: 'R-001' },
          { label: 'Tespit tarihi', type: 'date' },
          { label: 'Son gözden geçirme tarihi', type: 'date' },
          { label: 'Emniyet ilgili', type: 'select', options: ['Evet', 'Hayır'] },
          { label: 'Başlangıç skoru', type: 'number', placeholder: '1-25' },
          { label: 'Güncel skor', type: 'number', placeholder: '0-25' },
          { label: 'Durum', type: 'select', options: ['Açık', 'Azaltıldı', 'Kapandı'] },
          { label: 'Azaltma aksiyonları', type: 'textarea', placeholder: 'Aksiyon planı' }
        ]
      }
    ],
    action: 'Riski kaydet'
  },
  {
    id: 'KPI16',
    title: 'İnovasyon ROI',
    subtitle: 'Yatırım ve fayda',
    groups: [
      {
        name: 'ROI girişi',
        fields: [
          { label: 'Proje kodu', type: 'text', placeholder: 'PRJ-001' },
          { label: 'Dönem başlangıcı', type: 'date' },
          { label: 'Dönem bitişi', type: 'date' },
          { label: 'Yatırım maliyeti', type: 'number', placeholder: '0.00' },
          { label: 'Artan gelir', type: 'number', placeholder: '0.00' },
          { label: 'Maliyet tasarrufu', type: 'number', placeholder: '0.00' },
          { label: 'Artan maliyetler', type: 'number', placeholder: '0.00' },
          { label: 'Para birimi', type: 'text', placeholder: 'USD' }
        ]
      }
    ],
    action: 'ROI kaydet'
  }
];

function Field({ field }) {
  if (field.type === 'select') {
    return (
      <label className="field">
        <span>{field.label}</span>
        <select defaultValue="">
          <option value="" disabled>
            Seçiniz
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
        <title>KPI Kontrol Merkezi</title>
        <meta name="description" content="KPI veri girişi ve raporlama" />
      </Head>
      <div className="page">
        <header className="topbar">
          <div className="brand">
            <span className="brand-mark" />
            <div>
              <div className="brand-title">KPI Kontrol Merkezi</div>
              <div className="brand-sub">Railway + Postgres + GPT Actions altyapısı</div>
            </div>
          </div>
          <div className="top-actions">
            <button className="btn ghost" type="button">Yardım</button>
            <button className="btn" type="button">Yeni Proje</button>
          </div>
        </header>

        <div className="layout">
          <aside className="side-nav">
            <div className="nav-section">
              <div className="nav-title">Çalışma Alanı</div>
              <button className="nav-item active" type="button">Veri Girişi</button>
              <button className="nav-item" type="button">CSV İçe Aktar</button>
              <button className="nav-item" type="button">Raporlar</button>
              <button className="nav-item" type="button">Ayarlar</button>
            </div>
            <div className="nav-section">
              <div className="nav-title">Kapsam</div>
              <div className="nav-chip">Genel</div>
              <div className="nav-chip">Departman</div>
              <div className="nav-chip">Kişi</div>
            </div>
          </aside>

          <main className="main">
            <section className="hero">
              <div>
                <h1>Anlık rapor bağlantılarıyla manuel KPI girişi.</h1>
                <p>
                  Ham verileri bir kez girin, KPI'ları dönem bazında hesaplayın ve GPT'nin
                  raporları ihtiyaç olduğunda çekmesini sağlayın.
                </p>
              </div>
              <div className="hero-panel">
                <div className="hero-title">Dönem ve kapsam</div>
                <div className="hero-grid">
                  <label className="field">
                    <span>Dönem başlangıcı</span>
                    <input type="date" />
                  </label>
                  <label className="field">
                    <span>Dönem bitişi</span>
                    <input type="date" />
                  </label>
                  <label className="field">
                    <span>Kapsam tipi</span>
                    <select defaultValue="global">
                      <option value="global">Genel</option>
                      <option value="department">Departman</option>
                      <option value="person">Kişi</option>
                    </select>
                  </label>
                  <label className="field">
                    <span>Kapsam ID</span>
                    <input type="text" placeholder="UUID (genel için opsiyonel)" />
                  </label>
                </div>
                <div className="hero-actions">
                  <button className="btn" type="button">KPI'ları hesapla</button>
                  <button className="btn ghost" type="button">KPI özetini getir</button>
                </div>
              </div>
            </section>

            <section className="section">
              <div className="section-header">
                <h2>Temel KPI girdileri</h2>
                <p>KPI formülleriyle uyumlu manuel giriş modülleri.</p>
              </div>
              <div className="card-grid">
                {coreKpis.map((kpi, index) => (
                  <KpiCard key={kpi.id} kpi={kpi} index={index} />
                ))}
              </div>
            </section>

            <section className="section alt">
              <div className="section-header">
                <h2>Ek KPI girdileri</h2>
                <p>CSAT, bağlılık, risk ve ROI için opsiyonel modüller.</p>
              </div>
              <div className="card-grid">
                {extraKpis.map((kpi, index) => (
                  <KpiCard key={kpi.id} kpi={kpi} index={index + coreKpis.length} />
                ))}
              </div>
            </section>

            <section className="section">
              <div className="section-header">
                <h2>CSV veya Excel içe aktarım</h2>
                <p>Dosyaları bırakın, alanları eşleyin ve tablolara aktarın.</p>
              </div>
              <div className="dropzone">
                <div>
                  <strong>Dosyaları buraya sürükle bırak</strong>
                  <span>Kabul edilen: CSV, XLSX</span>
                </div>
                <button className="btn" type="button">Dosya yükle</button>
              </div>
            </section>
          </main>

          <aside className="right-rail">
            <div className="panel">
              <div className="panel-title">Canlı KPI özeti</div>
              <div className="metric">
                <span>KPI01 Kar Marjı</span>
                <span className="metric-value">--</span>
              </div>
              <div className="metric">
                <span>KPI02 İnovasyon Payı</span>
                <span className="metric-value">--</span>
              </div>
              <div className="metric">
                <span>KPI05 OTIF</span>
                <span className="metric-value">--</span>
              </div>
              <div className="metric">
                <span>KPI15 Risk Azaltma</span>
                <span className="metric-value">--</span>
              </div>
              <button className="btn" type="button">Sonuçları yenile</button>
            </div>

            <div className="panel">
              <div className="panel-title">GPT Actions hazır</div>
              <p className="panel-text">
                Raporlar /api/reports ve /api/reports/run üzerinden sunulur. API anahtarını
                Railway değişkenlerine ekleyin ve şemayı GPT Actions'a bağlayın.
              </p>
              <button className="btn ghost" type="button">OpenAPI şemasını kopyala</button>
            </div>

            <div className="panel">
              <div className="panel-title">Hızlı raporlar</div>
              <button className="btn ghost" type="button">KPI Özeti</button>
              <button className="btn ghost" type="button">KPI Zaman Serisi</button>
              <button className="btn ghost" type="button">Risk Envanteri</button>
              <button className="btn ghost" type="button">CSAT Detay</button>
            </div>
          </aside>
        </div>
      </div>
    </>
  );
}
