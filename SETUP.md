# TSI Build Quality Hub: hosted version with email and password login

This copy runs on your own web address (Vercel) with a real login (Supabase). Nobody needs a Claude account.
Allow about 45 minutes the first time. Menu names in Supabase and Vercel change now and then; the steps stay the same.

**What you have**

| File | What it is |
|---|---|
| `index.html` | The tool. You fill in 3 settings at the top. |
| `supabase-schema.sql` | Creates the database and the access rules. Run once. |
| `seed-data.sql` | Your team members and checklist from the Claude version. Run once. |
| `create-users.mjs` | Creates a login for every active team member. Run on your computer. |
| `vercel.json` | Security headers for Vercel. |

## 1. Create the database (Supabase, free plan is enough to start)

1. Go to supabase.com, sign in, **New project**. Pick a region close to your team and set a database password (keep it safe).
2. Open **Project Settings > API**. Copy two things:
   - **Project URL** (looks like `https://abcd1234.supabase.co`)
   - **anon public** key. This one is meant to be public.
   - Also note the **service_role** key. It is a master key. Never put it in `index.html`, never share it.
3. Open **SQL Editor > New query**. Open `supabase-schema.sql`, change `PASTE-ADMIN-EMAIL@company.com` at the very bottom to **your work email**, paste everything, press **Run**.
4. New query again: paste `seed-data.sql` and press **Run**. This loads your 29 team members and the checklist.

## 2. Set the sign-in rules (Supabase > Authentication)

1. **Sign in / Providers > Email**: switch **off** "Allow new users to sign up". Then only people you create can sign in. Set a **minimum password length** of 8 or more.
2. **URL Configuration**: set **Site URL** to your Vercel address (step 4) and add the same address under **Redirect URLs**. Do this after step 4. The "Forgot your password?" link needs it.
3. **Emails > SMTP Settings** (recommended): connect your own mail server so reset emails are reliable. The built-in sender allows only a few emails per hour. Until then, you can give people new passwords with `--reset` (step 3).

## 3. Create the logins

On your computer (Node 18 or newer installed):

```
SUPABASE_URL=https://abcd1234.supabase.co SERVICE_ROLE_KEY=paste-service-role-key node create-users.mjs
```

On Windows PowerShell:

```
$env:SUPABASE_URL="https://abcd1234.supabase.co"; $env:SERVICE_ROLE_KEY="paste-service-role-key"; node create-users.mjs
```

It creates a login for every **active** team member, using the work email in Team Members, and writes `new-logins.csv` with a temporary password for each person.
Send each person their password privately (not in a group chat), then delete the file. People can change it in **Settings > Account > Change password**.
Run it again whenever you add people. People who already have a login are skipped. `--reset` gives everyone listed a new password.
You can also add a single user in Supabase under **Authentication > Users > Add user** (tick "Auto confirm user").

## 4. Put the tool on the web (Vercel)

1. Open `index.html` in a text editor. At the top, replace the three `PASTE-...` values: the project URL, the anon public key, and your admin email (you can list more than one in the brackets).
2. At vercel.com choose **Add New > Project**, and upload this folder (or connect a repository). Deploy.
3. Open the web address Vercel gives you. You should see the animated sign-in page. Sign in with your work email and temporary password.
4. Go back to step 2.2 and enter this address in Supabase. If you use your own domain, add it in Vercel under Domains.

## 5. Day to day

- **New person:** add them in **Team Members** (work email required), then run `create-users.mjs` or add them in Supabase.
- **Someone leaves:** set them **Inactive** in Team Members. Access stops straight away. Optionally delete their login in Supabase.
- **Forgot password:** they use "Forgot your password?" on the sign-in page (needs the email setup above), or you run `create-users.mjs --reset`.
- **Who is admin:** the emails in `index.html` and in the `qa_admins` table. Admins see every tab, Settings branding and goals, and Sample data.

## How the security works

- Passwords are handled and stored (hashed) by Supabase. The tool never sees or saves them.
- The database refuses anyone who is not signed in **and** an active team member. Rules per role are enforced in the database too: for example Stakeholders cannot change anything, only Team Leads and up can edit Team Members or the checklist, and only QAs can write audits.
- The rules are per area, not per person: a Designer can still change any Designer-area record (self-audits, fixes, RCAs) through the database. The page limits this to their own work.
- Sessions refresh quietly. "Keep me signed in on this device" stores the session on that computer, so use it only on a personal work computer.

## What differs from the Claude version

- Updates reach other people within about 15 seconds (not instantly).
- Screenshots are stored as compressed images in the database. Each is a few hundred KB at most.
- The AI-written draft of the weekly PKT exam is not available here. The template draft is used.
- The "Enter workspace" and Employee ID link screens are only for the Claude version. Here people sign in with email and password.
- Your existing data was copied once. If you keep using the Claude version until the switch, export again before moving (Team Members > Export CSV, then re-import), or ask for a fresh `seed-data.sql`.

## Problems

| You see | Try |
|---|---|
| "Almost ready: not connected" | The three settings in `index.html` are still `PASTE-...`. |
| "Incorrect email or password" | Check the email is the one in Team Members. Reset the password. |
| Signed in but "Almost there... not in Team Members" | Add the person in Team Members with that exact work email (Active). |
| Signed in but the page stays empty | The SQL was not run, or the email is not in Team Members or `qa_admins`. |
| "Cannot reach the sign-in service" | The project URL or key in `index.html` is wrong, or the project is paused. |
| Reset email never arrives | Set up SMTP (step 2.3), check spam, or use `--reset`. |
