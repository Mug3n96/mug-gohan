# mug-gohan

Self-hosted recipe book with an AI assistant per recipe. Throw in a photo, a
note or a chat message; the AI turns it into a structured recipe, asks about
missing details and suggests changes you accept or reject.

無限 (mugen) "unlimited" + ごはん (gohan) "meal".

- Capture recipes from text, photos, voice or YouTube links
- Chat per recipe: edit, scale ("make it 500 g pasta"), get tips
- Clean view mode for cooking, edit mode with chat
- Single user, runs on a small VPS, web app + Android APK

## Quickstart

Needs Docker. Create a folder with two files:

`compose.yml`

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
      retries: 10

volumes:
  ollama_data:
```

`.env`

```env
API_KEY=pick-a-login-code
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=gemma4:31b-cloud
```

Start it and connect a model (pick one):

```bash
docker compose up -d

# Cloud model (no GPU needed): link the container to your ollama.com account
docker compose exec ollama ollama signin

# or local model: download it, then set OLLAMA_MODEL=gemma4:e2b in .env
docker compose exec ollama ollama pull gemma4:e2b
```

Open `http://localhost:3000` and log in with your `API_KEY`.

## Which model?

The model must support **vision** (recipe photos are sent as images).

| | Cloud `gemma4:31b-cloud` | Local `gemma4:e2b` |
|---|---|---|
| Hardware | none | several GB RAM, slow without GPU |
| Cost | pay per token, about 0.1 ct per chat message | free |
| Quality | good | okay, sometimes breaks the proposal format |

Ollama Cloud has no free tier since November 2026. Top up credits on
[ollama.com](https://ollama.com/pricing). When the credits run out, the chat says so.

Cloud without the Ollama container: remove the `ollama` service and `depends_on`,
then set `OLLAMA_HOST=https://ollama.com` and `OLLAMA_API_KEY` (from
ollama.com/settings/keys).

## YouTube links (optional)

Paste a YouTube link into a recipe chat and the assistant builds the recipe from
what is shown and said in the video. Needs a Gemini API key (free tier is enough
for personal use, key from [aistudio.google.com/apikey](https://aistudio.google.com/apikey)):

```env
GEMINI_API_KEY=your-key
```

Each video is analyzed **once** and the result is stored; follow-up messages
and other recipes with the same link reuse the text, so there is no extra
Gemini cost per chat message. Only public videos work. Without a key, links
still show as thumbnails, but the assistant cannot see the video.

Under a linked video, "Als Rezeptbild übernehmen" offers the thumbnail and three
scenes from the video as the recipe image (black bars are cut off).

## Update

```bash
docker compose pull && docker compose up -d
```

## Configuration

| `.env` | |
|---|---|
| `API_KEY` | Login code |
| `OLLAMA_HOST` | Ollama URL, default `http://ollama:11434` |
| `OLLAMA_MODEL` | Model name, see above |
| `OLLAMA_API_KEY` | Only for `OLLAMA_HOST=https://ollama.com` |
| `GEMINI_API_KEY` | Optional, enables YouTube links |
| `GEMINI_MODEL` | Default `gemini-3.1-flash-lite` |
| `WHISPER_URL` | Optional Whisper server, enables voice input |

**Look and assistant:** copy [`config.json.example`](config.json.example) to
`config.json` and mount it with `- ./config.json:/app/config.json:ro`. It sets
colors, UI texts and the assistant's name, persona and language. Restart to apply.

**Branding:** mount `- ./branding:/app/branding:ro` and put `favicon.png`,
`avatar.svg` or `avatar-icon.svg` in it.

## HTTPS

Put a reverse proxy in front of `127.0.0.1:3000`. It needs a large body limit
(images, ~50 MB) and a long timeout (LLM replies, ~300 s).

```caddy
recipes.example.com {
    reverse_proxy 127.0.0.1:3000
    request_body { max_size 50MB }
}
```

```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 300s;
    client_max_body_size 50m;
}
```

## Development

Node.js 20+, Flutter SDK, Ollama.

```bash
cd backend && npm install && npm run dev                 # API on :3000
cd frontend && flutter run -d chrome --web-port=8080     # web app on :8080
./build.sh                                               # build web app + image, start
cd frontend && flutter build apk --release               # Android APK
```

API docs: `http://localhost:3000/api/docs`. Pushes to `main` build the Docker
image `mug3n96/mug-gohan:latest`; tags `v*` publish the APK as a GitHub release.
