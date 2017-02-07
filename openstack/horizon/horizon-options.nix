{ config, lib, pkgs, ... }:

with lib;

with import ../../uwsgi/uwsgi-options.nix {
  config = config;
  lib = lib;
  pkgs = pkgs;
};

let
  cfg = config.horizon-options;
  horizon = pkgs.callPackage ./horizon.nix {};
in

{
  options = {
    horizon-options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          This option enables OpenStack Dashboard applications.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Install horizon
    environment.systemPackages = [
      horizon
    ];

    users.extraUsers.horizon = {
      description = "OpenStack Dashboard Service user";
      home = "/var/lib/horizon";
      createHome = true;
      group = "horizon";
      extraGroups = [ "users" "nginx" ];
      uid = 111;
    };

    users.extraGroups.horizon.gid = 111;

    environment.etc."horizon/local_settings.py" = {
      enable = true;
      source = ./etc/local_settings.py;
      uid = 111;
      gid = 111;
      mode = "0660";
    };

    environment.etc."horizon/__init__.py" = {
      enable = true;
      source = ./etc/__init__.py;
      uid = 111;
      gid = 111;
      mode = "0660";
    };

    environment.etc."horizon/enabled/__init__.py" = {
      enable = true;
      source = ./etc/enabled/__init__.py;
      uid = 111;
      gid = 111;
      mode = "0660";
    };

    environment.etc."horizon/ceilometer_policy.json" = {
      enable = true;
      source = ./etc/conf/ceilometer_policy.json;
      uid = 111;
      gid = config.ids.gids.nginx;
      mode = "0660";
    };

    environment.etc."horizon/cinder_policy.json" = {
      enable = true;
      source = ./etc/conf/cinder_policy.json;
      uid = 111;
      gid = config.ids.gids.nginx;
      mode = "0660";
    };

    environment.etc."horizon/glance_policy.json" = {
      enable = true;
      source = ./etc/conf/glance_policy.json;
      uid = 111;
      gid = config.ids.gids.nginx;
      mode = "0660";
    };

    environment.etc."horizon/heat_policy.json" = {
      enable = true;
      source = ./etc/conf/heat_policy.json;
      uid = 111;
      gid = config.ids.gids.nginx;
      mode = "0660";
    };

    environment.etc."horizon/keystone_policy.json" = {
      enable = true;
      source = ./etc/conf/keystone_policy.json;
      uid = 111;
      gid = config.ids.gids.nginx;
      mode = "0660";
    };

    environment.etc."horizon/neutron_policy.json" = {
      enable = true;
      source = ./etc/conf/neutron_policy.json;
      uid = 111;
      gid = config.ids.gids.nginx;
      mode = "0660";
    };

    environment.etc."horizon/nova_policy.json" = {
      enable = true;
      source = ./etc/conf/nova_policy.json;
      uid = 111;
      gid = config.ids.gids.nginx;
      mode = "0660";
    };

    networking.firewall.allowedTCPPorts = [
      80
    ];

    # Enable nginx
    services.nginx.enable = true;

    services.nginx.clientMaxBodySize = "5120m";
    services.nginx.virtualHosts."horizon" = {
      port = 80;

      locations = {
        "/" = {
          extraConfig = ''
            uwsgi_pass  unix://run/uwsgi/horizon.socket;
            include     ${pkgs.nginx}/conf/uwsgi_params;
            uwsgi_param SCRIPT_NAME "";
          '';
        };

        "/static" = {
          extraConfig = ''
            alias ${horizon}/lib/python2.7/site-packages/openstack_dashboard/local;
          '';
        };
      };
    };

    # Enable uwsgi

    uwsgi-options.enable = true;
    uwsgi-options.plugins = [ "python2" ];
    uwsgi-options.instance = {
      horizon = {

        uid = "horizon";
        gid = config.ids.gids.nginx;

        socket = "/run/uwsgi/horizon.socket";
        chmod-socket = 660;
        pidfile = "/run/uwsgi/horizon.pid";
        logto = "/run/uwsgi/horizon.log";

        chdir = "/var/lib/horizon";

        plugin = "python2";

        wsgi-file = "${horizon}/bin/.horizon.wsgi-wrapped";
      };
    };
  };
}
