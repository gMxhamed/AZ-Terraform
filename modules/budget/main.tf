resource "azurerm_monitor_action_group" "rg-act" {
  name                = "rgact"
  resource_group_name = var.resource_group_name
  short_name          = "rga"
}

resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "rg-budget"
  resource_group_id = var.rg-id
  amount     = 10
  time_grain = "Monthly"

  time_period {
    start_date = "2024-05-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        azurerm_monitor_action_group.rg-act.id,
      ]
    }

  }

  notification {
    enabled        = true
    threshold      = 90.0
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"

    contact_emails = ["put.ur.mail.here@gmail.com"]

    contact_groups = [
      azurerm_monitor_action_group.rg-act.id,
    ]

    contact_roles = [
      "Owner",
    ]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = ["mohammed.guendouz@ynov.com"]
  }
}