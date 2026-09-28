# Suwayomi on Fly.io

Fly.io deployment config for [Suwayomi-Server](https://github.com/Suwayomi/Suwayomi-Server), a self-hosted manga server that runs [Mihon](https://mihon.app) extensions and ships a web reader.

With this you can read your Mihon library in any browser, and keep reading progress in sync with Mihon on your phone.

- One Fly Machine (1 GB RAM) plus one volume. The database is Suwayomi's built-in H2.
- Basic auth is on, and credentials live in `fly secrets`.
- The machine suspends when idle and resumes on the next request in under a second. Cost is about $1–3/mo.

## Prerequisites

- [`fly` CLI](https://fly.io/docs/flyctl/install/) installed and authenticated
- A [Fly.io](https://fly.io) account with billing set up

## Choose your own app name

`app = 'suwayomi-af'` in `fly.toml` is an example. Fly app names are globally unique, so change it to something of your own before deploying. Nothing else references the name.

While you're there, set `primary_region` to a [Fly region](https://fly.io/docs/reference/regions/) near you and `TZ` to your timezone.

## Deploy

```bash
# 1. Create the app (use the name you put in fly.toml)
fly apps create <your-app-name>

# 2. Set login credentials. Use letters and digits only in the password:
#    upstream writes it into server.conf with sed, so / & \ and quotes break it.
fly secrets set AUTH_USERNAME=<user> AUTH_PASSWORD=<password> --stage

# 3. Deploy (builds the thin wrapper image and creates the volume on first run)
fly deploy
```

Open `https://<your-app-name>.fly.dev`. The browser asks for the credentials, then shows the web UI.

## Import your Mihon library

1. In Mihon, go to **Settings → Data and storage → Create backup** and copy the `.tachibk` file to your computer.
2. In the web UI, go to **Browse → Extensions** and install the extensions your library uses.
   - The [Keiyoushi](https://keiyoushi.github.io/) repo is preconfigured; change `EXTENSION_STORES` in `fly.toml` if you use another.
   - Install extensions before you restore, so the backup's sources resolve.
3. Go to **Settings → Backup → Restore** and pick the file. This brings over your library, categories, read chapters and tracker bindings.
4. Go to **Settings → Tracking** and log in to AniList (or MAL, MangaUpdates, …).

## Connect Mihon to the server

This keeps read status in sync both ways between Mihon and the web UI.

1. **Make a fresh Mihon backup and keep it somewhere safe.** The migration in step 3 rewrites library entries.
2. In Mihon, install the **Suwayomi** extension from the Keiyoushi repo. Open its settings and enter:
   - the server URL: `https://<your-app-name>.fly.dev`
   - your basic-auth username and password
3. Go to **Browse → Migrate** and move your library entries onto the Suwayomi source. Migration keeps read status and trackers.
4. Go to **Settings → Tracking** and enable **Suwayomi**. It binds automatically to entries from the Suwayomi source.

Progress you make in Mihon is pushed to the server as you read. To pull progress you made in the web UI, open the manga's tracking sheet in Mihon.

### AniList (or other trackers)

Keep your tracker enabled on both sides. Mihon and Suwayomi each push progress to it independently, so it always shows the furthest chapter either device reached.

Trackers are write-only from Mihon's point of view: nothing reads progress back from AniList. Phone↔server sync comes from the Suwayomi tracker above, not from AniList.

## Cost and availability

`fly.toml` ships with `auto_stop_machines = 'suspend'`. The comment block at `[http_service]` has the two lines to change for always-on (about $6/mo).

While suspended, scheduled library updates and automatic backups don't run. Use `suspend`, not `stop`: a cold JVM start takes about 15s, which is long enough for Mihon's requests to time out.

## Troubleshooting

- **A source works on your phone but not here.** Some sites block datacenter IPs or sit behind Cloudflare challenges. Suwayomi can route through [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) (`FLARESOLVERR_*`) or a SOCKS proxy (`SOCKS_PROXY_*`); see the [container docs](https://github.com/Suwayomi/Suwayomi-Server-docker) for the variables.
- **A source needs a WebView.** Set `KCEF_ENABLED = 'true'` and raise `memory_mb` to 2048.
- **Out-of-memory restarts.** Raise `memory_mb` and `-Xmx` in `JAVA_TOOL_OPTIONS` together, keeping the heap at about 60% of RAM.

## Why there's a Dockerfile

Fly mounts volumes owned by root, and the upstream image runs as uid 1000 without fixing ownership, so it can't write its own config. `Dockerfile` and `fly-entrypoint.sh` chown the volume on first boot, then drop back to uid 1000. Nothing else about the image changes.

## Ongoing

```bash
fly logs          # tail logs
fly status        # machine state (started / suspended)
fly ssh console   # shell into the machine
fly deploy        # redeploy after fly.toml changes
fly deploy --no-cache   # also re-pull the latest :stable upstream image
```
