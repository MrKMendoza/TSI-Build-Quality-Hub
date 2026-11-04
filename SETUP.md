# TSI Build Quality Hub: hosted version (username and password)

This copy runs on your own web address (Vercel) with its own sign-in (Supabase). Nobody needs a Claude account.
There are no scripts to run. You create each login by hand in the Supabase website.

| File | What it is |
|---|---|
| `index.html` | The tool. Your Supabase project, the two admins and the company domain are already filled in at the top. |
| `supabase-schema.sql` | Creates the database and the access rules. Run once. |
| `seed-data.sql` | Your team members and checklist from the Claude version. Run once. |
| `logins-to-create.csv` | A checklist of everyone who needs a login (name, username, email, role). Open it in Excel. |
| `vercel.json` | Security headers for Vercel. |

## 1. Set up the database (about 10 minutes)

1. Open your project at supabase.com. Go to **SQL Editor > New query**.
2. Open `supabase-schema.sql`, copy all of it, paste, press **Run**. (The two admin emails are already inside.)
3. New query again: paste all of `seed-data.sql` and press **Run**. This loads your team members and the checklist.

## 2. Turn off public sign-ups (important)

In Supabase go to **Authentication** and open the **Email** sign-in settings. Switch **off** "Allow new users to sign up", so only people you create can sign in. Set a **minimum password length** of 8 or more.

## 3. Create each login by hand

For every person (start with the two admins, Kenandrei and Julius):

1. Supabase > **Authentication > Users > Add user > Create new user**.
2. **Email:** their work email, exactly as in Team Members (see the third column of `logins-to-create.csv`).
3. **Password:** a password you choose.
4. Tick **Auto Confirm User**, then **Create user**.

They sign in with their **username** (the part before the @, for example `juan.delacruz`) and that password. Typing the full email also works.
Send each person their password privately, not in a group chat. They can change it later in **Settings > Account > Change password**.

## 4. Put the tool on the web (Vercel)

1. At vercel.com choose **Add New > Project** and upload this folder (`index.html` and `vercel.json`). Deploy.
2. Open the address Vercel gives you. You should see the animated sign-in page. Sign in as an admin to test.
3. Test with one Designer, one QA and one Team Lead before inviting everyone.

## Day to day

- **New person:** add them in **Team Members** (work email, Active), then add their login (step 3).
- **Someone leaves:** set them **Inactive** in Team Members. Their access stops straight away. You can also delete their login in Supabase.
- **Forgot password:** there is no reset by email. In Supabase delete that person's login and add it again with a new password.
- **Admins:** the emails in `index.html` and in the `qa_admins` table. Admins see every tab, plus Branding, Goals and Sample data in Settings. To add an admin, add the email in both places (in the SQL Editor: `insert into public.qa_admins (email) values ('name@eclerx.com') on conflict do nothing;`).

## How the security works

- Passwords are handled and stored (hashed) by Supabase. The tool never sees or saves them.
- The database refuses anyone who is not signed in **and** an active team member. Rules per role are enforced in the database too: Stakeholders cannot change anything, only Team Leads and up can edit Team Members or the checklist, and only QAs can write audits.
- The rules are per area, not per person: a Designer can still change any Designer-area record through the database. The page limits this to their own work.
- "Keep me signed in on this device" keeps the session on that computer, so use it only on a personal work computer.

## What differs from the Claude version

- Updates reach other people within about 15 seconds (not instantly).
- Screenshots are stored as compressed images in the database.
- The AI-written draft of the weekly PKT exam is not available here. The template draft is used.
- The "Enter workspace" and Employee ID link screens are only for the Claude version.
- Your data was copied once. If you keep adding people in the Claude version first, ask for a fresh `seed-data.sql` before switching.

## Problems

| You see | Try |
|---|---|
| "Almost ready: not connected" | The settings at the top of `index.html` were changed or removed. |
| "Incorrect username or password" | Check the login exists in Supabase with the work email, that Auto Confirm was ticked, and the password. |
| Signed in but "not in Team Members" | Add the person in Team Members with that exact work email (Active). |
| Signed in but the page stays empty | The SQL was not run, or the email is not in Team Members or `qa_admins`. |
| "Cannot reach the sign-in service" | The project URL or key is wrong, or the project is paused. |
