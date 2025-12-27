# Shredders - Performance Analysis & Optimization Plan

## Current Performance Issues

### Problem: Slow Mountain Navigation
When users navigate between mountains, they experience 2-5 second loading delays.

### Root Causes Identified

#### 1. **Sequential API Waterfall** (lines 164-238 in mountain page)
```
Current: 3 blocking calls + 6 non-blocking calls
- /api/mountains/${id}/conditions
- /api/mountains/${id}/powder-score
- /api/mountains/${id}/forecast
Plus: roads, trip-advice, powder-day, alerts, weather-gov-links, etc.

Each call hits external APIs:
- SNOTEL (USDA)
- NOAA Weather.gov
- Open-Meteo
```

**Impact**: ~2-4 seconds per mountain load

#### 2. **No Data Caching**
- Every navigation refetches all data
- External API calls have no cache layer
- No client-side persistence

**Impact**: Unnecessary API calls, slower UX, potential rate limiting

#### 3. **No Prefetching**
- Users must wait for each page to load
- No predictive loading of likely next mountains

**Impact**: Perceived slowness, poor UX

#### 4. **Client-Only Data Fetching**
- All data fetched in useEffect (client-side)
- No server-side rendering of initial data
- No streaming responses

**Impact**: Slower initial page load, SEO limitations

---

## Immediate Performance Fixes (Phase 1)

### 1. Server-Side Response Caching
**Effort**: Low | **Impact**: High | **Timeline**: 1-2 days

Add caching to API routes with short TTLs:

```typescript
// Example: Cache powder scores for 10 minutes
const CACHE_TTL = 600; // 10 minutes
const cache = new Map();

export async function GET(req, { params }) {
  const cacheKey = `powder-score:${params.mountainId}`;
  const cached = cache.get(cacheKey);

  if (cached && Date.now() - cached.timestamp < CACHE_TTL * 1000) {
    return NextResponse.json(cached.data);
  }

  // Fetch fresh data...
  const data = await fetchPowderScore();
  cache.set(cacheKey, { data, timestamp: Date.now() });

  return NextResponse.json(data);
}
```

**Benefits**:
- 80-90% reduction in external API calls
- Faster response times
- Reduced risk of rate limiting

### 2. Parallel API Batching
**Effort**: Low | **Impact**: Medium | **Timeline**: 1 day

Create a single `/api/mountains/${id}/all` endpoint that batches all requests in parallel:

```typescript
// Instead of 9 separate API calls, make 1
const response = await fetch(`/api/mountains/${id}/all`);
const { conditions, powderScore, forecast, roads, ... } = await response.json();
```

**Benefits**:
- Reduce network overhead
- Faster page loads (parallel vs sequential)
- Simpler client code

### 3. Client-Side SWR/React Query
**Effort**: Medium | **Impact**: High | **Timeline**: 2-3 days

Install and configure SWR for automatic caching:

```bash
npm install swr
```

```typescript
import useSWR from 'swr';

function MountainPage({ mountainId }) {
  const { data, error, isLoading } = useSWR(
    `/api/mountains/${mountainId}/all`,
    fetcher,
    {
      revalidateOnFocus: false,
      dedupingInterval: 300000 // 5 minutes
    }
  );
}
```

**Benefits**:
- Automatic caching
- Background revalidation
- Optimistic UI updates
- Prefetching support

### 4. Prefetch Adjacent Mountains
**Effort**: Low | **Impact**: Medium | **Timeline**: 1 day

```typescript
// Prefetch nearby mountains on hover/focus
<Link
  href={`/mountains/${mountain.id}`}
  onMouseEnter={() => prefetch(`/api/mountains/${mountain.id}/all`)}
>
```

**Benefits**:
- Instant navigation for prefetched routes
- Better perceived performance

---

## Advanced Optimizations (Phase 2)

