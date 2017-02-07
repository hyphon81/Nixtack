{ lib
, pkgs
, callPackage
, darwin
, gnome2
, gnome3
, spice_gtk
, ... }:

{
  # Applications build definition files

  libvirt_25 = callPackage ./libvirt/libvirt.nix {};

  qemu_25 = callPackage ./qemu/qemu_25.nix {
    inherit (darwin.apple_sdk.frameworks) CoreServices Cocoa;
    inherit (darwin.stubs) rez setfile;
  };

  virtmanager = callPackage ./virt-manager/virt-manager.nix {
    inherit (gnome2) gnome_python;
    vte = gnome3.vte;
    dconf = gnome3.dconf;
    spice_gtk = spice_gtk;
    system-libvirt = callPackage ./libvirt/libvirt.nix {};
  };

  openstackclient = callPackage ./openstack/openstackclient.nix {};

  keystone = callPackage ./openstack/keystone/keystone.nix {};

  glance = callPackage ./openstack/glance/glance.nix {};

  nova = callPackage ./openstack/nova/nova.nix {};

  neutron = callPackage ./openstack/neutron/neutron.nix {};

  horizon = callPackage ./openstack/horizon/horizon.nix {};
}
