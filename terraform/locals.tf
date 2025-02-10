locals {
  app_name               = "heig-vd-dai-vm"
  public_ip_label_prefix = "lentidas"

  default_tags = {
    app        = local.app_name
    project    = "HEIG-VD-DAI-VM"
    repository = "https://github.com/lentidas/"
  }
}
