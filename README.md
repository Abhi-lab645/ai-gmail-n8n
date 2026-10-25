# n8n RSS Summarizer: AI Summary → Google Sheets

Automated n8n workflow that fetches articles from an RSS feed (BBC News Technology), summarizes each article into 2 plain-English sentences using an OpenRouter free AI model, and writes the results to a Google Sheet.

## Repository Contents

- [workflows/rss-summarizer.json](file:///Users/abhinavkumar/ai-gmail-n8n/workflows/rss-summarizer.json): Main workflow definition (Manual Trigger → RSS Read → Limit (5) → Basic LLM Chain + OpenRouter Chat Model → Google Sheets).
- [workflows/rss-summarizer-scheduled.json](file:///Users/abhinavkumar/ai-gmail-n8n/workflows/rss-summarizer-scheduled.json): Scheduled variant (Schedule Trigger daily at 08:00 + Google Sheets `appendOrUpdate` matching on the `Link` column to avoid duplicates).
- [scripts/import-workflow.sh](file:///Users/abhinavkumar/ai-gmail-n8n/scripts/import-workflow.sh): Bash script to import the workflow into your Docker n8n container.
- [SETUP.md](file:///Users/abhinavkumar/ai-gmail-n8n/SETUP.md): Complete setup guide, Google Cloud OAuth walkthrough, verification steps, and troubleshooting table.
- [.env.example](file:///Users/abhinavkumar/ai-gmail-n8n/.env.example): Environment variable template with placeholders.

## Quick Links

- Local n8n Instance: [http://localhost:5678](http://localhost:5678)
- Direct Workflow Canvas: [http://localhost:5678/workflow/jSTdUWRulww8JA2H](http://localhost:5678/workflow/jSTdUWRulww8JA2H)
- Detailed Setup Instructions: [SETUP.md](file:///Users/abhinavkumar/ai-gmail-n8n/SETUP.md)
