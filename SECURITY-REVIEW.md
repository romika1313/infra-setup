# Security Review — acct-exp-hub

Reviewed against: `Omega-Healthcare-Investors-Inc/acct-exp-hub` `main` branch  
Date: 2026-08-17  
Reviewed by: Infrastructure team

---

## Summary

| # | File(s) | Issue | Priority |
|---|---|---|---|
| 1 | `lib/storage.ts`, `verify-storage.mjs`, `seed-with-receipts.mjs` | Azure Blob Storage uses AccountKey (shared key) instead of Managed Identity | 🔴 High |
| 2 | `lib/duplicate-judge.ts` | Azure OpenAI uses static API key as primary auth | 🔴 High |
| 3 | `lib/ocr-document-intelligence.ts` | Document Intelligence uses static API key | 🔴 High |
| 4 | `lib/maps.ts` | Azure Maps uses Shared Key auth | 🔴 High |
| 5 | `lib/directory.ts` | Microsoft Graph directory search uses client secret (client credentials flow) | 🟡 Medium |
| 6 | `app/api/dev/users/route.ts` | Dev endpoint exposes all users — not blocked in production | 🟡 Medium |
| 7 | CI build workflow | `NEXT_PUBLIC_ALLOW_MOCK_AUTH=false` not enforced in TEST/PROD builds | 🟡 Medium |
| 8 | Power Automate | Email-ingest flow HTTP action URL hardcoded, not reading env variable | 🟡 Medium |

---

## 🔴 HIGH — Must fix before production

### 1. Azure Blob Storage uses AccountKey, not Managed Identity

**Files:** `lib/storage.ts`, `scripts/verify-storage.mjs`, `scripts/seed-with-receipts.mjs`

The `isBlobEnabled()` function explicitly checks for `AccountKey=` in `AZURE_STORAGE_CONNECTION_STRING`. The app cannot connect to blob storage without a shared key — Managed Identity is structurally unsupported.

**Current pattern:**
```typescript
BlobServiceClient.fromConnectionString(process.env.AZURE_STORAGE_CONNECTION_STRING!)
```

**Required change:** Replace with `DefaultAzureCredential`. The App Service already has `Storage Blob Data Contributor` role assigned via the infra pipeline.

```typescript
import { DefaultAzureCredential } from "@azure/identity";
import { BlobServiceClient } from "@azure/storage-blob";

const credential = new DefaultAzureCredential();
const svc = new BlobServiceClient(
  `https://${process.env.AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
  credential
);
```

- Remove: `AZURE_STORAGE_CONNECTION_STRING` env var and all `AccountKey=` checks
- Add: `AZURE_STORAGE_ACCOUNT_NAME` env var (not a secret — just the account name)
- Update `isBlobEnabled()` to check for `AZURE_STORAGE_ACCOUNT_NAME` instead
- Update `scripts/verify-storage.mjs` and `scripts/seed-with-receipts.mjs` to match

---

### 2. Azure OpenAI uses a static API key as primary auth

**File:** `lib/duplicate-judge.ts`

The `authHeaders()` function prefers a static API key if `AZURE_OPENAI_API_KEY` is set. The OAuth fallback exists but client credentials (with a secret) are used instead of Managed Identity.

**Current pattern:**
```typescript
async function authHeaders() {
  const apiKey = process.env.AZURE_OPENAI_API_KEY;
  if (apiKey) return { "api-key": apiKey };           // static key wins
  const token = await getOAuthToken();                 // OAuth only as fallback
  return token ? { Authorization: `Bearer ${token}` } : null;
}
```

**Required change:** Replace both branches with `DefaultAzureCredential`.

```typescript
import { DefaultAzureCredential } from "@azure/identity";

async function authHeaders() {
  const credential = new DefaultAzureCredential();
  const token = await credential.getToken("https://cognitiveservices.azure.com/.default");
  return token ? { Authorization: `Bearer ${token.token}` } : null;
}
```

- Remove: `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_OAUTH_TOKEN_URL`, `AZURE_OPENAI_OAUTH_CLIENT_ID`, `AZURE_OPENAI_OAUTH_CLIENT_SECRET`, `AZURE_OPENAI_OAUTH_SCOPE` env vars
- The App Service managed identity needs **Cognitive Services OpenAI User** role on the OpenAI resource (add to `bicep/modules/rbac.bicep`)

---

### 3. Document Intelligence uses a static API key

**File:** `lib/ocr-document-intelligence.ts`

Uses `DOCUMENT_INTELLIGENCE_KEY` for authentication.

**Required change:**

```typescript
import { DefaultAzureCredential } from "@azure/identity";
import { DocumentAnalysisClient } from "@azure/ai-form-recognizer";

