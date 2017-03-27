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

      databaseUser = mkOption {
        type = types.str;
        default = "keystone";
        description = ''
          This is the name of the keystone database user.
        '';
      };

      databasePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the keystone database.
        '';
      };

      databaseName = mkOption {
        type = types.str;
        default = "keystone";
        description = ''
          This is the name of the keystone database.
        '';
      };

      databaseServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the database server.
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

    #environment.etc."keystone/default_catalog.templates" = {
    #  enable = true;
    #  source = ./etc/default_catalog.templates;
    #  uid = 91;
    #  gid = 91;
    #  mode = "0640";
    #};
    environment.etc."keystone/keystone.conf" = {
      enable = true;
      #source = ./etc/keystone.conf;
      uid = 91;
      gid = 91;
      mode = "0640";
      text = ''
        [DEFAULT]

        [assignment]

        [auth]

        [cache]

        [catalog]

        [cors]

        [cors.subdomain]

        [credential]
        driver = sql
        provider = fernet
        key_repository = /etc/keystone/credential-keys/

        [database]
        connection = mysql+pymysql://${cfg.databaseUser}:${cfg.databasePassword}@${cfg.databaseServer}/${cfg.databaseName}
        
        [domain_config]
        
        [endpoint_filter]

        [endpoint_policy]

        [eventlet_server]

        [federation]

        [fernet_tokens]

        [identity]

        [identity_mapping]

        [kvs]

        [ldap]

        [matchmaker_redis]

        [memcache]
        
        [oauth1]

        [os_inherit]

        [oslo_messaging_amqp]
        
        [oslo_messaging_notifications]

        [oslo_messaging_rabbit]

        [oslo_messaging_zmq]

        [oslo_middleware]

        [oslo_policy]

        [paste_deploy]

        [policy]

        [profiler]

        [resource]

        [revoke]

        [role]

        [saml]

        [security_compliance]

        [shadow_users]

        [signing]

        [token]
        provider = fernet

        [tokenless_auth]        
      '';
    };
    environment.etc."keystone/keystone-paste.ini" = {
      enable = true;
      #source = ./etc/keystone-paste.ini;
      uid = 91;
      gid = 91;
      mode = "0640";
      text = ''
        # Keystone PasteDeploy configuration file.

        [filter:debug]
        use = egg:oslo.middleware#debug

        [filter:request_id]
        use = egg:oslo.middleware#request_id

        [filter:build_auth_context]
        use = egg:keystone#build_auth_context

        [filter:token_auth]
        use = egg:keystone#token_auth

        [filter:admin_token_auth]
        # This is deprecated in the M release and will be removed in the O release.
        # Use `keystone-manage bootstrap` and remove this from the pipelines below.
        use = egg:keystone#admin_token_auth

        [filter:json_body]
        use = egg:keystone#json_body

        [filter:cors]
        use = egg:oslo.middleware#cors
        oslo_config_project = keystone

        [filter:http_proxy_to_wsgi]
        use = egg:oslo.middleware#http_proxy_to_wsgi

        [filter:ec2_extension]
        use = egg:keystone#ec2_extension

        [filter:ec2_extension_v3]
        use = egg:keystone#ec2_extension_v3

        [filter:s3_extension]
        use = egg:keystone#s3_extension

        [filter:url_normalize]
        use = egg:keystone#url_normalize

        [filter:sizelimit]
        use = egg:oslo.middleware#sizelimit

        [filter:osprofiler]
        use = egg:osprofiler#osprofiler

        [app:public_service]
        use = egg:keystone#public_service

        [app:service_v3]
        use = egg:keystone#service_v3

        [app:admin_service]
        use = egg:keystone#admin_service

        [pipeline:public_api]
        # The last item in this pipeline must be public_service or an equivalent
        # application. It cannot be a filter.
        pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension public_service

        [pipeline:admin_api]
        # The last item in this pipeline must be admin_service or an equivalent
        # application. It cannot be a filter.
        pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension s3_extension admin_service

        [pipeline:api_v3]
        # The last item in this pipeline must be service_v3 or an equivalent
        # application. It cannot be a filter.
        pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension_v3 s3_extension service_v3

        [app:public_version_service]
        use = egg:keystone#public_version_service

        [app:admin_version_service]
        use = egg:keystone#admin_version_service

        [pipeline:public_version_api]
        pipeline = cors sizelimit osprofiler url_normalize public_version_service

        [pipeline:admin_version_api]
        pipeline = cors sizelimit osprofiler url_normalize admin_version_service

        [composite:main]
        use = egg:Paste#urlmap
        /v2.0 = public_api
        /v3 = api_v3
        / = public_version_api

        [composite:admin]
        use = egg:Paste#urlmap
        /v2.0 = admin_api
        /v3 = api_v3
        / = admin_version_api
      '';
    };
    environment.etc."keystone/logging.conf" = {
      enable = true;
      #source = ./etc/logging.conf;
      uid = 91;
      gid = 91;
      mode = "0640";
      text = ''
        [loggers]
        keys=root,access

        [handlers]
        keys=production,file,access_file,devel

        [formatters]
        keys=minimal,normal,debug


        ###########
        # Loggers #
        ###########

        [logger_root]
        level=WARNING
        handlers=file

        [logger_access]
        level=INFO
        qualname=access
        handlers=access_file


        ################
        # Log Handlers #
        ################

        [handler_production]
        class=handlers.SysLogHandler
        level=ERROR
        formatter=normal
        args=(('localhost', handlers.SYSLOG_UDP_PORT), handlers.SysLogHandler.LOG_USER)

        [handler_file]
        class=handlers.WatchedFileHandler
        level=WARNING
        formatter=normal
        args=('error.log',)

        [handler_access_file]
        class=handlers.WatchedFileHandler
        level=INFO
        formatter=minimal
        args=('access.log',)

        [handler_devel]
        class=StreamHandler
        level=NOTSET
        formatter=debug
        args=(sys.stdout,)


        ##################
        # Log Formatters #
        ##################

        [formatter_minimal]
        format=%(message)s

        [formatter_normal]
        format=(%(name)s): %(asctime)s %(levelname)s %(message)s

        [formatter_debug]
        format=(%(name)s): %(asctime)s %(levelname)s %(module)s %(funcName)s %(message)s
      '';
    };
    environment.etc."keystone/policy.json" = {
      enable = true;
      #source = ./etc/policy.json;
      uid = 91;
      gid = 91;
      mode = "0640";
      text = ''
        {
            "admin_required": "role:admin or is_admin:1",
            "service_role": "role:service",
            "service_or_admin": "rule:admin_required or rule:service_role",
            "owner" : "user_id:%(user_id)s",
            "admin_or_owner": "rule:admin_required or rule:owner",
            "token_subject": "user_id:%(target.token.user_id)s",
            "admin_or_token_subject": "rule:admin_required or rule:token_subject",
            "service_admin_or_token_subject": "rule:service_or_admin or rule:token_subject",

            "default": "rule:admin_required",

            "identity:get_region": "",
            "identity:list_regions": "",
            "identity:create_region": "rule:admin_required",
            "identity:update_region": "rule:admin_required",
            "identity:delete_region": "rule:admin_required",

            "identity:get_service": "rule:admin_required",
            "identity:list_services": "rule:admin_required",
            "identity:create_service": "rule:admin_required",
            "identity:update_service": "rule:admin_required",
            "identity:delete_service": "rule:admin_required",

            "identity:get_endpoint": "rule:admin_required",
            "identity:list_endpoints": "rule:admin_required",
            "identity:create_endpoint": "rule:admin_required",
            "identity:update_endpoint": "rule:admin_required",
            "identity:delete_endpoint": "rule:admin_required",

            "identity:get_domain": "rule:admin_required or token.project.domain.id:%(target.domain.id)s",
            "identity:list_domains": "rule:admin_required",
            "identity:create_domain": "rule:admin_required",
            "identity:update_domain": "rule:admin_required",
            "identity:delete_domain": "rule:admin_required",

            "identity:get_project": "rule:admin_required or project_id:%(target.project.id)s",
            "identity:list_projects": "rule:admin_required",
            "identity:list_user_projects": "rule:admin_or_owner",
            "identity:create_project": "rule:admin_required",
            "identity:update_project": "rule:admin_required",
            "identity:delete_project": "rule:admin_required",

            "identity:get_user": "rule:admin_or_owner",
            "identity:list_users": "rule:admin_required",
            "identity:create_user": "rule:admin_required",
            "identity:update_user": "rule:admin_required",
            "identity:delete_user": "rule:admin_required",
            "identity:change_password": "rule:admin_or_owner",

            "identity:get_group": "rule:admin_required",
            "identity:list_groups": "rule:admin_required",
            "identity:list_groups_for_user": "rule:admin_or_owner",
            "identity:create_group": "rule:admin_required",
            "identity:update_group": "rule:admin_required",
            "identity:delete_group": "rule:admin_required",
            "identity:list_users_in_group": "rule:admin_required",
            "identity:remove_user_from_group": "rule:admin_required",
            "identity:check_user_in_group": "rule:admin_required",
            "identity:add_user_to_group": "rule:admin_required",

            "identity:get_credential": "rule:admin_required",
            "identity:list_credentials": "rule:admin_required",
            "identity:create_credential": "rule:admin_required",
            "identity:update_credential": "rule:admin_required",
            "identity:delete_credential": "rule:admin_required",

            "identity:ec2_get_credential": "rule:admin_required or (rule:owner and user_id:%(target.credential.user_id)s)",
            "identity:ec2_list_credentials": "rule:admin_or_owner",
            "identity:ec2_create_credential": "rule:admin_or_owner",
            "identity:ec2_delete_credential": "rule:admin_required or (rule:owner and user_id:%(target.credential.user_id)s)",

            "identity:get_role": "rule:admin_required",
            "identity:list_roles": "rule:admin_required",
            "identity:create_role": "rule:admin_required",
            "identity:update_role": "rule:admin_required",
            "identity:delete_role": "rule:admin_required",
            "identity:get_domain_role": "rule:admin_required",
            "identity:list_domain_roles": "rule:admin_required",
            "identity:create_domain_role": "rule:admin_required",
            "identity:update_domain_role": "rule:admin_required",
            "identity:delete_domain_role": "rule:admin_required",

            "identity:get_implied_role": "rule:admin_required ",
            "identity:list_implied_roles": "rule:admin_required",
            "identity:create_implied_role": "rule:admin_required",
            "identity:delete_implied_role": "rule:admin_required",
            "identity:list_role_inference_rules": "rule:admin_required",
            "identity:check_implied_role": "rule:admin_required",

            "identity:check_grant": "rule:admin_required",
            "identity:list_grants": "rule:admin_required",
            "identity:create_grant": "rule:admin_required",
            "identity:revoke_grant": "rule:admin_required",

            "identity:list_role_assignments": "rule:admin_required",
            "identity:list_role_assignments_for_tree": "rule:admin_required",

            "identity:get_policy": "rule:admin_required",
            "identity:list_policies": "rule:admin_required",
            "identity:create_policy": "rule:admin_required",
            "identity:update_policy": "rule:admin_required",
            "identity:delete_policy": "rule:admin_required",

            "identity:check_token": "rule:admin_or_token_subject",
            "identity:validate_token": "rule:service_admin_or_token_subject",
            "identity:validate_token_head": "rule:service_or_admin",
            "identity:revocation_list": "rule:service_or_admin",
            "identity:revoke_token": "rule:admin_or_token_subject",

            "identity:create_trust": "user_id:%(trust.trustor_user_id)s",
            "identity:list_trusts": "",
            "identity:list_roles_for_trust": "",
            "identity:get_role_for_trust": "",
            "identity:delete_trust": "",

            "identity:create_consumer": "rule:admin_required",
            "identity:get_consumer": "rule:admin_required",
            "identity:list_consumers": "rule:admin_required",
            "identity:delete_consumer": "rule:admin_required",
            "identity:update_consumer": "rule:admin_required",

            "identity:authorize_request_token": "rule:admin_required",
            "identity:list_access_token_roles": "rule:admin_required",
            "identity:get_access_token_role": "rule:admin_required",
            "identity:list_access_tokens": "rule:admin_required",
            "identity:get_access_token": "rule:admin_required",
            "identity:delete_access_token": "rule:admin_required",

            "identity:list_projects_for_endpoint": "rule:admin_required",
            "identity:add_endpoint_to_project": "rule:admin_required",
            "identity:check_endpoint_in_project": "rule:admin_required",
            "identity:list_endpoints_for_project": "rule:admin_required",
            "identity:remove_endpoint_from_project": "rule:admin_required",

            "identity:create_endpoint_group": "rule:admin_required",
            "identity:list_endpoint_groups": "rule:admin_required",
            "identity:get_endpoint_group": "rule:admin_required",
            "identity:update_endpoint_group": "rule:admin_required",
            "identity:delete_endpoint_group": "rule:admin_required",
            "identity:list_projects_associated_with_endpoint_group": "rule:admin_required",
            "identity:list_endpoints_associated_with_endpoint_group": "rule:admin_required",
            "identity:get_endpoint_group_in_project": "rule:admin_required",
            "identity:list_endpoint_groups_for_project": "rule:admin_required",
            "identity:add_endpoint_group_to_project": "rule:admin_required",
            "identity:remove_endpoint_group_from_project": "rule:admin_required",

            "identity:create_identity_provider": "rule:admin_required",
            "identity:list_identity_providers": "rule:admin_required",
            "identity:get_identity_providers": "rule:admin_required",
            "identity:update_identity_provider": "rule:admin_required",
            "identity:delete_identity_provider": "rule:admin_required",

            "identity:create_protocol": "rule:admin_required",
            "identity:update_protocol": "rule:admin_required",
            "identity:get_protocol": "rule:admin_required",
            "identity:list_protocols": "rule:admin_required",
            "identity:delete_protocol": "rule:admin_required",

            "identity:create_mapping": "rule:admin_required",
            "identity:get_mapping": "rule:admin_required",
            "identity:list_mappings": "rule:admin_required",
            "identity:delete_mapping": "rule:admin_required",
            "identity:update_mapping": "rule:admin_required",

            "identity:create_service_provider": "rule:admin_required",
            "identity:list_service_providers": "rule:admin_required",
            "identity:get_service_provider": "rule:admin_required",
            "identity:update_service_provider": "rule:admin_required",
            "identity:delete_service_provider": "rule:admin_required",

            "identity:get_auth_catalog": "",
            "identity:get_auth_projects": "",
            "identity:get_auth_domains": "",

            "identity:list_projects_for_user": "",
            "identity:list_domains_for_user": "",

            "identity:list_revoke_events": "",

            "identity:create_policy_association_for_endpoint": "rule:admin_required",
            "identity:check_policy_association_for_endpoint": "rule:admin_required",
            "identity:delete_policy_association_for_endpoint": "rule:admin_required",
            "identity:create_policy_association_for_service": "rule:admin_required",
            "identity:check_policy_association_for_service": "rule:admin_required",
            "identity:delete_policy_association_for_service": "rule:admin_required",
            "identity:create_policy_association_for_region_and_service": "rule:admin_required",
            "identity:check_policy_association_for_region_and_service": "rule:admin_required",
            "identity:delete_policy_association_for_region_and_service": "rule:admin_required",
            "identity:get_policy_for_endpoint": "rule:admin_required",
            "identity:list_endpoints_for_policy": "rule:admin_required",

            "identity:create_domain_config": "rule:admin_required",
            "identity:get_domain_config": "rule:admin_required",
            "identity:update_domain_config": "rule:admin_required",
            "identity:delete_domain_config": "rule:admin_required",
            "identity:get_domain_config_default": "rule:admin_required"
}
      '';
    };
    #environment.etc."keystone/policy.v3cloudsample.json" = {
    #  enable = true;
    #  source = ./etc/policy.v3cloudsample.json;
    #  uid = 91;
    #  gid = 91;
    #  mode = "0640";
    #};
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
