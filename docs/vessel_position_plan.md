That's very helpful context. The tiered refresh logic makes sense operationally, but let's start with **daily refresh as MVP** to reduce complexity - we can add the smart refresh logic in a future iteration.

I have enough context now. Here's the strategic implementation plan:

---

## Vessel Position Map - Implementation Plan

### Overview

A full-screen interactive map displaying ~250 active vessels with real-time position data, showing TEU counts per carrier when a vessel is selected. Data flows from the tracking Supabase → Edge Function → Terminal49 API → App.

---

### Phase 1: Backend Infrastructure

**Objective**: Create the data pipeline from tracking database to the app

#### 1.1 Edge Function: Vessel Data Aggregator
- **Purpose**: Query tracking Supabase for active vessels + aggregate TEU/carrier data
- **Location**: App's Supabase Edge Functions
- **Logic**:
  - Connect to tracking Supabase (separate credentials)
  - Query active vessels from container events (vessels with recent activity)
  - Aggregate TEU counts per carrier per vessel
  - Return vessel list with metadata (IMO, name, carrier breakdown)

#### 1.2 Edge Function: Vessel Position Fetcher
- **Purpose**: Fetch positions from Terminal49 API with caching
- **Location**: App's Supabase Edge Functions
- **Logic**:
  - Accept list of vessel IMOs
  - Check cache (stored positions table) for recent data
  - Call Terminal49 API only for stale/missing positions
  - Store results in cache table
  - Return positions merged with vessel metadata

#### 1.3 Cache Table (App's Supabase)
- **Purpose**: Store vessel positions to minimize Terminal49 API calls
- **Schema**: `vessel_positions_cache`
  - vessel_imo, vessel_name, latitude, longitude, heading, speed_knots
  - carrier_teu_breakdown (JSONB)
  - last_fetched_at, expires_at
- **Refresh**: Daily via scheduled function (or manual trigger)

---

### Phase 2: Scheduled Data Refresh

**Objective**: Keep vessel positions updated automatically

#### 2.1 Scheduled Function (Daily MVP)
- **Trigger**: Cron job (daily at specific time, e.g., 06:00 UTC)
- **Process**:
  1. Get list of active vessels from tracking DB
  2. Batch fetch positions from Terminal49 (respect rate limits)
  3. Update cache table
  4. Log refresh status for monitoring

#### 2.2 Manual Refresh Endpoint
- **Purpose**: Allow admin to trigger refresh on-demand
- **Use case**: After known data changes or for testing

---

### Phase 3: Frontend - Map Component

**Objective**: Beautiful, minimal map with vessel markers

#### 3.1 Map Foundation
- **Library**: Mapbox GL JS or Leaflet (Mapbox recommended for "wow factor")
- **Style**: Dark/minimal theme matching app aesthetic
- **Initial view**: World view with vessel clusters
- **Interactions**: Zoom, pan, vessel click

#### 3.2 Vessel Markers
- **Design**: Custom ship icons (oriented by heading if available)
- **Clustering**: Group nearby vessels at low zoom levels
- **Visual hierarchy**: Subtle markers that don't clutter the map

#### 3.3 Vessel Detail Panel
- **Trigger**: Click on vessel marker
- **Content**:
  - Vessel name
  - Current position (lat/lng)
  - Speed & heading (if available)
  - **TEU breakdown by carrier** (visual bars/chart)
  - Last updated timestamp
- **Design**: Slide-in panel or modal, minimalist style

---

### Phase 4: Mobile Optimization

**Objective**: Excellent touch experience on mobile

#### 4.1 Touch Interactions
- Pinch to zoom
- Tap vessel to select
- Swipe panel to dismiss

#### 4.2 Responsive Layout
- Full-screen map on mobile
- Bottom sheet for vessel details (instead of side panel)
- Larger touch targets for markers

---

### Phase 5: Polish & Performance

**Objective**: Production-ready quality

#### 5.1 Loading States
- Skeleton map while loading
- Progressive marker loading
- Graceful degradation if Terminal49 unavailable

#### 5.2 Error Handling
- Offline/network error states
- Stale data indicators ("Updated 2 hours ago")
- Retry mechanisms

#### 5.3 Performance
- Lazy load map library
- Efficient marker rendering (Canvas vs DOM)
- Position data pagination if needed

---

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (App)                           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │  Map View   │◄───│ Vessel Hook │◄───│ Supabase Client     │ │
│  │  (Mapbox)   │    │ (TanStack)  │    │ (App Project)       │ │
│  └─────────────┘    └─────────────┘    └──────────┬──────────┘ │
└───────────────────────────────────────────────────┼─────────────┘
                                                    │
                                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    APP'S SUPABASE PROJECT                       │
│  ┌─────────────────────┐    ┌─────────────────────────────────┐│
│  │ vessel_positions_   │    │ Edge Functions                  ││
│  │ cache (table)       │◄───│ - get_active_vessels            ││
│  │                     │    │ - refresh_vessel_positions      ││
│  └─────────────────────┘    └──────────┬──────────────────────┘│
└────────────────────────────────────────┼────────────────────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    ▼                                         ▼
┌─────────────────────────────────┐    ┌─────────────────────────┐
│   TRACKING SUPABASE PROJECT     │    │    TERMINAL49 API       │
│  ┌───────────┐ ┌──────────────┐ │    │                         │
│  │ shipments │ │ containers   │ │    │  GET /vessels/{imo}     │
│  │           │ │              │ │    │  → lat, lng, heading,   │
│  └───────────┘ └──────────────┘ │    │    speed, timestamp     │
│  ┌───────────────────────────┐  │    │                         │
│  │ container_events          │  │    └─────────────────────────┘
│  │ (vessel IMO extraction)   │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

---

### Implementation Order

| Order | Phase | Tool | Estimated Effort |
|-------|-------|------|------------------|
| 1 | 1.3 - Cache table schema | Claude Code | 1 hour |
| 2 | 1.1 - Vessel aggregator function | Claude Code | 2-3 hours |
| 3 | 1.2 - Position fetcher function | Claude Code | 2-3 hours |
| 4 | 2.1 - Scheduled refresh | Claude Code | 1-2 hours |
| 5 | 3.1 - Map foundation | Lovable | 2-3 hours |
| 6 | 3.2 - Vessel markers | Lovable | 2-3 hours |
| 7 | 3.3 - Detail panel | Lovable | 2-3 hours |
| 8 | 4 - Mobile optimization | Lovable | 1-2 hours |
| 9 | 5 - Polish & performance | Both | 2-3 hours |

**Total estimated effort**: 16-23 hours

---

### Key Decisions Made

1. **Daily refresh MVP** - Simpler to implement, can add smart refresh later
2. **Edge Functions** - Keeps Terminal49 API key secure, enables caching
3. **Cache table in app's Supabase** - Fast queries, no cross-project auth complexity
4. **Mapbox recommended** - Better aesthetics and performance for "wow factor"

---

### Open Items / Future Enhancements

- Smart refresh logic (2-hour refresh for vessels near ETD/ETA)
- Vessel route visualization (historical positions trail)
- Filter by carrier
- Search vessel by name
- Real-time position updates (WebSocket)

---

Ready to proceed? If this plan looks good, let me know which phase you'd like to start with and I'll generate the specific prompts/instructions.