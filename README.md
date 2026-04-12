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

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/your-username/mug-gohan.git
cd mug-gohan

# 2. Configure environment
cp .env.example .env
# Edit .env: set API_KEY and choose your Ollama model

# 3. Start
docker compose up -d
```

Open [http://localhost:3000](http://localhost:3000) and enter your API key.

### With Caddy (automatic HTTPS)

```bash
cp Caddyfile.example Caddyfile
# Edit Caddyfile: replace domain placeholder with your domain
docker compose -f docker-compose.caddy.yml up -d
```

### Ollama Models

**Local model** (requires GPU or sufficient RAM):
```env
OLLAMA_MODEL=gemma4:e4b
```

**Cloud model** (no local GPU needed, requires Ollama account):
```env
OLLAMA_MODEL=gemma4:e4b-cloud
```

Pull the model once after starting:
```bash
docker compose exec ollama ollama pull gemma4:e4b
```

## Development

### Requirements

- Node.js 20+
- Flutter SDK
- Ollama (local)

### Backend

```bash
cd backend
npm install
npm run dev
```

### Frontend

```bash
cd frontend
flutter run -d chrome
```

The Flutter dev server runs on its own port with hot reload. It talks to the backend on `http://localhost:3000`.

### Building for production

After the frontend is done, build it and copy it into the backend:

```bash
cd frontend
flutter build web
cp -r build/web/* ../backend/public/
```

The backend then serves the Flutter web app on `http://localhost:3000`.

### Building the Android APK

```bash
cd frontend
flutter build apk
# APK is at build/app/outputs/flutter-apk/app-release.apk
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `API_KEY` | Login key for the app | – |
| `OLLAMA_HOST` | Ollama API URL | `http://ollama:11434` |
| `OLLAMA_MODEL` | Model to use | `gemma4:e4b` |
| `OLLAMA_API_KEY` | Ollama account key (cloud models only) | – |
| `PORT` | Backend port | `3000` |
| `DATA_DIR` | SQLite database directory | `/app/data` |