### 5. Vercel KV/Redis Caching
**Effort**: Medium | **Impact**: Very High | **Timeline**: 3-4 days

```bash
npm install @vercel/kv
```

Persistent caching across all serverless function instances:

```typescript
import { kv } from '@vercel/kv';

const data = await kv.get(`mountain:${id}:powder-score`);
if (!data) {
  const fresh = await fetchPowderScore(id);
  await kv.set(`mountain:${id}:powder-score`, fresh, { ex: 600 });
}
```

**Benefits**:
- Shared cache across all users
- Dramatically reduced external API calls
- Cost savings
- Faster responses

### 6. Incremental Static Regeneration (ISR)
**Effort**: Medium | **Impact**: High | **Timeline**: 2-3 days

Pre-render mountain pages with automatic revalidation:

```typescript
export const revalidate = 600; // Revalidate every 10 minutes

export async function generateStaticParams() {
  return getAllMountains().map(m => ({ mountainId: m.id }));
}
```

**Benefits**:
- Near-instant page loads
- SEO benefits
- Reduced server load

### 7. Streaming & Suspense
**Effort**: High | **Impact**: Medium | **Timeline**: 4-5 days

Show UI immediately, stream in data progressively:

```typescript
<Suspense fallback={<SkeletonLoader />}>
  <PowderScore mountainId={id} />
</Suspense>
<Suspense fallback={<SkeletonLoader />}>
  <Forecast mountainId={id} />
</Suspense>
```

**Benefits**:
- Immediate visual feedback
- Progressive loading
- Better UX

---

## Performance Metrics

### Current State
- **Time to Interactive**: 2-5 seconds
- **API Calls per Navigation**: 9+ calls
- **External API Dependency**: 100%
- **Cache Hit Rate**: 0%

### Target State (After Phase 1)
- **Time to Interactive**: 0.3-0.8 seconds
- **API Calls per Navigation**: 1-2 calls
- **External API Dependency**: 10-20%
- **Cache Hit Rate**: 80-90%

### Target State (After Phase 2)
- **Time to Interactive**: 0.1-0.3 seconds
- **API Calls per Navigation**: 0-1 calls
- **External API Dependency**: 5-10%
- **Cache Hit Rate**: 95%+

---

## Recommended Implementation Order

### Week 1: Quick Wins
1. ✅ Server-side response caching (2 days)
2. ✅ Parallel API batching (1 day)
3. ✅ Client-side SWR integration (2 days)

**Expected Improvement**: 60-70% faster

### Week 2: Infrastructure
4. ✅ Vercel KV/Redis setup (3 days)
5. ✅ Prefetching strategy (1 day)

**Expected Improvement**: 80-90% faster

### Week 3: Advanced (Optional)
6. ✅ ISR for static pages (3 days)
7. ✅ Streaming responses (2 days)

**Expected Improvement**: 90-95% faster

---

## Cost Considerations

### Current (Free Tier)
- Vercel: Free (Hobby)
- External APIs: Free
- **Total**: $0/month

### With Optimizations
- Vercel: Free → Pro ($20/month for better performance)
- Vercel KV: ~$10-30/month (based on usage)
- **Total**: $30-50/month

**ROI**: Significantly better UX, reduced API costs, scalability

---

## Testing Strategy

### Performance Testing
```bash
# Lighthouse scores
npm run build
npm run start
lighthouse http://localhost:3000/mountains/baker --view

# Load testing
npx autocannon http://localhost:3000/api/mountains/baker/all
```

### Monitoring
- Vercel Analytics (built-in)
- Web Vitals tracking
- Error tracking (Sentry recommended)

---

## Next Steps

1. **Review this analysis** with team
2. **Prioritize optimizations** based on effort/impact
3. **Set up monitoring** before making changes
4. **Implement Phase 1** (Week 1 quick wins)
5. **Measure improvements**
6. **Iterate** based on results

Would you like me to implement any of these optimizations immediately?
