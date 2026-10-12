# Crewboard (Vercel + Supabase)
1. Supabase > SQL Editor: run `schema.sql`.
2. Supabase > Authentication > Users: add your manager email/password. Copy its UUID, then run:
   `insert into managers (user_id) values ('THE-UUID');`
3. Put your Project URL and anon key in `public/config.js`.
4. Deploy this folder to Vercel (static; `public/` is served, no build needed).
Links: `/` = join page (worker/supplier), `/manager.html` = manager dashboard (login required).
