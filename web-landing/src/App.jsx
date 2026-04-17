import { useRef, useCallback } from 'react';
import { LINKS, TEAM } from './content';
import {
  Download, ArrowUpRight, Code, Presentation,
  Zap, Brain, ShieldCheck, LogIn, ScanSearch,
  LayoutDashboard, BellRing, EyeOff, Lock,
  AlertTriangle, Users, Clock, TrendingUp, Smartphone,
} from 'lucide-react';

/* ═══════════════════════════════════════════════
   ANIMATED HERO SVG — Interactive with cursor
   ═══════════════════════════════════════════════ */
const HeroSvgArt = () => {
  const wrapRef = useRef(null);

  const onMove = useCallback((e) => {
    const el = wrapRef.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    const nx = (e.clientX - r.left) / r.width - 0.5;
    const ny = (e.clientY - r.top) / r.height - 0.5;

    const rings  = el.querySelector('.hero-layer-rings');
    const nodes  = el.querySelector('.hero-layer-nodes');
    const center = el.querySelector('.hero-layer-center');
    if (rings)  rings.style.transform  = `translate(${nx * 8}px, ${ny * 8}px)`;
    if (nodes)  nodes.style.transform  = `translate(${nx * 20}px, ${ny * 20}px)`;
    if (center) center.style.transform = `translate(${nx * 3}px, ${ny * 3}px)`;
  }, []);

  const onLeave = useCallback(() => {
    const el = wrapRef.current;
    if (!el) return;
    ['hero-layer-rings','hero-layer-nodes','hero-layer-center'].forEach(c => {
      const g = el.querySelector(`.${c}`);
      if (g) g.style.transform = 'translate(0,0)';
    });
  }, []);

  return (
    <div ref={wrapRef} onMouseMove={onMove} onMouseLeave={onLeave}
         className="w-full max-w-sm md:max-w-md lg:max-w-lg cursor-crosshair mx-auto md:mx-0">
      <svg viewBox="0 0 400 360" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-auto">
        {/* Static label */}
        <text x="200" y="350" fontSize="9" fontFamily="serif" textAnchor="middle"
              fill="#111" fontWeight="bold" letterSpacing="3" opacity="0.5">TRANSACTION SCAN</text>

        {/* LAYER 1 — Scanning rings (slow parallax, rotating) */}
        <g className="hero-layer-rings">
          <circle cx="200" cy="180" r="155" stroke="#111" strokeWidth="1.5"
                  strokeDasharray="8 6" opacity="0.3" className="hero-ring-1" />
          <circle cx="200" cy="180" r="120" stroke="#111" strokeWidth="1"
                  strokeDasharray="4 4" opacity="0.2" className="hero-ring-2" />
          {/* Pulse arcs */}
          <path d="M170 130 A 50 50 0 0 1 230 130" stroke="#B2D0B4" strokeWidth="2"
                fill="none" className="hero-center-pulse" />
          <path d="M230 230 A 50 50 0 0 1 170 230" stroke="#B2D0B4" strokeWidth="2"
                fill="none" className="hero-center-pulse" />
        </g>

        {/* LAYER 2 — Transaction nodes (fast parallax, floating) */}
        <g className="hero-layer-nodes">
          {/* Node 1 — top-left */}
          <g className="hero-float-a">
            <rect x="70" y="55" width="60" height="28" rx="2" stroke="#111" strokeWidth="1.5" fill="#F4F4F0" />
            <line x1="80" y1="65" x2="110" y2="65" stroke="#111" strokeWidth="1.5" />
            <line x1="80" y1="73" x2="120" y2="73" stroke="#111" strokeWidth="1" opacity="0.4" />
          </g>
          <path d="M130 69 L155 120" stroke="#111" strokeWidth="1" strokeDasharray="4 3" />
          <circle cx="155" cy="120" r="3" fill="#111" />

          {/* Node 2 — top-right */}
          <g className="hero-float-b">
            <rect x="275" y="40" width="65" height="28" rx="2" stroke="#111" strokeWidth="1.5" fill="#F4F4F0" />
            <line x1="285" y1="50" x2="320" y2="50" stroke="#111" strokeWidth="1.5" />
            <line x1="285" y1="58" x2="330" y2="58" stroke="#111" strokeWidth="1" opacity="0.4" />
          </g>
          <path d="M275 54 L248 125" stroke="#111" strokeWidth="1" strokeDasharray="4 3" />
          <circle cx="248" cy="125" r="3" fill="#111" />

          {/* Node 3 — right (sage) */}
          <g className="hero-float-c">
            <rect x="310" y="160" width="65" height="28" rx="2" stroke="#111" strokeWidth="1.5" fill="#B2D0B4" fillOpacity="0.35" />
            <line x1="320" y1="170" x2="355" y2="170" stroke="#111" strokeWidth="1.5" />
            <line x1="320" y1="178" x2="365" y2="178" stroke="#111" strokeWidth="1" opacity="0.4" />
          </g>
          <path d="M310 174 L260 178" stroke="#111" strokeWidth="1" strokeDasharray="4 3" />
          <circle cx="260" cy="178" r="3" fill="#111" />

          {/* Node 4 — bottom-right (flagged !) */}
          <g className="hero-float-d">
            <rect x="280" y="270" width="60" height="28" rx="2" stroke="#111" strokeWidth="2" fill="#F4F4F0" />
            <line x1="290" y1="280" x2="320" y2="280" stroke="#111" strokeWidth="1.5" />
            <line x1="290" y1="288" x2="330" y2="288" stroke="#111" strokeWidth="1" opacity="0.4" />
            <circle cx="335" cy="268" r="8" stroke="#111" strokeWidth="1.5" fill="#F4F4F0" />
            <text x="335" y="272" fontSize="11" fontFamily="serif" textAnchor="middle" fill="#111" fontWeight="bold">!</text>
          </g>
          <path d="M280 284 L245 230" stroke="#111" strokeWidth="1" strokeDasharray="4 3" />
          <circle cx="245" cy="230" r="3" fill="#111" />

          {/* Node 5 — bottom-left */}
          <g className="hero-float-e">
            <rect x="55" y="250" width="60" height="28" rx="2" stroke="#111" strokeWidth="1.5" fill="#F4F4F0" />
            <line x1="65" y1="260" x2="95" y2="260" stroke="#111" strokeWidth="1.5" />
            <line x1="65" y1="268" x2="105" y2="268" stroke="#111" strokeWidth="1" opacity="0.4" />
          </g>
          <path d="M115 264 L158 228" stroke="#111" strokeWidth="1" strokeDasharray="4 3" />
          <circle cx="158" cy="228" r="3" fill="#111" />

          {/* Node 6 — left (sage) */}
          <g className="hero-float-f">
            <rect x="25" y="140" width="60" height="28" rx="2" stroke="#111" strokeWidth="1.5" fill="#B2D0B4" fillOpacity="0.35" />
            <line x1="35" y1="150" x2="65" y2="150" stroke="#111" strokeWidth="1.5" />
            <line x1="35" y1="158" x2="75" y2="158" stroke="#111" strokeWidth="1" opacity="0.4" />
          </g>
          <path d="M85 154 L144 170" stroke="#111" strokeWidth="1" strokeDasharray="4 3" />
          <circle cx="144" cy="170" r="3" fill="#111" />
        </g>

        {/* LAYER 3 — Center shield (minimal parallax) */}
        <g className="hero-layer-center">
          <circle cx="200" cy="180" r="52" stroke="#111" strokeWidth="2" fill="#B2D0B4" fillOpacity="0.3" />
          <circle cx="200" cy="180" r="36" stroke="#111" strokeWidth="1.5" fill="#F4F4F0" />
          {/* Infinity / SubDetox mark */}
          <path d="M182 180c0-8 6-14 12-14s12 6 12 0c0 6 6 14 12 14s12-6 12-14" stroke="#111" strokeWidth="2.5" strokeLinecap="round" fill="none" />
          <path d="M182 180c0 8 6 14 12 14s12-6 12 0c0-6 6-14 12-14s12 6 12 14" stroke="#111" strokeWidth="2.5" strokeLinecap="round" fill="none" />
        </g>
      </svg>
    </div>
  );
};

