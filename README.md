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

## Quick Start

### Requirements

- Docker + Docker Compose
- Flutter SDK (for building)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/your-username/mug-gohan.git
cd mug-gohan

# 2. Configure environment
cp .env.example .env
# Edit .env: set API_KEY and choose your Ollama model

# 3. Build and start
./build.sh
```

Open [http://localhost:3000](http://localhost:3000) and enter your API key.

`build.sh` builds the Flutter web app, copies it into the backend, and starts all Docker containers.

### Ollama Models

**Option A: Local Ollama container (default)**

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

**Option B: Direct ollama.com API (no local container)**

If you don't want to run the Ollama container at all, point directly to ollama.com:

1. Create an API key at [ollama.com/settings/keys](https://ollama.com/settings/keys)
2. Remove the `ollama` service and `depends_on` from `compose.yml`
3. Set in `.env`:

```env
OLLAMA_HOST=https://ollama.com
OLLAMA_MODEL=gemma4:31b-cloud
OLLAMA_API_KEY=your-api-key
```

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

The Flutter dev server runs on port 8080 with hot reload. It talks to the backend on `http://localhost:3000`.

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

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `API_KEY` | Login key for the app | – |
| `OLLAMA_HOST` | Ollama API URL (`http://ollama:11434` for local container, `https://ollama.com` for direct API) | `http://ollama:11434` |
| `OLLAMA_MODEL` | Model to use | `gemma4:e2b` |
| `OLLAMA_API_KEY` | Only needed for Option B (direct ollama.com API) | – |
| `PORT` | Backend port | `3000` |
| `DATA_DIR` | SQLite database directory | `./data` |
