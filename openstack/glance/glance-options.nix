{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.glance-options;
  glance = pkgs.callPackage ./glance.nix {};
  modpacks = pkgs.callPackage ../python-packages.nix {};
in

{
  options = {
    glance-options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          This option enables OpenStack Image applications.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [
      glance
      modpacks.glanceclient
    ];

    users.extraUsers.glance = {
      description = "OpenStack Image Service user";
      home = "/var/lib/glance";
      createHome = true;
      group = "glance";
      uid = 258;
    };

    users.extraGroups.glance.gid = 258;

    environment.etc."glance/glance-api-paste.ini" = {
      enable = true;
      source = ./etc/glance-api-paste.ini;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-api.conf" = {
      enable = true;
      source = ./etc/glance-api.conf;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-cache.conf" = {
      enable = true;
      source = ./etc/glance-cache.conf;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-glare-paste.ini" = {
      enable = true;
      source = ./etc/glance-glare-paste.ini;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-glare.conf" = {
      enable = true;
      source = ./etc/glance-glare.conf;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-manage.conf" = {
      enable = true;
      source = ./etc/glance-manage.conf;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-registry-paste.ini" = {
      enable = true;
      source = ./etc/glance-registry-paste.ini;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-registry.conf" = {
      enable = true;
      source = ./etc/glance-registry.conf;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/glance-scrubber.conf" = {
      enable = true;
      source = ./etc/glance-scrubber.conf;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/policy.json" = {
      enable = true;
      source = ./etc/policy.json;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    environment.etc."glance/schema-image.json" = {
      enable = true;
      source = ./etc/schema-image.json;
      uid = 258;
      gid = 258;
      mode = "0440";
    };

    systemd.services.glance-api = {
      description = "OpenStack Image Service glance-api Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      serviceConfig = {
        ExecStart = "${glance}/bin/glance-api --config-dir /etc/glance --config-file /etc/glance/glance-api-paste.ini";
        User = "glance";
        Group = "glance";
      };
    };

    systemd.services.glance-registry = {
      description = "OpenStack Image Service glance-registry Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      serviceConfig = {
        ExecStart = "${glance}/bin/glance-registry --config-dir /etc/glance --config-file /etc/glance/glance-registry-paste.ini";
        User = "glance";
        Group = "glance";
      };
    };

    networking.firewall.allowedTCPPorts = [
      9292
    ];
    
  };
}