/* ═══════════════════════════════════════════════
   TECH STACK PYRAMID SVG
   ═══════════════════════════════════════════════ */
const TechPyramidSvg = () => (
  <svg viewBox="0 0 440 320" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-auto max-w-lg mx-auto">
    <polygon points="40,280 400,280 370,240 70,240" stroke="#111" strokeWidth="1.5" fill="#e8e8e4" />
    <text x="220" y="266" fontSize="13" fontFamily="serif" textAnchor="middle" fill="#111" fontWeight="bold">Google Cloud · Cloud Run</text>
    <polygon points="70,240 370,240 340,200 100,200" stroke="#111" strokeWidth="1.5" fill="#B2D0B4" fillOpacity="0.4" />
    <text x="220" y="226" fontSize="13" fontFamily="serif" textAnchor="middle" fill="#111" fontWeight="bold">Firebase · Auth · Firestore</text>
    <polygon points="100,200 340,200 310,160 130,160" stroke="#111" strokeWidth="1.5" fill="#F4F4F0" />
    <text x="220" y="186" fontSize="13" fontFamily="serif" textAnchor="middle" fill="#111" fontWeight="bold">Python · FastAPI</text>
    <polygon points="130,160 310,160 280,120 160,120" stroke="#111" strokeWidth="1.5" fill="#e8e8e4" />
    <text x="220" y="146" fontSize="13" fontFamily="serif" textAnchor="middle" fill="#111" fontWeight="bold">Rules Engine</text>
    <polygon points="160,120 280,120 255,80 185,80" stroke="#111" strokeWidth="1.5" fill="#B2D0B4" fillOpacity="0.5" />
    <text x="220" y="106" fontSize="13" fontFamily="serif" textAnchor="middle" fill="#111" fontWeight="bold">Gemini API</text>
    <polygon points="185,80 255,80 220,45" stroke="#111" strokeWidth="2" fill="#111" />
    <text x="220" y="70" fontSize="12" fontFamily="serif" textAnchor="middle" fill="#F4F4F0" fontWeight="bold">Flutter</text>
    <line x1="35" y1="280" x2="35" y2="45" stroke="#111" strokeWidth="1" strokeDasharray="3 3" opacity="0.3" />
    <text x="30" y="170" fontSize="9" fontFamily="serif" fill="#111" opacity="0.5" transform="rotate(-90 30 170)" textAnchor="middle" letterSpacing="2">INFRASTRUCTURE → USER</text>
    <circle cx="220" cy="290" r="3" fill="#111" />
    <line x1="220" y1="293" x2="220" y2="310" stroke="#111" strokeWidth="1" />
    <text x="220" y="318" fontSize="9" fontFamily="serif" textAnchor="middle" fill="#111" letterSpacing="2" opacity="0.5">DEPLOYMENT</text>
  </svg>
);

