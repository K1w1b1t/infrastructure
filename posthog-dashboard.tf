resource "posthog_dashboard" "shared_product_health" {
  project_id  = var.posthog_project_id
  name        = "Kiwibit & HirePair — Product health"
  description = "Uso, conversao, abandono do funil e erros dos dois produtos. Filtre cada insight por app e environment antes de tomar decisoes."
  tags        = ["kiwibit", "hirepair", "product-health"]
}

resource "posthog_insight" "shared_event_volume" {
  project_id    = var.posthog_project_id
  dashboard_ids = [posthog_dashboard.shared_product_health.id]
  name          = "Eventos por produto e tipo (30 dias)"
  description   = "Mostra quais areas dos sites recebem uso pelos eventos automaticos e de negocio."
  tags          = ["kiwibit", "hirepair", "usage"]
  query_sql     = <<-SQL
    SELECT properties.app AS app, event, count() AS total
    FROM events
    WHERE timestamp >= now() - INTERVAL 30 DAY
      AND properties.app IN ('kiwibit', 'hirepair')
    GROUP BY app, event
    ORDER BY total DESC
  SQL
}

resource "posthog_insight" "shared_daily_activity" {
  project_id    = var.posthog_project_id
  dashboard_ids = [posthog_dashboard.shared_product_health.id]
  name          = "Atividade diaria por produto (30 dias)"
  description   = "Detecta mudancas de uso e regressao de trafego em Kiwibit e HirePair."
  tags          = ["kiwibit", "hirepair", "usage"]
  query_sql     = <<-SQL
    SELECT toDate(timestamp) AS day, properties.app AS app, count() AS total
    FROM events
    WHERE timestamp >= now() - INTERVAL 30 DAY
      AND properties.app IN ('kiwibit', 'hirepair')
    GROUP BY day, app
    ORDER BY day ASC, app ASC
  SQL
}

resource "posthog_insight" "hirepair_funnel_progress" {
  project_id    = var.posthog_project_id
  dashboard_ids = [posthog_dashboard.shared_product_health.id]
  name          = "HirePair — progresso do funil (30 dias)"
  description   = "Evidencia em qual etapa os usuarios deixam o fluxo; os eventos compartilham funnel_session_id."
  tags          = ["hirepair", "funnel", "drop-off"]
  query_sql     = <<-SQL
    SELECT event, count() AS total
    FROM events
    WHERE timestamp >= now() - INTERVAL 30 DAY
      AND properties.app = 'hirepair'
      AND event IN ('session_started', 'facts_confirmed', 'resume_generated', 'whatsapp_shared')
    GROUP BY event
    ORDER BY total DESC
  SQL
}

resource "posthog_insight" "kiwibit_business_outcomes" {
  project_id    = var.posthog_project_id
  dashboard_ids = [posthog_dashboard.shared_product_health.id]
  name          = "Kiwibit — resultados de negocio (30 dias)"
  description   = "Acompanha conclusoes reais de login, criacao de post e contato, sem PII."
  tags          = ["kiwibit", "conversion"]
  query_sql     = <<-SQL
    SELECT event, count() AS total
    FROM events
    WHERE timestamp >= now() - INTERVAL 30 DAY
      AND properties.app = 'kiwibit'
      AND event IN ('user_logged_in', 'post_created', 'contact_form_submitted')
    GROUP BY event
    ORDER BY total DESC
  SQL
}

resource "posthog_insight" "shared_browser_exceptions" {
  project_id    = var.posthog_project_id
  dashboard_ids = [posthog_dashboard.shared_product_health.id]
  name          = "Excecoes do navegador por produto (30 dias)"
  description   = "Monitora $exception para priorizar erros que afetam usuarios consentidos."
  tags          = ["kiwibit", "hirepair", "errors"]
  query_sql     = <<-SQL
    SELECT properties.app AS app, count() AS total
    FROM events
    WHERE timestamp >= now() - INTERVAL 30 DAY
      AND event = '$exception'
      AND properties.app IN ('kiwibit', 'hirepair')
    GROUP BY app
    ORDER BY total DESC
  SQL
}