const client = new DocumentAnalysisClient(
  process.env.DOCUMENT_INTELLIGENCE_ENDPOINT!,
  new DefaultAzureCredential()
);
```

- Remove: `DOCUMENT_INTELLIGENCE_KEY` env var
- The App Service managed identity needs **Cognitive Services User** role on the Document Intelligence resource (add to `bicep/modules/rbac.bicep`)

---

### 4. Azure Maps uses Shared Key auth

**File:** `lib/maps.ts`

Uses `AZURE_MAPS_KEY` (the account's primary shared key) for all geocode and routing API calls.

**Required change:** Azure Maps supports Azure AD / Managed Identity authentication. Replace key-based calls with `DefaultAzureCredential` and the Maps SDK, or pass a Bearer token in the request headers.

```typescript
import { DefaultAzureCredential } from "@azure/identity";

const credential = new DefaultAzureCredential();
const token = await credential.getToken("https://atlas.microsoft.com/.default");
// Pass as: Authorization: `Bearer ${token.token}`
```

- Remove: `AZURE_MAPS_KEY` env var
- The App Service managed identity needs **Azure Maps Data Reader** role on the Maps account (add to `bicep/modules/rbac.bicep`)

---

## 🟡 MEDIUM — Must fix before go-live

### 5. Microsoft Graph directory search uses client secret

**File:** `lib/directory.ts`

The `getGraphToken()` function fetches a Graph token using `AZURE_AD_CLIENT_ID` + `AZURE_AD_CLIENT_SECRET` (client credentials flow). This reuses the same registration as user sign-in, meaning the client secret is doing double duty.

> **Note:** `AZURE_AD_CLIENT_SECRET` is still required for NextAuth's user-facing OAuth flow (`lib/auth.ts`) — that cannot be replaced with Managed Identity. Only the Graph directory calls can be migrated.

**Required change:** Use `DefaultAzureCredential` for Graph token acquisition instead of client credentials.

```typescript
import { DefaultAzureCredential } from "@azure/identity";

async function getGraphToken(): Promise<string | null> {
  const credential = new DefaultAzureCredential();
  const token = await credential.getToken("https://graph.microsoft.com/.default");
  return token?.token ?? null;
}
```

- The App Service managed identity needs the **User.Read.All** application permission granted on Microsoft Graph (admin consent required)

---

### 6. `/api/dev/users` endpoint exposes all users in production

**File:** `app/api/dev/users/route.ts`

This endpoint is used by the mock login page to list all users. It is not blocked in production — any request to this URL in a production deployment would return the full user list.

**Required change:** Add a hard block at the top of the route:

```typescript
if (process.env.NODE_ENV === "production") {
  return NextResponse.json({ error: "Not found" }, { status: 404 });
}
```

---

### 7. `NEXT_PUBLIC_ALLOW_MOCK_AUTH` not enforced as `false` in TEST/PROD builds

**File:** `.github/workflows/azure-app-service.yml` (build step)

This flag is compiled into the Next.js bundle at build time. If it is `true` in the bundle, the mock login button renders in the UI and anyone can sign in as any user by calling `/api/dev/users` — bypassing Entra ID completely.

**Required change:** The CI build step for TEST and PROD must explicitly set this to `false`:

```yaml
- name: Build
  env:
    NEXT_PUBLIC_ALLOW_MOCK_AUTH: "false"
  run: npm run build
```

This is a build-time change — setting `ALLOW_MOCK_AUTH=false` in App Service settings is not sufficient.

---

### 8. Email-ingest Power Automate flow URL is hardcoded

**Location:** Power Automate — email-ingest flow HTTP action `uri`

The `PROD-READINESS.md` notes: *"A `Receipts Ingest Url` environment variable already exists but the flow does not reference it."* The Daily Digest flow was already fixed to read from an environment variable; the email-ingest flow was not.

**Required change:** Edit the email-ingest flow's HTTP action to read `uri` from the `Receipts Ingest Url` Power Platform environment variable, matching the pattern used in the Daily Digest flow.

---

## ✅ Already correct — no changes needed

| Pattern | Status |
|---|---|
| `NEXTAUTH_SECRET` — startup refuses to boot if missing or placeholder | ✅ |
| `INGEST_SHARED_SECRET` — rate-limited, comma-separated list for zero-downtime rotation | ✅ |
| Receipt upload — oversized body rejected before buffering | ✅ |
| Receipt serving — `nosniff` / CSP / Content-Disposition headers, PDFs force-download | ✅ |
| SQL — no hardcoded credentials, reads `DATABASE_URL` from env | ✅ |
| Mock auth — red warning banner visible in UI when enabled | ✅ |
| Receipt ingest — shared secret checked before processing, brute-force rate-limited | ✅ |

---

## Infrastructure changes required (in `infra-setup` repo)

When the developer completes items 1–4, the following RBAC role assignments must be added to `bicep/modules/rbac.bicep` so the App Service managed identity has the permissions to replace the removed keys:

| Azure resource | Role to assign |
|---|---|
| Storage account | `Storage Blob Data Contributor` ← already assigned |
| OpenAI account | `Cognitive Services OpenAI User` ← needs to be added |
| Document Intelligence account | `Cognitive Services User` ← needs to be added |
| Azure Maps account | `Azure Maps Data Reader` ← needs to be added |
| Microsoft Graph (via Entra admin consent) | `User.Read.All` application permission ← separate step |
