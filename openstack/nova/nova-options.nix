{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.nova-options;
  nova = pkgs.callPackage ./nova.nix {};
  novnc = pkgs.callPackage ../../noVNC/noVNC.nix {};
  modpacks = pkgs.callPackage ../python-packages.nix {};
in

{
  options = {
    nova-options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          This option enables Openstack Compute applications.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Install nova
    environment.systemPackages = [
      nova
      novnc
      pkgs.python27Packages.websockify
      modpacks.novaclient
      modpacks.privsep-helper
    ];

    users.extraUsers.nova = {
      description = "OpenStack Compute Service user";
      home = "/var/lib/nova";
      createHome = true;
      group = "nova";
      extraGroups = [ "libvirtd" ];
      uid = 208;
    };

    users.extraGroups.nova.gid = 208;

    # Enable sudo
    security.sudo = {
      enable = true;
      extraConfig = ''
        nova ALL=(root) NOPASSWD: /run/current-system/sw/bin/nova-rootwrap /etc/nova/rootwrap.conf *
      '';
    };

    environment.etc."nova/api-paste.ini" = {
      enable = true;
      source = ./etc/api-paste.ini;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    environment.etc."nova/logging.conf" = {
      enable = true;
      source = ./etc/logging.conf;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    environment.etc."nova/nova-compute.conf" = {
      enable = true;
      source = ./etc/nova-compute.conf;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    environment.etc."nova/nova.conf" = {
      enable = true;
      source = ./etc/nova.conf;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    environment.etc."nova/policy.json" = {
      enable = true;
      source = ./etc/policy.json;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    environment.etc."nova/rootwrap.conf" = {
      enable = true;
      source = ./etc/rootwrap.conf;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    environment.etc."nova/rootwrap.d/api-metadata.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/api-metadata.filters;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    environment.etc."nova/rootwrap.d/compute.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/compute.filters;
      uid = 208;
      gid = 208;
      mode = "0440";
    };

    systemd.services.nova-api = {
      description = "OpenStack Compute Service nova-api Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      preStart = ''
        if [ ! -d "/var/lib/nova/log" ]; then
          mkdir -p /var/lib/nova/log
        fi
      '';

      script = ''
        PATH="/var/setuid-wrappers:$PATH"
        ${nova}/bin/nova-api
      '';

      serviceConfig = {
        User = "nova";
        Group = "nova";
      };
    };

    systemd.services.nova-compute = {
      description = "OpenStack Compute Service nova-compute Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      preStart = ''
        if [ ! -d "/var/lib/nova/log" ]; then
          mkdir -p /var/lib/nova/log
        fi
        if [ ! -d "/var/lib/nova/instances" ]; then
          mkdir -p /var/lib/nova/instances
        fi
      '';

      script = ''
        PATH="/var/setuid-wrappers:/run/current-system/sw/bin:$PATH"
        PYTHONIOENCODING="utf-8"
        ${nova}/bin/nova-compute
      '';

      serviceConfig = {
        User = "nova";
        Group = "nova";
      };
    };

    systemd.services.nova-conductor = {
      description = "OpenStack Compute Service nova-conductor Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      serviceConfig = {
        ExecStart = "${nova}/bin/nova-conductor";
        User = "nova";
        Group = "nova";
      };
    };

    systemd.services.nova-consoleauth = {
      description = "OpenStack Compute Service nova-consoleauth Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      serviceConfig = {
        ExecStart = "${nova}/bin/nova-consoleauth";
        User = "nova";
        Group = "nova";
      };
    };

    systemd.services.nova-novncproxy = {
      description = "OpenStack Compute Service nova-novncproxy Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      serviceConfig = {
        ExecStart = "${nova}/bin/nova-novncproxy --web ${novnc}";
        User = "nova";
        Group = "nova";
      };
    };

    systemd.services.nova-scheduler = {
      description = "OpenStack Compute Service nova-scheduler Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      serviceConfig = {
        ExecStart = "${nova}/bin/nova-scheduler";
        User = "nova";
        Group = "nova";
      };
    };

    networking.firewall.allowedTCPPorts = [
      8774
      6080
    ];
  };
}
