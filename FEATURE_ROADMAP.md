# Shredders - Feature Roadmap: Social & Personalization

## Executive Summary

Transform Shredders from a conditions tracker into a **comprehensive ski trip planning platform** with personalization, social features, and carpooling.

### Vision
"The all-in-one platform where PNW skiers plan trips, connect with friends, and coordinate rides to the mountains."

### Key Value Propositions
1. **Never miss a powder day** - Personalized alerts for YOUR favorite mountains
2. **Ski with friends** - See where your crew is riding, coordinate meetups
3. **Save money & reduce impact** - Share rides, split gas, reduce carbon footprint
4. **Build community** - Connect with local skiers, make new riding buddies

---

## Feature Breakdown

### Phase 1: Personalization (MVP)
**Timeline**: 2-3 weeks | **Complexity**: Medium | **User Value**: High

#### 1.1 User Accounts & Authentication
```typescript
// Tech Stack Options
Option A: Supabase Auth (Recommended)
  - Built-in auth, database, real-time
  - Free tier generous
  - Easy integration
  - Postgres database

Option B: NextAuth.js + Vercel Postgres
  - More control
  - Slightly more setup
  - Good Vercel integration

Option C: Clerk
  - Easiest to set up
  - Beautiful UI
  - More expensive at scale
```

**Features**:
- Email/password signup
- OAuth (Google, Apple, Facebook)
- Magic link login
- Profile management

**Database Schema**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  name VARCHAR,
  avatar_url VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 1.2 Favorite Mountains
**Features**:
- Star/favorite up to 5 mountains
- Customizable home dashboard showing only favorites
- Quick-switch between favorites

**Database Schema**:
```sql
CREATE TABLE user_favorites (
  user_id UUID REFERENCES users(id),
  mountain_id VARCHAR NOT NULL,
  order INT,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, mountain_id)
);
```

**UI**:
```
[Dashboard]
  Your Favorites (3)
  ┌─────────────┬─────────────┬─────────────┐
  │ Mt Baker    │ Stevens     │ Crystal     │
  │ Score: 8.2  │ Score: 6.5  │ Score: 7.1  │
  │ 12" new     │ 4" new      │ 8" new      │
  └─────────────┴─────────────┴─────────────┘
```

#### 1.3 Personalized Alerts & Notifications
**Features**:
- Email/SMS alerts when powder score > threshold
- Custom notification preferences per mountain
- Digest mode (daily summary vs real-time)
- Weekend warrior mode (Friday alerts for Saturday)

**Database Schema**:
```sql
CREATE TABLE notification_preferences (
  user_id UUID REFERENCES users(id),
  mountain_id VARCHAR,
  powder_threshold INT DEFAULT 7,
  notify_email BOOLEAN DEFAULT true,
  notify_sms BOOLEAN DEFAULT false,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  PRIMARY KEY (user_id, mountain_id)
);

CREATE TABLE notifications_sent (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  mountain_id VARCHAR,
  type VARCHAR,
  sent_at TIMESTAMP DEFAULT NOW()
);
```

**Implementation**:
```typescript
// Cron job runs every hour
// src/lib/jobs/powder-alerts.ts

export async function checkPowderAlerts() {
  const mountains = await getMountainsWithHighScores();

  for (const mountain of mountains) {
    const users = await getUsersWatchingMountain(mountain.id);

    for (const user of users) {
      if (shouldNotify(user, mountain)) {
        await sendNotification(user, mountain);
      }
    }
  }
}
```

#### 1.4 Riding Style Profile
**Features**:
- Preferences: Powder, Groomers, Park, Backcountry
- Skill level: Beginner, Intermediate, Advanced, Expert
- Custom powder score weights

**Database Schema**:
```sql
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  riding_style VARCHAR[], -- ['powder', 'groomers', 'park']
  skill_level VARCHAR,
  custom_weights JSONB, -- Override default powder score weights
  preferences JSONB -- Other preferences
);
```

