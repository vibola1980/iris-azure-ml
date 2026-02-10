# ============================================
# Azure Monitoring Module
# Log Analytics, Application Insights, Alerts
# ============================================

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = substr(var.project_name, 0, 12)

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  tags = var.tags
}

# Alert: High CPU usage
resource "azurerm_monitor_metric_alert" "high_cpu" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-high-cpu-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = var.aks_cluster_id != null ? [var.aks_cluster_id] : []
  description         = "Alert when CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Alert: High Memory usage
resource "azurerm_monitor_metric_alert" "high_memory" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-high-memory-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = var.aks_cluster_id != null ? [var.aks_cluster_id] : []
  description         = "Alert when memory usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.memory_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Alert: Pod restart count
resource "azurerm_monitor_metric_alert" "pod_restarts" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-pod-restarts-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = var.aks_cluster_id != null ? [var.aks_cluster_id] : []
  description         = "Alert when pods are restarting frequently"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Insights.Container/pods"
    metric_name      = "restartingContainerCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.pod_restart_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}
