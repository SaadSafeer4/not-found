# Not Found

Every URL on this site is a page that can be claimed once. Visit an address nobody has claimed and you can write up to 280 characters there. After that the page is permanent: anyone who visits that address sees the text. No accounts, no cookies, no stored IP addresses.

It is one static `index.html` (plain JavaScript, no build step) talking to Supabase's auto-generated REST API with plain `fetch`. There is no server code.

```
index.html            the whole app
config.js             your Supabase URL + anon key
_redirects            catch-all rewrite for Cloudflare Pages
supabase/schema.sql   the table and row-level-security policies
```

## 1. Create a Supabase project

1. Sign in at <https://supabase.com> and create a new project (the free tier is fine).
2. Wait for it to finish provisioning.

## 2. Run the schema

Open **SQL Editor** in the Supabase dashboard, paste the contents of [`supabase/schema.sql`](supabase/schema.sql), and run it. It creates `public.pages` with row-level security so that `anon` can read pages and insert new ones, and nobody can update or delete.

The primary key on `slug` is what makes a claim atomic: the insert itself decides who wins, and the loser gets HTTP 409 (Postgres error 23505).

## 3. Fill in `config.js`

In the dashboard go to **Project Settings -> API** and copy the **Project URL** and the **anon / public** key into [`config.js`](config.js):

```js
window.NOT_FOUND_CONFIG = {
  SUPABASE_URL: "https://abcdefghijkl.supabase.co",
  SUPABASE_ANON_KEY: "eyJ...",
};
```

The anon key is meant to be public, so committing it is fine. Never put the `service_role` key here.

**Also update the Content-Security-Policy** in `index.html`: replace `https://YOUR-PROJECT-REF.supabase.co` in the `connect-src` directive with the same URL. Until you do, the browser will block the requests.

## 4. Run locally

```bash
npx serve -s .
```

The `-s` flag makes `serve` fall back to `index.html` for unknown paths, like the Cloudflare rewrite does. Open the URL it prints, e.g. <http://localhost:3000/>, then visit any path.

## 5. Deploy to Cloudflare Pages

1. Push this folder to a Git repository.
2. In Cloudflare: **Workers & Pages -> Create -> Pages -> Connect to Git**, pick the repo.
3. **Build command:** leave empty. **Build output directory:** `/` (the repo root).
4. Deploy. `_redirects` (`/* /index.html 200`) makes every path serve `index.html`.

## Deploy to Vercel instead

`vercel.json` holds the catch-all rewrite (Vercel ignores `_redirects`). From the project folder run `vercel` (or `vercel --prod`) and accept the defaults: no framework, no build command, output directory `.`. Real files such as `config.js` are served first, and every other path falls through to `index.html`.

## Notes

- **Content-Security-Policy and the inline script.** The CSP allows same-origin scripts (`config.js`) plus the single inline script in `index.html`, pinned by SHA-256 hash, so the whole app can stay in one file without `'unsafe-inline'`. If you edit that script, the hash in the CSP must change or the page will go blank (the console will say which hash it expected). To recompute it:

  ```bash
  node -e "const s=require('fs').readFileSync('index.html','utf8').match(/<script>([\s\S]*?)<\/script>/)[1];console.log('sha256-'+require('crypto').createHash('sha256').update(s).digest('base64'))"
  ```

- **Reserved addresses.** Paths that are real files in the deployed folder (`/config.js`, `/README.md`, `/supabase/schema.sql`, ...) are served as files, not as claimable pages. Everything else, including `/index.html` on some hosts, falls through to the app.
- **Slugs.** Addresses are normalized (NFKC, lowercased, runs of non letter/number characters become a single hyphen, max 100 characters), so `/The%20Smell` and `/the-smell` are the same page. Combining marks (e.g. Arabic diacritics, Devanagari vowel signs) are not letters or numbers under `\p{L}\p{N}`, so they act as separators.
