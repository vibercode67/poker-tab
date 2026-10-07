# The Tab

A running tab for a home poker game: buy-ins, rebuys, chip counts, standings, quarterly settle-up, and a hand ranking cheat sheet.

Three files make up the site:

- `index.html` is the whole app.
- `config.js` holds your database address and key.
- `supabase.sql` sets up the database once.

Until `config.js` is filled in, the site runs in demo mode and keeps data on that one device only.

## Setup (about 15 minutes, once)

### 1. Create the database

1. Go to supabase.com, sign up (free), and create a new project. Any name and region.
2. In the project, open **SQL Editor**, paste in the full contents of `supabase.sql`, and press **Run**.

### 2. Connect the site to it

1. In Supabase, open **Project Settings**, then **API** (or **API Keys**).
2. Copy the **Project URL** and the **publishable** key (older projects call it the **anon public** key). Do not use the secret / service_role key.
3. Open `config.js` and paste them between the quotes:

```js
window.POKER_CONFIG = {
  supabaseUrl: "https://abcdefgh.supabase.co",
  supabaseKey: "sb_publishable_..."
};
```

### 3. Put it on GitHub Pages

1. On github.com, create a new **public** repository, for example `poker-tab`.
2. Choose **uploading an existing file** and drag in `index.html`, `config.js`, `supabase.sql` and this README. Commit.
3. In the repository, open **Settings**, then **Pages**. Under **Branch** pick `main` and `/ (root)`, then **Save**.
4. After a minute the link appears at the top of that page: `https://YOUR-USERNAME.github.io/poker-tab/`. That is the link to send your friends.

### 4. Change the PINs

The database starts with table PIN `DEAL` and host PIN `BANKER`.

1. Open the site and enter `BANKER`.
2. Tap **Host** (top right) and set your own table PIN (exactly 4 characters) and host PIN (4 or more).
3. Give friends the table PIN. Give co-hosts the host PIN.

PINs are not case sensitive. Changing one signs out everyone who was using the old one.

## How a night works

1. **Tonight**: set the cash buy-in and how many chips it buys (for example $20 buys 50), tap who's in, **Deal them in**.
2. Tap **+ $20** for a rebuy. **Edit** adds a different amount or removes a mistake. Seat latecomers at any point.
3. At the end, type each player's final chip count. The cash-out table shows what the chips are worth and who is up or down. If the count is a few chips off, payouts are scaled so the night still balances to zero.
4. **Close the night**. Results move onto the tab.

Nothing is paid on the night. **The tab** shows running balances and the fewest payments that would square everyone. When the quarter is up, the host taps **Settle up and start a new season**, then marks each payment as paid.

## Good to know

- The PINs are checked by the database, so the data cannot be read or changed without one. A 4-character PIN keeps casual visitors out; it is not bank-grade security.
- **Host → Copy a backup** copies the whole book as text. Paste it into a note every so often.
- Free Supabase projects pause after a week with no visits. If the site says it can't reach the books, open your Supabase dashboard and press **Restore**.
- Add it to a phone's home screen from the browser's share menu to use it like an app.
