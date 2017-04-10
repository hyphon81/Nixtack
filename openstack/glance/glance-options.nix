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
          This is the OpenStack glance project name.
        '';
      };

      serviceUser = mkOption {
        type = types.str;
        default = "glance";
        description = ''
          This is the name of the glance service user.
        '';
      };

      servicePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the glance service.
        '';
      };

      databaseUser = mkOption {
        type = types.str;
        default = "glance";
        description = ''
          This is the name of the glance database user.
        '';
      };

      databasePassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          This is the password of the glance database.
        '';
      };

      databaseName = mkOption {
        type = types.str;
        default = "glance";
        description = ''
          This is the name of the glance database.
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

      memcachedServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the domain name or ip address of the memcached server.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Install glance
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
      uid = 258;
      gid = 258;
      mode = "0440";
      text = ''
        # Use this pipeline for no auth or image caching - DEFAULT
        [pipeline:glance-api]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler unauthenticated-context rootapp

        # Use this pipeline for image caching and no auth
        [pipeline:glance-api-caching]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler unauthenticated-context cache rootapp

        # Use this pipeline for caching w/ management interface but no auth
        [pipeline:glance-api-cachemanagement]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler unauthenticated-context cache cachemanage rootapp

        # Use this pipeline for keystone auth
        [pipeline:glance-api-keystone]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler authtoken context  rootapp

        # Use this pipeline for keystone auth with image caching
        [pipeline:glance-api-keystone+caching]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler authtoken context cache rootapp

        # Use this pipeline for keystone auth with caching and cache management
        [pipeline:glance-api-keystone+cachemanagement]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler authtoken context cache cachemanage rootapp

        # Use this pipeline for authZ only. This means that the registry will treat a
        # user as authenticated without making requests to keystone to reauthenticate
        # the user.
        [pipeline:glance-api-trusted-auth]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler context rootapp

        # Use this pipeline for authZ only. This means that the registry will treat a
        # user as authenticated without making requests to keystone to reauthenticate
        # the user and uses cache management
        [pipeline:glance-api-trusted-auth+cachemanagement]
        pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler context cache cachemanage rootapp

        [composite:rootapp]
        paste.composite_factory = glance.api:root_app_factory
        /: apiversions
        /v1: apiv1app
        /v2: apiv2app

        [app:apiversions]
        paste.app_factory = glance.api.versions:create_resource

        [app:apiv1app]
        paste.app_factory = glance.api.v1.router:API.factory

        [app:apiv2app]
        paste.app_factory = glance.api.v2.router:API.factory

        [filter:healthcheck]
        paste.filter_factory = oslo_middleware:Healthcheck.factory
        backends = disable_by_file
        disable_by_file_path = /etc/glance/healthcheck_disable

        [filter:versionnegotiation]
        paste.filter_factory = glance.api.middleware.version_negotiation:VersionNegotiationFilter.factory

        [filter:cache]
        paste.filter_factory = glance.api.middleware.cache:CacheFilter.factory

        [filter:cachemanage]
        paste.filter_factory = glance.api.middleware.cache_manage:CacheManageFilter.factory

        [filter:context]
        paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory

        [filter:unauthenticated-context]
        paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory

        [filter:authtoken]
        paste.filter_factory = keystonemiddleware.auth_token:filter_factory
        delay_auth_decision = true

        [filter:gzip]
        paste.filter_factory = glance.api.middleware.gzip:GzipMiddleware.factory

        [filter:osprofiler]
        paste.filter_factory = osprofiler.web:WsgiMiddleware.factory
        hmac_keys = SECRET_KEY  #DEPRECATED
        enabled = yes  #DEPRECATED

        [filter:cors]
        paste.filter_factory =  oslo_middleware.cors:filter_factory
        oslo_config_project = glance
        oslo_config_program = glance-api

        [filter:http_proxy_to_wsgi]
        paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory
      '';
    };

    environment.etc."glance/glance-api.conf" = {
      enable = true;
      uid = 258;
      gid = 258;
      mode = "0440";
      text = ''
        [DEFAULT]
        data_api = glance.db.registry.api
        enable_v2_api = true
        enable_v2_registry = true
        registry_host = localhost
        registry_port = 9191

        [cors]

        [cors.subdomain]

        [database]
        connection = mysql+pymysql://${cfg.databaseUser}:${cfg.databasePassword}@${cfg.databaseServer}/${cfg.databaseName}

        [glance_store]
        stores = file,http
        default_store = file
        filesystem_store_datadir = /var/lib/glance/images

        [image_format]

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

        [matchmaker_redis]

        [oslo_concurrency]

        [oslo_messaging_amqp]

        [oslo_messaging_notifications]

        [oslo_messaging_rabbit]

        [oslo_messaging_zmq]

        [oslo_middleware]

        [oslo_policy]

        [paste_deploy]
        flavor = keystone

        [profiler]

        [store_type_location_strategy]

        [task]

        [taskflow_executor]
      '';
    };

    #environment.etc."glance/glance-cache.conf" = {
    #  enable = true;
    #  uid = 258;
    #  gid = 258;
    #  mode = "0440";
    #  text = ''
    #    [DEFAULT]
    #
    #    [glance_store]
    #
    #    [oslo_policy]
    #  '';
    #};

    #environment.etc."glance/glance-glare-paste.ini" = {
    #  enable = true;
    #  uid = 258;
    #  gid = 258;
    #  mode = "0440";
    #  text = ''
    #    # Use this pipeline for no auth - DEFAULT
    #    [pipeline:glare-api]
    #    pipeline = cors healthcheck versionnegotiation osprofiler unauthenticated-context rootapp
    #
    #    # Use this pipeline for keystone auth
    #    [pipeline:glare-api-keystone]
    #    pipeline = cors healthcheck versionnegotiation osprofiler authtoken context rootapp
    #
    #    [composite:rootapp]
    #    paste.composite_factory = glance.api:root_app_factory
    #    /: apiversions
    #    /v0.1: glareapi
    #
    #    [app:apiversions]
    #    paste.app_factory = glance.api.glare.versions:create_resource
    #
    #    [app:glareapi]
    #    paste.app_factory = glance.api.glare.v0_1.router:API.factory
    #
    #    [filter:healthcheck]
    #    paste.filter_factory = oslo_middleware:Healthcheck.factory
    #    backends = disable_by_file
    #    disable_by_file_path = /etc/glance/healthcheck_disable
    #
    #    [filter:versionnegotiation]
    #    paste.filter_factory = glance.api.middleware.version_negotiation:GlareVersionNegotiationFilter.factory
    #
    #    [filter:context]
    #    paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory
    #
    #    [filter:unauthenticated-context]
    #    paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory
    #
    #    [filter:authtoken]
    #    paste.filter_factory = keystonemiddleware.auth_token:filter_factory
    #    delay_auth_decision = true
    #
    #    [filter:osprofiler]
    #    paste.filter_factory = osprofiler.web:WsgiMiddleware.factory
    #
    #    [filter:cors]
    #    paste.filter_factory =  oslo_middleware.cors:filter_factory
    #    oslo_config_project = glance
    #    oslo_config_program = glance-glare
    #    # Basic Headers (Automatic)
    #    # Accept = Origin, Accept, Accept-Language, Content-Type, Cache-Control, Content-Language, Expires, Last-Modified, Pragma
    #    # Expose = Origin, Accept, Accept-Language, Content-Type, Cache-Control, Content-Language, Expires, Last-Modified, Pragma
    #
    #    # Glance Headers
    #    # Accept = Content-MD5, Accept-Encoding
    #
    #    # Keystone Headers
    #    # Accept = X-Auth-Token, X-Identity-Status, X-Roles, X-Service-Catalog, X-User-Id, X-Tenant-Id
    #    # Expose = X-Auth-Token, X-Subject-Token, X-Service-Token
    #
    #    # Request ID Middleware Headers
    #    # Accept = X-OpenStack-Request-ID
    #    # Expose = X-OpenStack-Request-ID
    #    latent_allow_headers = Content-MD5, Accept-Encoding, X-Auth-Token, X-Identity-Status, X-Roles, X-Service-Catalog, X-User-Id, X-Tenant-Id, X-OpenStack-Request-ID
    #    latent_expose_headers = X-Auth-Token, X-Subject-Token, X-Service-Token, X-OpenStack-Request-ID
    #  '';
    #};

    #environment.etc."glance/glance-glare.conf" = {
    #  enable = true;
    #  uid = 258;
    #  gid = 258;
    #  mode = "0440";
    #  text = ''
    #    [DEFAULT]
    #
    #    [cors]
    #
    #    [cors.subdomain]
    #
    #    [database]
    #
    #    [glance_store]
    #
    #    [profiler]
    #  '';
    #};

    #environment.etc."glance/glance-manage.conf" = {
    #  enable = true;
    #  uid = 258;
    #  gid = 258;
    #  mode = "0440";
    #  text = ''
    #    [DEFAULT]
    #
    #    [database]
    #  '';
    #};

    environment.etc."glance/glance-registry-paste.ini" = {
      enable = true;
      uid = 258;
      gid = 258;
      mode = "0440";
      text = ''
        # Use this pipeline for no auth - DEFAULT
        [pipeline:glance-registry]
        pipeline = healthcheck osprofiler unauthenticated-context registryapp

        # Use this pipeline for keystone auth
        [pipeline:glance-registry-keystone]
        pipeline = healthcheck osprofiler authtoken context registryapp

        # Use this pipeline for authZ only. This means that the registry will treat a
        # user as authenticated without making requests to keystone to reauthenticate
        # the user.
        [pipeline:glance-registry-trusted-auth]
        pipeline = healthcheck osprofiler context registryapp

        [app:registryapp]
        paste.app_factory = glance.registry.api:API.factory

        [filter:healthcheck]
        paste.filter_factory = oslo_middleware:Healthcheck.factory
        backends = disable_by_file
        disable_by_file_path = /etc/glance/healthcheck_disable

        [filter:context]
        paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory

        [filter:unauthenticated-context]
        paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory

        [filter:authtoken]
        paste.filter_factory = keystonemiddleware.auth_token:filter_factory

        [filter:osprofiler]
        paste.filter_factory = osprofiler.web:WsgiMiddleware.factory
        hmac_keys = SECRET_KEY  #DEPRECATED
        enabled = yes  #DEPRECATED
      '';
    };

    environment.etc."glance/glance-registry.conf" = {
      enable = true;
      uid = 258;
      gid = 258;
      mode = "0440";
      text = ''
        [DEFAULT]

        [database]
        connection = mysql+pymysql://${cfg.databaseUser}:${cfg.databasePassword}@${cfg.databaseServer}/${cfg.databaseName}

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

        [matchmaker_redis]

        [oslo_messaging_amqp]

        [oslo_messaging_notifications]

        [oslo_messaging_rabbit]

        [oslo_messaging_zmq]

        [oslo_policy]

        [paste_deploy]

        [profiler]
      '';
    };

    #environment.etc."glance/glance-scrubber.conf" = {
    #  enable = true;
    #  uid = 258;
    #  gid = 258;
    #  mode = "0440";
    #  text = ''
    #    [DEFAULT]
    #
    #    [database]
    #
    #    [glance_store]
    #
    #    [oslo_concurrency]
    #
    #    [oslo_policy]
    #  '';
    #};

    environment.etc."glance/policy.json" = {
      enable = true;
      uid = 258;
      gid = 258;
      mode = "0440";
      text = ''
        {
           "context_is_admin":  "role:admin",
           "default": "role:admin",

           "add_image": "",
           "delete_image": "",
           "get_image": "",
           "get_images": "",
           "modify_image": "",
           "publicize_image": "role:admin",
           "copy_from": "",

           "download_image": "",
           "upload_image": "",

           "delete_image_location": "",
           "get_image_location": "",
           "set_image_location": "",

           "add_member": "",
           "delete_member": "",
           "get_member": "",
           "get_members": "",
           "modify_member": "",

           "manage_image_cache": "role:admin",

           "get_task": "role:admin",
           "get_tasks": "role:admin",
           "add_task": "role:admin",
           "modify_task": "role:admin",

           "deactivate": "",
           "reactivate": "",

           "get_metadef_namespace": "",
           "get_metadef_namespaces":"",
           "modify_metadef_namespace":"",
           "add_metadef_namespace":"",

           "get_metadef_object":"",
           "get_metadef_objects":"",
           "modify_metadef_object":"",
           "add_metadef_object":"",

           "list_metadef_resource_types":"",
           "get_metadef_resource_type":"",
           "add_metadef_resource_type_association":"",

           "get_metadef_property":"",
           "get_metadef_properties":"",
           "modify_metadef_property":"",
           "add_metadef_property":"",

           "get_metadef_tag":"",
           "get_metadef_tags":"",
           "modify_metadef_tag":"",
           "add_metadef_tag":"",
           "add_metadef_tags":""
        }
      '';
    };

    environment.etc."glance/schema-image.json" = {
      enable = true;
      uid = 258;
      gid = 258;
      mode = "0440";
      text = ''
        {
           "kernel_id": {
             "type": ["null", "string"],
             "pattern": "^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$",
             "description": "ID of image stored in Glance that should be used as the kernel when booting an AMI-style image."
           },
           "ramdisk_id": {
             "type": ["null", "string"],
             "pattern": "^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$",
             "description": "ID of image stored in Glance that should be used as the ramdisk when booting an AMI-style image."
           },
           "instance_uuid": {
             "type": "string",
             "description": "Metadata which can be used to record which instance this image is associated with. (Informational only, does not create an instance snapshot.)"
           },
           "architecture": {
             "description": "Operating system architecture as specified in http://docs.openstack.org/trunk/openstack-compute/admin/content/adding-images.html",
             "type": "string"
           },
           "os_distro": {
             "description": "Common name of operating system distribution as specified in http://docs.openstack.org/trunk/openstack-compute/admin/content/adding-images.html",
             "type": "string"
           },
           "os_version": {
             "description": "Operating system version as specified by the distributor",
             "type": "string"
           }
        }
      '';
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
