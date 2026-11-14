# The Common Need • Federated Mutual Aid Network (`decidim-module-common_need`)

A native, mountable **Decidim v0.32+ Component Engine** (`decidim-common_need`, mounted alongside `decidim-courier` and `decidim-services`) and **Offline-First 5-Role Progressive Web App (PWA) Suite** built with Ruby on Rails 7.2+, PostgreSQL 17 + PostGIS (`SRID 4326`), Hotwire (Turbo Frames, Turbo Streams, Stimulus), Trailblazer Cells (`Decidim::ViewModel`), local-node OSRM routing, and a local-node Ollama/Llama-3 Paperwork Co-Pilot.

---

## Core Architectural Principles

1. **Zero-Means-Testing & Unconditional Solidarity**:
   - Zero commercial payment gateways, pricing columns, or income-verification gates for Members.
   - All community resource accounting uses the **De-Commodified Community Value & Care Ledger** (tracking nourishing meals, weight in lbs, protective respiratory/safety items, and volunteer timebank hours).
2. **Local Data Sovereignty & Zero-Knowledge Federation**:
   - Household PII and delivery coordinates (`st_point :dropoff_coordinates, geographic: true, srid: 4326`) remain 100% on the neighborhood node's local PostgreSQL/PostGIS instance (e.g., East Oakland `#OAK-01`).
   - Only zero-knowledge aggregate telemetry (`households_served`, `shift_fill_rate_pct`, `surplus_rescued_lbs`, `household_pii_bytes: 0`) is syndicated to the Central Hub.
3. **Offline-First Volunteer Navigation & Low-Data Member Tracking**:
   - Workbox/IndexedDB Service Worker (`/service-worker.js`) caches OSRM route polylines, turn-by-turn maneuver steps, and Leaflet map tiles so Volunteer Couriers can navigate and confirm stops with zero cellular connectivity.
   - ActionCable / Turbo Streams (`Decidim::CommonNeed::DeliveryWindowChannel`) broadcast low-data, zero-map-tile arrival window updates (`Window: 2:38 PM – 2:45 PM (You Are Next!)`) to Members when upstream stops are confirmed.

---

## The 5-Role PWA Suite

| Role | Portal Module | Key Capabilities |
| :--- | :--- | :--- |
| **1. Member PWA** | `Decidim::CommonNeed::MemberPortal` | • **Tab 1 (Browse)**: 19-Category Community Catalog with real-time Stimulus pill filtering (`catalog_filter_controller.js`) & PostGIS hub distances.<br>• **Tab 2 (AI Helper)**: 100% Local-Node Ollama (`#OAK-01`) AI Assistant & Encrypted Local Paperwork Co-Pilot (CalFresh/Medi-Cal/LIHEAP, Eviction Defense, Rent Relief, Municipal ID/Paratransit, VA Claim/DD-214).<br>• **Tab 3 (Basket)**: Multi-Hub Care Basket, expandable Low-Data Delivery Updates Banner, accessibility handoff flags (`bring_up_porch_steps`, `wait_60s_at_door`), and De-Commodified Care Ledger.<br>• **Tab 4 (Calendar)**: Centralized Local Partner Calendar (`decidim-meetings`) with 3-Mode View Switcher (`List` \| `Calendar Grid` \| `Leaflet Map`) and `.ics` export.<br>• **Tab 5 (Vote)**: Democratic Governance (`decidim-proposals`, `1 Member = 1 Vote`). |
| **2. Volunteer PWA** | `Decidim::Courier::VolunteerPortal` | • **Tab 1 (Route)**: Offline-Ready OSRM Navigator with Leaflet polyline, turn-by-turn maneuver stepper, Web Speech API (`voice_nav_controller.js`), and chronological Pickup/Dropoff cards (`ConfirmStopCommand`).<br>• **Tab 2 (Shifts)**: Community Bulk Distribution Shifts (`decidim-meetings` + `TimebankEntry`). |
| **3. Partner Non-Profit PWA** | `Decidim::Services::PartnerPortal` | • Gated via `Decidim::Verifications::NonProfitHandler` (501(c)(3) / community collective verification).<br>• **Tab 1 (Handoff)**: Loading Ramp batch staging (`VerifyAndStageCratesCommand`).<br>• **Tab 2 (Stock)**: Live Surplus Inventory (`PostSurplusItemCommand`) & Partner Calendar Event Publisher (`CreatePartnerEventCommand`).<br>• **Tab 3 (Audit)**: Local Node Accountability Ledger (`decidim-accountability`). |
| **4. Local Node Admin PWA** | `Decidim::CommonNeed::LocalNodeAdmin` | • **Tab 1 (Analytics)**: Local PostGIS/PostgreSQL telemetry (`LocalNodeAnalyticsQuery`).<br>• **Tab 2 (Partners)**: 501(c)(3) EIN moderation & onboarding invites.<br>• **Tab 3 (Requests)**: `Decidim::Reportable` moderation logged to `Decidim::ActionLog`.<br>• **Tab 4 (Votes)**: Local node routing & radius ballots (`#OAK-09`). |
| **5. Central Hub Federation PWA** | `Decidim::CommonNeed::FederationHub` | • **Tab 1 (Deploy Nodes)**: Federated Server Incubator (`PeerFederatedNodeCommand` + `NodeProvisionerService` generating Docker Compose + PostGIS + OSRM + Photon + Doorkeeper stacks) & `Sync All Nodes`.<br>• **Tab 2 (Area Requests)**: Inter-node mutual aid transfers (`DispatchInterNodeTransferCommand`, `REQ #401`).<br>• **Tab 3 (Network Votes)**: Cross-node syndicated governance (`#NET-88`).<br>• **Tab 4 (Telemetry)**: Zero-Knowledge Aggregate Telemetry (`HOUSEHOLD PII ON HUB: 0 Bytes`). |

---

## Repository Layout

- `gems/decidim-module-common_need/` — Primary Decidim Component Engine (`Decidim::CommonNeed::Engine` & `Decidim::CommonNeed::AdminEngine`)
- `gems/decidim-module-courier/` — Companion Volunteer Courier Engine (`Decidim::Courier::Engine`)
- `gems/decidim-module-services/` — Companion Partner Non-Profit Services Engine (`Decidim::Services::Engine`)
- `the_common_need_pwa_preview.html` — Self-contained interactive 5-Role PWA reference wireframe
