# Setting up the Confluence backend

The app now saves to a real database (Supabase) instead of your phone's local storage, so your confluences survive a reinstall and — once the skill is wired up — Claude can read them too. This takes about 10 minutes, once.

## 1. Create a free Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up (GitHub login is fastest).
2. Click **New project**. Pick any name (e.g. "confluence"), generate a database password (save it somewhere — you likely won't need it again, but it's your project's master key), and pick a region close to you.
3. Wait ~2 minutes for the project to finish provisioning.

## 2. Run the schema

1. In your new project, open the **SQL Editor** (left sidebar).
2. Click **New query**, paste in the entire contents of `backend/schema.sql`, and click **Run**.
3. You should see a list of "CREATE TABLE" / "CREATE POLICY" confirmations. This creates two tables — `confluences` and `threads` — with Row Level Security turned on, so each account can only ever see its own data.

## 3. Turn off email confirmation (optional, for solo use)

By default Supabase requires you to click a confirmation link before a new account can sign in. Since this is just you for now:

1. Go to **Authentication > Providers > Email**.
2. Turn off **Confirm email**.

(You can leave this on instead and just click the confirmation link Supabase emails you the first time — either works.)

## 4. Get your project's API keys

1. Go to **Project Settings > API**.
2. Copy the **Project URL** (looks like `https://abcdefghijk.supabase.co`).
3. Copy the **anon public** key (a long string starting with `eyJ...`). Do **not** copy the `service_role` key — that one bypasses Row Level Security and should never go in client-side code.

## 5. Plug them into the app

1. Open `index.html` in a text editor.
2. Near the top of the `<script>` block, find:
   ```js
   const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
   const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
   ```
3. Replace both placeholder strings with the values from step 4.
4. Save the file.

## 6. Re-deploy to your phone

However you're currently hosting `index.html` (a static host, or just opening it locally and using "Add to Home Screen"), replace it with this updated version. The first time you open it you'll see a sign-in screen — click "Sign up" and create an account with your email and a password. That's it; everything you capture from then on is saved to your Supabase project instead of the phone's local storage.

## What changed, if you're curious

- `confluences` and `threads` tables, both with Row Level Security scoped to `auth.uid()` — meaning even with the (public, client-side-safe) anon key, nobody can read or write rows they don't own.
- The app talks to Supabase via `@supabase/supabase-js`, loaded from a CDN (`esm.sh`) — no build step, still a single HTML file.
- Sessions persist automatically (Supabase stores a refresh token in the browser), so you won't have to sign in every time you open the app.

## Already set up? Picking up the quick-add (voice) feature

Quick-add needs one new column, `needs_review`, on the `confluences` table. `schema.sql` is safe to re-run in full on a project you've already set up — open the **SQL Editor** again, paste the whole file in, and click **Run**. Existing rows are untouched; the new column just defaults to `false` for everything already there.

## If something goes wrong

- **"Almost there" screen never goes away** — the URL/key weren't saved, or still have the `YOUR_` placeholder text.
- **Sign-up says check your email, but you turned off confirmation** — double check step 3 was saved; it can take a minute to apply.
- **"Couldn't reach your data" after signing in** — usually means `schema.sql` wasn't run, or was run against a different project than the URL/key you copied.
