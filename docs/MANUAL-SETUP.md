# Manual Setup

Complete these steps before running the automated GitHub Actions workflows.

## 1. Cloudflare account

Create or select the Cloudflare account that will own the R2 state bucket, Hyperdrive configuration, and Worker. Record its account ID.

Add this GitHub environment variable:

- `CLOUDFLARE_ACCOUNT_ID`

## 2. Cloudflare R2 Terraform backend

Create a private R2 bucket for Terraform state. Create S3-compatible credentials with access to that bucket.

Add these secrets to the GitHub Actions environment named `terraform`:

- `CLOUDFLARE_R2_ACCESS_KEY_ID`
- `CLOUDFLARE_R2_SECRET_ACCESS_KEY`

Add these variables to the same environment:

- `CLOUDFLARE_R2_BUCKET`
- `CLOUDFLARE_R2_ENDPOINT`

The endpoint must be the R2 S3 API endpoint for the Cloudflare account.

## 3. Cloudflare API token

Create a Cloudflare API token for the account. It must be able to manage the Cloudflare resources used by this repository:

- Hyperdrive configurations
- Workers and Worker versions/deployments
- Secrets Store secret updates and Worker bindings (`Account Secrets Store: Edit`)

Add it as this GitHub environment secret:

- `CLOUDFLARE_API_TOKEN`

## 4. Cloudflare Secrets Store

Create the Secrets Store and service-role secret manually in the Cloudflare account. Terraform does not create these resources because Cloudflare rejected the Terraform create request with `maximum_stores_exceeded`, even though no store was visible in the account dashboard.

Create one Secrets Store, then create a secret with:

- Name: `SUPABASE_SERVICE_ROLE_KEY`
- Scope: `workers`
- Initial value: `TEMP`

Record the store ID and add it as a variable in the GitHub Actions environment named `terraform`:

- `CLOUDFLARE_SECRETS_STORE_ID`

The deployment workflow discovers the secret ID by finding `SUPABASE_SERVICE_ROLE_KEY` in that store through the Cloudflare API. The initial `TEMP` value only allows the secret to be created. Every `01-worker-deploy` run retrieves the current Supabase service-role key through the Supabase Management API and replaces the value before deploying the Worker.

## 5. Supabase organization and project settings

Create or select the Supabase organization that will own the project.

Add these GitHub environment variables:

- `SUPABASE_ORG_ID`
- `SUPABASE_PROJECT_NAME`
- `SUPABASE_REGION`

## 6. Supabase access and database passwords

Create a Supabase personal access token with access for the Supabase Terraform provider and CLI. Add it as:

- `SUPABASE_ACCESS_TOKEN`

`01-worker-deploy` retrieves the current Supabase service role key through the Supabase Management API using `SUPABASE_ACCESS_TOKEN` and refreshes the Cloudflare Secrets Store secret; no separate project-specific service-role secret is required.

Choose the initial Platform Owner credentials and add them as:

- `PLATFORM_OWNER_EMAIL` (environment variable)
- `PLATFORM_OWNER_PASSWORD` (environment secret)

The Terraform bootstrap creates or locates this Auth user and promotes its generated UUID to `platform_owner` in `app.platform_admins`. The key and password are not stored in the repository or exposed to the Worker.

Choose a strong administrator password for the Supabase project and add it as:

- `SUPABASE_DB_PASSWORD`

Generate a separate strong password for the Hyperdrive database role, for example:

```bash
openssl rand -hex 32
```

Add the result as:

- `HYPERDRIVE_DB_PASSWORD`

`SUPABASE_DB_PASSWORD` creates the Supabase project. `HYPERDRIVE_DB_PASSWORD` is applied by the setup SQL to `cloudflare_hyperdrive_role` and supplied to Hyperdrive.

## 7. GitHub Actions environment

Create a GitHub Actions environment named `terraform`. Add all secrets and variables listed above to that environment.

Ensure the default branch contains:

- `.github/workflows/00-terraform-apply.yml`
- `.github/workflows/01-worker-deploy.yml`
- `infra/terraform/`
- `supabase/setup/`
- `apps/worker/`

After these prerequisites are configured, run `00-terraform-apply` to provision the initial infrastructure. Later application deployments use `01-worker-deploy`.
