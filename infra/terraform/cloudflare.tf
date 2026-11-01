# Reads CLOUDFLARE_API_TOKEN from the environment.
provider "cloudflare" {}

# Hyperdrive can validate the database login only after the bootstrap SQL has
# created it. The bootstrap resource runs once after Supabase project creation.
resource "cloudflare_hyperdrive_config" "supabase" {
  account_id = var.cloudflare_account_id
  name       = "pantrynext-supabase"

  origin = {
    scheme   = "postgresql"
    host     = "db.${supabase_project.pantrynext.id}.supabase.co"
    port     = 5432
    database = "postgres"
    user     = "cloudflare_hyperdrive_role"
    password = var.hyperdrive_database_password
  }

  caching = {
    disabled = true
  }

  origin_connection_limit = 5

  depends_on = [terraform_data.database_setup]
}

resource "cloudflare_worker" "pantrynext" {
  account_id = var.cloudflare_account_id
  name       = "pantrynext"

  subdomain = {
    enabled = true
  }
}

resource "cloudflare_secrets_store" "pantrynext" {
  account_id = var.cloudflare_account_id
  name       = "pantrynext"
}

resource "cloudflare_secrets_store_secret" "supabase_service_role" {
  account_id = var.cloudflare_account_id
  store_id   = cloudflare_secrets_store.pantrynext.id
  name       = "SUPABASE_SERVICE_ROLE_KEY"
  scopes     = ["workers"]
  value      = ""

  lifecycle {
    ignore_changes = [value]
  }
}

output "hyperdrive_id" {
  description = "Cloudflare Hyperdrive configuration ID bound to the Worker."
  value       = cloudflare_hyperdrive_config.supabase.id
}

output "worker_name" {
  description = "Cloudflare Worker name."
  value       = cloudflare_worker.pantrynext.name
}

output "secrets_store_id" {
  description = "Cloudflare Secrets Store ID for Worker secrets."
  value       = cloudflare_secrets_store.pantrynext.id
}

output "service_role_secret_id" {
  description = "Cloudflare Secrets Store secret ID for the Supabase service role key."
  value       = cloudflare_secrets_store_secret.supabase_service_role.id
}
