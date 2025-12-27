# Shredders - Production Deployment Checklist

## Pre-Deployment Checklist

### 1. Environment Variables
- [ ] Copy `.env.example` to `.env.local` (if not already done)
- [ ] Add your `OPENAI_API_KEY` to `.env.local`
- [ ] Set `NEXT_PUBLIC_BASE_URL` to your production URL
- [ ] **IMPORTANT**: Ensure `.env.local` is in `.gitignore` (already configured)
- [ ] Add environment variables to your hosting platform (Vercel, etc.)

### 2. API Keys & Security
- [ ] Verify API keys are valid and have appropriate rate limits
- [ ] Optional: Add `ANTHROPIC_API_KEY` if using Claude features
- [ ] Review security headers in `next.config.ts`
- [ ] Ensure no API keys are committed to git

### 3. SEO & Metadata
- [x] SEO metadata configured in `src/app/layout.tsx`
- [x] Open Graph and Twitter cards configured
- [x] Sitemap generated at `/sitemap.xml`
- [x] Robots.txt configured
- [x] PWA manifest configured
- [ ] Update `metadataBase` URL in `src/app/layout.tsx` with your production domain
- [ ] Add Google/Bing verification codes when ready (in `src/app/layout.tsx`)

### 4. Performance & Optimization
- [x] Production build tested (`npm run build`)
- [x] Security headers configured
- [x] Image optimization enabled
- [x] React Strict Mode enabled
- [ ] Test page load speeds
- [ ] Review bundle size with `npm run build`

### 5. Error Handling
- [x] Custom 404 page configured
- [x] Global error boundary configured
- [x] Loading states for all pages
- [x] API error handling in all routes
- [ ] Test error scenarios manually

### 6. Content & Assets
- [x] Favicon placeholder created (update with actual icon)
- [x] App icons configured
- [ ] Generate proper favicon.ico from logo.svg
- [ ] Add OG image for social sharing (recommended size: 1200x630px)
- [ ] Test on multiple devices/browsers

### 7. Analytics & Monitoring (Optional)
- [ ] Add Google Analytics (if desired)
- [ ] Add error monitoring (Sentry, LogRocket, etc.)
- [ ] Set up performance monitoring
- [ ] Configure uptime monitoring

### 8. Legal & Compliance
- [ ] Add Privacy Policy (if collecting user data)
- [ ] Add Terms of Service
- [ ] Add Cookie consent (if using analytics)
- [ ] Review GDPR/CCPA compliance

### 9. Testing
- [ ] Test all pages load correctly
- [ ] Test API endpoints respond correctly
- [ ] Test error pages (404, 500)
- [ ] Test on mobile devices
- [ ] Test with slow network conditions
- [ ] Verify all external API integrations work

### 10. Deployment Platform (Vercel)
- [ ] Connect GitHub repository to Vercel
- [ ] Add environment variables in Vercel dashboard
- [ ] Configure custom domain (optional)
- [ ] Set up SSL certificate (automatic with Vercel)
- [ ] Enable automatic deployments from main branch
- [ ] Test preview deployments

## Post-Deployment

### Immediate
- [ ] Verify production site loads correctly
- [ ] Check all API endpoints work
- [ ] Test chat functionality
- [ ] Verify mountain data loads
- [ ] Check console for errors

### Within 24 Hours
- [ ] Submit sitemap to Google Search Console
- [ ] Submit sitemap to Bing Webmaster Tools
- [ ] Monitor error logs
- [ ] Check analytics setup (if configured)

### Within 1 Week
- [ ] Monitor API rate limits and costs
- [ ] Review performance metrics
- [ ] Gather user feedback
- [ ] Fix any reported issues

## Production URLs to Test

After deployment, test these URLs:
- `https://your-domain.com/` - Homepage
- `https://your-domain.com/mountains` - Mountains list
- `https://your-domain.com/chat` - AI chat
- `https://your-domain.com/sitemap.xml` - Sitemap
- `https://your-domain.com/robots.txt` - Robots file
- `https://your-domain.com/manifest.webmanifest` - PWA manifest
- `https://your-domain.com/api/mountains` - API test

## Important Notes

### Environment Variables
Your `.env.local` contains sensitive API keys. It is **NOT** committed to git.
When deploying to Vercel or another platform, add these variables in their dashboard.

### Rate Limiting
A basic in-memory rate limiter is included in `src/lib/api-utils.ts`.
For production at scale, consider using:
- Vercel Edge Config
- Upstash Redis
- CloudFlare Rate Limiting

### Favicon
The current `favicon.ico` is a placeholder. Generate a proper favicon:
```bash
# Use a tool like https://realfavicongenerator.net/
# Or generate from your logo.svg
```

### Custom Domain
If using a custom domain:
1. Update `NEXT_PUBLIC_BASE_URL` in your environment
2. Update `metadataBase` in `src/app/layout.tsx`
3. Configure DNS records
4. Set up in Vercel dashboard

## Quick Deploy to Vercel

```bash
# Install Vercel CLI (if not already installed)
npm i -g vercel

# Deploy
vercel

# Or deploy to production directly
vercel --prod
```

## Support & Resources

- Next.js Docs: https://nextjs.org/docs
- Vercel Docs: https://vercel.com/docs
- Report Issues: Create an issue in your repository

---

**Ready to deploy?** Make sure you've completed all items with [ ] before pushing to production!
