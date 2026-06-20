# mug-gohan

A self-hosted recipe book web app with an AI chat assistant per recipe.

The name comes from Japanese: 無限 (mugen) = "unlimited" + ごはん (gohan) = "meal".

## Features

- Capture recipes via text, photo or chat — the AI fills in a structured template
- AI chat assistant per recipe for editing, scaling ingredients, and tips
- View mode (clean, distraction-free) and Edit mode (all fields + chat)
- Self-hosted, single-user — like Bitwarden for recipes
- Flutter Web + Android from a single codebase

## Tech Stack

- **Backend:** Node.js + Express + TypeScript + SQLite
- **Frontend:** Flutter (Web + Android)
- **LLM:** Ollama (local or cloud models)
- **Deployment:** Docker Compose

---

## Quick Start

Runs everything locally on `http://localhost:3000`.

### Requirements

- Docker + Docker Compose
- Flutter SDK (for building the web app)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/your-username/mug-gohan.git
cd mug-gohan

# 2. Configure environment
cp .env.example .env
# Edit .env: set API_KEY and choose your Ollama model

cp config.json.example config.json
# Optional: edit config.json to set theme, UI texts and the AI persona

# 3. Build and start
./build.sh
```

Open [http://localhost:3000](http://localhost:3000) and enter your API key.

`build.sh` builds the Flutter web app, copies it into the backend, and starts all
Docker containers. The backend serves **both** the web app and the API on port 3000.

---

## Ollama Models

### Option A: Local Ollama container (default)

The `ollama` service in `compose.yml` runs Ollama locally.

Local model (requires ~7 GB RAM):
```env
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=gemma4:e2b
```

Cloud model via local container (requires ollama.com account, no GPU/RAM needed):
```env
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=gemma4:31b-cloud
```

Sign in once after first start (credentials are stored in the `ollama_data` volume):
```bash
docker compose exec ollama ollama signin
```

Pull a local model once before use:
```bash
docker compose exec ollama ollama pull gemma4:e2b
```

### Option B: Direct ollama.com API (no local container)

If you don't want to run the Ollama container at all, point directly to ollama.com:

1. Create an API key at [ollama.com/settings/keys](https://ollama.com/settings/keys)
2. Remove the `ollama` service and `depends_on` from `compose.yml`
3. Set in `.env`:

```env
OLLAMA_HOST=https://ollama.com
OLLAMA_MODEL=gemma4:31b-cloud
OLLAMA_API_KEY=your-api-key
```

---

## Production Deployment (Reverse Proxy)

For a public deployment you put a reverse proxy in front of the app for a domain
name and HTTPS. The app still runs via `./build.sh` and listens on `127.0.0.1:3000`;
the proxy terminates TLS and forwards to it.

### DNS

Point an **A record** (and **AAAA** for IPv6) for your domain to the server's
**public IP address**:

```
rezepte.example.com.   A     203.0.113.10
rezepte.example.com.   AAAA  2001:db8::10
```

Wait until `dig +short rezepte.example.com` returns your server IP before requesting
a certificate.

> **Two settings this app requires on any proxy:**
> - **Long read timeout** — LLM chat responses can take a while (cold model start, up
>   to ~180s). The default 60s would cut the request mid-generation.
> - **Large request body** — image uploads are sent as Base64; the backend accepts up
>   to 50 MB.

### Option 1: nginx (recommended)

**1. Create the site config** at `/etc/nginx/sites-available/mug-gohan`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name rezepte.example.com;

    client_max_body_size 50m;        # Base64 image uploads

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 300s;     # LLM responses are slow
        proxy_send_timeout 300s;
    }
}
```

**2. Enable it** by symlinking into `sites-enabled`:

```bash
sudo ln -s /etc/nginx/sites-available/mug-gohan /etc/nginx/sites-enabled/
sudo nginx -t            # check config
sudo systemctl reload nginx
```

**3. Add HTTPS with Let's Encrypt** (certbot edits the config and sets up renewal):

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d rezepte.example.com
```

certbot adds the `listen 443 ssl` block and a redirect from HTTP to HTTPS, and
renews automatically via a systemd timer.

### Option 2: Caddy (automatic HTTPS)

Caddy fetches and renews certificates by itself — no certbot step. Put this in
`/etc/caddy/Caddyfile`:

```caddy
rezepte.example.com {
    reverse_proxy 127.0.0.1:3000
    request_body {
        max_size 50MB
    }
}
```

```bash
sudo systemctl reload caddy
```

Caddy streams proxied responses without a default response timeout, so the long
LLM requests work out of the box.

---

## Development

### Requirements

- Node.js 20+
- Flutter SDK
- Ollama running locally

### Backend

```bash
cd backend
npm install
npm run dev   # starts on http://localhost:3000 with hot reload
```

### Frontend

```bash
cd frontend
flutter run -d chrome --web-port=8080
# or with a specific browser:
CHROME_EXECUTABLE=/usr/bin/brave flutter run -d chrome --web-port=8080
```

The Flutter dev server runs on port 8080 with hot reload. It talks to the backend
on `http://localhost:3000`.

### Building for production

```bash
./build.sh
```

This script:
1. Builds the Flutter web app (`flutter build web --release`)
2. Copies the output to `backend/public/`
3. Rebuilds and restarts the Docker containers

### Building the Android APK

```bash
cd frontend
flutter build apk --release
# APK is at build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuration

App appearance, UI strings and the AI assistant's persona are read from
`config.json` (mounted read-only into the container). Edit it and restart the
backend — no rebuild needed:

- `theme` — seed and accent color
- `strings` — UI texts (titles, empty states, greetings)
- `assistant` — the AI's name, persona and language rules (the technical
  response-format rules stay in the backend so the parser cannot break)

### Custom branding (favicon + AI avatar)

Drop these files into the `branding/` folder and restart the backend — no
rebuild needed (the folder is mounted read-only):

| `branding/` file | Overrides |
|---|---|
| `favicon.png` | browser tab icon |
| `avatar.svg` | the large assistant illustration (empty chat) |
| `avatar-icon.svg` | the small assistant icon (chat header, recipe detail) |

When a file is absent the app uses its bundled neutral default (a small
chef-bot). The avatars are rendered as a single-color silhouette tinted with the
theme color, so design them as flat shapes — fine detail and color are dropped.
Custom branding is applied on the web app; the Android APK always uses the
bundled default.

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `API_KEY` | Login key for the app | – |
| `OLLAMA_HOST` | Ollama API URL (`http://ollama:11434` for local container, `https://ollama.com` for direct API) | `http://ollama:11434` |
| `OLLAMA_MODEL` | Model to use | `gemma4:e2b` |
| `OLLAMA_API_KEY` | Only needed for Option B (direct ollama.com API) | – |
| `PORT` | Backend port | `3000` |
| `DATA_DIR` | SQLite database directory | `./data` |
| `WHISPER_URL` | Optional Whisper service URL; enables the mic/voice button when set | – |
