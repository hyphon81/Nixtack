# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # Include applicetions plugin file
  #nixtackApps = pkgs.callPackages /path/to/applicationsPlugin.nix {};
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Include OpenStack options plugin file
      /path/to/optionsPlugin.nix
    ];

  nixpkgs.config.allowUnfree = true;
  #nixpkgs.config.allowBroken = true;

  ##############################
  # Settings for system on ZFS #
  ##############################

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "8425e349";
  #
  ##############################

  ################################
  # Settings for GPU Passthrough #
  ################################

  # Set Video Driver
  services.xserver.videoDrivers = [ "nvidia" "intel" ];

  boot.kernelModules = [
    "vfio"
    "vfio_pci"
    "vfio_iommu_type1"
    "nvidia"
    "nvidia_drm"
  ];

  boot.blacklistedKernelModules = [ "radeon" "nouveau" "fglrx" ];

  boot.kernelParams = [
    "intel_iommu=on"
    "vfio_iommu_type1.allow_unsafe_interrupts=1"
    "kvm.allow_unsafe_assigned_interrupts=1"
    "kvm.ignore_msrs=1"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:1380,10de:0fbc,10de:128b,10de:0e0f,10de:104a,10de:0e08
    options igb max_vfs=4
  '';
  #
  ################################

  ###########################
  # Settings for networking #
  ###########################

  networking.hostName = "nixos-Nixtack"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.defaultGateway = "192.168.0.1"; # Example of the default gateway
  networking.interfaces.eth0 = {
    ip4 = [
      # Example of the fixed ip address
      { address = "192.168.0.10"; prefixLength = 24; } 
    ];
    # Example of the device's mtu setting
    mtu = 1450;
  };
  # Example of the name servers setting
  networking.extraResolvconfConf = ''
    name_servers=8.8.8.8
    name_servers_append=8.8.4.4
  '';

  networking.firewall.logRefusedConnections = true;
  networking.firewall.logRefusedPackets = true;
  networking.firewall.logRefusedUnicastsOnly = true;
  networking.firewall.logReversePathDrops = true;
  networking.firewall.allowedTCPPorts = [
    5672  # RabbitMQ's port
    15672 # RabbitMQ web UI's port
    11211 # Memcached's port
  ];
  #
  ###########################

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    ######################
    #  nixpkgs packages  #
    ######################
    #pciutils
    #gnumake
    #gcc
    #cudatoolkit

    ##############################
    #  This code's mod packages  #
    ##############################
    #nixtackApps.libvirt_25
    #nixtackApps.qemu_25
    #nixtackApps.virtmanager
    #nixtackApps.openstackclient
    #############################
  ];

  ##############################
  #   This code's mod options  #
  ##############################
  # Enable horizon
  # (If horizon is enable, there run nginx and uwsgi.)
  horizon-options = {
    enable = true;
    memcachedServer = "localhost";
    memcachedPort = 11211;
    keystoneServer = "localhost";
  };

  # Enable neutron
  # (If neutron is enable, there are installed some packages on system,
  #  ebtables, bridge-utils, dnsmasq, ipset, conntrack_tools.
  #  And, there is set "networking.firewall.checkReversePath = false".)
  neutron-options = {
    enable = true;
    nodeType = "control";
  };

  # Enable nova
  nova-options = {
    enable = true;
    nodeType = "control";
    extraConfig = ''
      # Set keymap
      vnc_keymap = ja
      # PCI passthrough whitelist
      pci_passthrough_whitelist=[{ "vendor_id":"10de", "product_id":"1380"}, { "vendor_id":"10de", "product_id":"0fbc"}]
      # PCI alias
      pci_alias={"vendor_id":"10de", "product_id":"1380", "name":"GTX750Ti"}
      pci_alias={"vendor_id":"10de", "product_id":"0fbc", "name":"GTX750Ti-sound"}
    '';
    rabbitMQUser = "openstack";
    rabbitMQPassword = "openstack_password";
    rabbitMQServer = "localhost";
    myIp = "192.168.0.10";
    projectDomainName = "Default";
    userDomainName = "Default";
    projectName = "service";
    serviceUser = "nova";
    servicePassword = "nova";
    regionType = "RegionOne";
    neutronProjectName = "service";
    neutronServiceUser = "neutron";
    neutronServicePassword = "neutron_password";
    databaseUser = "nova";
    databasePassword = "nova_db_password";
    novaDatabaseName = "nova";
    novaApiDatabaseName = "nova_api";
    databaseServer = "localhost";
    keystoneServer = "localhost";
    glanceServer = "localhost";
    neutronServer = "localhost";
    memcachedServer = "localhost";
    sharedSecret = "SHAREDSECRET";
    vncFrontend = "localhost";
  };

  # Enable glance
  glance-options = {
    enable = true;
    projectDomainName = "Default";
    userDomainName = "Default";
    projectName = "service";
    serviceUser = "glance";
    servicePassword = "glance_password";
    databaseUser = "glance";
    databasePassword = "glance_db_password";
    databaseName = "glance";
    databaseServer = "localhost";
  };

  # Enable keystone
  # (If keystone is enable, there run nginx and uwsgi.)
  keystone-options = {
    enable = true;
    databaseUser = "keystone";
    databasePassword = "keystone_db_password";
    databaseName = "keystone";
    databaseServer = "localhost";
  };

  # Enable libvirtd
  libvirt-options.enable = true;
  libvirt-options.enableKVM = true;

  # The user use libvirtd needs extraGroups "libvirtd".
  #users.extraUsers.hyphon81 = {
  #  isNormalUser = true;
  #  createHome = true;
  #  uid = 1000;
  #  extraGroups = [ "wheel" "libvirtd" ];
  #};

  ##############################

