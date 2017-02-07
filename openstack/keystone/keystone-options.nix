{ config, lib, pkgs, ... }:

with lib;

with import ../../uwsgi/uwsgi-options.nix {
  config = config;
  lib = lib;
  pkgs = pkgs;
};

let
  cfg = config.keystone-options;
  keystone = pkgs.callPackage ./keystone.nix {};
in

{
  options = {
    keystone-options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          This option enables OpenStack Identify applications.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Install keystone
    environment.systemPackages = [
      keystone
    ];

    users.extraUsers.keystone = {
      description = "OpenStack Identify Service user";
      group = "keystone";
      extraGroups = [ "nginx" ];
      uid = 91;
    };

    users.extraGroups.keystone.gid = 91;

    environment.etc."keystone/default_catalog.templates" = {
      enable = true;
      source = ./etc/default_catalog.templates;
      uid = 91;
      gid = 91;
      mode = "0640";
    };
    environment.etc."keystone/keystone.conf" = {
      enable = true;
      source = ./etc/keystone.conf;
      uid = 91;
      gid = 91;
      mode = "0640";
    };
    environment.etc."keystone/keystone-paste.ini" = {
      enable = true;
      source = ./etc/keystone-paste.ini;
      uid = 91;
      gid = 91;
      mode = "0640";
    };
    environment.etc."keystone/logging.conf" = {
      enable = true;
      source = ./etc/logging.conf;
      uid = 91;
      gid = 91;
      mode = "0640";
    };
    environment.etc."keystone/policy.json" = {
      enable = true;
      source = ./etc/policy.json;
      uid = 91;
      gid = 91;
      mode = "0640";
    };
    environment.etc."keystone/policy.v3cloudsample.json" = {
      enable = true;
      source = ./etc/policy.v3cloudsample.json;
      uid = 91;
      gid = 91;
      mode = "0640";
    };
    environment.etc."keystone/sso_callback_template.html" = {
      enable = true;
      source = ./etc/sso_callback_template.html;
      uid = 91;
      gid = 91;
      mode = "0640";
    };

    networking.firewall.allowedTCPPorts = [
      5000
      35357
      8000
    ];

    # Enable nginx
    services.nginx.enable = true;

    services.nginx.virtualHosts."keystone-main" = {
      port = 5000;
  
      locations = {
        "/" = {
          extraConfig = ''
            uwsgi_pass  unix://run/uwsgi/keystone-main.socket;
            include     ${pkgs.nginx}/conf/uwsgi_params;
            uwsgi_param SCRIPT_NAME "";
          '';
        };
      };
    };
    
    services.nginx.virtualHosts."keystone-admin" = {
      port = 35357;
  
      locations = {
        "/" = {
          extraConfig = ''
            uwsgi_pass  unix://run/uwsgi/keystone-admin.socket;
            include     ${pkgs.nginx}/conf/uwsgi_params;
            uwsgi_param SCRIPT_NAME "";
          '';
        };
      };
    };

    # Enable uwsgi

    uwsgi-options.enable = true;
    uwsgi-options.plugins = [ "python2" ];
    uwsgi-options.instance = {
      keystone-main = {

        uid = "keystone";
        gid = config.ids.gids.nginx;
          
        socket = "/run/uwsgi/keystone-main.socket";
        chmod-socket = 660;
        pidfile = "/run/uwsgi/keystone-main.pid";
        #logto = "/run/uwsgi/keystone-main.log";

        chdir = "${keystone}";

        plugin = "python2";

        wsgi-file = "${keystone}/bin/.keystone-wsgi-public-wrapped";
      };

      keystone-admin = {
        type = "normal";

        uid = "keystone";
        gid = config.ids.gids.nginx;

        socket = "/run/uwsgi/keystone-admin.socket";
        chmod-socket = 660;
        pidfile = "/run/uwsgi/keystone-admin.pid";
        #logto = "/run/uwsgi/keystone-admin.log";

        chdir = "${keystone}";

        plugin = "python2";

        wsgi-file = "${keystone}/bin/.keystone-wsgi-admin-wrapped";
      };
    };
  };
}
