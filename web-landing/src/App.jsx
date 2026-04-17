import {
  CORE_PILLARS,
  LINKS,
  TEAM,
  TECH_STACK,
  WORKING_FLOW,
} from './content';

import { motion } from 'framer-motion';
import { Download, ChevronRight, Github } from 'lucide-react';
import './styles2.css';

const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: 'easeOut' } }
};

const staggerContainer = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.2 } }
};

function App() {
  return (
    <>
      <div className="bg-beams" />
      <div className="noise" />

      <header className="container top-nav">
        <motion.div 
          className="brand-block"
          initial={{ opacity: 0, x: -30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.6 }}
        >
          <div className="brand-logo-wrap">
            <img src="/assets/subdetox-logo.png" alt="SubDetox logo" style={{ width: 48, height: 48 }} />
          </div>
          <div>
            <p className="brand-kicker">Hackathon Build</p>
            <h1 className="brand-title">SubDetox</h1>
          </div>
        </motion.div>

        <motion.div 
          className="team-chip"
          initial={{ opacity: 0, x: 30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.6 }}
        >
          <img src="/assets/redline-logo.png" alt="Redline logo" style={{ width: 32, height: 32 }} />
          <span>Team {TEAM.name}</span>
        </motion.div>
      </header>

      <main>
        <section className="section hero">
          <div className="container hero-content">
            <motion.div
              initial="hidden"
              animate="visible"
              variants={staggerContainer}
            >
              <motion.div variants={fadeUp}>
                <span className="tagline">Silent Wealth Leakage Auditor</span>
              </motion.div>
              <motion.h2 variants={fadeUp} className="hero-title">
                Detect, quantify, and stop subscription leaks.
              </motion.h2>
              <motion.p variants={fadeUp} className="hero-subtitle">
                SubDetox combines deterministic transaction intelligence with resilient AI guidance to help users stop recurring mandates before it compounds.
              </motion.p>
              
              <motion.div variants={fadeUp} className="btn-group">
                <a className="btn btn-primary" href={LINKS.apkDownload} download>
                  <Download size={20} /> Get Android APK
                </a>
                <a className="btn btn-secondary" href={LINKS.pptDownload} download>
                  <ChevronRight size={20} /> View Deck
                </a>
                <a className="btn btn-outline" href={LINKS.githubRepo} target="_blank" rel="noreferrer">
                  <Github size={20} /> View Code
                </a>
              </motion.div>
            </motion.div>

            <motion.div 
              className="glass-panel"
              style={{ marginTop: 80 }}
              initial={{ opacity: 0, y: 40 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              <h3 style={{ color: 'var(--muted)', textAlign: 'left', marginBottom: 10 }}>Live Demo Metrics</h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 20 }}>
                <div style={{ padding: 20 }}>
                  <h4 style={{ fontSize: 36, color: 'var(--mint)' }}>33</h4>
                  <p style={{ color: 'var(--muted)', fontSize: 14 }}>Transactions Scanned</p>
                </div>
                <div style={{ padding: 20 }}>
                  <h4 style={{ fontSize: 36, color: '#f87171' }}>4</h4>
                  <p style={{ color: 'var(--muted)', fontSize: 14 }}>Active Risks</p>
                </div>
                <div style={{ padding: 20 }}>
                  <h4 style={{ fontSize: 36, color: '#fff' }}>₹2,390</h4>
                  <p style={{ color: 'var(--muted)', fontSize: 14 }}>Monthly Leakage Detected</p>
                </div>
              </div>
            </motion.div>
          </div>
        </section>

        <section className="section container">
          <div className="section-head">
            <h2>Core Pillars</h2>
            <p style={{ color: 'var(--muted)' }}>Intelligence without the compromise.</p>
          </div>
          <motion.div 
            className="grid-3"
            variants={staggerContainer}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
          >
            {CORE_PILLARS.map((pillar) => (
              <motion.div key={pillar.title} variants={fadeUp} className="feature-box">
                <h3 style={{ marginBottom: '10px', color: '#fff' }}>{pillar.title}</h3>
                <p style={{ color: 'var(--muted)' }}>{pillar.detail}</p>
              </motion.div>
            ))}
          </motion.div>
        </section>

        <section className="section container">
          <div className="section-head">
            <h2>Architecture Stack</h2>
            <p style={{ color: 'var(--muted)' }}>A robust pyramid covering mobile, intelligent backend, data, and cloud layers.</p>
          </div>
          
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '40px', justifyContent: 'center' }}>
            <motion.div 
              className="pyramid-container" 
              style={{ flex: '1 1 500px' }}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
              variants={staggerContainer}
            >
              <motion.div variants={fadeUp} className="pyramid-layer top">
                <div className="layer-title">Experience Layer</div>
                <div className="layer-stack">Flutter | React + Vite</div>
                <div className="layer-desc">Guided mobile flow & web presence.</div>
              </motion.div>

              <motion.div variants={fadeUp} className="pyramid-layer middle">
                <div className="layer-title">Intelligence & Services</div>
                <div className="layer-stack">FastAPI | Gemini AI | Rules Engine</div>
                <div className="layer-desc">Deterministic detection paired with Gen AI reasoning.</div>
              </motion.div>

              <motion.div variants={fadeUp} className="pyramid-layer bottom">
                <div className="layer-title">Data & Cloud Runtime</div>
                <div className="layer-stack">Firebase Auth & Firestore | Google Cloud Run</div>
                <div className="layer-desc">Secure identity, state persistence, and auto-scaling containers.</div>
              </motion.div>
            </motion.div>
            
            <motion.div 
              style={{ flex: '1 1 300px' }}
              initial={{ opacity: 0, x: 30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
            >
              <div className="glass-panel" style={{ padding: 30, height: '100%' }}>
                <h3 style={{ marginBottom: 20, color: 'var(--mint)' }}>Working Flow</h3>
                <ul className="flow-list">
                  {WORKING_FLOW.map((step, i) => (
                    <li key={i} className="flow-item">
                      <span className="flow-num">{i + 1}</span>
                      <span style={{ fontSize: 14 }}>{step}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </motion.div>
          </div>
        </section>

        <section className="section container">
          <div className="section-head">
            <h2>Demo Walkthrough</h2>
            <p style={{ color: 'var(--muted)' }}>See SubDetox in action from end to end.</p>
          </div>
          <motion.div 
            className="video-frame"
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <iframe
              src={LINKS.youtubeEmbed}
              title="SubDetox full walkthrough"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowFullScreen
            />
          </motion.div>
        </section>
      </main>

      <footer className="footer container">
        <p>SubDetox © {new Date().getFullYear()} · Team {TEAM.name}</p>
        <div className="footer-links">
            <a href={LINKS.githubRepo} target="_blank" rel="noreferrer">
              GitHub Repository
            </a>
            <a href={LINKS.pptDownload} download>
              Presentation Deck
            </a>
        </div>
      </footer>
    </>