/* ═══════════════════════════════════════════════
   PILLAR FLOWCHART ICONS
   ═══════════════════════════════════════════════ */
const FlowChart1 = () => (
  <svg width="80" height="40" viewBox="0 0 100 40" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-80">
    <rect x="5" y="10" width="20" height="16" /><path d="M25 18 H 40" />
    <polygon points="40,18 48,10 56,18 48,26" /><path d="M56 18 H 70" />
    <rect x="70" y="10" width="25" height="16" />
  </svg>
);
const FlowChart2 = () => (
  <svg width="80" height="40" viewBox="0 0 100 40" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-80">
    <rect x="5" y="10" width="20" height="16" /><path d="M25 18 H 40" />
    <polygon points="40,18 48,10 56,18 48,26" />
    <path d="M48 10 V 2" /><path d="M48 26 V 34" />
    <rect x="65" y="2" width="20" height="12" /><rect x="65" y="24" width="20" height="12" />
    <path d="M48 8 H 65" /><path d="M48 30 H 65" />
  </svg>
);
const FlowChart3 = () => (
  <svg width="60" height="40" viewBox="0 0 80 40" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-80">
    <rect x="5" y="5" width="25" height="10" /><path d="M17 15 V 25" />
    <rect x="5" y="25" width="25" height="10" /><path d="M30 10 H 50" /><path d="M30 30 H 50" />
    <rect x="50" y="5" width="25" height="30" />
  </svg>
);

/* ═══════════════════════════════════════════════
   TEAM MEMBER CARD
   ═══════════════════════════════════════════════ */
const TeamMemberCard = ({ name, role, initial, rotate }) => (
  <div className={`border-print p-6 bg-paper relative flex flex-col items-center text-center transform ${rotate} hover:rotate-0 transition-transform duration-300 group`}>
    <div className="w-20 h-20 border-print rounded-full flex items-center justify-center mb-5 relative overflow-hidden bg-ink text-paper group-hover:scale-105 transition-transform duration-300">
      <span className="text-3xl font-serif font-bold select-none">{initial}</span>
      <div className="absolute inset-0 circle-drawn pointer-events-none transform scale-110 opacity-40" />
    </div>
    <h4 className="text-xl font-serif font-bold mb-1">{name}</h4>
    <p className="text-xs font-bold tracking-[0.15em] uppercase text-ink/60">{role}</p>
  </div>
);

/* ═══════════════════════════════════════════════
   MAIN APP
   ═══════════════════════════════════════════════ */
