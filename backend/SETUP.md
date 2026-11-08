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

## Making it invite-only

By default, anyone with your app's URL could sign up and get their own private (RLS-isolated) space in your Supabase project. If you'd rather it only be you and people you let in:

1. **Turn off public sign-up.** In Supabase: **Authentication > Sign In / Providers > Email**, turn off **Allow new users to sign up** (wording varies slightly by Supabase version — look for a toggle naming email sign-ups). Save. This blocks the public sign-up endpoint entirely; it does **not** sign out or affect any account that already exists, so if you've already got an account, you're unaffected.
2. **Re-run `backend/schema.sql`** if you haven't already after this update — it's additive and safe to re-run, and adds one new table, `access_requests`.
3. **Re-deploy `index.html`.** The app's sign-up form is gone; in its place, the sign-in screen has a "Need access? Request an invite" link. Anyone who taps it and submits their email (and an optional note) has that request saved to the new `access_requests` table — they're told "you'll get an email if you're invited," nothing more.
4. **Review requests.** In Supabase: **Table Editor > access_requests**. You'll see each pending request's email and note. There's no app screen for this — it's deliberately dashboard-only, so requests can't be read back out through the public anon key.
5. **Invite someone.** In Supabase: **Authentication > Users > Invite user**, enter their email. They'll get an email with a link to set a password; once they do, they sign in in the app like anyone else. (Optionally, go back and update that row's `status` in `access_requests` to `invited` or `declined`, just for your own bookkeeping — nothing in the app reads that column.)

## What changed, if you're curious

- `confluences`, `threads`, and `access_requests` tables, all with Row Level Security — `confluences`/`threads` scoped to `auth.uid()` (nobody can read or write rows they don't own, even with the public anon key), `access_requests` allowing public inserts but no reads at all (requests go in, nobody but you — via the dashboard — can read them back out).
- The app talks to Supabase via `@supabase/supabase-js`, loaded from a CDN (`esm.sh`) — no build step, still a single HTML file.
- Sessions persist automatically (Supabase stores a refresh token in the browser), so you won't have to sign in every time you open the app.

## Already set up? Picking up the quick-add (voice) feature

Quick-add needs one new column, `needs_review`, on the `confluences` table. `schema.sql` is safe to re-run in full on a project you've already set up — open the **SQL Editor** again, paste the whole file in, and click **Run**. Existing rows are untouched; the new column just defaults to `false` for everything already there.

## If something goes wrong

- **"Almost there" screen never goes away** — the URL/key weren't saved, or still have the `YOUR_` placeholder text.
- **Sign-up says check your email, but you turned off confirmation** — double check step 3 was saved; it can take a minute to apply.
- **"Couldn't reach your data" after signing in** — usually means `schema.sql` wasn't run, or was run against a different project than the URL/key you copied.
- **"Request access" form errors out** — usually means `schema.sql` hasn't been re-run since the invite-only update, so the `access_requests` table doesn't exist yet. Re-run it (step 2 under "Making it invite-only" above).
- **Invited someone but they can't sign in** — they need to click the invite email's link and set a password first; until then there's no account for them to sign in with.
