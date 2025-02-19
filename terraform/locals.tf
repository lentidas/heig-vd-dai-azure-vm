locals {
  resource_tags = merge({
    course = "HEIG-VD-DAI"
    app    = var.app_name
  }, var.extra_resource_tags)
}