function App() {
  return (
    <div className="relative min-h-screen text-ink selection:bg-ink selection:text-paper">
      <div className="noise-paper" />

      <div className="w-full min-h-screen relative">

        {/* ── Header ──────────────────────────────── */}
        <header className="px-5 md:px-16 lg:px-24 py-5 md:py-6 flex justify-between items-center border-print-b relative z-20">
          <div className="flex items-center gap-3 md:gap-4">
            <img src="/assets/subdetox-logo.png" alt="SubDetox Logo" className="h-8 md:h-10 w-auto" />
            <div>
              <h1 className="text-xl md:text-3xl font-serif font-bold tracking-tight leading-none mb-0.5">SubDetox</h1>
              <p className="text-[9px] md:text-xs font-bold tracking-[0.2em] uppercase text-ink/60">Hackathon Build</p>
            </div>
          </div>
          <div className="flex items-center gap-2 md:gap-3">
            <a href={LINKS.githubRepo} target="_blank" rel="noreferrer"
               className="stamped-btn-dark px-2.5 md:px-3 py-2 flex items-center gap-2 transform -rotate-1 hover:rotate-0 transition-transform" title="View on GitHub">
              <Code size={16} strokeWidth={2} className="text-paper" />
              <span className="text-sm font-serif font-semibold text-paper hidden md:inline">GitHub</span>
            </a>
            <div className="stamped-btn-dark px-2.5 md:px-3 py-2 flex items-center gap-2 transform rotate-1">
              <img src="/assets/redline-logo.png" alt="Team Redline" className="h-5 md:h-6 w-auto brightness-200 contrast-0 invert" />
              <span className="text-sm font-serif italic text-paper hidden md:inline">Team {TEAM.name}</span>
            </div>
          </div>
        </header>

        <main className="z-10 relative">

          {/* ── HERO ──────────────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-12 md:py-16 pb-16 md:pb-20">
            <div className="flex flex-col md:flex-row items-center gap-10 md:gap-16">
              <div className="flex-1 min-w-0">
                <h2 className="text-[2.5rem] sm:text-[3.5rem] md:text-[4.5rem] lg:text-[5.5rem] font-serif font-bold tracking-tight leading-[0.95] mb-6 md:mb-8">
                  Detect, quantify,<br />and stop leaks.
                </h2>
                <p className="text-lg md:text-2xl font-body mb-8 md:mb-10 max-w-2xl leading-relaxed">
                  SubDetox combines deterministic transaction intelligence with resilient AI guidance to help users stop recurring mandates before it compounds.
                </p>
                <div className="flex flex-wrap items-center gap-3 md:gap-4">
                  <a href={LINKS.apkDownload} className="stamped-btn-sage flex items-center gap-2 px-5 md:px-6 py-3 font-serif font-semibold text-base md:text-lg">
                    <Download size={20} strokeWidth={2.5} /> Get Android APK
                  </a>
                  <a href={LINKS.pptDownload} className="stamped-btn-dark flex items-center gap-2 px-5 md:px-6 py-3 font-serif font-semibold text-base md:text-lg">
                    View Deck <ArrowUpRight size={20} strokeWidth={2.5} />
                  </a>
                </div>
              </div>
              {/* Animated SVG — visible on all sizes */}
              <div className="flex-shrink-0 w-full md:w-auto">
                <HeroSvgArt />
              </div>
            </div>
          </section>

          {/* ── THE PROBLEM ──────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-16 md:py-20 border-print-t border-print-b bg-[#fafaf6]">
            <p className="text-xs font-bold tracking-[0.25em] uppercase text-ink/50 mb-2">The Problem</p>
            <h2 className="text-[2rem] sm:text-[2.5rem] md:text-[3.5rem] font-serif font-bold tracking-tight leading-[0.95] mb-4">The Silent Wealth Drain</h2>
            <p className="text-base md:text-lg font-body mb-10 md:mb-14 max-w-3xl leading-relaxed text-ink/80">
              Indian consumers lose thousands of rupees annually to fragmented, forgotten micro-subscriptions, hidden telecom VAS charges, and dormant UPI AutoPay mandates — often without ever realising it.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 md:gap-8">
              <div className="border-print p-6 md:p-8 bg-paper group hover:bg-accent-sage/10 transition-colors">
                <div className="relative inline-block mb-5">
                  <EyeOff size={36} strokeWidth={1.2} />
                  <div className="absolute inset-0 circle-drawn pointer-events-none transform scale-[1.5] rotate-6" />
                </div>
                <h3 className="text-lg md:text-xl font-serif font-bold mb-2">Invisible by Design</h3>
                <p className="font-body text-[13px] md:text-[14px] leading-relaxed text-ink/70">
                  Scattered across multiple banking apps with zero unified visibility.
                </p>
              </div>
              <div className="border-print p-6 md:p-8 bg-paper group hover:bg-accent-sage/10 transition-colors">
                <div className="relative inline-block mb-5">
                  <Lock size={36} strokeWidth={1.2} />
                  <div className="absolute inset-0 circle-drawn-alt pointer-events-none transform scale-[1.5] -rotate-3" />
                </div>
                <h3 className="text-lg md:text-xl font-serif font-bold mb-2">Dark Pattern Traps</h3>
                <p className="font-body text-[13px] md:text-[14px] leading-relaxed text-ink/70">
                  Cancellation flows are deliberately complex and buried deep.
                </p>
              </div>
              <div className="border-print p-6 md:p-8 bg-paper group hover:bg-accent-sage/10 transition-colors">
                <div className="relative inline-block mb-5">
                  <AlertTriangle size={36} strokeWidth={1.2} />
                  <div className="absolute inset-0 circle-drawn pointer-events-none transform scale-[1.5] rotate-12" />
                </div>
                <h3 className="text-lg md:text-xl font-serif font-bold mb-2">No Oversight</h3>
                <p className="font-body text-[13px] md:text-[14px] leading-relaxed text-ink/70">
                  Users have no way to audit recurring debits at a glance.
                </p>
              </div>
            </div>
          </section>

          {/* ── THE SCALE — Stat Strip ────────────── */}
          <div className="border-print-b flex flex-col md:flex-row divide-y-[1.5px] md:divide-y-0 md:divide-x-[1.5px] divide-ink border-ink">
            <div className="flex-1 py-10 md:py-12 flex flex-col items-center justify-center relative">
              <div className="relative inline-block mb-3">
                <h4 className="text-4xl md:text-6xl font-serif font-bold relative z-10 px-4 py-2">1B+</h4>
                <div className="absolute inset-0 circle-drawn pointer-events-none transform -rotate-2 scale-110" />
              </div>
              <p className="text-[10px] md:text-xs font-bold tracking-widest uppercase">Monthly Recurring Debits</p>
              <p className="text-[11px] font-body text-ink/50 mt-2 max-w-[200px] text-center hidden md:block">UPI AutoPay processes nearly 1 billion recurring transactions every month</p>
            </div>
            <div className="flex-1 py-10 md:py-12 flex flex-col items-center justify-center relative">
              <div className="relative inline-block mb-3">
                <h4 className="text-4xl md:text-6xl font-serif font-bold relative z-10 px-6 py-2">870M+</h4>
                <div className="absolute inset-0 border-print rounded-[50%] pointer-events-none transform rotate-3" />
              </div>
              <p className="text-[10px] md:text-xs font-bold tracking-widest uppercase">Active Mandates</p>
              <p className="text-[11px] font-body text-ink/50 mt-2 max-w-[200px] text-center hidden md:block">Over 870 million active UPI mandates per RBI data</p>
            </div>
            <div className="flex-1 py-10 md:py-12 flex flex-col items-center justify-center relative">
              <div className="relative inline-block mb-3">
                <h4 className="text-4xl md:text-6xl font-serif font-bold relative z-10 px-4 py-2">↑↑↑</h4>
                <div className="absolute inset-0 circle-drawn-alt pointer-events-none transform -rotate-1 scale-[1.15]" />
              </div>
              <p className="text-[10px] md:text-xs font-bold tracking-widest uppercase">Complaint Surge</p>
              <p className="text-[11px] font-body text-ink/50 mt-2 max-w-[200px] text-center hidden md:block">Sharp rise in consumer complaints about unexplained involuntary debits</p>
            </div>
          </div>

          {/* ── THE SOLUTION ─────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-16 md:py-24 border-print-b">
            <p className="text-xs font-bold tracking-[0.25em] uppercase text-ink/50 mb-2">The Solution</p>
            <h2 className="text-[2rem] sm:text-[2.5rem] md:text-[3.5rem] font-serif font-bold tracking-tight leading-[0.95] mb-8 md:mb-10 max-w-4xl">
              An AI-driven financial auditor that bypasses intentional corporate complexity.
            </h2>
            <div className="flex flex-col md:flex-row gap-6 md:gap-12 items-start">
              <p className="text-base md:text-xl font-body leading-relaxed max-w-2xl text-ink/80">
                SubDetox shifts the power dynamic from corporations back to the individual, compressing hours of frustration into a single moment of clarity — giving consumers absolute, unambiguous control over every recurring payment.
              </p>
              <div className="flex flex-col gap-3 flex-shrink-0">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-accent-sage rounded-full flex items-center justify-center border-print"><ScanSearch size={20} strokeWidth={1.5} /></div>
                  <span className="font-serif font-bold text-sm">Expose</span>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-paper rounded-full flex items-center justify-center border-print"><ShieldCheck size={20} strokeWidth={1.5} /></div>
                  <span className="font-serif font-bold text-sm">Decide</span>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-ink text-paper rounded-full flex items-center justify-center border-print"><Zap size={20} strokeWidth={1.5} /></div>
                  <span className="font-serif font-bold text-sm">Revoke</span>
                </div>
              </div>
            </div>
          </section>

          {/* ── PILLARS ──────────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-14 md:py-16 border-print-b">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-12">
              <div className="flex flex-col">
                <div className="flex items-center gap-4 mb-4">
                  <div className="relative">
                    <ShieldCheck size={36} strokeWidth={1} />
                    <div className="absolute inset-0 circle-drawn pointer-events-none transform scale-[1.3] rotate-6" />
                  </div>
                  <FlowChart1 />
                </div>
                <h3 className="text-lg md:text-xl font-serif font-bold mb-3 mt-4">Rules-First Detection</h3>
                <p className="font-body text-[13px] md:text-[15px] leading-relaxed">
                  SubDetox's transaction intelligence with firm, deterministic scoring patterns — no black-box guessing.
                </p>
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-4 mb-4">
                  <div className="relative">
                    <Brain size={36} strokeWidth={1} />
                    <div className="absolute inset-0 circle-drawn-alt pointer-events-none transform scale-[1.4] -rotate-3" />
                  </div>
                  <FlowChart2 />
                </div>
                <h3 className="text-lg md:text-xl font-serif font-bold mb-3 mt-4">AI-Enhanced Insights</h3>
                <p className="font-body text-[13px] md:text-[15px] leading-relaxed">
                  Optional Gemini-powered enrichment surfaces unknown mandates via semantic anomaly detection.
                </p>
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-4 mb-4">
                  <div className="relative">
                    <Zap size={36} strokeWidth={1} />
                    <div className="absolute inset-0 circle-drawn pointer-events-none transform scale-[1.4] rotate-12" />
                  </div>
                  <FlowChart3 />
                </div>
                <h3 className="text-lg md:text-xl font-serif font-bold mb-3 mt-4">Action-Driven UX</h3>
                <p className="font-body text-[13px] md:text-[15px] leading-relaxed">
                  Pro-active UI that empowers one-tap revocation ticketing directly to service providers.
                </p>
              </div>
            </div>
          </section>

          {/* ── HOW IT WORKS ─────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-16 md:py-20 border-print-b bg-[#fafaf6]">
            <p className="text-xs font-bold tracking-[0.25em] uppercase text-ink/50 mb-2">Step by Step</p>
            <h2 className="text-[2rem] sm:text-[2.5rem] md:text-[3.5rem] font-serif font-bold tracking-tight mb-4 leading-[0.95]">How It Works</h2>
            <p className="text-base md:text-lg font-body mb-10 md:mb-12 max-w-2xl">From sign-in to resolution — five steps to reclaim your leaked subscriptions.</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-0">
              {[
                { n: 1, icon: <LogIn size={24} strokeWidth={1.5} />, title: 'Sign In', desc: 'Authenticate via Firebase — Email, Google, or OTP. Your data stays yours.' },
                { n: 2, icon: <ScanSearch size={24} strokeWidth={1.5} />, title: 'Link Accounts', desc: 'Discover and select linked bank accounts to pull transaction history from.' },
                { n: 3, icon: <Brain size={24} strokeWidth={1.5} />, title: 'Analyze', desc: 'Rules-first detection scores every transaction. Gemini AI enriches with semantic insights.' },
                { n: 4, icon: <LayoutDashboard size={24} strokeWidth={1.5} />, title: 'Review Dashboard', desc: 'See risk-prioritized subscriptions, monthly leakage totals, and threat scores at a glance.' },
                { n: 5, icon: <BellRing size={24} strokeWidth={1.5} />, title: 'Resolve', desc: 'One-tap revocation tickets, service requests, or guided AI chat to cancel subscriptions.' },
              ].map((s) => (
                <div key={s.n} className="border-print p-5 bg-paper relative group hover:bg-accent-sage/20 transition-colors">
                  <div className="flex items-center gap-3 mb-5">
                    <div className="w-10 h-10 bg-ink text-paper rounded-full flex items-center justify-center font-serif font-bold text-lg">{s.n}</div>
                    {s.icon}
                  </div>
                  <h4 className="text-base md:text-lg font-serif font-bold mb-2">{s.title}</h4>
                  <p className="font-body text-[12px] md:text-[13px] leading-relaxed text-ink/70">{s.desc}</p>
                </div>
              ))}
            </div>
          </section>

          {/* ── IMPACT — Stat Strip ──────────────── */}
          <div className="border-print-b flex flex-col md:flex-row divide-y-[1.5px] md:divide-y-0 md:divide-x-[1.5px] divide-ink border-ink">
            <div className="flex-1 py-10 md:py-14 flex flex-col items-center justify-center relative px-4">
              <div className="relative inline-block mb-3">
                <TrendingUp size={28} strokeWidth={1.5} className="mb-2 mx-auto block text-accent-sage" />
                <h4 className="text-4xl md:text-6xl font-serif font-bold relative z-10 px-4 py-1">₹3K</h4>
                <div className="absolute inset-0 circle-drawn pointer-events-none transform -rotate-2 scale-110" />
              </div>
              <p className="text-[10px] md:text-xs font-bold tracking-widest uppercase mb-1">Saved Per User</p>
              <p className="text-[11px] font-body text-ink/50 text-center max-w-[220px]">Reclaims ₹1,500–₹3,000 annually in involuntary recurring charges per user</p>
            </div>
            <div className="flex-1 py-10 md:py-14 flex flex-col items-center justify-center relative px-4">
              <div className="relative inline-block mb-3">
                <Clock size={28} strokeWidth={1.5} className="mb-2 mx-auto block text-accent-sage" />
                <h4 className="text-4xl md:text-6xl font-serif font-bold relative z-10 px-6 py-1">5s</h4>
                <div className="absolute inset-0 border-print rounded-[50%] pointer-events-none transform rotate-3" />
              </div>
              <p className="text-[10px] md:text-xs font-bold tracking-widest uppercase mb-1">To Cancel</p>
              <p className="text-[11px] font-body text-ink/50 text-center max-w-[220px]">Compresses 10–15 minute cancellation loops into a single 5-second action</p>
            </div>
            <div className="flex-1 py-10 md:py-14 flex flex-col items-center justify-center relative px-4">
              <div className="relative inline-block mb-3">
                <Users size={28} strokeWidth={1.5} className="mb-2 mx-auto block text-accent-sage" />
                <h4 className="text-4xl md:text-6xl font-serif font-bold relative z-10 px-4 py-1">₹150Cr</h4>
                <div className="absolute inset-0 circle-drawn-alt pointer-events-none transform -rotate-1 scale-[1.15]" />
              </div>
              <p className="text-[10px] md:text-xs font-bold tracking-widest uppercase mb-1">Macro Impact</p>
              <p className="text-[11px] font-body text-ink/50 text-center max-w-[220px]">Just 1M users prevents over ₹150 crores in annual involuntary wealth drain</p>
            </div>
          </div>
          <p className="text-center font-body text-sm md:text-base italic py-8 md:py-10 px-5 text-ink/60 border-print-b">
            SubDetox doesn't just save money — it restores financial agency to hundreds of millions of underserved consumers.
          </p>

          {/* ── WHO BENEFITS ─────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-16 md:py-20 border-print-b">
            <p className="text-xs font-bold tracking-[0.25em] uppercase text-ink/50 mb-2">Target Audience</p>
            <h2 className="text-[2rem] sm:text-[2.5rem] md:text-[3.5rem] font-serif font-bold tracking-tight leading-[0.95] mb-10 md:mb-14">Who Benefits?</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 md:gap-8 max-w-3xl">
              <div className="border-print p-6 md:p-8 bg-paper relative group hover:bg-accent-sage/10 transition-colors">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-12 h-12 bg-ink text-paper rounded-full flex items-center justify-center border-print">
                    <Smartphone size={24} strokeWidth={1.5} />
                  </div>
                  <h3 className="text-lg md:text-xl font-serif font-bold">Gen Z & Millennials</h3>
                </div>
                <p className="font-body text-[13px] md:text-[14px] leading-relaxed text-ink/70">
                  Urban and semi-urban middle class suffering from subscription fatigue — subscribed to everything, tracking nothing.
                </p>
              </div>
              <div className="border-print p-6 md:p-8 bg-paper relative group hover:bg-accent-sage/10 transition-colors">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-12 h-12 bg-accent-sage rounded-full flex items-center justify-center border-print">
                    <Users size={24} strokeWidth={1.5} />
                  </div>
                  <h3 className="text-lg md:text-xl font-serif font-bold">Gen X & Boomers</h3>
                </div>
                <p className="font-body text-[13px] md:text-[14px] leading-relaxed text-ink/70">
                  Older demographics vulnerable to deceptive auto-renewals, lacking the digital literacy to navigate opaque banking interfaces.
                </p>
              </div>
            </div>
          </section>

          {/* ── TECH STACK ────────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-16 md:py-20 border-print-b">
            <div className="flex flex-col lg:flex-row items-start lg:items-center gap-10 lg:gap-20">
              <div className="flex-1">
                <p className="text-xs font-bold tracking-[0.25em] uppercase text-ink/50 mb-2">Under the Hood</p>
                <h2 className="text-[2rem] sm:text-[2.5rem] md:text-[3.5rem] font-serif font-bold tracking-tight leading-[0.95] mb-6">Tech Stack</h2>
                <div className="space-y-4 md:space-y-5">
                  {[
                    { icon: 'F', bg: 'bg-ink text-paper', name: 'Flutter', desc: 'Cross-platform mobile app with Provider state management' },
                    { icon: '🔥', bg: 'bg-accent-sage', name: 'Firebase', desc: 'Auth, Firestore for real-time data, and Cloud Functions' },
                    { icon: '⚡', bg: '', name: 'Python · FastAPI', desc: 'High-performance async backend with Pydantic validation' },
                    { icon: '📏', bg: '', name: 'Rules Engine', desc: 'Deterministic transaction scoring with confidence and threat levels' },
                    { icon: '✦', bg: 'bg-accent-sage', name: 'Gemini API', desc: 'AI enrichment, anomaly detection, and agentic chat guidance' },
                    { icon: '☁', bg: 'bg-ink text-paper', name: 'Google Cloud', desc: 'Cloud Run deployment with Cloud Build CI/CD pipeline' },
                  ].map((t) => (
                    <div key={t.name} className="flex items-start gap-3 md:gap-4">
                      <div className={`w-8 h-8 border-print rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 font-serif font-bold text-sm ${t.bg}`}>{t.icon}</div>
                      <div>
                        <h4 className="font-serif font-bold text-base md:text-lg">{t.name}</h4>
                        <p className="font-body text-[12px] md:text-[13px] text-ink/70">{t.desc}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="flex-1 w-full">
                <TechPyramidSvg />
              </div>
            </div>
          </section>

          {/* ── THE TEAM ──────────────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-16 md:py-20 border-print-b">
            <div className="flex flex-col md:flex-row items-start md:items-end gap-6 mb-10 md:mb-12">
              <div className="flex-1">
                <p className="text-xs font-bold tracking-[0.25em] uppercase text-ink/50 mb-2">Built by</p>
                <h2 className="text-[2rem] sm:text-[2.5rem] md:text-[3.5rem] font-serif font-bold tracking-tight leading-[0.95]">The Team</h2>
              </div>
              <div className="flex items-center gap-4 opacity-90">
                <img src="/assets/redline-logo.png" alt="Team Redline" className="h-12 md:h-20 w-auto" />
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 max-w-xl">
              <TeamMemberCard name="Amaan Syed" role="Full-Stack · AI" initial="AS" rotate="rotate-[-1deg]" />
              <TeamMemberCard name="Chaitanya" role="Backend · Systems" initial="C" rotate="rotate-[1.5deg]" />
            </div>
            <div className="mt-8 md:mt-10 flex items-center gap-4">
              <a href={LINKS.githubRepo} target="_blank" rel="noreferrer"
                 className="stamped-btn-sage flex items-center gap-3 px-5 md:px-6 py-3 font-serif font-semibold text-base md:text-lg">
                <Code size={22} strokeWidth={2} /> View on GitHub <ArrowUpRight size={18} strokeWidth={2.5} />
              </a>
            </div>
          </section>

          {/* ── DEMO WALKTHROUGH ──────────────────── */}
          <section className="px-5 md:px-16 lg:px-24 py-16 md:py-20 flex flex-col md:flex-row gap-10 md:gap-12 items-center">
            <div className="w-full md:w-1/2">
              <h2 className="text-[2rem] md:text-[2.5rem] font-serif font-bold tracking-tight mb-2">Demo Walkthrough</h2>
              <p className="text-lg md:text-xl font-body">See SubDetox in action from end to end.</p>
            </div>
            <div className="w-full md:w-1/2">
              <div className="border-print p-1 bg-ink relative shadow-[6px_6px_0px_rgba(0,0,0,0.8)] rounded-sm">
                <div className="aspect-video bg-[#0a0a0a] w-full overflow-hidden filter grayscale contrast-125 opacity-90 relative">
                  <div className="noise-paper opacity-50 z-10 mix-blend-overlay" />
                  <iframe src={LINKS.youtubeEmbed} title="SubDetox full walkthrough"
                          className="absolute inset-0 w-full h-full border-0"
                          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                          allowFullScreen />
                </div>
              </div>
            </div>
          </section>

        </main>

        {/* ── Footer ──────────────────────────────── */}
        <footer className="px-5 md:px-16 lg:px-24 py-8 md:py-10 border-print-t flex flex-col md:flex-row justify-between items-center gap-4 md:gap-6 text-sm font-serif font-bold bg-[#fafaf6]">
          <div className="flex items-center gap-3">
            <img src="/assets/subdetox-logo.png" alt="SubDetox" className="h-5 md:h-6 w-auto opacity-70" />
            <p>SubDetox © {new Date().getFullYear()} · Team {TEAM.name}</p>
          </div>
          <div className="flex gap-6 md:gap-8">
            <a href={LINKS.githubRepo} target="_blank" rel="noreferrer" className="hover:underline flex items-center gap-2">
              <Code size={16} strokeWidth={2.5} /> GitHub
            </a>
            <a href={LINKS.pptDownload} download className="hover:underline flex items-center gap-2">
              <Presentation size={16} strokeWidth={2.5} /> Presentation Deck
            </a>
          </div>
        </footer>

      </div>
    </div>
  );
}

export default App;
