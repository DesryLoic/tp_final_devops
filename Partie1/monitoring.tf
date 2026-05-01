resource "virtualbox_vm" "monitor_node" {
  depends_on = [virtualbox_vm.debian_node]
  count     = 1
  name      = "vm_final_monitoring"
  image     = "https://vagrantcloud.com/generic/boxes/debian11/versions/4.3.12/providers/virtualbox.box"
  cpus      = 1
  memory    = "1024 mib"

  network_adapter {
    type           = "bridged"
    host_interface = var.network_host_if
  }
}

output "monitor_ip" {
  value = virtualbox_vm.monitor_node[0].network_adapter[0].ipv4_address
}
