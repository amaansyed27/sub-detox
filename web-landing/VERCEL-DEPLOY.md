# Deploy on Vercel (Dashboard)

Use these steps to deploy web-landing from the Vercel web dashboard.

## 1. Push latest code

Make sure your repository has web-landing committed and pushed.

## 2. Import project in Vercel

1. Open Vercel dashboard
2. Click Add New -> Project
3. Import repository: amaansyed27/sub-detox

## 3. Configure build settings

In Project Settings during import:

- Framework Preset: Vite
- Root Directory: web-landing
- Build Command: npm run build
- Output Directory: dist
- Install Command: npm install

## 4. Deploy

Click Deploy and wait for build to finish.

## 5. Verify resource links

After deploy, verify these open correctly:

- APK download button
- PPT download button
- GitHub button
- Architecture doc button
- YouTube embed

## 6. Update video and deck links

If you have a final demo video or final deck, update src/content.js:

- LINKS.youtubeEmbed
- LINKS.pptDownload

Then push changes; Vercel will auto-redeploy.

## Optional: custom domain

1. Go to project Settings -> Domains
2. Add your custom domain
3. Follow DNS instructions from Vercel
