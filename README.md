# mug-gohan

A self-hosted recipe book with an AI chat assistant per recipe. Capture recipes by
text, photo or chat; the AI fills a structured template and asks when something is
missing.

The name is Japanese: 無限 (mugen) "unlimited" + ごはん (gohan) "meal".

## Features

- Capture recipes via text, photo or chat; the AI structures them into a template
- AI chat assistant per recipe: editing, ingredient scaling, tips, accept/reject proposals
- View mode (clean, for cooking) and Edit mode (all fields + chat)
- Self-hosted, single user
- Flutter Web + Android from one codebase

## Tech Stack

- **Backend:** Node.js + Express + TypeScript + SQLite
- **Frontend:** Flutter (Web + Android)
- **LLM:** Ollama (local or cloud)
- **Deployment:** Docker Compose

---

## Deployment (Docker Compose)

Runs from the prebuilt image, no source build needed. On a server with Docker, create
a folder with three files.

`compose.yml`:

```yaml
services:
  backend:
    image: mug3n96/mug-gohan:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    env_file: .env
    volumes:
      - ./data:/app/data
      - ./config.json:/app/config.json:ro
    depends_on:
      ollama:
        condition: service_healthy

  ollama:
    image: ollama/ollama:latest
    restart: unless-stopped
    volumes:
      - ollama_data:/root/.ollama
    healthcheck:
      test: ["CMD", "ollama", "list"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

volumes:
  ollama_data:
```

`.env`:

```env
API_KEY=change_me
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=gemma3
```

`config.json` (optional: theme, UI texts, AI persona):

```json
{
  "theme": { "seedColor": "#2D6A4F", "accentColor": "#52B788" },
  "assistant": {
    "name": "Miso",
    "persona": "You are Miso, a friendly cooking assistant. Keep answers short.",
    "language": "Reply in German by default, in English if the user writes English."
  }
}
```

Start, then pull a vision model once (needed for recipe photos):

```bash
docker compose up -d
docker compose exec ollama ollama pull gemma3
```

Open `http://SERVER:3000` and log in with your `API_KEY`.

### HTTPS via reverse proxy

For a public domain, put nginx or Caddy in front. The app listens on `127.0.0.1:3000`.
Any proxy needs two settings: a large request body (Base64 image uploads, ~50 MB) and
a long read timeout (~300s, LLM responses are slow).

**nginx** at `/etc/nginx/sites-available/mug-gohan`:

```nginx
server {
    listen 80;
    server_name rezepte.example.com;
    client_max_body_size 50m;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host              $host;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/mug-gohan /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d rezepte.example.com
```

**Caddy** at `/etc/caddy/Caddyfile`:

```caddy
rezepte.example.com {
    reverse_proxy 127.0.0.1:3000
    request_body { max_size 50MB }
}
```

### Ollama: local vs cloud

The bundled `ollama` container runs the model locally. The model must support
**vision** (recipe photos); `gemma3` runs almost everywhere. For a cloud model
(suffix `-cloud`, needs an ollama.com account):

```bash
docker compose exec ollama ollama signin
# then set e.g. OLLAMA_MODEL=gemma3:27b-cloud in .env
```

---

## Development

Build from source. Requirements: Node.js 20+, Flutter SDK, Ollama.

```bash
# Backend (hot reload on http://localhost:3000)
cd backend && npm install && npm run dev

# Frontend (hot reload on http://localhost:8080)
cd frontend && flutter run -d chrome --web-port=8080

# Build the served web app + image and start the containers
./build.sh

# Android APK
cd frontend && flutter build apk --release
```

`build.sh` builds the Flutter web app, copies it into `backend/public/`, builds the
backend image and starts the containers. The backend serves the web app and the API on
port 3000.

---

## Configuration

`config.json` is mounted read-only; edit it and restart the backend (no rebuild):

- `theme`: seed and accent color
- `strings`: UI texts
- `assistant`: name, persona, language (the technical response-format rules stay in the
  backend so the parser cannot break)

**Branding:** drop `favicon.png`, `avatar.svg` or `avatar-icon.svg` into `branding/` to
override; bundled defaults are used otherwise. Avatars render as a single-color
silhouette tinted with the theme color (web only).

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `API_KEY` | Login key for the app | – |
| `OLLAMA_HOST` | Ollama API URL | `http://ollama:11434` |
| `OLLAMA_MODEL` | Model to use (must support vision) | `gemma3` |
| `OLLAMA_API_KEY` | Only for the direct ollama.com API | – |
| `WHISPER_URL` | Optional Whisper URL; shows the mic button when set | – |
