# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

with import <nixpkgs> {};

{
  config ? import <nixpkgs/config> {}
, pkgs ? import <nixpkgs> {}
, ...
}:

let
  # Include applicetions plugin file
  nixtackApps = pkgs.callPackages ./applicationsPlugin.nix {};
in

rec {
  nikpkgs.config.allowBroken = true;

  #imports = [ 
  #  # Include OpenStack options plugin file
  #  ./optionsPlugin.nix
  #];

  openstackclient = nixtackApps.openstackclient;

  keystone = nixtackApps.keystone;

  glance = nixtackApps.glance;

  nova = nixtackApps.nova;

  neutron = nixtackApps.neutron;

  horizon = nixtackApps.horizon;

  ironic = nixtackApps.ironic;

  ##############################
  #   This code's mod options  #
  ##############################
  # Enable horizon
  # (If horizon is enable, there run nginx and uwsgi.)
  #horizon-options = {
  #  enable = true;
  #  memcachedServer = "localhost";
  #  memcachedPort = 11211;
  #  keystoneServer = "localhost";
  #};

  # Enable neutron
  # (If neutron is enable, there are installed some packages on system,
  #  ebtables, bridge-utils, dnsmasq, ipset, conntrack_tools.
  #  And, there is set "networking.firewall.checkReversePath = false".)
  #neutron-options = {
  #  enable = true;
  #  nodeType = "control";
  #};

  # Enable nova
  #nova-options = {
  #  enable = true;
  #  nodeType = "control";
  #};

  # Enable glance
  #glance-options.enable = true;

  # Enable keystone
  # (If keystone is enable, there run nginx and uwsgi.)
  #keystone-options = {
  #  enable = true;
  #  databaseUser = "keystone";
  #  databasePassword = "keystone_password";
  #  databaseName = "keystone";
  #  databaseServer = "localhost";
  #};

  # Enable libvirtd
  #libvirt-options.enable = true;
  #libvirt-options.enableKVM = true;
}
