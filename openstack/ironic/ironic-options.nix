{ config, lib, pkgs, ...}:

with lib;

with import ../../uwsgi/uwsgi-options.nix {
  config = config;
  lib = lib;
  pkgs = pkgs;
};

let
  cfg = config.ironic-options;
  ironic = pkgs.callPackage ./ironic.nix {};
  modpacks = pkgs.callPackage ../python-packages.nix {};
in

{
  options = {
    ironic-options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          This option enables Openstack Bare Metal Service applications.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Install ironic
    environment.systemPackages = [
      ironic
      modpacks.ironicclient
      pkgs.ipmitool
      pkgs.ipmiutil
      pkgs.openiscsi
      pkgs.psmisc
      pkgs.gptfdisk
      pkgs.parted
    ];

    users.extraUsers.ironic = {
      description = "OpenStack Bare Metal Service user";
      home = "/var/lib/ironic";
      createHome = true;
      group = "ironic";
      extraGroups = [ "nginx" ];
      uid = 131;
    };

    users.extraGroups.ironic.gid = 131;

    # Enable sudo
    security.sudo = {
      enable = true;
      extraConfig = ''
        ironic ALL=(root) NOPASSWD: /run/current-system/sw/bin/ironic-rootwrap /etc/ironic/rootwrap.conf *
      '';
    };

    environment.etc."ironic/ironic.conf" = {
      enable = true;
      source = ./etc/ironic.conf;
      uid = 131;
      gid = 131;
      mode = "0440";
    };

    environment.etc."ironic/ironic_api_audit_map.conf" = {
      enable = true;
      source = ./etc/ironic_api_audit_map.conf;
      uid = 131;
      gid = 131;
      mode = "0440";
    };

    environment.etc."ironic/policy.json" = {
      enable = true;
      source = ./etc/policy.json;
      uid = 131;
      gid = 131;
      mode = "0440";
    };

    environment.etc."ironic/rootwrap.conf" = {
      enable = true;
      source = ./etc/rootwrap.conf;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."ironic/rootwrap.d/ironic-images.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/ironic-images.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."ironic/rootwrap.d/ironic-lib.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/ironic-lib.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."ironic/rootwrap.d/ironic-utils.filters" = {
      enable = true;
      source = ./etc/rootwrap.d/ironic-utils.filters;
      uid = 0;
      gid = 0;
      mode = "0440";
    };

    environment.etc."iscsi/iscsid.conf" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0400";
      text = ''
        iscsid.startup = ${pkgs.openiscsi}/bin/iscsid
        node.startup = manual
        node.leading_login = No
        node.session.timeo.replacement_timeout = 120
        node.conn[0].timeo.login_timeout = 15
        node.conn[0].timeo.logout_timeout = 15
        node.conn[0].timeo.noop_out_interval = 5
        node.conn[0].timeo.noop_out_timeout = 5
        node.session.err_timeo.abort_timeout = 15
        node.session.err_timeo.lu_reset_timeout = 30
        node.session.err_timeo.tgt_reset_timeout = 30
        node.session.initial_login_retry_max = 8
        node.session.cmds_max = 128
        node.session.queue_depth = 32
        node.session.xmit_thread_priority = -20
        node.session.iscsi.InitialR2T = No
        node.session.iscsi.ImmediateData = Yes
        node.session.iscsi.FirstBurstLength = 262144
        node.session.iscsi.MaxBurstLength = 16776192
        node.conn[0].iscsi.MaxRecvDataSegmentLength = 262144
        node.conn[0].iscsi.MaxXmitDataSegmentLength = 0
        discovery.sendtargets.iscsi.MaxRecvDataSegmentLength = 32768
        node.session.nr_sessions = 1
        node.session.iscsi.FastAbort = Yes 
      '';
    };

    environment.etc."iscsi/initiatorname.iscsi" = {
      enable = true;
      source = "${pkgs.openiscsi}/etc/iscsi/initiatorname.iscsi";
      uid = 0;
      gid = 0;
      mode = "0400";
    };

    networking.firewall.allowedTCPPorts = [
      #iscsi
      3260
      
      #ironic-api
      6385
    ];

    systemd.services.ironic-api = {
      description = "OpenStack Bare Metal Service ironic-api Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      preStart = ''
        chmod 755 /var/lib/ironic
      '';

      script = ''
        PATH="/var/setuid-wrappers:$PATH"
        ${ironic}/bin/ironic-api
      '';

      serviceConfig = {
        User = "ironic";
        Group = "ironic";
      };
    };

    systemd.services.ironic-conductor = {
      description = "OpenStack Bare Metal Service ironic-conductor Daemon";

      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
      ];

      preStart = ''
        chmod 755 /var/lib/ironic
      '';

      script = ''
        PATH="/var/setuid-wrappers:$PATH"
        ${ironic}/bin/ironic-conductor
      '';

      serviceConfig = {
        User = "ironic";
        Group = "ironic";
      };
    };
  };
}
