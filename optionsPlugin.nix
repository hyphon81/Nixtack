{ config
, pkgs
, ... }:

{
  imports = [
    # Options definition files
    ./libvirt/libvirt-options.nix
    ./uwsgi/uwsgi-options.nix
    ./openstack/keystone/keystone-options.nix
    ./openstack/glance/glance-options.nix
    ./openstack/nova/nova-options.nix
    ./openstack/neutron/neutron-options.nix
    ./openstack/horizon/horizon-options.nix
  ];
}
