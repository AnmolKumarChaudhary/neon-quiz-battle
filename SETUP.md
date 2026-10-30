# Neon Quiz Battle — setup and deployment

This repository is the first playable implementation of Neon Quiz Battle. It uses React + Vite, Supabase Postgres/Realtime, and a Supabase Edge Function for room actions and scoring.

## 1. Install tools

Install Node.js 20 or newer from https://nodejs.org/ and Git if you want to publish through GitHub. Open Terminal in this project folder.

```bash
npm install
```

## 2. Create a Supabase project

1. Open https://supabase.com/dashboard and create a new project.
2. Save the database password somewhere private; do not send it to anyone.
3. In **Project Settings → API**, copy the Project URL and the **anon/public** key.
4. Create a file named `.env` in this project folder by copying `.env.example` and replacing the placeholders:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Only the URL and anon/public key belong in `.env`. Never put the service-role key in a `VITE_` variable or frontend source.

## 3. Apply the database migration

Install the Supabase CLI using its official instructions: https://supabase.com/docs/guides/cli/getting-started

From this project folder, authenticate and link the project:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

If asked for the database password, enter it in your own terminal. The migration creates rooms, players and private answer submissions, enables realtime for public room/player state, and restricts direct writes.

Alternative: open **SQL Editor** in the Supabase dashboard, open `supabase/migrations/001_init.sql` in a text editor, copy the entire SQL file into the editor and run it once. Do not run both methods against the same fresh project unless you first check for duplicate objects.

## 4. Deploy the server function

The Edge Function uses the Supabase service-role key only on the server. Supabase provides `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge Functions by default.

```bash
supabase functions deploy game-action
```

Do not expose the service-role key to the browser, a public repository, or chat.

## 5. Run locally

```bash
npm run dev
```

Open the local URL Vite prints, normally `http://localhost:5173`. To test two players on one computer, open the URL in two separate browser profiles or one normal window and one private/incognito window. Enter different nicknames, create a room in one, join with the code in the other, then start the match as host.

## 6. Deploy the public frontend to Vercel

1. Push this project to a private or public GitHub repository. Ensure `.env` is not committed; it is ignored by Vite's usual defaults only if you add it to `.gitignore` (see below).
2. Open https://vercel.com/new and import the repository.
3. Set the build command to `npm run build` and output directory to `dist`.
4. In Vercel **Project Settings → Environment Variables**, add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` with the same public values.
5. Deploy. Open the generated `https://....vercel.app` URL on two devices and repeat the multiplayer test.

## Gameplay notes

- There are 10 questions per match, a 15-second round timer, and three categories.
- A correct answer earns 500 base points plus up to 500 speed points. Wrong or missing answers earn zero.
- The server holds the correct answers in the Edge Function; the safe question sent to players includes only the prompt and choices.
- The host's browser triggers round advancement when its timer reaches zero. Keep the host connected during a match in this initial version.
- Nickname-only rooms are intentionally low-friction, not account-secured. Anyone who obtains a room/player identifier may be able to impersonate that player; do not use this as a high-stakes or private system. A production hardening pass should add short-lived signed player sessions and transactional scoring/round advancement.