**Personalized Powder Score**:
```typescript
// Adjust powder score based on user preferences
function getPersonalizedScore(mountain, user) {
  const baseScore = mountain.powderScore;
  const weights = user.custom_weights || DEFAULT_WEIGHTS;

  // If user loves powder, weight fresh snow higher
  if (user.riding_style.includes('powder')) {
    weights.fresh *= 1.2;
  }

  return recalculatePowderScore(mountain, weights);
}
```

---

### Phase 2: Social Features (Friends)
**Timeline**: 3-4 weeks | **Complexity**: High | **User Value**: Very High

#### 2.1 Friend Connections
**Features**:
- Send/accept friend requests
- Search users by name/email
- Friend list management
- Privacy controls

**Database Schema**:
```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  friend_id UUID REFERENCES users(id),
  status VARCHAR, -- 'pending', 'accepted', 'blocked'
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);
```

#### 2.2 Trip Planning & Coordination
**Features**:
- Create trip plans (date, mountain, group)
- Invite friends to trips
- Comment/discuss plans
- Weather updates for planned trips
- Calendar integration

**Database Schema**:
```sql
CREATE TABLE trips (
  id UUID PRIMARY KEY,
  creator_id UUID REFERENCES users(id),
  mountain_id VARCHAR NOT NULL,
  trip_date DATE NOT NULL,
  title VARCHAR,
  description TEXT,
  status VARCHAR DEFAULT 'planning', -- 'planning', 'confirmed', 'completed', 'cancelled'
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE trip_participants (
  trip_id UUID REFERENCES trips(id),
  user_id UUID REFERENCES users(id),
  status VARCHAR DEFAULT 'invited', -- 'invited', 'accepted', 'declined', 'maybe'
  role VARCHAR, -- 'organizer', 'participant'
  PRIMARY KEY (trip_id, user_id)
);

CREATE TABLE trip_comments (
  id UUID PRIMARY KEY,
  trip_id UUID REFERENCES trips(id),
  user_id UUID REFERENCES users(id),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**UI Mockup**:
```
[Trip: Baker - Saturday Dec 28]
  📅 Organized by Kevin
  ⛷️  5 people going
  📊 Current Powder Score: 8.2
  🌨️  Forecast: 18" in next 48hrs

  Participants:
  ✓ Kevin (organizer)
  ✓ Sarah
  ✓ Mike
  ? Jamie (maybe)
  ✗ Alex (can't make it)

  Comments:
  Kevin: "Looks epic! Leaving Seattle at 6am"
  Sarah: "Can we carpool?"
  Mike: "I'm bringing my GoPro!"

  [Join This Trip] [Share] [Leave Trip]
```

#### 2.3 Live Activity Feed
**Features**:
- See where friends are riding today
- Check-in feature
- Photo sharing from the mountain
- Real-time updates

**Database Schema**:
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  type VARCHAR, -- 'checkin', 'trip_created', 'photo_shared'
  mountain_id VARCHAR,
  content TEXT,
  photo_url VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE checkins (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  mountain_id VARCHAR NOT NULL,
  checkin_time TIMESTAMP DEFAULT NOW(),
  checkout_time TIMESTAMP,
  notes TEXT
);
```

**Real-time Updates**:
```typescript
// Use Supabase Realtime or WebSockets
supabase
  .channel('activities')
  .on('INSERT', payload => {
    showNotification(`${payload.user.name} just checked in at ${payload.mountain}!`);
  })
  .subscribe();
```

---

### Phase 3: Carpooling & Ride Sharing
**Timeline**: 4-6 weeks | **Complexity**: Very High | **User Value**: Very High

#### 3.1 Core Carpooling Features
**Features**:
- Create ride offers (driver)
- Search available rides (passenger)
- Route matching algorithm
- Departure time coordination
- Seats available tracking
- Cost splitting calculator

**Database Schema**:
```sql
CREATE TABLE rides (
  id UUID PRIMARY KEY,
  driver_id UUID REFERENCES users(id),
  mountain_id VARCHAR NOT NULL,
  ride_date DATE NOT NULL,
  departure_time TIME NOT NULL,
  departure_location VARCHAR NOT NULL, -- Address or landmark
  departure_lat DECIMAL,
  departure_lng DECIMAL,
  return_time TIME,
  seats_available INT NOT NULL,
  seats_taken INT DEFAULT 0,
  cost_per_person DECIMAL, -- Optional
  vehicle_info VARCHAR, -- "White Toyota 4Runner"
  requirements TEXT, -- "Ski pass required", "Split gas"
  status VARCHAR DEFAULT 'active', -- 'active', 'full', 'completed', 'cancelled'
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ride_requests (
  id UUID PRIMARY KEY,
  ride_id UUID REFERENCES rides(id),
  passenger_id UUID REFERENCES users(id),
  pickup_location VARCHAR,
  pickup_lat DECIMAL,
  pickup_lng DECIMAL,
  status VARCHAR DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'cancelled'
  message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ride_reviews (
  id UUID PRIMARY KEY,
  ride_id UUID REFERENCES rides(id),
  reviewer_id UUID REFERENCES users(id),
  reviewee_id UUID REFERENCES users(id),
  rating INT CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Matching Algorithm**:
```typescript
// Find compatible rides
function findMatchingRides(searchCriteria) {
  return rides.filter(ride => {
    // Same mountain
    if (ride.mountain_id !== searchCriteria.mountain_id) return false;

    // Same date
    if (ride.ride_date !== searchCriteria.date) return false;

    // Seats available
    if (ride.seats_available <= ride.seats_taken) return false;

    // Departure location within N miles
    const distance = calculateDistance(
      searchCriteria.lat,
      searchCriteria.lng,
      ride.departure_lat,
      ride.departure_lng
    );
    if (distance > searchCriteria.maxDistance) return false;

    // Departure time within window
    const timeDiff = Math.abs(
      parseTime(ride.departure_time) - parseTime(searchCriteria.time)
    );
    if (timeDiff > 60) return false; // 60 min window

    return true;
  })
  .sort((a, b) => {
    // Sort by distance, then time match
    const distA = calculateDistance(...);
    const distB = calculateDistance(...);
    return distA - distB;
  });
}
```

#### 3.2 Safety & Trust Features
**Critical for carpooling adoption**

**Features**:
- User verification (phone, email, social)
- Ratings & reviews system
- Report/block users
- Background checks (optional, premium)
- Emergency contact sharing
- Live trip tracking (optional)
- Insurance information sharing

**Database Schema**:
```sql
CREATE TABLE user_verifications (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  phone_verified BOOLEAN DEFAULT false,
  email_verified BOOLEAN DEFAULT false,
  social_connected BOOLEAN DEFAULT false,
  background_check_status VARCHAR, -- 'pending', 'passed', 'failed'
  verification_score INT, -- 0-100
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE safety_reports (
  id UUID PRIMARY KEY,
  reporter_id UUID REFERENCES users(id),
  reported_id UUID REFERENCES users(id),
  ride_id UUID REFERENCES rides(id),
  reason VARCHAR,
  description TEXT,
  status VARCHAR DEFAULT 'pending', -- 'pending', 'reviewed', 'action_taken'
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 3.3 Payment Integration (Optional)
**Features**:
- In-app payment for ride sharing
- Automatic cost splitting
- Stripe Connect for drivers
- Escrow system

**Note**: This adds significant complexity and legal requirements. Consider Venmo/PayPal links instead for MVP.

#### 3.4 Carpooling UI
```
[Find a Ride to Mt Baker - Sat Dec 28]

Available Rides (3):

┌─────────────────────────────────────────────┐
│ 🚗 Sarah's Subaru Outback                   │
│ ⭐ 4.9 (23 rides) ✓ Verified                │
│                                             │
│ 📍 U-District, Seattle → Mt Baker           │
│ 🕐 Depart: 6:00 AM | Return: 4:00 PM       │
│ 💺 2 seats left (of 3)                      │
│ 💵 $25/person (gas + parking)               │
│                                             │
│ 📝 "Looking for chill riders. I have a     │
│     ski rack and usually stop for coffee   │
│     in Burlington."                         │
│                                             │
│ [Request to Join] [Message Sarah]           │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ 🚗 Mike's Toyota 4Runner                    │
│ ⭐ 5.0 (12 rides) ✓ Verified                │
│ 📍 Capitol Hill → Mt Baker                  │
│ 🕐 Depart: 5:30 AM | Return: 5:00 PM       │
│ 💺 1 seat left (of 4)                       │
│ 💵 $30/person                                │
│ [Request to Join]                            │
└─────────────────────────────────────────────┘

[Create Your Own Ride]
```

---

## Technical Architecture

### Stack Recommendation

```typescript
// Auth
- Supabase Auth (or NextAuth.js)

// Database
- Supabase Postgres (or Vercel Postgres)
- Prisma ORM

// Real-time
- Supabase Realtime (or Pusher, Ably)

// Storage (photos)
- Supabase Storage (or Vercel Blob)

// Notifications
- Resend (email)
- Twilio (SMS)
- Expo Push (mobile, future)

// Payments (optional)
- Stripe Connect

// Maps
- Mapbox (route matching)
- Google Maps API (geocoding)

// Background Jobs
- Vercel Cron
- or Trigger.dev for complex workflows
```

### Database Choice: Supabase vs Vercel Postgres

**Supabase** (Recommended):
✅ Auth included
✅ Real-time subscriptions
✅ Storage included
✅ Generous free tier
✅ Row-level security (RLS)
✅ Auto-generated APIs
❌ Another service to manage

**Vercel Postgres**:
✅ Same provider as hosting
✅ Good DX
✅ Neon under the hood
❌ No built-in auth
❌ No real-time
❌ More expensive at scale

**Recommendation**: Start with Supabase. The auth + realtime + storage combo is unbeatable for this use case.

---

## Implementation Phases

### Phase 1: Foundation (3-4 weeks)
**Goal**: User accounts + basic personalization

- [ ] Set up Supabase project
- [ ] Implement authentication
- [ ] Create user profiles
- [ ] Favorite mountains feature
- [ ] Basic notification system
- [ ] Deploy to production

**Deliverable**: Users can sign up, favorite mountains, get alerts

### Phase 2: Social Core (4-5 weeks)
**Goal**: Friends + trip planning

- [ ] Friend system
- [ ] Trip creation & management
- [ ] Activity feed
- [ ] Comments & discussions
- [ ] Real-time updates
- [ ] Mobile-responsive design

**Deliverable**: Users can connect with friends, plan trips together

### Phase 3: Carpooling MVP (5-6 weeks)
**Goal**: Basic ride sharing

- [ ] Ride creation (drivers)
- [ ] Ride search (passengers)
- [ ] Request/accept flow
- [ ] Basic safety features
- [ ] Ratings system
- [ ] Payment coordination (external)

**Deliverable**: Users can offer/find rides, coordinate carpools

### Phase 4: Polish & Scale (ongoing)
**Goal**: Improve UX, add features

- [ ] Mobile apps (React Native / Flutter)
- [ ] Advanced matching algorithm
- [ ] Background checks
- [ ] Insurance integration
- [ ] Live trip tracking
- [ ] Community features (groups, events)
- [ ] Premium features

---

## Business Model

### Free Tier
- Basic conditions tracking
- Up to 3 favorite mountains
- Limited notifications
- Friends (up to 20)
- Trip planning
- Carpool listings

### Premium ($4.99/month or $39.99/year)
- Unlimited favorites
- Unlimited notifications
- Custom powder score weights
- Priority support
- Advanced trip features
- Verified badge
- Background check included
- Ad-free experience

### Premium Plus ($9.99/month)
- Everything in Premium
- Live trip tracking
- Trip insurance
- Priority carpool matching
- Analytics & insights
- API access

### Revenue Streams
1. Subscription ($4.99 - $9.99/month)
2. Carpool transaction fee (5-10% optional)
3. Affiliate links (ski gear, lodging)
4. Sponsored mountain features
5. API access for businesses

---

## Go-to-Market Strategy

### Beta Launch (Months 1-2)
- Invite 50-100 beta users from PNW ski communities
- Reddit: r/Skiing, r/Snowboarding, r/Seattle
- Facebook groups: PNW Skiers & Riders
- Focus on Mt Baker, Stevens Pass (most active)

### Public Launch (Month 3)
- Press release to local media
- Social media campaign
- Influencer partnerships
- Ski resort partnerships

### Growth (Months 4-6)
- Referral program ("Invite 3 friends, get 3 months free")
- Mountain ambassador program
- Expand to more resorts
- Mobile app launch

---

## Risk Analysis

### Technical Risks
- **Real-time scale**: Supabase realtime limits
- **API costs**: External weather APIs
- **Performance**: Database queries at scale

**Mitigation**: Caching, rate limiting, gradual rollout

### Product Risks
- **Low adoption**: Not enough users for network effects
- **Safety concerns**: Carpooling liability
- **Competitive**: Existing apps (e.g., Ski Carpool apps)

**Mitigation**: Focus on unique value (conditions + social + carpool), strong safety features, community building

### Legal Risks
- **Liability**: Carpooling accidents
- **Insurance**: Ride sharing insurance requirements
- **Data privacy**: GDPR, CCPA compliance

**Mitigation**: Terms of service, waivers, insurance partnerships, privacy policy

---

## Success Metrics

### Phase 1 (Personalization)
- 500+ registered users
- 30% weekly active users
- 10+ avg mountain checks per user/week

### Phase 2 (Social)
- 1000+ users
- 50+ trips created/week
- 20% of users with 3+ friends

### Phase 3 (Carpooling)
- 2000+ users
- 100+ rides posted/week
- 50+ successful carpools/week
- 4.5+ avg rating

---

## Next Steps

### Immediate (This Week)
1. **Review this roadmap** - Validate features, priorities
2. **User research** - Survey potential users on which features they want most
3. **Set up Supabase** - Create project, configure auth
4. **Start Phase 1** - Implement authentication

### Short-term (Next Month)
1. **Launch Phase 1** - User accounts + personalization
2. **Gather feedback** - Iterate based on user input
3. **Plan Phase 2** - Refine social features based on feedback

### Long-term (3-6 Months)
1. **Launch Phase 2** - Social features
2. **Build community** - Engage users, create content
3. **Launch Phase 3** - Carpooling beta
4. **Explore monetization** - Premium features

---

## Questions for Decision

1. **Priority**: Which phase should we start with?
   - Option A: Focus on performance first, then features
   - Option B: Start personalization now, optimize later
   - Option C: Build MVP of all features at once

2. **Auth Provider**: Supabase or NextAuth.js?
   - Supabase = easier, more features
   - NextAuth = more control, familiar

3. **Monetization**: Freemium now or later?
   - Now = revenue earlier, but might limit growth
   - Later = more users, but no revenue

4. **Scope**: Full roadmap or MVP?
   - MVP = Faster launch, less risk
   - Full = More impressive, but slower

**My Recommendation**:
- Fix performance issues first (1-2 weeks)
- Launch Phase 1 personalization (3-4 weeks)
- Gather user feedback
- Prioritize Phase 2 or 3 based on demand

Would you like me to start implementing any of these features?
