# Docker & Workflow Deployment Guide: n8n RSS Summarizer

This comprehensive guide explains how to deploy, configure, run, and maintain the **n8n RSS Summarizer** pipeline using Docker, OpenRouter AI, and Google Sheets.

---

## 1. System Overview & Architecture

The system supports both single-source and multi-source RSS intelligence pipelines:

```
[Trigger] (Manual / Schedule @ 08:00)
    │
    ▼
[Feed Sources] (BBC Tech, TechCrunch, The Verge, Wired)
    │
    ▼
[RSS Read] (Fetches RSS XML feeds sequentially)
    │
    ▼
[Format & Filter] (Balances 2 items per source, cleans HTML)
    │
    ▼
[Basic LLM Chain] ◄── [OpenRouter Chat Model] (openrouter/free)
    │                  (Summarizes each item into 2 plain-English sentences)
    ▼
[Google Sheets]
    (Appends/Updates: Source | Title | Link | Published | Summary)
```

---

## 2. Docker Setup & Deployment

### Prerequisites
- Docker Engine / Docker Desktop (macOS, Linux, or Windows)
- Port `5678` available on localhost

### Method A: Docker Compose (Recommended)
Use the included `docker-compose.yml`:

```bash
# Start container
docker compose up -d

# Check status
docker compose ps

# View live container logs
docker compose logs -f n8n
```

### Method B: Docker CLI
Run n8n in detached mode with persistent volume storage:

```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e TZ=Asia/Kolkata \
  -e GENERIC_TIMEZONE=Asia/Kolkata \
  -v n8n-class_n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n:latest
```

### Volume Persistence
All workflows, user credentials, settings, and execution history are stored in Docker volume `n8n-class_n8n_data` mounted at `/home/node/.n8n`. Restarting or updating the container preserves all data.

---

## 3. Workflow Installation & Management

### Automated Import via Script
Import all workflow definitions directly into the running n8n container:

```bash
chmod +x ./scripts/import-workflow.sh
./scripts/import-workflow.sh
```

### Verifying Imported Workflows
List all active workflows in the container:

```bash
docker exec n8n n8n list:workflow
```

---

## 4. Credentials & External Services

### A. OpenRouter AI (Free Tier)
1. Generate an API key at [openrouter.ai/keys](https://openrouter.ai/keys).
2. Model used: `openrouter/free` (or any `:free` model ID such as `meta-llama/llama-3.3-70b-instruct:free`).
3. The prompt template:
   ```text
   Summarize this article in 2 plain-English sentences. Highlight the main news impact.

   Source: {{ $json.source }}
   Title: {{ $json.title }}

   Content: {{ $json.contentSnippet }}
   ```
4. Retry and error handling:
   - `retryOnFail: true`
   - `maxTries: 3`
   - `waitBetweenTries: 2000 ms`
   - `onError: "continueRegularOutput"`

### B. Google Cloud & Google Sheets
1. Enable **Google Sheets API** and **Google Drive API** in Google Cloud Console.
2. In **OAuth consent screen**:
   - User Type: **External**
   - Add your Google account to **Test users**.
3. In **Credentials**:
   - Create **OAuth client ID** (Web application).
   - Authorized redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`
4. Destination Google Sheet (`RSS Summaries`):
   - Row 1 headers: `Source | Title | Link | Published | Summary`.

---

## 5. Execution Methods

### Option 1: Via n8n Web UI
1. Navigate to [http://localhost:5678](http://localhost:5678).
2. Select your workflow:
   - **Multi-Source Pipeline**: `RSS Summarizer (Multi-Source)`
   - **Single-Source Baseline**: `RSS Summarizer`
3. Click **Execute workflow** at the bottom of the canvas.
4. Observe live execution left-to-right with item counts and green status ticks.

### Option 2: Via Terminal CLI
Run headless workflow execution inside the container:

```bash
# Execute Multi-Source Pipeline
docker exec -e N8N_RUNNERS_BROKER_PORT=5689 n8n n8n execute --id=shY8hRfrlFmK2Suq

# Execute Single-Source Baseline
docker exec -e N8N_RUNNERS_BROKER_PORT=5689 n8n n8n execute --id=jSTdUWRulww8JA2H
```

---

## 6. Production Troubleshooting Matrix

| Problem | Cause | Resolution |
| :--- | :--- | :--- |
| **Why single feed fetches same 5 items** | The feed only refreshes when publisher publishes news. | Switch to `rss-summarizer-multi.json` which aggregates 4 publications and deduplicates via `appendOrUpdate`. |
| **Error 403: access_denied** | User email not registered as tester in Google Cloud. | Add email under Google Cloud Console → OAuth consent screen → **Test users**. |
| **Drive/Sheets API Disabled** | Google Cloud APIs not activated for project. | Enable both **Google Drive API** and **Google Sheets API** in Google Cloud Library. |
| **Parameter "Document" is required** | Spreadsheet ID or URL not selected in node. | Connect document via list or paste spreadsheet URL into `documentId`. |
| **columns.schema required** | n8n 4.4+ requires schema definition for manual column mapping. | Define `columns.schema` array matching sheet header names. |
| **OpenRouter 429 Rate Limit** | Free model peak usage reached. | Automated retries (`3 tries`, `2000 ms`) automatically recover; switch to alternate `:free` model if needed. |
