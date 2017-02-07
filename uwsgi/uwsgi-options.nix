{ config, lib, pkgs, ... }:

with lib;

let

  modpacks-uwsgi = pkgs.callPackage ./uwsgi.nix {
    plugins = [];
    withPAM = pkgs.stdenv.isLinux;
    withSystemd = pkgs.stdenv.isLinux;
    php-embed = false;
  };

  cfg = config.uwsgi-options;

  uwsgi = modpacks-uwsgi.override {
    plugins = cfg.plugins;
  };

  buildCfg = name: c:
    let
      plugins =
        if any (n: !any (m: m == n) cfg.plugins) (c.plugins or [])
        then throw "`plugins` attribute in UWSGI configuration contains plugins not in config.uwsgi-options.plugins"
        else c.plugins or cfg.plugins;

      hasPython = v: filter (n: n == "python${v}") plugins != [];
      hasPython2 = hasPython "2";
      hasPython3 = hasPython "3";

      python =
        if hasPython2 && hasPython3 then
          throw "`plugins` attribute in UWSGI configuration shouldn't contain both python2 and python3"
        else if hasPython2 then uwsgi.python2
        else if hasPython3 then uwsgi.python3
        else null;

      pythonPackages = pkgs.pythonPackages.override {
        inherit python;
      };

      penv = python.buildEnv.override {
        extraLibs = (c.pythonPackages or (self: [])) pythonPackages;
      };

      uwsgiCfg = {
        uwsgi = 
          if name == "server"
            then {
              emperor = pkgs.buildEnv {
                name = "vassals";
                paths = mapAttrsToList buildCfg c;
              };
            }
         else c;
      };   

    in pkgs.writeTextDir "${name}.json" (builtins.toJSON uwsgiCfg);

    jsonHash = buildCfg "server" cfg.instance;
in {

  options = {
    uwsgi-options = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable uWSGI";
      };

      runDir = mkOption {
        type = types.string;
        default = "/run/uwsgi";
        description = "Where uWSGI communication sockets can live";
      };

      instance = mkOption {
        type = types.attrs;
        default = {
          
        };
        example = literalExample ''
          {
            moin = {
              pythonPackages = self: with self; [ moinmoin ];
              socket = "${config.uwsgi-options.runDir}/uwsgi.sock";
            };
          }
        '';
        description = ''
          uWSGI configuration for OpenStack applications.
        '';
      };

      plugins = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Plugins used with uWSGI";
      };

      user = mkOption {
        type = types.str;
        default = "uwsgi";
        description = "User account under which uwsgi runs.";
      };

      group = mkOption {
        type = types.str;
        default = "nginx";
        description = "Group account under which uwsgi runs.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.openstack-uwsgi = {
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        mkdir -p ${cfg.runDir}
        chown ${cfg.user}:${cfg.group} ${cfg.runDir}
        chmod g+w ${cfg.runDir}
      '';
      serviceConfig = {
        Type = "notify";
        ExecStart = "${uwsgi}/bin/uwsgi --json ${jsonHash}/server.json";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        ExecStop = "${pkgs.coreutils}/bin/kill -INT $MAINPID";
        NotifyAccess = "main";
        KillSignal = "SIGQUIT";
      };
    };

    users.extraUsers = optionalAttrs (cfg.user == "uwsgi") (singleton
      { name = "uwsgi";
        group = cfg.group;
        uid = config.ids.uids.uwsgi;
      });

    users.extraGroups = optionalAttrs (cfg.group == "uwsgi") (singleton
      { name = "uwsgi";
        gid = config.ids.gids.uwsgi;
      });
  };
}
