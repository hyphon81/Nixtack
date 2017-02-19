{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.neutron-options;
  neutron = pkgs.callPackage ./neutron.nix {};
  modpacks = pkgs.callPackage ../python-packages.nix {};
in

{
  options = {
    neutron-options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          This option enables Openstack Networking applications.
        '';
      };

      nodeType = mkOption {
        type = types.enum ["control" "compute"];
        default = "control";
        description = ''
          OpenStack Networking Service node type.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    #Install neutron
    environment.systemPackages = [
      neutron
      pkgs.ebtables
      pkgs.bridge-utils
      pkgs.dnsmasq
      pkgs.ipset
      pkgs.conntrack_tools
      modpacks.neutronclient
    ];

    users.extraUsers.neutron = {
      description = "OpenStack Networking Service user";
      home = "/var/lib/neutron";
      createHome = true;
      group = "neutron";
      uid = 106;
    };

    users.extraGroups.neutron.gid = 106;

    # Enable sudo
    security.sudo = {
      enable = true;
      extraConfig = ''
        neutron ALL=(root) NOPASSWD: /run/current-system/sw/bin/neutron-rootwrap /etc/neutron/rootwrap.conf *
      '';
    };

    environment.etc."neutron/api-paste.ini" = {
      enable = true;
      source = ./etc/api-paste.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/dnsmasq" = {
      enable = true;
      source = ./etc/dnsmasq;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/dhcp_agent.ini" = {
      enable = true;
      source = ./etc/dhcp_agent.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/l3_agent.ini" = {
      enable = true;
      source = ./etc/l3_agent.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/metadata_agent.ini" = {
      enable = true;
      source = ./etc/metadata_agent.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/metering_agent.ini" = {
      enable = true;
      source = ./etc/metering_agent.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/neutron.conf" = {
      enable = true;
      source = ./etc/neutron.conf;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/policy.json" = {
      enable = true;
      source = ./etc/policy.json;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.conf" = {
      enable = true;
      source = ./etc/rootwrap.conf;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/linuxbridge_agent.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/linuxbridge_agent.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/ml2_conf.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/ml2_conf.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/ml2_conf_brocade.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/ml2_conf_brocade.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/ml2_conf_brocade_fi_ni.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/ml2_conf_brocade_fi_ni.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/ml2_conf_fslsdn.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/ml2_conf_brocade_fi_ni.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/ml2_conf_ofa.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/ml2_conf_ofa.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/ml2_conf_sriov.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/ml2_conf_sriov.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/openvswitch_agent.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/openvswitch_agent.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/restproxy.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/restproxy.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/plugins/ml2/sriov_agent.ini" = {
      enable = true;
      source = ./etc/plugins/ml2/sriov_agent.ini;
      uid = 106;
      gid = 106;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/conntrack.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/conntrack.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/debug.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/debug.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/dhcp.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/dhcp.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/ebtables.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/ebtables.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/ipset-firewall.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/ipset-firewall.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/iptables-firewall.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/iptables-firewall.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/l3.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/l3.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/linuxbridge-plugin.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/linuxbridge-plugin.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."neutron/rootwrap.d/openvswitch-plugin.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/openvswitch-plugin.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    systemd = (
      let
        neutron-server = {
          description = "OpenStack Networking Service neutron-server Daemon";

          wantedBy = [ "multi-user.target" ];
          after = [
            "systemd-udev-settle.service"
          ];

          serviceConfig = {
            ExecStart = "${neutron}/bin/neutron-server --config-dir /etc/neutron --config-file /etc/neutron/plugins/ml2/ml2_conf.ini";
            User = "neutron";
            Group = "neutron";
          };
        };

        neutron-linuxbridge-agent = {
          description = "OpenStack Networking Service neutron-linuxbridge-agent Daemon";

          wantedBy = [ "multi-user.target" ];
          after = [
            "systemd-udev-settle.service"
          ];

          script = ''
            PATH="/var/setuid-wrappers:/run/current-system/sw/bin:$PATH"
            PYTHONPATH="${neutron}/lib/${pkgs.python.libPrefix}/site-packages:$PYTHONPATH"
            PYTHONIOENCODING="utf-8"
            ${neutron}/bin/neutron-linuxbridge-agent --config-dir /etc/neutron --config-file /etc/neutron/plugins/ml2/linuxbridge_agent.ini
          '';

          serviceConfig = {
            User = "neutron";
            Group = "neutron";
          };
        };

        neutron-dhcp-agent = {
          description = "OpenStack Networking Service neutron-dhcp-agent Daemon";

          wantedBy = [ "multi-user.target" ];
          after = [
            "systemd-udev-settle.service"
          ];

          script = ''
            PATH="/var/setuid-wrappers:/run/current-system/sw/bin:$PATH"
            PYTHONPATH="${neutron}/lib/${pkgs.python.libPrefix}/site-packages:$PYTHONPATH"
            PYTHONIOENCODING="utf-8"
            ${neutron}/bin/neutron-dhcp-agent --config-dir /etc/neutron --config-file /etc/neutron/dhcp_agent.ini
          '';

          serviceConfig = {
            User = "neutron";
            Group = "neutron";
          };
        };

        neutron-metadata-agent = {
          description = "OpenStack Networking Service neutron-metadata-agent Daemon";

          wantedBy = [ "multi-user.target" ];
          after = [
            "systemd-udev-settle.service"
          ];

          serviceConfig = {
            ExecStart = "${neutron}/bin/neutron-metadata-agent --config-dir /etc/neutron --config-file /etc/neutron/metadata_agent.ini";
            User = "neutron";
            Group = "neutron";
          };
        };

        neutron-l3-agent = {
          description = "OpenStack Networking Service neutron-l3-agent Daemon";

          wantedBy = [ "multi-user.target" ];
          after = [
            "systemd-udev-settle.service"
          ];

          script = ''
            PATH="/var/setuid-wrappers:/run/current-system/sw/bin:$PATH"
            PYTHONPATH="${neutron}/lib/${pkgs.python.libPrefix}/site-packages:$PYTHONPATH"
            PYTHONIOENCODING="utf-8"
            ${neutron}/bin/neutron-l3-agent --config-dir /etc/neutron --config-file /etc/neutron/l3_agent.ini
          '';

          serviceConfig = {
            User = "neutron";
            Group = "neutron";
          };
        };
      in

      if cfg.nodeType == "control" then {
        services.neutron-server = neutron-server;
        services.neutron-linuxbridge-agent = neutron-linuxbridge-agent;
        services.neutron-dhcp-agent = neutron-dhcp-agent;
        services.neutron-metadata-agent = neutron-metadata-agent;
        services.neutron-l3-agent = neutron-l3-agent;

      } else (if cfg.nodeType == "compute" then {
        services.neutron-linuxbridge-agent = neutron-linuxbridge-agent;
      } else {
        ##DON'T RUN
      })
    );

    networking.firewall.allowedTCPPorts = [
      9696
    ];
    networking.firewall.allowedUDPPorts = [
      # Allow vxlan
      8472
    ];
    networking.firewall.checkReversePath = false;
    networking.firewall.logReversePathDrops = true;
  };
}
