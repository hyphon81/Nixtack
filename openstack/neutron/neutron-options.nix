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
        type = types.enum ["control" "compute" "custom"];
        default = "control";
        description = ''
          OpenStack Networking Service node type.
        '';
      };

      dnsmasqDnsServers = mkOption {
        type = types.listOf types.str;
        default = [ "8.8.8.8" "8.8.4.4" ];
        description = ''
          The dnsmasq uses dns servers that witten in this option.
        '';
      };

      regionType = mkOption {
        type = types.str;
        default = "RegionOne";
        description = ''
          The OpenStack region type name.
        '';
      };

      keystoneServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the keystone server.
        '';
      };

      novaServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the nova server.
        '';
      };

      memcachedServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the memcached server.
        '';
      };

      sharedSecret = mkOption {
        type = types.str;
        default = "";
        description = ''
          The memcached's shared secret.
        '';
      };

      rabbitMQUser = mkOption {
        type = types.str;
        default = "openstack";
        description = ''
          This is the name of the user for OpenStack on rabbitMQ server.
        '';
      };

      rabbitMQPassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the user for OpenStack on rabbitMQ server.
        '';
      };

      rabbitMQServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the rabbitMQ server.
        '';
      };

      projectDomainName = mkOption {
        type = types.str;
        default = "Default";
        description = ''
          This is the OpenStack project domain name.
        '';
      };

      userDomainName = mkOption {
        type = types.str;
        default = "Default";
        description = ''
          This is the OpenStack user domain name.
        '';
      };

      projectName = mkOption {
        type = types.str;
        default = "service";
        description = ''
          This is the OpenStack nova project name.
        '';
      };

      serviceUser = mkOption {
        type = types.str;
        default = "neutron";
        description = ''
          This is the name of the neutron service user.
        '';
      };

      servicePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the nova service.
        '';
      };

      databaseUser = mkOption {
        type = types.str;
        default = "nova";
        description = ''
          This is the name of the neutron database user.
        '';
      };

      databasePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the neutron database.
        '';
      };

      databaseName = mkOption {
        type = types.str;
        default = "neutron";
        description = ''
          This is the name of the neutron database.
        '';
      };

      databaseServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the database server.
        '';
      };

      novaProjectName = mkOption {
        type = types.str;
        default = "service";
        description = ''
          This is the OpenStack nova project name.
        '';
      };

      novaServiceUser = mkOption {
        type = types.str;
        default = "nova";
        description = ''
          This is the name of the nova service user.
        '';
      };

      novaServicePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the nova service.
        '';
      };

      physicalInterfaceMappings = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "provider:eth0" "physicallan:eth1" ];
        description = ''
          The name of the underlying provider physical network interface.
        '';
      };

      flatNetworks = = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "provider" "physical_lan" ];
        description = ''
          The name of the physical flat network.
        '';
      };

      vxlanLocalIp = mkOption {
        type = types.str;
        default = "";
        description = ''
          The local IP address to use for VXLAN endpoints.
        '';
      };

      enableServer = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables neutron-server daemon.
          This option needs to set neutron-options.nodeType = "custom".
        '';
      };

      enableLinuxbridgeAgent = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables neutron-linuxbridge-agent daemon.
          This option needs to set neutron-options.nodeType = "custom".
        '';
      };

      enableDhcpAgent = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables neutron-dhcp-agent daemon.
          This option needs to set neutron-options.nodeType = "custom".
        '';
      };

      enableMetadataAgent = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables neutron-metadata-agent daemon.
          This option needs to set neutron-options.nodeType = "custom".
        '';
      };

      enableL3Agent = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables neutron-l3-agent daemon.
          This option needs to set neutron-options.nodeType = "custom".
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
      uid = 260;
    };

    users.extraGroups.neutron.gid = 260;

    # Enable sudo
    security.sudo = {
      enable = true;
      extraConfig = ''
        neutron ALL=(root) NOPASSWD: /run/current-system/sw/bin/neutron-rootwrap /etc/neutron/rootwrap.conf *
      '';
    };

    environment.etc."neutron/api-paste.ini" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [composite:neutron]
        use = egg:Paste#urlmap
        /: neutronversions
        /v2.0: neutronapi_v2_0

        [composite:neutronapi_v2_0]
        use = call:neutron.auth:pipeline_factory
        noauth = request_id catch_errors extensions neutronapiapp_v2_0
        keystone = request_id catch_errors authtoken keystonecontext extensions neutronapiapp_v2_0

        [filter:request_id]
        paste.filter_factory = oslo_middleware:RequestId.factory

        [filter:catch_errors]
        paste.filter_factory = oslo_middleware:CatchErrors.factory

        [filter:keystonecontext]
        paste.filter_factory = neutron.auth:NeutronKeystoneContext.factory

        [filter:authtoken]
        paste.filter_factory = keystonemiddleware.auth_token:filter_factory

        [filter:extensions]
        paste.filter_factory = neutron.api.extensions:plugin_aware_extension_middleware_factory

        [app:neutronversions]
        paste.app_factory = neutron.api.versions:Versions.factory

        [app:neutronapiapp_v2_0]
        paste.app_factory = neutron.api.v2.router:APIRouter.factory
      '';
    };

    environment.etc."neutron/dnsmasq" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        user=neutron
        group=neutron

        log-dhcp
        log-queries
      '';
    };

    environment.etc."neutron/dhcp_agent.ini" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [DEFAULT]
        interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
        dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
        enable_isolated_metadata = True

        enable_metadata_network = True
        dnsmasq_config_file = /etc/neutron/dnsmasq
        dnsmasq_dns_servers = ${concatStringsSep ", " cfg.dnsmasqDnsServers}

        [AGENT]
        log_agent_heartbeats = False
      '';
    };

    environment.etc."neutron/l3_agent.ini" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [DEFAULT]
        interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
        external_network_bridge =
        metadata_port = 9697

        [AGENT]
      '';
    };

    environment.etc."neutron/metadata_agent.ini" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [DEFAULT]
        auth_url = http://${cfg.keystoneServer}:5000/v3
        auth_region = ${cfg.regionType}
        nova_metadata_ip = ${cfg.novaServer}
        nova_metadata_port = 8775
        metadata_proxy_shared_secret = ${cfg.sharedSecret}

        [AGENT]
      '';
    };

    environment.etc."neutron/metering_agent.ini" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [DEFAULT]
      '';
    };

    environment.etc."neutron/neutron.conf" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [DEFAULT]
        core_plugin = ml2
        service_plugins = router
        auth_strategy = keystone
        allow_overlapping_ips = True
        transport_url = rabbit://${cfg.rabbitMQUser}:${cfg.rabbitMQPassword}@${cfg.rabbitMQServer}

        notify_nova_on_port_status_changes = True
        notify_nova_on_port_data_changes = True

        [matchmaker_redis]

        [matchmaker_ring]

        [quotas]

        [agent]
        root_helper = sudo neutron-rootwrap /etc/neutron/rootwrap.conf

        [keystone_authtoken]
        auth_uri = http://${cfg.keystoneServer}:5000
        auth_url = http://${cfg.keystoneServer}:35357
        memcached_servers = ${cfg.memcachedServer}:11211
        auth_type = password
        project_domain_name = ${cfg.projectDomainName}
        user_domain_name = ${cfg.userDomainName}
        project_name = ${cfg.projectName}
        username = ${cfg.serviceUser}
        password = ${cfg.servicePassword}


        [database]
        connection = mysql+pymysql://${cfg.databaseUser}:${cfg.databasePassword}@${cfg.databaseServer}/${cfg.databaseName}

        [nova]
        auth_url = http://${cfg.keystoneServer}:35357
        auth_type = password
        project_domain_name = ${cfg.projectDomainName}
        user_domain_name = ${cfg.userDomainName}
        region_name = ${cfg.regionType}
        project_name = ${cfg.novaProjectName}
        username = ${cfg.novaServiceUser}
        password = ${cfg.novaServicePassword}

        [oslo_concurrency]
        lock_path = $state_path/lock

        [oslo_policy]

        [oslo_messaging_amqp]

        [oslo_messaging_qpid]

        [oslo_messaging_rabbit]

        [qos]

      '';
    };

    environment.etc."neutron/policy.json" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        {
           "context_is_admin":  "role:admin",
           "owner": "tenant_id:%(tenant_id)s",
           "admin_or_owner": "rule:context_is_admin or rule:owner",
           "context_is_advsvc":  "role:advsvc",
           "admin_or_network_owner": "rule:context_is_admin or tenant_id:%(network:tenant_id)s",
           "admin_owner_or_network_owner": "rule:admin_or_network_owner or rule:owner",
           "admin_only": "rule:context_is_admin",
           "regular_user": "",
           "shared": "field:networks:shared=True",
           "shared_firewalls": "field:firewalls:shared=True",
           "shared_firewall_policies": "field:firewall_policies:shared=True",
           "shared_subnetpools": "field:subnetpools:shared=True",
           "shared_address_scopes": "field:address_scopes:shared=True",
           "external": "field:networks:router:external=True",
           "default": "rule:admin_or_owner",

           "create_subnet": "rule:admin_or_network_owner",
           "get_subnet": "rule:admin_or_owner or rule:shared",
           "update_subnet": "rule:admin_or_network_owner",
           "delete_subnet": "rule:admin_or_network_owner",

           "create_subnetpool": "",
           "create_subnetpool:shared": "rule:admin_only",
           "get_subnetpool": "rule:admin_or_owner or rule:shared_subnetpools",
           "update_subnetpool": "rule:admin_or_owner",
           "delete_subnetpool": "rule:admin_or_owner",

           "create_address_scope": "",
           "create_address_scope:shared": "rule:admin_only",
           "get_address_scope": "rule:admin_or_owner or rule:shared_address_scopes",
           "update_address_scope": "rule:admin_or_owner",
           "update_address_scope:shared": "rule:admin_only",
           "delete_address_scope": "rule:admin_or_owner",

           "create_network": "",
           "get_network": "rule:admin_or_owner or rule:shared or rule:external or rule:context_is_advsvc",
           "get_network:router:external": "rule:regular_user",
           "get_network:segments": "rule:admin_only",
           "get_network:provider:network_type": "rule:admin_only",
           "get_network:provider:physical_network": "rule:admin_only",
           "get_network:provider:segmentation_id": "rule:admin_only",
           "get_network:queue_id": "rule:admin_only",
           "create_network:shared": "rule:admin_only",
           "create_network:router:external": "rule:admin_only",
           "create_network:segments": "rule:admin_only",
           "create_network:provider:network_type": "rule:admin_only",
           "create_network:provider:physical_network": "rule:admin_only",
           "create_network:provider:segmentation_id": "rule:admin_only",
           "update_network": "rule:admin_or_owner",
           "update_network:segments": "rule:admin_only",
           "update_network:shared": "rule:admin_only",
           "update_network:provider:network_type": "rule:admin_only",
           "update_network:provider:physical_network": "rule:admin_only",
           "update_network:provider:segmentation_id": "rule:admin_only",
           "update_network:router:external": "rule:admin_only",
           "delete_network": "rule:admin_or_owner",

           "network_device": "field:port:device_owner=~^network:",
           "create_port": "",
           "create_port:device_owner": "not rule:network_device or rule:admin_or_network_owner or rule:context_is_advsvc",
           "create_port:mac_address": "rule:admin_or_network_owner or rule:context_is_advsvc",
           "create_port:fixed_ips": "rule:admin_or_network_owner or rule:context_is_advsvc",
           "create_port:port_security_enabled": "rule:admin_or_network_owner or rule:context_is_advsvc",
           "create_port:binding:host_id": "rule:admin_only",
           "create_port:binding:profile": "rule:admin_only",
           "create_port:mac_learning_enabled": "rule:admin_or_network_owner or rule:context_is_advsvc",
           "create_port:allowed_address_pairs": "rule:admin_or_network_owner",
           "get_port": "rule:admin_owner_or_network_owner or rule:context_is_advsvc",
           "get_port:queue_id": "rule:admin_only",
           "get_port:binding:vif_type": "rule:admin_only",
           "get_port:binding:vif_details": "rule:admin_only",
           "get_port:binding:host_id": "rule:admin_only",
           "get_port:binding:profile": "rule:admin_only",
           "update_port": "rule:admin_or_owner or rule:context_is_advsvc",
           "update_port:device_owner": "not rule:network_device or rule:admin_or_network_owner or rule:context_is_advsvc",
           "update_port:mac_address": "rule:admin_only or rule:context_is_advsvc",
           "update_port:fixed_ips": "rule:admin_or_network_owner or rule:context_is_advsvc",
           "update_port:port_security_enabled": "rule:admin_or_network_owner or rule:context_is_advsvc",
           "update_port:binding:host_id": "rule:admin_only",
           "update_port:binding:profile": "rule:admin_only",
           "update_port:mac_learning_enabled": "rule:admin_or_network_owner or rule:context_is_advsvc",
           "update_port:allowed_address_pairs": "rule:admin_or_network_owner",
           "delete_port": "rule:admin_owner_or_network_owner or rule:context_is_advsvc",

           "get_router:ha": "rule:admin_only",
           "create_router": "rule:regular_user",
           "create_router:external_gateway_info:enable_snat": "rule:admin_only",
           "create_router:distributed": "rule:admin_only",
           "create_router:ha": "rule:admin_only",
           "get_router": "rule:admin_or_owner",
           "get_router:distributed": "rule:admin_only",
           "update_router:external_gateway_info:enable_snat": "rule:admin_only",
           "update_router:distributed": "rule:admin_only",
           "update_router:ha": "rule:admin_only",
           "delete_router": "rule:admin_or_owner",

           "add_router_interface": "rule:admin_or_owner",
           "remove_router_interface": "rule:admin_or_owner",

           "create_router:external_gateway_info:external_fixed_ips": "rule:admin_only",
           "update_router:external_gateway_info:external_fixed_ips": "rule:admin_only",

           "create_firewall": "",
           "get_firewall": "rule:admin_or_owner",
           "create_firewall:shared": "rule:admin_only",
           "get_firewall:shared": "rule:admin_only",
           "update_firewall": "rule:admin_or_owner",
           "update_firewall:shared": "rule:admin_only",
           "delete_firewall": "rule:admin_or_owner",

           "create_firewall_policy": "",
           "get_firewall_policy": "rule:admin_or_owner or rule:shared_firewall_policies",
           "create_firewall_policy:shared": "rule:admin_or_owner",
           "update_firewall_policy": "rule:admin_or_owner",
           "delete_firewall_policy": "rule:admin_or_owner",

           "insert_rule": "rule:admin_or_owner",
           "remove_rule": "rule:admin_or_owner",

           "create_firewall_rule": "",
           "get_firewall_rule": "rule:admin_or_owner or rule:shared_firewalls",
           "update_firewall_rule": "rule:admin_or_owner",
           "delete_firewall_rule": "rule:admin_or_owner",

           "create_qos_queue": "rule:admin_only",
           "get_qos_queue": "rule:admin_only",

           "update_agent": "rule:admin_only",
           "delete_agent": "rule:admin_only",
           "get_agent": "rule:admin_only",

           "create_dhcp-network": "rule:admin_only",
           "delete_dhcp-network": "rule:admin_only",
           "get_dhcp-networks": "rule:admin_only",
           "create_l3-router": "rule:admin_only",
           "delete_l3-router": "rule:admin_only",
           "get_l3-routers": "rule:admin_only",
           "get_dhcp-agents": "rule:admin_only",
           "get_l3-agents": "rule:admin_only",
           "get_loadbalancer-agent": "rule:admin_only",
           "get_loadbalancer-pools": "rule:admin_only",
           "get_agent-loadbalancers": "rule:admin_only",
           "get_loadbalancer-hosting-agent": "rule:admin_only",

           "create_floatingip": "rule:regular_user",
           "create_floatingip:floating_ip_address": "rule:admin_only",
           "update_floatingip": "rule:admin_or_owner",
           "delete_floatingip": "rule:admin_or_owner",
           "get_floatingip": "rule:admin_or_owner",

           "create_network_profile": "rule:admin_only",
           "update_network_profile": "rule:admin_only",
           "delete_network_profile": "rule:admin_only",
           "get_network_profiles": "",
           "get_network_profile": "",
           "update_policy_profiles": "rule:admin_only",
           "get_policy_profiles": "",
           "get_policy_profile": "",

           "create_metering_label": "rule:admin_only",
           "delete_metering_label": "rule:admin_only",
           "get_metering_label": "rule:admin_only",

           "create_metering_label_rule": "rule:admin_only",
           "delete_metering_label_rule": "rule:admin_only",
           "get_metering_label_rule": "rule:admin_only",

           "get_service_provider": "rule:regular_user",
           "get_lsn": "rule:admin_only",
           "create_lsn": "rule:admin_only",

           "create_flavor": "rule:admin_only",
           "update_flavor": "rule:admin_only",
           "delete_flavor": "rule:admin_only",
           "get_flavors": "rule:regular_user",
           "get_flavor": "rule:regular_user",
           "create_service_profile": "rule:admin_only",
           "update_service_profile": "rule:admin_only",
           "delete_service_profile": "rule:admin_only",
           "get_service_profiles": "rule:admin_only",
           "get_service_profile": "rule:admin_only",

           "get_policy": "rule:regular_user",
           "create_policy": "rule:admin_only",
           "update_policy": "rule:admin_only",
           "delete_policy": "rule:admin_only",
           "get_policy_bandwidth_limit_rule": "rule:regular_user",
           "create_policy_bandwidth_limit_rule": "rule:admin_only",
           "delete_policy_bandwidth_limit_rule": "rule:admin_only",
           "update_policy_bandwidth_limit_rule": "rule:admin_only",
           "get_rule_type": "rule:regular_user",

           "restrict_wildcard": "(not field:rbac_policy:target_tenant=*) or rule:admin_only",
           "create_rbac_policy": "",
           "create_rbac_policy:target_tenant": "rule:restrict_wildcard",
           "update_rbac_policy": "rule:admin_or_owner",
           "update_rbac_policy:target_tenant": "rule:restrict_wildcard and rule:admin_or_owner",
           "get_rbac_policy": "rule:admin_or_owner",
           "delete_rbac_policy": "rule:admin_or_owner"
        }
      '';
    };

    environment.etc."neutron/rootwrap.conf" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [DEFAULT]
        filters_path=/etc/neutron/rootwrap.d
        exec_dirs=/run/current-system/sw/bin,/run/current-system/sw/sbin,/var/setuid-wrappers
        use_syslog=True
        syslog_log_facility=syslog
        syslog_log_level=DEBUG

        [xenapi]
        xenapi_connection_url=<None>
        xenapi_connection_username=root
        xenapi_connection_password=<None>
      '';
    };

    environment.etc."neutron/plugins/ml2/linuxbridge_agent.ini" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [linux_bridge]
        physical_interface_mappings = ${concatStringsSep ", " cfg.physicalInterfaceMappings}

        [vxlan]
        enable_vxlan = True
        local_ip = ${cfg.vxlanLocalIp}
        l2_population = True

        [agent]

        [securitygroup]
        firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
        enable_security_group = True
      '';
    };

    environment.etc."neutron/plugins/ml2/ml2_conf.ini" = {
      enable = true;
      uid = 260;
      gid = 260;
      mode = "0440";
      text = ''
        [ml2]
        type_drivers = flat,vlan,vxlan,local
        tenant_network_types = vxlan,local
        mechanism_drivers = linuxbridge,l2population
        extension_drivers = port_security

        [ml2_type_flat]
        flat_networks = ${concatStringsSep ", " cfg.flatNetworks}

        [ml2_type_vlan]

        [ml2_type_gre]

        [ml2_type_vxlan]
        vni_ranges = 1:1000

        [ml2_type_geneve]

        [securitygroup]
        enable_ipset = True
      '';
    };

    environment.etc."neutron/rootwrap.d/conntrack.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        conntrack: CommandFilter, conntrack, root
      '';
    };

    environment.etc."neutron/rootwrap.d/debug.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        ping: RegExpFilter, ping, root, ping, -w, \d+, -c, \d+, [0-9\.]+
        ping_alt: RegExpFilter, ping, root, ping, -c, \d+, -w, \d+, [0-9\.]+
        ping6: RegExpFilter, ping6, root, ping6, -w, \d+, -c, \d+, [0-9A-Fa-f:]+
        ping6_alt: RegExpFilter, ping6, root, ping6, -c, \d+, -w, \d+, [0-9A-Fa-f:]+
      '';
    };

    environment.etc."neutron/rootwrap.d/dhcp.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        ip_exec: IpNetnsExecFilter, ip, root
        dnsmasq: CommandFilter, dnsmasq, root
        kill_dnsmasq: KillFilter, root, ${pkgs.dnsmasq}/bin/dnsmasq, -9, -HUP
        kill_dnsmasq_usr: KillFilter, root, ${pkgs.dnsmasq}/bin/dnsmasq, -9, -HUP

        ovs-vsctl: CommandFilter, ovs-vsctl, root
        ivs-ctl: CommandFilter, ivs-ctl, root
        mm-ctl: CommandFilter, mm-ctl, root
        dhcp_release: CommandFilter, dhcp_release, root

        metadata_proxy: CommandFilter, neutron-ns-metadata-proxy, root
        kill_metadata: KillFilter, root, python, -9
        kill_metadata7: KillFilter, root, python2.7, -9

        ip: IpFilter, ip, root
        find: RegExpFilter, find, root, find, /sys/class/net, -maxdepth, 1, -type, l, -printf, %.*
      '';
    };

    environment.etc."neutron/rootwrap.d/ebtables.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        ebtables: CommandFilter, ebtables, root
      '';
    };

    environment.etc."neutron/rootwrap.d/ipset-firewall.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        ipset: CommandFilter, ipset, root
      '';
    };

    environment.etc."neutron/rootwrap.d/iptables-firewall.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        iptables-save: CommandFilter, iptables-save, root
        iptables-restore: CommandFilter, iptables-restore, root
        ip6tables-save: CommandFilter, ip6tables-save, root
        ip6tables-restore: CommandFilter, ip6tables-restore, root

        iptables: CommandFilter, iptables, root
        ip6tables: CommandFilter, ip6tables, root
      '';
    };

    environment.etc."neutron/rootwrap.d/l3.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        arping: CommandFilter, arping, root

        sysctl: CommandFilter, sysctl, root
        route: CommandFilter, route, root
        radvd: CommandFilter, radvd, root

        metadata_proxy: CommandFilter, neutron-ns-metadata-proxy, root
        kill_metadata: KillFilter, root, python, -9
        kill_metadata7: KillFilter, root, python2.7, -9
        kill_radvd_usr: KillFilter, root, /usr/sbin/radvd, -9, -HUP
        kill_radvd: KillFilter, root, /sbin/radvd, -9, -HUP

        ip: IpFilter, ip, root
        find: RegExpFilter, find, root, find, /sys/class/net, -maxdepth, 1, -type, l, -printf, %.*
        ip_exec: IpNetnsExecFilter, ip, root

        kill_ip_monitor: KillFilter, root, ip, -9

        ovs-vsctl: CommandFilter, ovs-vsctl, root

        iptables-save: CommandFilter, iptables-save, root
        iptables-restore: CommandFilter, iptables-restore, root
        ip6tables-save: CommandFilter, ip6tables-save, root
        ip6tables-restore: CommandFilter, ip6tables-restore, root

        keepalived: CommandFilter, keepalived, root
        kill_keepalived: KillFilter, root, /usr/sbin/keepalived, -HUP, -15, -9

        conntrack: CommandFilter, conntrack, root

        keepalived_state_change: CommandFilter, neutron-keepalived-state-change, root
      '';
    };

    environment.etc."neutron/rootwrap.d/linuxbridge-plugin.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        [Filters]
        ip_exec: IpNetnsExecFilter, ip, root

        brctl: CommandFilter, brctl, root
        bridge: CommandFilter, bridge, root

        ip: IpFilter, ip, root
        find: RegExpFilter, find, root, find, /sys/class/net, -maxdepth, 1, -type, l, -printf, %.*
      '';
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
            chmod 0755 /var/lib/neutron
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

            chmod 0755 /var/lib/neutron
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

      } else if cfg.nodeType == "compute" then {
        services.neutron-linuxbridge-agent = neutron-linuxbridge-agent;
      } else if cfg.nodeType == "custom" then (
        (if cfg.enableServer == true then {
          services.neutron-server = neutron-server;
        } else {
          ##DO NOTHING
        })

        (if cfg.enableLinuxbridgeAgent == true then {
          services.neutron-linuxbridge-agent = neutron-linuxbridge-agent;
        } else {
          ##DO NOTHING
        })

        (if cfg.enableDhcpAgent == true then {
          services.neutron-dhcp-agent = neutron-dhcp-agent;
        } else {
          ##DO NOTHING
        })

        (if cfg.enableMetadataAgent == true then {
          services.neutron-metadata-agent = neutron-linuxbridge-agent;
        } else {
          ##DO NOTHING
        })

        (if cfg.enableL3Agent == true then {
          services.neutron-l3-agent = neutron-l3-agent;
        } else {
          ##DO NOTHING
        })
      ) else {
        ##UNREACHABLE
      }
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
