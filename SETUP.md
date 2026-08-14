# Infrastructure Setup & Migration Guide

## GitHub & Azure IDs (romika1313 / infra-setup)

| Thing | ID |
|---|---|
| GitHub user ID (romika1313) | `279083698` |
| GitHub repo ID (infra-setup) | `1333983013` |
| Azure subscription | `5afac646-8a2a-4662-90df-0d34a9775af8` |
| Azure tenant (omegahealthcare.com) | *(from Entra ID → Overview)* |

---

## Resource Groups (already created)

| Name | Location | Status |
|---|---|---|
| `rgrp-expense-dev-eus2` | eastus2 | ✅ Created |
| `rgrp-expense-test-eus2` | eastus2 | ✅ Created |
| `rgrp-expense-prod-eus2` | eastus2 | ✅ Created |

---

## App Registrations & Federated Credentials

### DEV — `expense-hub-infra-dev`

| Step | Action | Status |
|---|---|---|
| Create app registration | Single tenant, no redirect URI | ✅ Done |
| Add federated credential | Org: `romika1313` · Org ID: `279083698` · Repo: `infra-setup` · Repo ID: `1333983013` · Entity: Environment · Name: `dev` | ✅ Done |
| Save client ID | Paste into GitHub → dev environment secret `AZURE_CLIENT_ID` | ⬜ |
| Assign Owner on RG | `rgrp-expense-dev-eus2` → IAM → Owner → `expense-hub-infra-dev` | ⬜ |

### TEST — `expense-hub-infra-test`

| Step | Action | Status |
|---|---|---|
| Create app registration | Single tenant, no redirect URI | ⬜ |
| Add federated credential | Org: `romika1313` · Org ID: `279083698` · Repo: `infra-setup` · Repo ID: `1333983013` · Entity: Environment · Name: `test` | ⬜ |
| Save client ID | Paste into GitHub → test environment secret `AZURE_CLIENT_ID` | ⬜ |
| Assign Owner on RG | `rgrp-expense-test-eus2` → IAM → Owner → `expense-hub-infra-test` | ⬜ |

### PROD — `expense-hub-infra-prod`

| Step | Action | Status |
|---|---|---|
| Create app registration | Single tenant, no redirect URI | ⬜ |
| Add federated credential | Org: `romika1313` · Org ID: `279083698` · Repo: `infra-setup` · Repo ID: `1333983013` · Entity: Environment · Name: `prod` | ⬜ |
| Save client ID | Paste into GitHub → prod environment secret `AZURE_CLIENT_ID` | ⬜ |
| Assign Owner on RG | `rgrp-expense-prod-eus2` → IAM → Owner → `expense-hub-infra-prod` | ⬜ |

---

## GitHub Secrets

### Repo-level secrets (Settings → Secrets → Actions)
Same value for all environments — set once.

| Secret | Value | Status |
|---|---|---|
| `AZURE_TENANT_ID` | Directory (tenant) ID from Entra ID → Overview | ⬜ |
| `AZURE_SUBSCRIPTION_ID` | `5afac646-8a2a-4662-90df-0d34a9775af8` | ⬜ |

### Environment-level secrets (Settings → Environments → [env] → Add secret)

| Environment | Secret | Value | Status |
|---|---|---|---|
| dev | `AZURE_CLIENT_ID` | Client ID of `expense-hub-infra-dev` | ⬜ |
| dev | `SQL_ADMIN_PASSWORD` | `openssl rand -base64 18` | ⬜ |
| test | `AZURE_CLIENT_ID` | Client ID of `expense-hub-infra-test` | ⬜ |
| test | `SQL_ADMIN_PASSWORD` | Different value | ⬜ |
| prod | `AZURE_CLIENT_ID` | Client ID of `expense-hub-infra-prod` | ⬜ |
| prod | `SQL_ADMIN_PASSWORD` | Different value | ⬜ |

---

## First Pipeline Run

Push any change to `bicep/` → pipeline triggers automatically:
```
validate → deploy DEV → deploy TEST → (approval required) → deploy PROD
```

---

## After Each Environment Deploys — Manual Key Vault Secrets

Add these to `kv-expense-{env}-eus2` in Azure Portal before the app can start.
The pipeline auto-populates the Azure service keys; these must be set by hand.

| Secret name | How to generate | Status |
|---|---|---|
| `nextauth-secret` | `openssl rand -base64 32` | ⬜ |
| `azure-ad-client-secret` | From the Entra app registration for the expense app (not the infra registrations) | ⬜ |
| `ingest-shared-secret` | Any random value — authenticates Power Automate → app webhook calls | ⬜ |
| `digest-shared-secret` | Any random value | ⬜ |

---

## Migrating to a Different GitHub Account/Repo

When moving to the client's GitHub org:

1. **Update each federated credential** — on each app registration → Certificates & secrets → Federated credentials → edit → change Org and Repo to the new values
2. **Re-add GitHub secrets** — in the new repo, add all the same secrets listed above
3. **Push the code** to the new repo — no Bicep changes required
4. **Delete the old federated credentials** after confirming the new repo works

The Bicep modules and resource group names do not change.
