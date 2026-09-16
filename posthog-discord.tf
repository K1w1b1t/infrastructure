# Destination declarativa do template oficial Discord. O valor do webhook é
# sensível no Stack e nunca é publicado como output ou variável de runtime.
resource "posthog_hog_function" "production_operational_alerts" {
  project_id  = var.posthog_project_id
  template_id = "template-discord"
  name        = "Production operational alerts"
  description = "Exceções e fallbacks de IA de produção, sem PII."
  enabled     = true

  sensitive_inputs_json = jsonencode({
    webhookUrl = { value = var.posthog_discord_webhook_url }
  })

  inputs_json = jsonencode({
    content = {
      value = "PostHog produção: {event.event} · app={event.properties.app} · erro={event.properties.name}"
    }
    allowedMentions = { value = "none" }
  })

  # Uma destination para os dois sinais operacionais. As propriedades de
  # evento garantem que staging e qualquer evento sem ambiente não alertem.
  filters_json = jsonencode({
    events = [
      {
        id         = "$exception"
        name       = "$exception"
        type       = "events"
        order      = 0
        properties = [{ key = "environment", value = "production", operator = "exact", type = "event" }]
      },
      {
        id         = "ai_fallback_triggered"
        name       = "ai_fallback_triggered"
        type       = "events"
        order      = 1
        properties = [{ key = "environment", value = "production", operator = "exact", type = "event" }]
      }
    ]
  })
}
