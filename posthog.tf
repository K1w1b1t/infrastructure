locals {
  posthog_app_urls = jsondecode(var.posthog_app_urls)
}

# Projeto PostHog único para hirepair_web e kiwibit_web.
# Importe este endereço no mesmo OCI Resource Manager Stack se o projeto já existir.
resource "posthog_project" "shared_telemetry" {
  name     = var.posthog_project_name
  timezone = "America/Sao_Paulo"
}

resource "posthog_project_settings" "shared_telemetry" {
  project_id = posthog_project.shared_telemetry.id

  app_urls          = local.posthog_app_urls
  recording_domains = local.posthog_app_urls

  autocapture_exceptions_opt_in = true
  autocapture_web_vitals_opt_in = true
  session_recording_opt_in      = true
  heatmaps_opt_in               = false

  # Replay não captura payloads de rede; SDKs também mascaram texto e inputs.
  capture_performance_opt_in = false
  session_recording_network_payload_capture_config = {
    record_headers = false
    record_body    = false
  }
}

output "posthog_project_id" {
  description = "ID do projeto compartilhado para POSTHOG_PROJECT_ID nos builds Vercel de source maps."
  value       = posthog_project.shared_telemetry.id
}

output "posthog_project_api_key" {
  description = "Project API Key para SDKs; cadastre somente como variável Vercel."
  value       = posthog_project.shared_telemetry.api_token
  sensitive   = true

}
