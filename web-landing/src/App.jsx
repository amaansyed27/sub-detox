import {
  CORE_PILLARS,
  LINKS,
  TEAM,
  TECH_STACK,
  WORKING_FLOW,
} from './content';

const ARCHITECTURE_LAYERS = [
  {
    title: 'Experience Layer',
    stack: 'Flutter mobile app + this React web presence',
    detail:
      'Users authenticate, link accounts, run scans, and take direct actions in a guided flow.',
  },
  {
    title: 'Intelligence Layer',
    stack: 'Rules Engine + Gemini augmentation',
    detail:
      'Deterministic detection is the source of truth; AI adds explanation and guided assistance.',
  },
  {
    title: 'Service Layer',
    stack: 'FastAPI + app-compatible APIs',
    detail:
      'Account availability, selection, analysis, revoke, chat, ticketing, and request workflows.',
  },
  {
    title: 'Identity + Data Layer',
    stack: 'Firebase Auth + Firestore',
    detail:
      'Secure identity, persistent user state, analysis history, and resolved subscription actions.',
  },
  {
    title: 'Cloud Runtime Layer',
    stack: 'Cloud Run + Cloud Build',
    detail:
      'Containerized backend delivery with repeatable CI/CD and production-ready scaling.',
  },
];

function App() {
  return (
    <div className="landing-shell">
      <div className="bg-orb orb-left" />
      <div className="bg-orb orb-right" />
      <div className="grid-overlay" />

      <header className="top-nav container">
        <div className="brand-block">
          <div className="brand-logo-wrap">
            <img
              className="brand-logo"
              src="/assets/subdetox-logo.png"
              alt="SubDetox logo"
            />
          </div>
          <div>
            <p className="brand-kicker">Hackathon Build</p>
            <h1 className="brand-title">SubDetox</h1>
          </div>
        </div>

        <div className="team-chip">
          <span className="team-logo-wrap">
            <img
              className="team-logo"
              src="/assets/redline-logo.png"
              alt="Redline logo"
            />
          </span>
          <span>Team {TEAM.name}</span>
        </div>
      </header>

      <main>
        <section className="hero container">
          <div className="hero-copy">
            <p className="section-tag">Silent Wealth Leakage Auditor</p>
            <h2>
              Detect hidden recurring debits, quantify leakage, and trigger
              action in one flow.
            </h2>
            <p>
              SubDetox combines deterministic transaction intelligence with
              resilient AI guidance to help users stop subscription and mandate
              leakage before it compounds.
            </p>

            <div className="cta-row">
              <a className="btn btn-primary" href={LINKS.apkDownload} download>
                Download Android APK
              </a>
              <a className="btn btn-secondary" href={LINKS.pptDownload} download>
                Download PPT Deck
              </a>
              <a
                className="btn btn-ghost"
                href={LINKS.githubRepo}
                target="_blank"
                rel="noreferrer"
              >
                GitHub Repository
              </a>
            </div>
          </div>

          <div className="hero-panel">
            <p className="metric-label">Demo Snapshot</p>
            <div className="metrics-grid">
              <article>
                <h3>33</h3>
                <p>Transactions Scanned</p>
              </article>
              <article>
                <h3>4</h3>
                <p>Active Risks</p>
              </article>
              <article>
                <h3>₹2,390</h3>
                <p>Potential Monthly Leakage</p>
              </article>
            </div>
            <small>
              Sample from one run. Values vary by user transaction behavior.
            </small>
          </div>
        </section>

        <section className="pillars container">
          {CORE_PILLARS.map((pillar) => (
            <article key={pillar.title} className="glass-card">
              <h3>{pillar.title}</h3>
              <p>{pillar.detail}</p>
            </article>
          ))}
        </section>

        <section className="architecture container">
          <div className="section-head">
            <p className="section-tag">Full Working Architecture</p>
            <h3>From onboarding to automated remediation support.</h3>
          </div>

          <div className="architecture-layout">
            <div className="layer-list">
              {ARCHITECTURE_LAYERS.map((layer) => (
                <article key={layer.title} className="layer-card">
                  <h4>{layer.title}</h4>
                  <p className="stack-line">{layer.stack}</p>
                  <p>{layer.detail}</p>
                </article>
              ))}
            </div>

            <div className="flow-card">
              <h4>Working Flow</h4>
              <ol>
                {WORKING_FLOW.map((step) => (
                  <li key={step}>{step}</li>
                ))}
              </ol>
              <a
                href={LINKS.architectureDoc}
                target="_blank"
                rel="noreferrer"
              >
                View detailed architecture document
              </a>
            </div>
          </div>
        </section>

        <section className="stack container">
          <div className="section-head">
            <p className="section-tag">Tech Stack</p>
            <h3>Production-minded choices for a hackathon MVP with depth.</h3>
          </div>
          <div className="stack-grid">
            {Object.entries(TECH_STACK).map(([area, items]) => (
              <article key={area} className="stack-card">
                <h4>{area.replace(/([A-Z])/g, ' $1').trim()}</h4>
                <ul>
                  {items.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </article>
            ))}
          </div>
        </section>

        <section className="video container">
          <div className="section-head">
            <p className="section-tag">Walkthrough</p>
            <h3>Embed your full product demo video here.</h3>
          </div>
          <div className="video-frame">
            <iframe
              src={LINKS.youtubeEmbed}
              title="SubDetox full walkthrough"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowFullScreen
            />
          </div>
          <p className="note-text">
            Replace the YouTube embed URL in src/content.js with your final demo
            walkthrough link before publishing.
          </p>
        </section>

        <section className="team container">
          <div className="team-card">
            <img
              className="team-logo-large"
              src="/assets/redline-logo.png"
              alt="Redline"
            />
            <div>
              <p className="section-tag">Built By</p>
              <h3>Team {TEAM.name}</h3>
              <ul>
                {TEAM.members.map((member) => (
                  <li key={member}>{member}</li>
                ))}
              </ul>
            </div>
          </div>
        </section>
      </main>

      <footer className="container footer-row">
        <p>SubDetox © {new Date().getFullYear()} · Team {TEAM.name}</p>
        <div className="footer-links">
          <a href={LINKS.githubRepo} target="_blank" rel="noreferrer">
            GitHub
          </a>
          <a href={LINKS.pptDownload} download>
            PPT Deck
          </a>
          <a href={LINKS.apkDownload} download>
            Android APK
          </a>
        </div>
      </footer>
    </div>
  );
}

export default App;
