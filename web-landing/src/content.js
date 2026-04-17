export const LINKS = {
  githubRepo: 'https://github.com/amaansyed27/sub-detox',
  apkDownload:
    'https://raw.githubusercontent.com/amaansyed27/sub-detox/main/android-apk/subdetox-android.apk',
  pptDownload: '/downloads/subdetox-hackathon-deck.pptx',
  architectureDoc:
    'https://github.com/amaansyed27/sub-detox/blob/main/rules-engine-working.md',
  youtubeEmbed: 'https://www.youtube.com/embed/aqz-KE-bpKQ',
};

export const TEAM = {
  name: 'Redline',
  members: ['Amaan Syed', 'Lingareddy Chaitanya Chakravarti Reddy'],
};

export const CORE_PILLARS = [
  {
    title: 'Rules-First Detection',
    detail:
      'Deterministic recurring-charge detection from transaction patterns with confidence and threat scoring.',
  },
  {
    title: 'AI-Enhanced Insights',
    detail:
      'Gemini enrichment and agentic chat with fallback safety so core analysis never fails.',
  },
  {
    title: 'Action-Driven UX',
    detail:
      'From detection to revocation, tickets, and service requests in one guided mobile flow.',
  },
];

export const WORKING_FLOW = [
  'Sign in via Firebase Auth (Email, Google, or OTP)',
  'Discover and select linked accounts',
  'Run transaction analysis (rules-first, AI-enhanced)',
  'View leakage dashboard with risk-prioritized subscriptions',
  'Resolve through revoke flow, tickets, requests, or guided chat',
];

export const TECH_STACK = {
  frontend: ['React + Vite (landing)', 'Flutter + Provider (mobile app)'],
  backend: ['Python FastAPI', 'Pydantic schemas', 'Uvicorn'],
  ai: ['Gemini analysis enrichment', 'Grounded chat + agentic actions'],
  dataInfra: ['Firebase Auth', 'Firestore', 'Cloud Run + Cloud Build'],
};
