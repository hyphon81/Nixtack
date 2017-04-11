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

      nodeType = mkOption {
        type = types.enum ["control" "compute"];
        default = "control";
        description = ''
          OpenStack Compute Service node type.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          # Set keymap
          vnc_keymap = ja
          # PCI passthrough whitelist
          pci_passthrough_whitelist=[{ "vendor_id":"10de", "product_id":"1380"}, { "vendor_id":"10de", "product_id":"0fbc"}]
          # PCI alias
          pci_alias={"vendor_id":"10de", "product_id":"1380", "name":"GTX750Ti"}
          pci_alias={"vendor_id":"10de", "product_id":"0fbc", "name":"GTX750Ti-sound"}
        '';
        description = ''
          Provide extra config to the OpenStack Nova [DEFAULT] configuration.
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

      myIp = mkOption {
        type = types.str;
        default = "";
        description = ''
          The ip address of this node.
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
        default = "nova";
        description = ''
          This is the name of the nova service user.
        '';
      };

      servicePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the nova service.
        '';
      };

      regionType = mkOption {
        type = types.str;
        default = "RegionOne";
        description = ''
          The OpenStack region type name.
        '';
      };

      neutronProjectName = mkOption {
        type = types.str;
        default = "service";
        description = ''
          This is the OpenStack neutron project name.
        '';
      };

      neutronServiceUser = mkOption {
        type = types.str;
        default = "nova";
        description = ''
          This is the name of the neutronservice user.
        '';
      };

      neutronServicePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the neutron service.
        '';
      };

      databaseUser = mkOption {
        type = types.str;
        default = "nova";
        description = ''
          This is the name of the nova and nova-api database user.
        '';
      };

      databasePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the nova and nova-api database.
        '';
      };

      novaDatabaseName = mkOption {
        type = types.str;
        default = "nova";
        description = ''
          This is the name of the nova database.
        '';
      };

      novaApiDatabaseName = mkOption {
        type = types.str;
        default = "nova-api";
        description = ''
          This is the name of the nova-api database.
        '';
      };

      databaseServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the database server.
        '';
      };

      keystoneServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the keystone server.
        '';
      };

      glanceServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the glance server.
        '';
      };

      neutronServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the neutron server.
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

      vncFrontend = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the node provide vnc front end.
        '';
      };

      enableApi = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables nova-api daemon.
        '';
      };

      enableCompute = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables nova-compute daemon.
        '';
      };

      enableConductor = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables nova-conductor daemon.
        '';
      };

      enableConsoleauth = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables nova-consoleauth daemon.
        '';
      };

      enableNovncproxy = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables nova-novncproxy daemon.
        '';
      };

      enableScheduler = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          This option enables nova-scheduler daemon.
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
      uid = 261;
    };

    users.extraGroups.nova.gid = 261;

    # Enable sudo
    security.sudo = {
      enable = true;
      extraConfig = ''
        nova ALL=(root) NOPASSWD: /run/current-system/sw/bin/nova-rootwrap /etc/nova/rootwrap.conf *
      '';
    };

    environment.etc."nova/api-paste.ini" = {
      enable = true;
      uid = 261;
      gid = 261;
      mode = "0440";
      text = ''
        ############
        # Metadata #
        ############
        [composite:metadata]
        use = egg:Paste#urlmap
        /: meta

        [pipeline:meta]
        pipeline = cors metaapp

        [app:metaapp]
        paste.app_factory = nova.api.metadata.handler:MetadataRequestHandler.factory

        #############
        # OpenStack #
        #############

        [composite:osapi_compute]
        use = call:nova.api.openstack.urlmap:urlmap_factory
        /: oscomputeversions
        # v21 is an exactly feature match for v2, except it has more stringent
        # input validation on the wsgi surface (prevents fuzzing early on the
        # API). It also provides new features via API microversions which are
        # opt into for clients. Unaware clients will receive the same frozen
        # v2 API feature set, but with some relaxed validation
        /v2: openstack_compute_api_v21_legacy_v2_compatible
        /v2.1: openstack_compute_api_v21

        [composite:openstack_compute_api_v21]
        use = call:nova.api.auth:pipeline_factory_v21
        noauth2 = cors http_proxy_to_wsgi compute_req_id faultwrap sizelimit noauth2 osapi_compute_app_v21
        keystone = cors http_proxy_to_wsgi compute_req_id faultwrap sizelimit authtoken keystonecontext osapi_compute_app_v21

        [composite:openstack_compute_api_v21_legacy_v2_compatible]
        use = call:nova.api.auth:pipeline_factory_v21
        noauth2 = cors http_proxy_to_wsgi compute_req_id faultwrap sizelimit noauth2 legacy_v2_compatible osapi_compute_app_v21
        keystone = cors http_proxy_to_wsgi compute_req_id faultwrap sizelimit authtoken keystonecontext legacy_v2_compatible osapi_compute_app_v21

        [filter:request_id]
        paste.filter_factory = oslo_middleware:RequestId.factory

        [filter:compute_req_id]
        paste.filter_factory = nova.api.compute_req_id:ComputeReqIdMiddleware.factory

        [filter:faultwrap]
        paste.filter_factory = nova.api.openstack:FaultWrapper.factory

        [filter:noauth2]
        paste.filter_factory = nova.api.openstack.auth:NoAuthMiddleware.factory

        [filter:sizelimit]
        paste.filter_factory = oslo_middleware:RequestBodySizeLimiter.factory

        [filter:http_proxy_to_wsgi]
        paste.filter_factory = oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory

        [filter:legacy_v2_compatible]
        paste.filter_factory = nova.api.openstack:LegacyV2CompatibleWrapper.factory

        [app:osapi_compute_app_v21]
        paste.app_factory = nova.api.openstack.compute:APIRouterV21.factory

        [pipeline:oscomputeversions]
        pipeline = faultwrap http_proxy_to_wsgi oscomputeversionapp

        [app:oscomputeversionapp]
        paste.app_factory = nova.api.openstack.compute.versions:Versions.factory

        ##########
        # Shared #
        ##########

        [filter:cors]
        paste.filter_factory = oslo_middleware.cors:filter_factory
        oslo_config_project = nova

        [filter:keystonecontext]
        paste.filter_factory = nova.api.auth:NovaKeystoneContext.factory

        [filter:authtoken]
        paste.filter_factory = keystonemiddleware.auth_token:filter_factory
      '';
    };

    environment.etc."nova/logging.conf" = {
      enable = true;
      uid = 261;
      gid = 261;
      mode = "0440";
      text = ''
        [loggers]
        keys = root, nova

        [handlers]
        keys = stderr, stdout, watchedfile, syslog, null

        [formatters]
        keys = context, default

        [logger_root]
        level = WARNING
        handlers = null

        [logger_nova]
        level = INFO
        handlers = stderr
        qualname = nova

        [logger_amqp]
        level = WARNING
        handlers = stderr
        qualname = amqp

        [logger_amqplib]
        level = WARNING
        handlers = stderr
        qualname = amqplib

        [logger_sqlalchemy]
        level = WARNING
        handlers = stderr
        qualname = sqlalchemy
        # "level = INFO" logs SQL queries.
        # "level = DEBUG" logs SQL queries and results.
        # "level = WARNING" logs neither.  (Recommended for production systems.)

        [logger_boto]
        level = WARNING
        handlers = stderr
        qualname = boto

        # NOTE(mikal): suds is used by the vmware driver, removing this will
        # cause many extraneous log lines for their tempest runs. Refer to
        # https://review.openstack.org/#/c/219225/ for details.
        [logger_suds]
        level = INFO
        handlers = stderr
        qualname = suds

        [logger_eventletwsgi]
        level = WARNING
        handlers = stderr
        qualname = eventlet.wsgi.server

        [handler_stderr]
        class = StreamHandler
        args = (sys.stderr,)
        formatter = context

        [handler_stdout]
        class = StreamHandler
        args = (sys.stdout,)
        formatter = context

        [handler_watchedfile]
        class = handlers.WatchedFileHandler
        args = ('nova.log',)
        formatter = context

        [handler_syslog]
        class = handlers.SysLogHandler
        args = ('/dev/log', handlers.SysLogHandler.LOG_USER)
        formatter = context

        [handler_null]
        class = logging.NullHandler
        formatter = default
        args = ()

        [formatter_context]
        class = oslo_log.formatters.ContextFormatter

        [formatter_default]
        format = %(message)s
      '';
    };

    environment.etc."nova/nova-compute.conf" = {
      enable = true;
      uid = 261;
      gid = 261;
      mode = "0440";
      text = ''
        [DEFAULT]
        compute_driver=libvirt.LibvirtDriver
        [libvirt]
        virt_type=kvm
      '';
    };

    environment.etc."nova/nova.conf" = {
      enable = true;
      uid = 261;
      gid = 261;
      mode = "0440";
      text = ''
        [DEFAULT]
        dhcpbridge_flagfile = /etc/nova/nova.conf
        dhcpbridge = /run/current-system/sw/bin/nova-dhcpbridge
        log-dir = /var/lib/nova/log
        state_path = /var/lib/nova
        force_dhcp_release = True
        debug = True
        ec2_private_dns_show_ip = True
        enabled_apis = osapi_compute,metadata
        transport_url = rabbit://${cfg.rabbitMQUser}:${cfg.rabbitMQPassword}@${cfg.rabbitMQServer}
        auth_strategy = keystone
        my_ip = ${cfg.myIp}
        use_neutron = True
        firewall_driver = nova.virt.firewall.NoopFirewallDriver

        ${cfg.extraConfig}

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
        connection = mysql+pymysql://${cfg.databaseUser}:${cfg.databasePassword}@${cfg.databaseServer}/${cfg.novaDatabaseName}

        [api_database]
        connection = mysql+pymysql://${cfg.databaseUser}:${cfg.databasePassword}@${cfg.databaseServer}/${cfg.novaApiDatabaseName}

        [oslo_concurrency]
        lock_path = /var/lock/nova

        [libvirt]
        use_virtio_for_bridges = True

        [wsgi]
        api_paste_config=/etc/nova/api-paste.ini

        [vnc]
        vncserver_listen = $my_ip
        vncserver_proxyclient_address = $my_ip

        enabled = True
        vncserver_listen = 0.0.0.0
        novncproxy_base_url = http://${cfg.vncFrontend}:6080/vnc_auto.html

        [glance]
        api_servers = http://${cfg.glanceServer}:9292
        use_glance_v1 = False
        debug = True

        [neutron]
        url = http://${cfg.neutronServer}:9696
        auth_url = http://${cfg.keystoneServer}:35357
        auth_type = password
        project_domain_name = ${cfg.projectDomainName}
        user_domain_name = ${cfg.userDomainName}
        region_name = ${cfg.regionType}
        project_name = ${cfg.neutronProjectName}
        username = ${cfg.neutronServiceUser}
        password = ${cfg.neutronServicePassword}
        service_metadata_proxy = True
        metadata_proxy_shared_secret = ${cfg.sharedSecret}

        [oslo_concurrency]
        lock_path = /var/lib/nova/tmp
      '';
    };

    environment.etc."nova/policy.json" = {
      enable = true;
      uid = 261;
      gid = 261;
      mode = "0440";
      text = ''
        {
           "context_is_admin":  "role:admin",
           "admin_or_owner":  "is_admin:True or project_id:%(project_id)s",
           "default": "rule:admin_or_owner",

           "cells_scheduler_filter:TargetCellFilter": "is_admin:True",

           "compute:create": "",
           "compute:create:attach_network": "",
           "compute:create:attach_volume": "",
           "compute:create:forced_host": "is_admin:True",

           "compute:get": "",
           "compute:get_all": "",
           "compute:get_all_tenants": "is_admin:True",

           "compute:update": "",

           "compute:get_instance_metadata": "",
           "compute:get_all_instance_metadata": "",
           "compute:get_all_instance_system_metadata": "",
           "compute:update_instance_metadata": "",
           "compute:delete_instance_metadata": "",

           "compute:get_instance_faults": "",
           "compute:get_diagnostics": "",
           "compute:get_instance_diagnostics": "",

           "compute:start": "rule:admin_or_owner",
           "compute:stop": "rule:admin_or_owner",

           "compute:get_lock": "",
           "compute:lock": "",
           "compute:unlock": "",
           "compute:unlock_override": "rule:admin_api",

           "compute:get_vnc_console": "",
           "compute:get_spice_console": "",
           "compute:get_rdp_console": "",
           "compute:get_serial_console": "",
           "compute:get_mks_console": "",
           "compute:get_console_output": "",

           "compute:reset_network": "",
           "compute:inject_network_info": "",
           "compute:add_fixed_ip": "",
           "compute:remove_fixed_ip": "",

           "compute:attach_volume": "",
           "compute:detach_volume": "",
           "compute:swap_volume": "",

           "compute:attach_interface": "",
           "compute:detach_interface": "",

           "compute:set_admin_password": "",

           "compute:rescue": "",
           "compute:unrescue": "",

           "compute:suspend": "",
           "compute:resume": "",

           "compute:pause": "",
           "compute:unpause": "",

           "compute:shelve": "",
           "compute:shelve_offload": "",
           "compute:unshelve": "",

           "compute:snapshot": "",
           "compute:snapshot_volume_backed": "",
           "compute:backup": "",

           "compute:resize": "",
           "compute:confirm_resize": "",
           "compute:revert_resize": "",

           "compute:rebuild": "",
           "compute:reboot": "",
           "compute:delete": "rule:admin_or_owner",
           "compute:soft_delete": "rule:admin_or_owner",
           "compute:force_delete": "rule:admin_or_owner",

           "compute:security_groups:add_to_instance": "",
           "compute:security_groups:remove_from_instance": "",

           "compute:delete": "",
           "compute:soft_delete": "",
           "compute:force_delete": "",
           "compute:restore": "",

           "compute:volume_snapshot_create": "",
           "compute:volume_snapshot_delete": "",

           "admin_api": "is_admin:True",
           "compute_extension:accounts": "rule:admin_api",
           "compute_extension:admin_actions": "rule:admin_api",
           "compute_extension:admin_actions:pause": "rule:admin_or_owner",
           "compute_extension:admin_actions:unpause": "rule:admin_or_owner",
           "compute_extension:admin_actions:suspend": "rule:admin_or_owner",
           "compute_extension:admin_actions:resume": "rule:admin_or_owner",
           "compute_extension:admin_actions:lock": "rule:admin_or_owner",
           "compute_extension:admin_actions:unlock": "rule:admin_or_owner",
           "compute_extension:admin_actions:resetNetwork": "rule:admin_api",
           "compute_extension:admin_actions:injectNetworkInfo": "rule:admin_api",
           "compute_extension:admin_actions:createBackup": "rule:admin_or_owner",
           "compute_extension:admin_actions:migrateLive": "rule:admin_api",
           "compute_extension:admin_actions:resetState": "rule:admin_api",
           "compute_extension:admin_actions:migrate": "rule:admin_api",
           "compute_extension:aggregates": "rule:admin_api",
           "compute_extension:agents": "rule:admin_api",
           "compute_extension:attach_interfaces": "",
           "compute_extension:baremetal_nodes": "rule:admin_api",
           "compute_extension:cells": "rule:admin_api",
           "compute_extension:cells:create": "rule:admin_api",
           "compute_extension:cells:delete": "rule:admin_api",
           "compute_extension:cells:update": "rule:admin_api",
           "compute_extension:cells:sync_instances": "rule:admin_api",
           "compute_extension:certificates": "",
           "compute_extension:cloudpipe": "rule:admin_api",
           "compute_extension:cloudpipe_update": "rule:admin_api",
           "compute_extension:config_drive": "",
           "compute_extension:console_output": "",
           "compute_extension:consoles": "",
           "compute_extension:createserverext": "",
           "compute_extension:deferred_delete": "",
           "compute_extension:disk_config": "",
           "compute_extension:evacuate": "rule:admin_api",
           "compute_extension:extended_server_attributes": "rule:admin_api",
           "compute_extension:extended_status": "",
           "compute_extension:extended_availability_zone": "",
           "compute_extension:extended_ips": "",
           "compute_extension:extended_ips_mac": "",
           "compute_extension:extended_vif_net": "",
           "compute_extension:extended_volumes": "",
           "compute_extension:fixed_ips": "rule:admin_api",
           "compute_extension:flavor_access": "",
           "compute_extension:flavor_access:addTenantAccess": "rule:admin_api",
           "compute_extension:flavor_access:removeTenantAccess": "rule:admin_api",
           "compute_extension:flavor_disabled": "",
           "compute_extension:flavor_rxtx": "",
           "compute_extension:flavor_swap": "",
           "compute_extension:flavorextradata": "",
           "compute_extension:flavorextraspecs:index": "",
           "compute_extension:flavorextraspecs:show": "",
           "compute_extension:flavorextraspecs:create": "rule:admin_api",
           "compute_extension:flavorextraspecs:update": "rule:admin_api",
           "compute_extension:flavorextraspecs:delete": "rule:admin_api",
           "compute_extension:flavormanage": "rule:admin_api",
           "compute_extension:floating_ip_dns": "",
           "compute_extension:floating_ip_pools": "",
           "compute_extension:floating_ips": "",
           "compute_extension:floating_ips_bulk": "rule:admin_api",
           "compute_extension:fping": "",
           "compute_extension:fping:all_tenants": "rule:admin_api",
           "compute_extension:hide_server_addresses": "is_admin:False",
           "compute_extension:hosts": "rule:admin_api",
           "compute_extension:hypervisors": "rule:admin_api",
           "compute_extension:image_size": "",
           "compute_extension:instance_actions": "",
           "compute_extension:instance_actions:events": "rule:admin_api",
           "compute_extension:instance_usage_audit_log": "rule:admin_api",
           "compute_extension:keypairs": "",
           "compute_extension:keypairs:index": "",
           "compute_extension:keypairs:show": "",
           "compute_extension:keypairs:create": "",
           "compute_extension:keypairs:delete": "",
           "compute_extension:multinic": "",
           "compute_extension:networks": "rule:admin_api",
           "compute_extension:networks:view": "",
           "compute_extension:networks_associate": "rule:admin_api",
           "compute_extension:os-tenant-networks": "",
           "compute_extension:quotas:show": "",
           "compute_extension:quotas:update": "rule:admin_api",
           "compute_extension:quotas:delete": "rule:admin_api",
           "compute_extension:quota_classes": "",
           "compute_extension:rescue": "",
           "compute_extension:security_group_default_rules": "rule:admin_api",
           "compute_extension:security_groups": "",
           "compute_extension:server_diagnostics": "rule:admin_api",
           "compute_extension:server_groups": "",
           "compute_extension:server_password": "",
           "compute_extension:server_usage": "",
           "compute_extension:services": "rule:admin_api",
           "compute_extension:shelve": "",
           "compute_extension:shelveOffload": "rule:admin_api",
           "compute_extension:simple_tenant_usage:show": "rule:admin_or_owner",
           "compute_extension:simple_tenant_usage:list": "rule:admin_api",
           "compute_extension:unshelve": "",
           "compute_extension:users": "rule:admin_api",
           "compute_extension:virtual_interfaces": "",
           "compute_extension:virtual_storage_arrays": "",
           "compute_extension:volumes": "",
           "compute_extension:volume_attachments:index": "",
           "compute_extension:volume_attachments:show": "",
           "compute_extension:volume_attachments:create": "",
           "compute_extension:volume_attachments:update": "",
           "compute_extension:volume_attachments:delete": "",
           "compute_extension:volumetypes": "",
           "compute_extension:availability_zone:list": "",
           "compute_extension:availability_zone:detail": "rule:admin_api",
           "compute_extension:used_limits_for_admin": "rule:admin_api",
           "compute_extension:migrations:index": "rule:admin_api",
           "compute_extension:os-assisted-volume-snapshots:create": "rule:admin_api",
           "compute_extension:os-assisted-volume-snapshots:delete": "rule:admin_api",
           "compute_extension:console_auth_tokens": "rule:admin_api",
           "compute_extension:os-server-external-events:create": "rule:admin_api",

           "network:get_all": "",
           "network:get": "",
           "network:create": "",
           "network:delete": "",
           "network:associate": "",
           "network:disassociate": "",
           "network:get_vifs_by_instance": "",
           "network:allocate_for_instance": "",
           "network:deallocate_for_instance": "",
           "network:validate_networks": "",
           "network:get_instance_uuids_by_ip_filter": "",
           "network:get_instance_id_by_floating_address": "",
           "network:setup_networks_on_host": "",
           "network:get_backdoor_port": "",

           "network:get_floating_ip": "",
           "network:get_floating_ip_pools": "",
           "network:get_floating_ip_by_address": "",
           "network:get_floating_ips_by_project": "",
           "network:get_floating_ips_by_fixed_address": "",
           "network:allocate_floating_ip": "",
           "network:associate_floating_ip": "",
           "network:disassociate_floating_ip": "",
           "network:release_floating_ip": "",
           "network:migrate_instance_start": "",
           "network:migrate_instance_finish": "",

           "network:get_fixed_ip": "",
           "network:get_fixed_ip_by_address": "",
           "network:add_fixed_ip_to_instance": "",
           "network:remove_fixed_ip_from_instance": "",
           "network:add_network_to_project": "",
           "network:get_instance_nw_info": "",

           "network:get_dns_domains": "",
           "network:add_dns_entry": "",
           "network:modify_dns_entry": "",
           "network:delete_dns_entry": "",
           "network:get_dns_entries_by_address": "",
           "network:get_dns_entries_by_name": "",
           "network:create_private_dns_domain": "",
           "network:create_public_dns_domain": "",
           "network:delete_dns_domain": "",
           "network:attach_external_network": "rule:admin_api",
           "network:get_vif_by_mac_address": "",

           "os_compute_api:servers:detail:get_all_tenants": "is_admin:True",
           "os_compute_api:servers:index:get_all_tenants": "is_admin:True",
           "os_compute_api:servers:confirm_resize": "",
           "os_compute_api:servers:create": "",
           "os_compute_api:servers:create:attach_network": "",
           "os_compute_api:servers:create:attach_volume": "",
           "os_compute_api:servers:create:forced_host": "rule:admin_api",
           "os_compute_api:servers:delete": "",
           "os_compute_api:servers:update": "",
           "os_compute_api:servers:detail": "",
           "os_compute_api:servers:index": "",
           "os_compute_api:servers:reboot": "",
           "os_compute_api:servers:rebuild": "",
           "os_compute_api:servers:resize": "",
           "os_compute_api:servers:revert_resize": "",
           "os_compute_api:servers:show": "",
           "os_compute_api:servers:create_image": "",
           "os_compute_api:servers:create_image:allow_volume_backed": "",
           "os_compute_api:servers:start": "rule:admin_or_owner",
           "os_compute_api:servers:stop": "rule:admin_or_owner",
           "os_compute_api:os-access-ips:discoverable": "",
           "os_compute_api:os-access-ips": "",
           "os_compute_api:os-admin-actions": "rule:admin_api",
           "os_compute_api:os-admin-actions:discoverable": "",
           "os_compute_api:os-admin-actions:reset_network": "rule:admin_api",
           "os_compute_api:os-admin-actions:inject_network_info": "rule:admin_api",
           "os_compute_api:os-admin-actions:reset_state": "rule:admin_api",
           "os_compute_api:os-admin-password": "",
           "os_compute_api:os-admin-password:discoverable": "",
           "os_compute_api:os-aggregates:discoverable": "",
           "os_compute_api:os-aggregates:index": "rule:admin_api",
           "os_compute_api:os-aggregates:create": "rule:admin_api",
           "os_compute_api:os-aggregates:show": "rule:admin_api",
           "os_compute_api:os-aggregates:update": "rule:admin_api",
           "os_compute_api:os-aggregates:delete": "rule:admin_api",
           "os_compute_api:os-aggregates:add_host": "rule:admin_api",
           "os_compute_api:os-aggregates:remove_host": "rule:admin_api",
           "os_compute_api:os-aggregates:set_metadata": "rule:admin_api",
           "os_compute_api:os-agents": "rule:admin_api",
           "os_compute_api:os-agents:discoverable": "",
           "os_compute_api:os-attach-interfaces": "",
           "os_compute_api:os-attach-interfaces:discoverable": "",
           "os_compute_api:os-baremetal-nodes": "rule:admin_api",
           "os_compute_api:os-baremetal-nodes:discoverable": "",
           "os_compute_api:os-block-device-mapping-v1:discoverable": "",
           "os_compute_api:os-cells": "rule:admin_api",
           "os_compute_api:os-cells:create": "rule:admin_api",
           "os_compute_api:os-cells:delete": "rule:admin_api",
           "os_compute_api:os-cells:update": "rule:admin_api",
           "os_compute_api:os-cells:sync_instances": "rule:admin_api",
           "os_compute_api:os-cells:discoverable": "",
           "os_compute_api:os-certificates:create": "",
           "os_compute_api:os-certificates:show": "",
           "os_compute_api:os-certificates:discoverable": "",
           "os_compute_api:os-cloudpipe": "rule:admin_api",
           "os_compute_api:os-cloudpipe:discoverable": "",
           "os_compute_api:os-config-drive": "",
           "os_compute_api:os-consoles:discoverable": "",
           "os_compute_api:os-consoles:create": "",
           "os_compute_api:os-consoles:delete": "",
           "os_compute_api:os-consoles:index": "",
           "os_compute_api:os-consoles:show": "",
           "os_compute_api:os-console-output:discoverable": "",
           "os_compute_api:os-console-output": "",
           "os_compute_api:os-remote-consoles": "",
           "os_compute_api:os-remote-consoles:discoverable": "",
           "os_compute_api:os-create-backup:discoverable": "",
           "os_compute_api:os-create-backup": "rule:admin_or_owner",
           "os_compute_api:os-deferred-delete": "",
           "os_compute_api:os-deferred-delete:discoverable": "",
           "os_compute_api:os-disk-config": "",
           "os_compute_api:os-disk-config:discoverable": "",
           "os_compute_api:os-evacuate": "rule:admin_api",
           "os_compute_api:os-evacuate:discoverable": "",
           "os_compute_api:os-extended-server-attributes": "rule:admin_api",
           "os_compute_api:os-extended-server-attributes:discoverable": "",
           "os_compute_api:os-extended-status": "",
           "os_compute_api:os-extended-status:discoverable": "",
           "os_compute_api:os-extended-availability-zone": "",
           "os_compute_api:os-extended-availability-zone:discoverable": "",
           "os_compute_api:extensions": "",
           "os_compute_api:extension_info:discoverable": "",
           "os_compute_api:os-extended-volumes": "",
           "os_compute_api:os-extended-volumes:discoverable": "",
           "os_compute_api:os-fixed-ips": "rule:admin_api",
           "os_compute_api:os-fixed-ips:discoverable": "",
           "os_compute_api:os-flavor-access": "",
           "os_compute_api:os-flavor-access:discoverable": "",
           "os_compute_api:os-flavor-access:remove_tenant_access": "rule:admin_api",
           "os_compute_api:os-flavor-access:add_tenant_access": "rule:admin_api",
           "os_compute_api:os-flavor-rxtx": "",
           "os_compute_api:os-flavor-rxtx:discoverable": "",
           "os_compute_api:flavors:discoverable": "",
           "os_compute_api:os-flavor-extra-specs:discoverable": "",
           "os_compute_api:os-flavor-extra-specs:index": "",
           "os_compute_api:os-flavor-extra-specs:show": "",
           "os_compute_api:os-flavor-extra-specs:create": "rule:admin_api",
           "os_compute_api:os-flavor-extra-specs:update": "rule:admin_api",
           "os_compute_api:os-flavor-extra-specs:delete": "rule:admin_api",
           "os_compute_api:os-flavor-manage:discoverable": "",
           "os_compute_api:os-flavor-manage": "rule:admin_api",
           "os_compute_api:os-floating-ip-dns": "",
           "os_compute_api:os-floating-ip-dns:discoverable": "",
           "os_compute_api:os-floating-ip-dns:domain:update": "rule:admin_api",
           "os_compute_api:os-floating-ip-dns:domain:delete": "rule:admin_api",
           "os_compute_api:os-floating-ip-pools": "",
           "os_compute_api:os-floating-ip-pools:discoverable": "",
           "os_compute_api:os-floating-ips": "",
           "os_compute_api:os-floating-ips:discoverable": "",
           "os_compute_api:os-floating-ips-bulk": "rule:admin_api",
           "os_compute_api:os-floating-ips-bulk:discoverable": "",
           "os_compute_api:os-fping": "",
           "os_compute_api:os-fping:discoverable": "",
           "os_compute_api:os-fping:all_tenants": "rule:admin_api",
           "os_compute_api:os-hide-server-addresses": "is_admin:False",
           "os_compute_api:os-hide-server-addresses:discoverable": "",
           "os_compute_api:os-hosts": "rule:admin_api",
           "os_compute_api:os-hosts:discoverable": "",
           "os_compute_api:os-hypervisors": "rule:admin_api",
           "os_compute_api:os-hypervisors:discoverable": "",
           "os_compute_api:images:discoverable": "",
           "os_compute_api:image-size": "",
           "os_compute_api:image-size:discoverable": "",
           "os_compute_api:os-instance-actions": "",
           "os_compute_api:os-instance-actions:discoverable": "",
           "os_compute_api:os-instance-actions:events": "rule:admin_api",
           "os_compute_api:os-instance-usage-audit-log": "rule:admin_api",
           "os_compute_api:os-instance-usage-audit-log:discoverable": "",
           "os_compute_api:ips:discoverable": "",
           "os_compute_api:ips:index": "rule:admin_or_owner",
           "os_compute_api:ips:show": "rule:admin_or_owner",
           "os_compute_api:os-keypairs:discoverable": "",
           "os_compute_api:os-keypairs": "",
           "os_compute_api:os-keypairs:index": "rule:admin_api or user_id:%(user_id)s",
           "os_compute_api:os-keypairs:show": "rule:admin_api or user_id:%(user_id)s",
           "os_compute_api:os-keypairs:create": "rule:admin_api or user_id:%(user_id)s",
           "os_compute_api:os-keypairs:delete": "rule:admin_api or user_id:%(user_id)s",
           "os_compute_api:limits:discoverable": "",
           "os_compute_api:limits": "",
           "os_compute_api:os-lock-server:discoverable": "",
           "os_compute_api:os-lock-server:lock": "rule:admin_or_owner",
           "os_compute_api:os-lock-server:unlock": "rule:admin_or_owner",
           "os_compute_api:os-lock-server:unlock:unlock_override": "rule:admin_api",
           "os_compute_api:os-migrate-server:discoverable": "",
           "os_compute_api:os-migrate-server:migrate": "rule:admin_api",
           "os_compute_api:os-migrate-server:migrate_live": "rule:admin_api",
           "os_compute_api:os-multinic": "",
           "os_compute_api:os-multinic:discoverable": "",
           "os_compute_api:os-networks": "rule:admin_api",
           "os_compute_api:os-networks:view": "",
           "os_compute_api:os-networks:discoverable": "",
           "os_compute_api:os-networks-associate": "rule:admin_api",
           "os_compute_api:os-networks-associate:discoverable": "",
           "os_compute_api:os-pause-server:discoverable": "",
           "os_compute_api:os-pause-server:pause": "rule:admin_or_owner",
           "os_compute_api:os-pause-server:unpause": "rule:admin_or_owner",
           "os_compute_api:os-pci:pci_servers": "",
           "os_compute_api:os-pci:discoverable": "",
           "os_compute_api:os-pci:index": "rule:admin_api",
           "os_compute_api:os-pci:detail": "rule:admin_api",
           "os_compute_api:os-pci:show": "rule:admin_api",
           "os_compute_api:os-personality:discoverable": "",
           "os_compute_api:os-preserve-ephemeral-rebuild:discoverable": "",
           "os_compute_api:os-quota-sets:discoverable": "",
           "os_compute_api:os-quota-sets:show": "rule:admin_or_owner",
           "os_compute_api:os-quota-sets:defaults": "",
           "os_compute_api:os-quota-sets:update": "rule:admin_api",
           "os_compute_api:os-quota-sets:delete": "rule:admin_api",
           "os_compute_api:os-quota-sets:detail": "rule:admin_api",
           "os_compute_api:os-quota-class-sets:update": "rule:admin_api",
           "os_compute_api:os-quota-class-sets:show": "is_admin:True or quota_class:%(quota_class)s",
           "os_compute_api:os-quota-class-sets:discoverable": "",
           "os_compute_api:os-rescue": "",
           "os_compute_api:os-rescue:discoverable": "",
           "os_compute_api:os-scheduler-hints:discoverable": "",
           "os_compute_api:os-security-group-default-rules:discoverable": "",
           "os_compute_api:os-security-group-default-rules": "rule:admin_api",
           "os_compute_api:os-security-groups": "",
           "os_compute_api:os-security-groups:discoverable": "",
           "os_compute_api:os-server-diagnostics": "rule:admin_api",
           "os_compute_api:os-server-diagnostics:discoverable": "",
           "os_compute_api:os-server-password": "",
           "os_compute_api:os-server-password:discoverable": "",
           "os_compute_api:os-server-usage": "",
           "os_compute_api:os-server-usage:discoverable": "",
           "os_compute_api:os-server-groups": "",
           "os_compute_api:os-server-groups:discoverable": "",
           "os_compute_api:os-services": "rule:admin_api",
           "os_compute_api:os-services:discoverable": "",
           "os_compute_api:server-metadata:discoverable": "",
           "os_compute_api:server-metadata:index": "rule:admin_or_owner",
           "os_compute_api:server-metadata:show": "rule:admin_or_owner",
           "os_compute_api:server-metadata:delete": "rule:admin_or_owner",
           "os_compute_api:server-metadata:create": "rule:admin_or_owner",
           "os_compute_api:server-metadata:update": "rule:admin_or_owner",
           "os_compute_api:server-metadata:update_all": "rule:admin_or_owner",
           "os_compute_api:servers:discoverable": "",
           "os_compute_api:os-shelve:shelve": "",
           "os_compute_api:os-shelve:shelve:discoverable": "",
           "os_compute_api:os-shelve:shelve_offload": "rule:admin_api",
           "os_compute_api:os-simple-tenant-usage:discoverable": "",
           "os_compute_api:os-simple-tenant-usage:show": "rule:admin_or_owner",
           "os_compute_api:os-simple-tenant-usage:list": "rule:admin_api",
           "os_compute_api:os-suspend-server:discoverable": "",
           "os_compute_api:os-suspend-server:suspend": "rule:admin_or_owner",
           "os_compute_api:os-suspend-server:resume": "rule:admin_or_owner",
           "os_compute_api:os-tenant-networks": "rule:admin_or_owner",
           "os_compute_api:os-tenant-networks:discoverable": "",
           "os_compute_api:os-shelve:unshelve": "",
           "os_compute_api:os-user-data:discoverable": "",
           "os_compute_api:os-virtual-interfaces": "",
           "os_compute_api:os-virtual-interfaces:discoverable": "",
           "os_compute_api:os-volumes": "",
           "os_compute_api:os-volumes:discoverable": "",
           "os_compute_api:os-volumes-attachments:index": "",
           "os_compute_api:os-volumes-attachments:show": "",
           "os_compute_api:os-volumes-attachments:create": "",
           "os_compute_api:os-volumes-attachments:update": "",
           "os_compute_api:os-volumes-attachments:delete": "",
           "os_compute_api:os-volumes-attachments:discoverable": "",
           "os_compute_api:os-availability-zone:list": "",
           "os_compute_api:os-availability-zone:discoverable": "",
           "os_compute_api:os-availability-zone:detail": "rule:admin_api",
           "os_compute_api:os-used-limits": "rule:admin_api",
           "os_compute_api:os-used-limits:discoverable": "",
           "os_compute_api:os-migrations:index": "rule:admin_api",
           "os_compute_api:os-migrations:discoverable": "",
           "os_compute_api:os-assisted-volume-snapshots:create": "rule:admin_api",
           "os_compute_api:os-assisted-volume-snapshots:delete": "rule:admin_api",
           "os_compute_api:os-assisted-volume-snapshots:discoverable": "",
           "os_compute_api:os-console-auth-tokens": "rule:admin_api",
           "os_compute_api:os-server-external-events:create": "rule:admin_api"
        }
      '';
    };

    environment.etc."nova/rootwrap.conf" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        # Configuration for nova-rootwrap
        # This file should be owned by (and only-writeable by) the root user

        [DEFAULT]
        # List of directories to load filter definitions from (separated by ',').
        # These directories MUST all be only writeable by root !
        filters_path=/etc/nova/rootwrap.d,/usr/share/nova/rootwrap

        # List of directories to search executables in, in case filters do not
        # explicitly specify a full path (separated by ',')
        # If not specified, defaults to system PATH environment variable.
        # These directories MUST all be only writeable by root !
        exec_dirs=/bin,/usr/bin,/run/current-system/sw/bin

        # Enable logging to syslog
        # Default value is False
        use_syslog=False

        # Which syslog facility to use.
        # Valid values include auth, authpriv, syslog, local0, local1...
        # Default value is 'syslog'
        syslog_log_facility=syslog

        # Which messages to log.
        # INFO means log all usage
        # ERROR means only log unsuccessful attempts
        syslog_log_level=ERROR
      '';
    };

    environment.etc."nova/rootwrap.d/api-metadata.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        # nova-rootwrap command filters for api-metadata nodes
        # This is needed on nova-api hosts running with "metadata" in enabled_apis
        # or when running nova-api-metadata
        # This file should be owned by (and only-writeable by) the root user

        [Filters]
        # nova/network/linux_net.py: 'ip[6]tables-save' % (cmd, '-t', ...
        iptables-save: CommandFilter, iptables-save, root
        ip6tables-save: CommandFilter, ip6tables-save, root

        # nova/network/linux_net.py: 'ip[6]tables-restore' % (cmd,)
        iptables-restore: CommandFilter, iptables-restore, root
        ip6tables-restore: CommandFilter, ip6tables-restore, root
      '';
    };

    environment.etc."nova/rootwrap.d/compute.filters" = {
      enable = true;
      uid = 0;
      gid = 0;
      mode = "0440";
      text = ''
        # nova-rootwrap command filters for compute nodes
        # This file should be owned by (and only-writeable by) the root user

        [Filters]
        # nova/virt/disk/mount/api.py: 'kpartx', '-a', device
        # nova/virt/disk/mount/api.py: 'kpartx', '-d', device
        kpartx: CommandFilter, kpartx, root

        # nova/virt/xenapi/vm_utils.py: tune2fs, -O ^has_journal, part_path
        # nova/virt/xenapi/vm_utils.py: tune2fs, -j, partition_path
        tune2fs: CommandFilter, tune2fs, root

        # nova/virt/disk/mount/api.py: 'mount', mapped_device
        # nova/virt/disk/api.py: 'mount', '-o', 'bind', src, target
        # nova/virt/xenapi/vm_utils.py: 'mount', '-t', 'ext2,ext3,ext4,reiserfs'..
        # nova/virt/configdrive.py: 'mount', device, mountdir
        # nova/virt/libvirt/volume.py: 'mount', '-t', 'sofs' ...
        mount: CommandFilter, mount, root

        # nova/virt/disk/mount/api.py: 'umount', mapped_device
        # nova/virt/disk/api.py: 'umount' target
        # nova/virt/xenapi/vm_utils.py: 'umount', dev_path
        # nova/virt/configdrive.py: 'umount', mountdir
        umount: CommandFilter, umount, root

        # nova/virt/disk/mount/nbd.py: 'qemu-nbd', '-c', device, image
        # nova/virt/disk/mount/nbd.py: 'qemu-nbd', '-d', device
        qemu-nbd: CommandFilter, qemu-nbd, root

        # nova/virt/disk/mount/loop.py: 'losetup', '--find', '--show', image
        # nova/virt/disk/mount/loop.py: 'losetup', '--detach', device
        losetup: CommandFilter, losetup, root

        # nova/virt/disk/vfs/localfs.py: 'blkid', '-o', 'value', '-s', 'TYPE', device
        blkid: CommandFilter, blkid, root

        # nova/virt/libvirt/utils.py: 'blockdev', '--getsize64', path
        # nova/virt/disk/mount/nbd.py: 'blockdev', '--flushbufs', device
        blockdev: RegExpFilter, blockdev, root, blockdev, (--getsize64|--flushbufs), /dev/.*

        # nova/virt/disk/vfs/localfs.py: 'tee', canonpath
        tee: CommandFilter, tee, root

        # nova/virt/disk/vfs/localfs.py: 'mkdir', canonpath
        mkdir: CommandFilter, mkdir, root

        # nova/virt/disk/vfs/localfs.py: 'chown'
        # nova/virt/libvirt/connection.py: 'chown', os.getuid( console_log
        # nova/virt/libvirt/connection.py: 'chown', os.getuid( console_log
        # nova/virt/libvirt/connection.py: 'chown', 'root', basepath('disk')
        chown: CommandFilter, chown, root

        # nova/virt/disk/vfs/localfs.py: 'chmod'
        chmod: CommandFilter, chmod, root

        # nova/virt/libvirt/vif.py: 'ip', 'tuntap', 'add', dev, 'mode', 'tap'
        # nova/virt/libvirt/vif.py: 'ip', 'link', 'set', dev, 'up'
        # nova/virt/libvirt/vif.py: 'ip', 'link', 'delete', dev
        # nova/network/linux_net.py: 'ip', 'addr', 'add', str(floating_ip)+'/32'i..
        # nova/network/linux_net.py: 'ip', 'addr', 'del', str(floating_ip)+'/32'..
        # nova/network/linux_net.py: 'ip', 'addr', 'add', '169.254.169.254/32',..
        # nova/network/linux_net.py: 'ip', 'addr', 'show', 'dev', dev, 'scope',..
        # nova/network/linux_net.py: 'ip', 'addr', 'del/add', ip_params, dev)
        # nova/network/linux_net.py: 'ip', 'addr', 'del', params, fields[-1]
        # nova/network/linux_net.py: 'ip', 'addr', 'add', params, bridge
        # nova/network/linux_net.py: 'ip', '-f', 'inet6', 'addr', 'change', ..
        # nova/network/linux_net.py: 'ip', 'link', 'set', 'dev', dev, 'promisc',..
        # nova/network/linux_net.py: 'ip', 'link', 'add', 'link', bridge_if ...
        # nova/network/linux_net.py: 'ip', 'link', 'set', interface, address,..
        # nova/network/linux_net.py: 'ip', 'link', 'set', interface, 'up'
        # nova/network/linux_net.py: 'ip', 'link', 'set', bridge, 'up'
        # nova/network/linux_net.py: 'ip', 'addr', 'show', 'dev', interface, ..
        # nova/network/linux_net.py: 'ip', 'link', 'set', dev, address, ..
        # nova/network/linux_net.py: 'ip', 'link', 'set', dev, 'up'
        # nova/network/linux_net.py: 'ip', 'route', 'add', ..
        # nova/network/linux_net.py: 'ip', 'route', 'del', .
        # nova/network/linux_net.py: 'ip', 'route', 'show', 'dev', dev
        ip: CommandFilter, ip, root

        # nova/virt/libvirt/vif.py: 'tunctl', '-b', '-t', dev
        # nova/network/linux_net.py: 'tunctl', '-b', '-t', dev
        tunctl: CommandFilter, tunctl, root

        # nova/virt/libvirt/vif.py: 'ovs-vsctl', ...
        # nova/virt/libvirt/vif.py: 'ovs-vsctl', 'del-port', ...
        # nova/network/linux_net.py: 'ovs-vsctl', ....
        ovs-vsctl: CommandFilter, ovs-vsctl, root

        # nova/virt/libvirt/vif.py: 'vrouter-port-control', ...
        vrouter-port-control: CommandFilter, vrouter-port-control, root

        # nova/virt/libvirt/vif.py: 'ebrctl', ...
        ebrctl: CommandFilter, ebrctl, root

        # nova/virt/libvirt/vif.py: 'mm-ctl', ...
        mm-ctl: CommandFilter, mm-ctl, root

        # nova/network/linux_net.py: 'ovs-ofctl', ....
        ovs-ofctl: CommandFilter, ovs-ofctl, root

        # nova/virt/libvirt/connection.py: 'dd', if=%s % virsh_output, ...
        dd: CommandFilter, dd, root

        # nova/virt/xenapi/volume_utils.py: 'iscsiadm', '-m', ...
        iscsiadm: CommandFilter, iscsiadm, root

        # nova/virt/libvirt/volume/aoe.py: 'aoe-revalidate', aoedev
        # nova/virt/libvirt/volume/aoe.py: 'aoe-discover'
        aoe-revalidate: CommandFilter, aoe-revalidate, root
        aoe-discover: CommandFilter, aoe-discover, root

        # nova/virt/xenapi/vm_utils.py: parted, --script, ...
        # nova/virt/xenapi/vm_utils.py: 'parted', '--script', dev_path, ..*.
        parted: CommandFilter, parted, root

        # nova/virt/xenapi/vm_utils.py: 'pygrub', '-qn', dev_path
        pygrub: CommandFilter, pygrub, root

        # nova/virt/xenapi/vm_utils.py: fdisk %(dev_path)s
        fdisk: CommandFilter, fdisk, root

        # nova/virt/xenapi/vm_utils.py: e2fsck, -f, -p, partition_path
        # nova/virt/disk/api.py: e2fsck, -f, -p, image
        e2fsck: CommandFilter, e2fsck, root

        # nova/virt/xenapi/vm_utils.py: resize2fs, partition_path
        # nova/virt/disk/api.py: resize2fs, image
        resize2fs: CommandFilter, resize2fs, root

        # nova/network/linux_net.py: 'ip[6]tables-save' % (cmd, '-t', ...
        iptables-save: CommandFilter, iptables-save, root
        ip6tables-save: CommandFilter, ip6tables-save, root

        # nova/network/linux_net.py: 'ip[6]tables-restore' % (cmd,)
        iptables-restore: CommandFilter, iptables-restore, root
        ip6tables-restore: CommandFilter, ip6tables-restore, root

        # nova/network/linux_net.py: 'arping', '-U', floating_ip, '-A', '-I', ...
        # nova/network/linux_net.py: 'arping', '-U', network_ref['dhcp_server'],..
        arping: CommandFilter, arping, root

        # nova/network/linux_net.py: 'dhcp_release', dev, address, mac_address
        dhcp_release: CommandFilter, dhcp_release, root

        # nova/network/linux_net.py: 'kill', '-9', pid
        # nova/network/linux_net.py: 'kill', '-HUP', pid
        kill_dnsmasq: KillFilter, root, /usr/sbin/dnsmasq, -9, -HUP

        # nova/network/linux_net.py: 'kill', pid
        kill_radvd: KillFilter, root, /usr/sbin/radvd

        # nova/network/linux_net.py: dnsmasq call
        dnsmasq: EnvFilter, env, root, CONFIG_FILE=, NETWORK_ID=, dnsmasq

        # nova/network/linux_net.py: 'radvd', '-C', '%s' % _ra_file(dev, 'conf'..
        radvd: CommandFilter, radvd, root

        # nova/network/linux_net.py: 'brctl', 'addbr', bridge
        # nova/network/linux_net.py: 'brctl', 'setfd', bridge, 0
        # nova/network/linux_net.py: 'brctl', 'stp', bridge, 'off'
        # nova/network/linux_net.py: 'brctl', 'addif', bridge, interface
        brctl: CommandFilter, brctl, root

        # nova/virt/libvirt/utils.py: 'mkswap'
        # nova/virt/xenapi/vm_utils.py: 'mkswap'
        mkswap: CommandFilter, mkswap, root

        # nova/virt/libvirt/utils.py: 'nova-idmapshift'
        nova-idmapshift: CommandFilter, nova-idmapshift, root

        # nova/virt/xenapi/vm_utils.py: 'mkfs'
        # nova/utils.py: 'mkfs', fs, path, label
        mkfs: CommandFilter, mkfs, root

        # nova/virt/libvirt/utils.py: 'qemu-img'
        qemu-img: CommandFilter, qemu-img, root

        # nova/virt/disk/vfs/localfs.py: 'readlink', '-e'
        readlink: CommandFilter, readlink, root

        # nova/virt/disk/api.py:
        mkfs.ext3: CommandFilter, mkfs.ext3, root
        mkfs.ext4: CommandFilter, mkfs.ext4, root
        mkfs.ntfs: CommandFilter, mkfs.ntfs, root

        # nova/virt/libvirt/connection.py:
        lvremove: CommandFilter, lvremove, root

        # nova/virt/libvirt/utils.py:
        lvcreate: CommandFilter, lvcreate, root

        # nova/virt/libvirt/utils.py:
        lvs: CommandFilter, lvs, root

        # nova/virt/libvirt/utils.py:
        vgs: CommandFilter, vgs, root

        # nova/utils.py:read_file_as_root: 'cat', file_path
        # (called from nova/virt/disk/vfs/localfs.py:VFSLocalFS.read_file)
        read_passwd: RegExpFilter, cat, root, cat, (/var|/usr)?/tmp/openstack-vfs-localfs[^/]+/etc/passwd
        read_shadow: RegExpFilter, cat, root, cat, (/var|/usr)?/tmp/openstack-vfs-localfs[^/]+/etc/shadow

        # os-brick needed commands
        read_initiator: ReadFileFilter, /etc/iscsi/initiatorname.iscsi
        multipath: CommandFilter, multipath, root
        # multipathd show status
        multipathd: CommandFilter, multipathd, root
        systool: CommandFilter, systool, root
        vgc-cluster: CommandFilter, vgc-cluster, root
        # os_brick/initiator/connector.py
        drv_cfg: CommandFilter, /opt/emc/scaleio/sdc/bin/drv_cfg, root, /opt/emc/scaleio/sdc/bin/drv_cfg, --query_guid

        # TODO(smcginnis) Temporary fix.
        # Need to pull in os-brick os-brick.filters file instead and clean
        # out stale brick values from this file.
        scsi_id: CommandFilter, /lib/udev/scsi_id, root
        # os_brick.privileged.default oslo.privsep context
        # This line ties the superuser privs with the config files, context name,
        # and (implicitly) the actual python code invoked.
        privsep-rootwrap: RegExpFilter, privsep-helper, root, privsep-helper, --config-file, /etc/(?!\.\.).*, --privsep_context, os_brick.privileged.default, --privsep_sock_path, /tmp/.*

        # nova/storage/linuxscsi.py: sg_scan device
        sg_scan: CommandFilter, sg_scan, root

        # nova/volume/encryptors/cryptsetup.py:
        # nova/volume/encryptors/luks.py:
        ln: RegExpFilter, ln, root, ln, --symbolic, --force, /dev/mapper/crypt-.+, .+

        # nova/volume/encryptors.py:
        # nova/virt/libvirt/dmcrypt.py:
        cryptsetup: CommandFilter, cryptsetup, root

        # nova/virt/xenapi/vm_utils.py:
        xenstore-read: CommandFilter, xenstore-read, root

        # nova/virt/libvirt/utils.py:
        rbd: CommandFilter, rbd, root

        # nova/virt/libvirt/utils.py: 'shred', '-n3', '-s%d' % volume_size, path
        shred: CommandFilter, shred, root

        # nova/virt/libvirt/volume.py: 'cp', '/dev/stdin', delete_control..
        cp: CommandFilter, cp, root

        # nova/virt/xenapi/vm_utils.py:
        sync: CommandFilter, sync, root

        # nova/virt/libvirt/imagebackend.py:
        ploop: RegExpFilter, ploop, root, ploop, restore-descriptor, .*
        prl_disk_tool: RegExpFilter, prl_disk_tool, root, prl_disk_tool, resize, --size, .*M$, --resize_partition, --hdd, .*

        # nova/virt/libvirt/utils.py: 'xend', 'status'
        xend: CommandFilter, xend, root

        # nova/virt/libvirt/utils.py:
        touch: CommandFilter, touch, root

        # nova/virt/libvirt/volume/vzstorage.py
        pstorage-mount: CommandFilter, pstorage-mount, root
      '';
    };

    systemd = (
      let
        nova-api = {
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

        nova-compute = {
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

        nova-conductor = {
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

        nova-consoleauth = {
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

        nova-novncproxy = {
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

        nova-scheduler = {
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
      in

      if cfg.nodeType == "control" then {
        services.nova-api = nova-api;
        services.nova-compute = nova-compute;
        services.nova-conductor = nova-conductor;
        services.nova-consoleauth = nova-consoleauth;
        services.nova-novncproxy = nova-novncproxy;
        services.nova-scheduler = nova-scheduler;

      } else (if cfg.nodeType == "compute" then {
        services.nova-compute = nova-compute;

      } else {
        ##DON'T RUN
      })

      (if cfg.enableApi == true then {
        services.nova-api = nova-api;
      } else {
        ##DO NOTHING
      })

      (if cfg.enableCompute == true then {
        services.nova-compute = nova-compute;
      } else {
        ##DO NOTHING
      })

      (if cfg.enableConductor == true then {
        services.nova-api = nova-conductor;
      } else {
        ##DO NOTHING
      })

      (if cfg.enableConsoleauth == true then {
        services.nova-api = nova-consoleauth;
      } else {
        ##DO NOTHING
      })

      (if cfg.enableNovncproxy == true then {
        services.nova-novncproxy = nova-novncproxy;
      } else {
        ##DO NOTHING
      })

      (if cfg.enableScheduler == true then {
        services.nova-scheduler = nova-scheduler;
      } else {
        ##DO NOTHING
      })
    );

    networking.firewall.allowedTCPPorts = [
      8774
      6080
    ];
  };
}
