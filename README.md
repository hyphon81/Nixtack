# nixosGPUPassthroughOpenStack
This code for construction GPUPassthrough and OpenStack environment on NixOS.

This code assumes environments refer from "OpenStack Installation Tutorial for Ubuntu".
(http://docs.openstack.org/newton/install-guide-ubuntu/index.html)


## OpenStack Newton
- keystone-10.0.0
- nova-14.0.3
- neutron-9.1.1
- glance-13.0.0
- horizon-10.0.1

## Settings for CUDA with OpenStack

### Image metadata

hw_firmware_type uefi  
hw_machine_type pc-q35-2.5

### /etc/nova/nova.conf

pci_passthrough_whitelist=[{ "vendor_id":"10de", "product_id":"XXXX"}, { "vendor_id":"10de", "product_id":"YYYY"}, ... ]

pci_alias={"vendor_id":"10de", "product_id":"XXXX", "name":"Device1"}  
pci_alias={"vendor_id":"10de", "product_id":"YYYY", "name":"Device2"}  
...

### Flavor metadata

pci_passthrough:alias \<Device1 name\>:\<Device1 count\>,\<Device2 name\>:\<Device2 count\>, ...