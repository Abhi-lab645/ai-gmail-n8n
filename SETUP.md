# RSS Summarizer: Setup & Execution Guide

This document captures the complete configuration, verification steps, and troubleshooting knowledge adapted from the exercise specification (`n8n Exercise RSS Feed → AI Summary → Google Sheets`).

---

## 1. Prerequisites Checklist

- [x] **n8n Container**: Running at `http://localhost:5678` (Docker container: `n8n`, version: `2.44.6`).
- [ ] **OpenRouter Account & API Key**: Free account created at [openrouter.ai/keys](https://openrouter.ai/keys).
- [ ] **Google Cloud Project**: Project with Google Sheets & Google Drive APIs enabled.
- [ ] **Google Sheet Destination**: Spreadsheet named `RSS Summaries` with required column headers.

---

## 2. Step-by-Step Manual Setup

Follow these exact steps in order to attach your credentials and connect the destination spreadsheet.

### Part A: Create the Google Sheet
1. Open [sheets.google.com](https://sheets.google.com) and create a new blank spreadsheet.
2. Rename the spreadsheet to exactly: `RSS Summaries`.
3. In **Row 1**, type these exact five column headers:
   | Column A | Column B | Column C | Column D | Column E |
   | :--- | :--- | :--- | :--- | :--- |
   | **Source** | **Title** | **Link** | **Published** | **Summary** |
4. Ensure the default sheet tab at the bottom is named `Sheet1`.

---

### Part B: Set Up Google Cloud OAuth2
1. Open the [Google Cloud Console](https://console.cloud.google.com/) and create a new project (e.g., `n8n-rss-summarizer`).
2. Navigate to **APIs & Services → Library**:
   - Search for **Google Sheets API** and click **Enable**.
   - Search for **Google Drive API** and click **Enable**.
3. Navigate to **APIs & Services → OAuth consent screen**:
   - Choose User Type: **External** and click **Create**.
   - Fill in the required fields (*App name*, *User support email*, *Developer contact email*).
   - Click **Save and Continue** past Scopes.
   - Under **Test users**, click **+ Add Users** and enter your Google account email address. Click **Save and Continue**.
4. Navigate to **APIs & Services → Credentials**:
   - Click **+ Create Credentials → OAuth client ID**.
   - Application type: **Web application**.
   - Name: `n8n local client` (or any name).
   - Under **Authorized redirect URIs**, add exactly:
     ```text
     http://localhost:5678/rest/oauth2-credential/callback
     ```
   - Click **Create**. Copy your **Client ID** and **Client Secret**.

---

### Part C: Configure Credentials in n8n UI
Open your n8n workspace at [http://localhost:5678](http://localhost:5678).

#### 1. OpenRouter API Credential
1. Go to **Settings → Credentials** (or click the key icon in the left sidebar).
2. Click **Add Credential** and search for **OpenRouter API**.
3. Paste your OpenRouter API key from [openrouter.ai/keys](https://openrouter.ai/keys).
4. Click **Save**.

#### 2. Google Sheets OAuth2 API Credential
1. In **Credentials**, click **Add Credential** and search for **Google Sheets OAuth2 API**.
2. Paste the **Client ID** and **Client Secret** created in Google Cloud.
3. Click **Sign in with Google**.
4. Select your test user Google account and approve the permissions.
   *(If Google displays "Google hasn't verified this app", click "Advanced" and proceed to your app)*.
5. Click **Save**.

---

### Part D: Attach Credentials to the Workflow Nodes
1. Open the imported workflow: **RSS Summarizer**.
2. Double-click the **OpenRouter Chat Model** node:
   - Under **Credential for OpenRouter API**, select the credential you created in Step C.1.
   - Confirm Model is set to `openrouter/free` (or any specific model ID ending in `:free`, e.g., via Expression mode).
3. Double-click the **Google Sheets** node:
   - Under **Credential for Google Sheets OAuth2 API**, select the credential you created in Step C.2.
   - Under **Document**, select **From list** and choose `RSS Summaries`.
   - Under **Sheet**, select `Sheet1`.
   - Confirm the column mappings match:
     - `Source` → `={{ $('Format and Filter').item.json.source }}` (or `"BBC Tech"`)
     - `Title` → `={{ $('Format and Filter').item.json.title }}`
     - `Link` → `={{ $('Format and Filter').item.json.link }}`
     - `Published` → `={{ $('Format and Filter').item.json.pubDate }}`
     - `Summary` → `={{ $json.text }}`
4. Press `Cmd + S` (macOS) or `Ctrl + S` to save the workflow.

---

## 3. How to Run and Verify

1. Click **Execute workflow** (or "Test workflow") at the bottom of the canvas.
2. Watch the execution progress left to right:
   - **When clicking 'Execute workflow'**: Starts the run.
   - **RSS Read**: Fetches articles from BBC News Technology feed.
   - **Limit**: Narrows items to exactly 5.
   - **Basic LLM Chain & OpenRouter Chat Model**: Produces a 2-sentence summary in `$json.text` for each article.
   - **Google Sheets**: Inserts 5 rows into your spreadsheet.
3. **Verification Indicators**:
   - Every node displays a **green checkmark**.
   - Item counts display **5 items** passing through RSS Read, Limit, Basic LLM Chain, and Google Sheets.
   - Open your `RSS Summaries` Google Sheet and confirm **5 new rows** populated with Title, URL Link, Publication Date, and a 2-sentence Summary.

---

## 4. Troubleshooting Guide

Adapted from the exercise guidelines:

| Issue / Symptom | Likely Cause | Solution |
| :--- | :--- | :--- |
| **403 Forbidden / "Credential does not have access"** | The Google Sheets API or Google Drive API is not enabled, or the Google account is not added as a Test User. | In Google Cloud Console, enable both **Google Sheets API** and **Google Drive API**, and verify your email is under **Test Users** on the OAuth consent screen. |
| **Redirect URI mismatch when signing in** | The redirect URI does not match byte-for-byte with what n8n expects. | Ensure Authorized Redirect URI in Google Cloud credentials is typed exactly as: `http://localhost:5678/rest/oauth2-credential/callback` (check protocol `http`, port `5678`, and no trailing slash). |
| **Summary column is empty in Google Sheet** | Incorrect expression mapping on the Google Sheets node. | Basic LLM Chain outputs `{ "text": "..." }`. The Summary column must be mapped to `{{ $json.text }}` (not an RSS field name). |
| **OpenRouter 401 Unauthorized** | The OpenRouter API key is invalid or has leading/trailing whitespaces. | Re-copy the API key from [openrouter.ai/keys](https://openrouter.ai/keys) and update the credential in n8n without whitespace. |
| **OpenRouter 429 Too Many Requests or Model Not Found** | Free tier rate limit reached or model temporarily unavailable. | Wait a minute and re-test. The Basic LLM Chain node has automatic retries configured (`maxTries: 3`, `waitBetweenTries: 2000 ms`). You can also switch the Model field to Expression and select another `:free` model (e.g. `meta-llama/llama-3.3-70b-instruct:free`). |
| **Model name missing from dropdown** | Free models frequently change or might not appear in the static list. | Switch the **Model** selector to **Expression** mode and type the model ID manually (e.g. `openrouter/free`). |

---

## 5. Architectural Notes & Deviations from the PDF

1. **Part 1, Step 3 (Known Gap in PDF)**:
   - The PDF document left the header row specification blank on page 1.
   - The canonical headers were resolved from the column-mapping table in Part 4:
     `Title | Link | Published | Summary`.
2. **Robust Error Handling & Live-Class Settings**:
   - The Basic LLM Chain node settings have been pre-configured with:
     - `retryOnFail: true`
     - `maxTries: 3`
     - `waitBetweenTries: 2000` (ms)
     - `onError: "continueRegularOutput"`
   - This prevents temporary OpenRouter rate-limiting spikes from halting workflow execution.
3. **Optional Scheduled Workflow (`./workflows/rss-summarizer-scheduled.json`)**:
   - Configured with a `Schedule Trigger` (daily at 08:00).
   - Uses `operation: "appendOrUpdate"` on Google Sheets with `matchingColumns: ["Link"]` to prevent duplicate article entries across recurrent runs.
