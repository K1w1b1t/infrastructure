locals {
  posthog_app_urls = jsondecode(jsondecode(var.posthog_app_urls))
}


resource "posthog_project_settings" "shared_telemetry" {
  project_id = var.posthog_project_id

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
  value       = var.posthog_project_id
}