#############################################################
# Please setting under options for this codes applications  #
#############################################################
  
  ################################################
  # This code's application needs those settings #
  ################################################
  # Enable mariadb
  # (This code's assume the system using database server like MariaDB.
  #  So, please set those options.)
  services.mysql.package = pkgs.mariadb;
  services.mysql.enable = true;
  services.mysql.extraOptions = ''
    default-storage-engine = innodb
    innodb_file_per_table
    max_connections = 4096
    collation-server = utf8_general_ci
    character-set-server=utf8
  '';

  # Create initial databases
  services.mysql.initialDatabases = [
    # Create keystone database
    # (If database server is localhost, then it will be run.)
    {
      name = "${keystone-options.databaseName}";
      schema = writeText "keystone.sql" ''
        GRANT ALL PRIVILEGES ON ${keystone-options.databaseName}.* TO '${keystone-options.databaseUser}'@'localhost' IDENTIFIED BY '${keystone-options.databasePassword}'
        GRANT ALL PRIVILEGES ON ${keystone-options.databaseName}.* TO '${keystone-options.databaseUser}'@'localhost' IDENTIFIED BY '${keystone-options.databasePassword}'
      '';
    }

    # Create glance database
    # (If database server is localhost, then it will be run.)
    {
      name = "${glance-options.databaseName}";
      schema = writeText "glance.sql" ''
        GRANT ALL PRIVILEGES ON ${glance-options.databaseName}.* TO '${glance-options.databaseUser}'@'localhost' IDENTIFIED BY '${glance-options.databasePassword}'
        GRANT ALL PRIVILEGES ON ${glance-options.databaseName}.* TO '${glance-options.databaseUser}'@'localhost' IDENTIFIED BY '${glance-options.databasePassword}'
      '';
    }
  ];

  # Enable rabbitmq
  # (This code's assume the system using rabbitmq.
  #  So, please set those options.)
  services.rabbitmq.enable = true;
  services.rabbitmq.listenAddress = "0.0.0.0";
  services.rabbitmq.plugins = [
    "rabbitmq_management"
  ];

  # Enable ntp
  # (This code's assume the system using ntp.
  #  So, please set those options.)
  services.ntp.enable = true;

  # Enable memcached
  # (This code's assume the system using memcached.
  #  So, please set those options.)
  services.memcached.enable = true;
  services.memcached.listen = "0.0.0.0";

#############################################################
# Please setting above options for this code's applications #
#############################################################

  #####################
  # Personal Settings #
  #####################
  
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "jp";

  # Enable the i3 Desktop Environment.
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.windowManager.i3.enable = true;

  # Enable the LightDM
  services.xserver.displayManager.lightdm.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "jp106";
    defaultLocale = "ja_JP.UTF-8";
    #defaultLocale = "en_US.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "16.09";

}
