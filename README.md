# 🎓 Campus Marketplace

A real-time, full-stack marketplace where students buy and sell textbooks, electronics, lab supplies and campus essentials.

**Live:** _add your Vercel link_ · **Video:** _add your walkthrough link_

## Features
- **Auth** – sign up / log in (Supabase Auth); protected actions require login
- **Listings** – create, edit, delete, mark sold / available, image upload (Supabase Storage)
- **Browse** – instant search, category + max-price filter, "available only", skeleton loaders, empty and error states
- **Authorization** – Postgres Row Level Security: only the owner can edit/delete a listing, even if the API is called directly
- **Input validation** – client-side checks plus database `CHECK` constraints
- **Sold items** – greyed out with a SOLD badge
- **External APIs** – (1) **Anthropic API** generates listing descriptions (`/api/describe`, key stays server-side); (2) **Open-Meteo** powers the live weather chip
- **Live clock + weather** in the header
- **Insights graph** – Top 5 sellers (items sold) and Top 5 buyers (distinct listings enquired), via SQL views + Chart.js
- **Bonus** – real-time updates (Supabase Realtime), location-based sorting ("Near me", haversine), favourites, buyer–seller chat, in-app and browser notifications for new messages

## Tech stack & decisions
| Layer | Choice | Why |
|---|---|---|
| Frontend | Vanilla JS single page, no build step | Fast load, no framework overhead, easy to deploy |
| Backend/DB | Supabase (Postgres + Auth + Storage + Realtime) | Persistent DB, auth and live updates in one service |
| Security | RLS policies in `supabase.sql` | Authorization enforced at the database, not just the UI |
| Serverless | One Vercel function | Keeps the AI API key secret; verifies the user's JWT |

## Setup
1. Create a Supabase project. In **SQL Editor**, run `supabase.sql`.
2. In **Authentication → Providers → Email**, optionally turn off "Confirm email" for quicker testing.
3. In `index.html`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` (Project Settings → API).
4. Push to GitHub and import the repo in Vercel (no build settings needed).
5. In Vercel → Settings → Environment Variables add: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ANTHROPIC_API_KEY`. Redeploy.
6. In Supabase → Authentication → URL Configuration, add your Vercel URL as the Site URL.

## Challenges & solutions
- **Chart for "buyers"** – no purchase table exists, so buyers are ranked by distinct listings they enquired about in chat.
- **Securing the AI key** – moved the call into a serverless function that checks the Supabase session first.
- **Lag-free UI** – debounced search, client-side filtering, lazy-loaded images, and debounced realtime refreshes.

## Known limitations / future work
- Sample data: create a few listings named "Product 1", "Product 2" etc. through the UI.
- Browser notifications work while the tab is open; true background push needs a service worker + Web Push.
- No rate limit on the AI endpoint yet.
