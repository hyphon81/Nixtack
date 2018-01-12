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

      memcachedServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the memcached server's domain name or ip address.
        '';
      };

      memcachedPort = mkOption {
        type = types.int;
        default = 11211;
        description = ''
          This is the memcached server's port num.
        '';
      };

      keystoneServer = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          This is the keystone server's domain name or ip address.
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
      #source = ./etc/local_settings.py;
      uid = 111;
      gid = 111;
      mode = "0660";
      text = ''
        # -*- coding: utf-8 -*-

        import os

        from django.utils.translation import ugettext_lazy as _

        from horizon.utils import secret_key

        from openstack_dashboard import exceptions
        from openstack_dashboard.settings import HORIZON_CONFIG

        DEBUG = True


        # WEBROOT is the location relative to Webserver root
        # should end with a slash.
        WEBROOT = '/'
        #LOGIN_URL = WEBROOT + 'auth/login/'
        #LOGOUT_URL = WEBROOT + 'auth/logout/'
        #
        # LOGIN_REDIRECT_URL can be used as an alternative for
        # HORIZON_CONFIG.user_home, if user_home is not set.
        # Do not set it to '/home/', as this will cause circular redirect loop
        #LOGIN_REDIRECT_URL = WEBROOT

        # If horizon is running in production (DEBUG is False), set this
        # with the list of host/domain names that the application can serve.
        # For more information see:
        # https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts
        ALLOWED_HOSTS = ['*', ]

        # Set SSL proxy settings:
        # Pass this header from the proxy after terminating the SSL,
        # and don't forget to strip it from the client's request.
        # For more information see:
        # https://docs.djangoproject.com/en/dev/ref/settings/#secure-proxy-ssl-header
        #SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

        # If Horizon is being served through SSL, then uncomment the following two
        # settings to better secure the cookies from security exploits
        #CSRF_COOKIE_SECURE = True
        #SESSION_COOKIE_SECURE = True

        # The absolute path to the directory where message files are collected.
        # The message file must have a .json file extension. When the user logins to
        # horizon, the message files collected are processed and displayed to the user.
        #MESSAGES_PATH=None

        # Overrides for OpenStack API versions. Use this setting to force the
        # OpenStack dashboard to use a specific API version for a given service API.
        # Versions specified here should be integers or floats, not strings.
        # NOTE: The version should be formatted as it appears in the URL for the
        # service API. For example, The identity service APIs have inconsistent
        # use of the decimal point, so valid options would be 2.0 or 3.
        # Minimum compute version to get the instance locked status is 2.9.
        OPENSTACK_API_VERSIONS = {
        #    "data-processing": 1.1,
            "identity": 3,
            "image": 2,
            "volume": 2,
        #    "compute": 2,
        }

        # Set this to True if running on a multi-domain model. When this is enabled, it
        # will require the user to enter the Domain name in addition to the username
        # for login.
        OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True

        # Overrides the default domain used when running on single-domain model
        # with Keystone V3. All entities will be created in the default domain.
        # NOTE: This value must be the ID of the default domain, NOT the name.
        # Also, you will most likely have a value in the keystone policy file like this
        #    "cloud_admin": "rule:admin_required and domain_id:<your domain id>"
        # This value must match the domain id specified there.
        OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'

        # Set this to True to enable panels that provide the ability for users to
        # manage Identity Providers (IdPs) and establish a set of rules to map
        # federation protocol attributes to Identity API attributes.
        # This extension requires v3.0+ of the Identity API.
        #OPENSTACK_KEYSTONE_FEDERATION_MANAGEMENT = False

        # Set Console type:
        # valid options are "AUTO"(default), "VNC", "SPICE", "RDP", "SERIAL" or None
        # Set to None explicitly if you want to deactivate the console.
        #CONSOLE_TYPE = "AUTO"

        # If provided, a "Report Bug" link will be displayed in the site header
        # which links to the value of this setting (ideally a URL containing
        # information on how to report issues).
        #HORIZON_CONFIG["bug_url"] = "http://bug-report.example.com"

        # Show backdrop element outside the modal, do not close the modal
        # after clicking on backdrop.
        #HORIZON_CONFIG["modal_backdrop"] = "static"

        # Specify a regular expression to validate user passwords.
        #HORIZON_CONFIG["password_validator"] = {
        #    "regex": '.*',
        #    "help_text": _("Your password does not meet the requirements."),
        #}

        # Disable simplified floating IP address management for deployments with
        # multiple floating IP pools or complex network requirements.
        #HORIZON_CONFIG["simple_ip_management"] = False

        # Turn off browser autocompletion for forms including the login form and
        # the database creation workflow if so desired.
        #HORIZON_CONFIG["password_autocomplete"] = "off"

        # Setting this to True will disable the reveal button for password fields,
        # including on the login form.
        #HORIZON_CONFIG["disable_password_reveal"] = False

        LOCAL_PATH = os.path.dirname(os.path.abspath(__file__))

        # Set custom secret key:
        # You can either set it to a specific value or you can let horizon generate a
        # default secret key that is unique on this machine, e.i. regardless of the
        # amount of Python WSGI workers (if used behind Apache+mod_wsgi): However,
        # there may be situations where you would want to set this explicitly, e.g.
        # when multiple dashboard instances are distributed on different machines
        # (usually behind a load-balancer). Either you have to make sure that a session
        # gets all requests routed to the same dashboard instance or you set the same
        # SECRET_KEY for all of them.
        #SECRET_KEY = secret_key.generate_or_read_from_file(
        #    os.path.join(LOCAL_PATH, '.secret_key_store'))
        SECRET_KEY = secret_key.generate_or_read_from_file('/var/lib/horizon/secret_key')

        # We recommend you use memcached for development; otherwise after every reload
        # of the django development server, you will have to login again. To use
        # memcached set CACHES to something like
        SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

        CACHES = {
            'default': {
                    'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
                    'LOCATION': '${cfg.memcachedServer}:${toString cfg.memcachedPort}',
            },
        }

        # Send email to the console by default
        EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
        # Or send them to /dev/null
        #EMAIL_BACKEND = 'django.core.mail.backends.dummy.EmailBackend'

        # Configure these for your outgoing email host
        #EMAIL_HOST = 'smtp.my-company.com'
        #EMAIL_PORT = 25
        #EMAIL_HOST_USER = 'djangomail'
        #EMAIL_HOST_PASSWORD = 'top-secret!'

        # For multiple regions uncomment this configuration, and add (endpoint, title).
        #AVAILABLE_REGIONS = [
        #    ('http://cluster1.example.com:5000/v2.0', 'cluster1'),
        #    ('http://cluster2.example.com:5000/v2.0', 'cluster2'),
        #]

        OPENSTACK_HOST = '${cfg.keystoneServer}'
        OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
        OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"

        # Enables keystone web single-sign-on if set to True.
        #WEBSSO_ENABLED = False

        # Determines which authentication choice to show as default.
        #WEBSSO_INITIAL_CHOICE = "credentials"

        # The list of authentication mechanisms which include keystone
        # federation protocols and identity provider/federation protocol
        # mapping keys (WEBSSO_IDP_MAPPING). Current supported protocol
        # IDs are 'saml2' and 'oidc'  which represent SAML 2.0, OpenID
        # Connect respectively.
        # Do not remove the mandatory credentials mechanism.
        # Note: The last two tuples are sample mapping keys to a identity provider
        # and federation protocol combination (WEBSSO_IDP_MAPPING).
        #WEBSSO_CHOICES = (
        #    ("credentials", _("Keystone Credentials")),
        #    ("oidc", _("OpenID Connect")),
        #    ("saml2", _("Security Assertion Markup Language")),
        #    ("acme_oidc", "ACME - OpenID Connect"),
        #    ("acme_saml2", "ACME - SAML2"),
        #)

        # A dictionary of specific identity provider and federation protocol
        # combinations. From the selected authentication mechanism, the value
        # will be looked up as keys in the dictionary. If a match is found,
        # it will redirect the user to a identity provider and federation protocol
        # specific WebSSO endpoint in keystone, otherwise it will use the value
        # as the protocol_id when redirecting to the WebSSO by protocol endpoint.
        # NOTE: The value is expected to be a tuple formatted as: (<idp_id>, <protocol_id>).
        #WEBSSO_IDP_MAPPING = {
        #    "acme_oidc": ("acme", "oidc"),
        #    "acme_saml2": ("acme", "saml2"),
        #}

        # Disable SSL certificate checks (useful for self-signed certificates):
        #OPENSTACK_SSL_NO_VERIFY = True

        # The CA certificate to use to verify SSL connections
        #OPENSTACK_SSL_CACERT = '/path/to/cacert.pem'

        # The OPENSTACK_KEYSTONE_BACKEND settings can be used to identify the
        # capabilities of the auth backend for Keystone.
        # If Keystone has been configured to use LDAP as the auth backend then set
        # can_edit_user to False and name to 'ldap'.
        #
        # TODO(tres): Remove these once Keystone has an API to identify auth backend.
        OPENSTACK_KEYSTONE_BACKEND = {
          'name': 'native',
          'can_edit_user': True,
          'can_edit_group': True,
          'can_edit_project': True,
          'can_edit_domain': True,
          'can_edit_role': True,
        }

        # Setting this to True, will add a new "Retrieve Password" action on instance,
        # allowing Admin session password retrieval/decryption.
        #OPENSTACK_ENABLE_PASSWORD_RETRIEVE = False

        # This setting allows deployers to control whether a token is deleted on log
        # out. This can be helpful when there are often long running processes being
        # run in the Horizon environment.
        #TOKEN_DELETE_DISABLED = False

        # The Launch Instance user experience has been significantly enhanced.
        # You can choose whether to enable the new launch instance experience,
        # the legacy experience, or both. The legacy experience will be removed
        # in a future release, but is available as a temporary backup setting to ensure
        # compatibility with existing deployments. Further development will not be
        # done on the legacy experience. Please report any problems with the new
        # experience via the Launchpad tracking system.
        #
        # Toggle LAUNCH_INSTANCE_LEGACY_ENABLED and LAUNCH_INSTANCE_NG_ENABLED to
        # determine the experience to enable.  Set them both to true to enable
        # both.
        #LAUNCH_INSTANCE_LEGACY_ENABLED = True
        #LAUNCH_INSTANCE_NG_ENABLED = False

        # A dictionary of settings which can be used to provide the default values for
        # properties found in the Launch Instance modal.
        #LAUNCH_INSTANCE_DEFAULTS = {
        #    'config_drive': False,
        #    'enable_scheduler_hints': True
        #    'disable_image': False,
        #    'disable_instance_snapshot': False,
        #    'disable_volume': False,
        #    'disable_volume_snapshot': False,
        #}

        # The Xen Hypervisor has the ability to set the mount point for volumes
        # attached to instances (other Hypervisors currently do not). Setting
        # can_set_mount_point to True will add the option to set the mount point
        # from the UI.
        OPENSTACK_HYPERVISOR_FEATURES = {
            'can_set_mount_point': False,
            'can_set_password': False,
            'requires_keypair': False,
            'enable_quotas': True
        }

        # The OPENSTACK_CINDER_FEATURES settings can be used to enable optional
        # services provided by cinder that is not exposed by its extension API.
        OPENSTACK_CINDER_FEATURES = {
            'enable_backup': False,
        }

        # The OPENSTACK_NEUTRON_NETWORK settings can be used to enable optional
        # services provided by neutron. Options currently available are load
        # balancer service, security groups, quotas, VPN service.
        OPENSTACK_NEUTRON_NETWORK = {
            'enable_router': True,
            'enable_quotas': True,
            'enable_ipv6': True,
            'enable_distributed_router': False,
            'enable_ha_router': False,
            'enable_lb': True,
            'enable_firewall': True,
            'enable_vpn': True,
            'enable_fip_topology_check': True,

            # Default dns servers you would like to use when a subnet is
            # created.  This is only a default, users can still choose a different
            # list of dns servers when creating a new subnet.
            # The entries below are examples only, and are not appropriate for
            # real deployments
            # 'default_dns_nameservers': ["8.8.8.8", "8.8.4.4", "208.67.222.222"],

            # The profile_support option is used to detect if an external router can be
            # configured via the dashboard. When using specific plugins the
            # profile_support can be turned on if needed.
            'profile_support': None,
            #'profile_support': 'cisco',

            # Set which provider network types are supported. Only the network types
            # in this list will be available to choose from when creating a network.
            # Network types include local, flat, vlan, gre, vxlan and geneve.
            # 'supported_provider_types': ['*'],

            # You can configure available segmentation ID range per network type
            # in your deployment.
            # 'segmentation_id_range': {
            #     'vlan': [1024, 2048],
            #     'vxlan': [4094, 65536],
            # },

            # You can define additional provider network types here.
            # 'extra_provider_types': {
            #     'awesome_type': {
            #         'display_name': 'Awesome New Type',
            #         'require_physical_network': False,
            #         'require_segmentation_id': True,
            #     }
            # },

            # Set which VNIC types are supported for port binding. Only the VNIC
            # types in this list will be available to choose from when creating a
            # port.
            # VNIC types include 'normal', 'macvtap' and 'direct'.
            # Set to empty list or None to disable VNIC type selection.
            'supported_vnic_types': ['*'],
        }

        # The OPENSTACK_HEAT_STACK settings can be used to disable password
        # field required while launching the stack.
        OPENSTACK_HEAT_STACK = {
            'enable_user_pass': True,
        }

        # The OPENSTACK_IMAGE_BACKEND settings can be used to customize features
        # in the OpenStack Dashboard related to the Image service, such as the list
        # of supported image formats.
        #OPENSTACK_IMAGE_BACKEND = {
        #    'image_formats': [
        #        (\'\', _('Select format')),
        #        ('aki', _('AKI - Amazon Kernel Image')),
        #        ('ami', _('AMI - Amazon Machine Image')),
        #        ('ari', _('ARI - Amazon Ramdisk Image')),
        #        ('docker', _('Docker')),
        #        ('iso', _('ISO - Optical Disk Image')),
        #        ('ova', _('OVA - Open Virtual Appliance')),
        #        ('qcow2', _('QCOW2 - QEMU Emulator')),
        #        ('raw', _('Raw')),
        #        ('vdi', _('VDI - Virtual Disk Image')),
        #        ('vhd', _('VHD - Virtual Hard Disk')),
        #        ('vmdk', _('VMDK - Virtual Machine Disk')),
        #    ],
        #}

        # The IMAGE_CUSTOM_PROPERTY_TITLES settings is used to customize the titles for
        # image custom property attributes that appear on image detail pages.
        IMAGE_CUSTOM_PROPERTY_TITLES = {
            "architecture": _("Architecture"),
            "kernel_id": _("Kernel ID"),
            "ramdisk_id": _("Ramdisk ID"),
            "image_state": _("Euca2ools state"),
            "project_id": _("Project ID"),
            "image_type": _("Image Type"),
        }

        # The IMAGE_RESERVED_CUSTOM_PROPERTIES setting is used to specify which image
        # custom properties should not be displayed in the Image Custom Properties
        # table.
        IMAGE_RESERVED_CUSTOM_PROPERTIES = []

        # Set to 'legacy' or 'direct' to allow users to upload images to glance via
        # Horizon server. When enabled, a file form field will appear on the create
        # image form. If set to 'off', there will be no file form field on the create
        # image form. See documentation for deployment considerations.
        HORIZON_IMAGES_UPLOAD_MODE = 'legacy'

        # Allow a location to be set when creating or updating Glance images.
        # If using Glance V2, this value should be False unless the Glance
        # configuration and policies allow setting locations.
        IMAGES_ALLOW_LOCATION = False

        # OPENSTACK_ENDPOINT_TYPE specifies the endpoint type to use for the endpoints
        # in the Keystone service catalog. Use this setting when Horizon is running
        # external to the OpenStack environment. The default is 'publicURL'.
        #OPENSTACK_ENDPOINT_TYPE = "publicURL"

        # SECONDARY_ENDPOINT_TYPE specifies the fallback endpoint type to use in the
        # case that OPENSTACK_ENDPOINT_TYPE is not present in the endpoints
        # in the Keystone service catalog. Use this setting when Horizon is running
        # external to the OpenStack environment. The default is None. This
        # value should differ from OPENSTACK_ENDPOINT_TYPE if used.
        #SECONDARY_ENDPOINT_TYPE = None

        # The number of objects (Swift containers/objects or images) to display
        # on a single page before providing a paging element (a "more" link)
        # to paginate results.
        API_RESULT_LIMIT = 1000
        API_RESULT_PAGE_SIZE = 20

        # The size of chunk in bytes for downloading objects from Swift
        SWIFT_FILE_TRANSFER_CHUNK_SIZE = 512 * 1024

        # The default number of lines displayed for instance console log.
        INSTANCE_LOG_LENGTH = 35

        # Specify a maximum number of items to display in a dropdown.
        DROPDOWN_MAX_ITEMS = 30

        # The timezone of the server. This should correspond with the timezone
        # of your entire OpenStack installation, and hopefully be in UTC.
        TIME_ZONE = "Asia/Tokyo"

        # When launching an instance, the menu of available flavors is
        # sorted by RAM usage, ascending. If you would like a different sort order,
        # you can provide another flavor attribute as sorting key. Alternatively, you
        # can provide a custom callback method to use for sorting. You can also provide
        # a flag for reverse sort. For more info, see
        # http://docs.python.org/2/library/functions.html#sorted
        #CREATE_INSTANCE_FLAVOR_SORT = {
        #    'key': 'name',
        #     # or
        #    'key': my_awesome_callback_method,
        #    'reverse': False,
        #}

        # Set this to True to display an 'Admin Password' field on the Change Password
        # form to verify that it is indeed the admin logged-in who wants to change
        # the password.
        #ENFORCE_PASSWORD_CHECK = False

        # Modules that provide /auth routes that can be used to handle different types
        # of user authentication. Add auth plugins that require extra route handling to
        # this list.
        #AUTHENTICATION_URLS = [
        #    'openstack_auth.urls',
        #]

        # The Horizon Policy Enforcement engine uses these values to load per service
        # policy rule files. The content of these files should match the files the
        # OpenStack services are using to determine role based access control in the
        # target installation.

        # Path to directory containing policy.json files
        #POLICY_FILES_PATH = os.path.join(ROOT_PATH, "conf")

        # Map of local copy of service policy files.
        # Please insure that your identity policy file matches the one being used on
        # your keystone servers. There is an alternate policy file that may be used
        # in the Keystone v3 multi-domain case, policy.v3cloudsample.json.
        # This file is not included in the Horizon repository by default but can be
        # found at
        # http://git.openstack.org/cgit/openstack/keystone/tree/etc/ \
        # policy.v3cloudsample.json
        # Having matching policy files on the Horizon and Keystone servers is essential
        # for normal operation. This holds true for all services and their policy files.
        #POLICY_FILES = {
        #    'identity': 'keystone_policy.json',
        #    'compute': 'nova_policy.json',
        #    'volume': 'cinder_policy.json',
        #    'image': 'glance_policy.json',
        #    'orchestration': 'heat_policy.json',
        #    'network': 'neutron_policy.json',
        #    'telemetry': 'ceilometer_policy.json',
        #}

        # TODO: (david-lyle) remove when plugins support adding settings.
        # Note: Only used when trove-dashboard plugin is configured to be used by
        # Horizon.
        # Trove user and database extension support. By default support for
        # creating users and databases on database instances is turned on.
        # To disable these extensions set the permission here to something
        # unusable such as ["!"].
        #TROVE_ADD_USER_PERMS = []
        #TROVE_ADD_DATABASE_PERMS = []

        # Change this patch to the appropriate list of tuples containing
        # a key, label and static directory containing two files:
        # _variables.scss and _styles.scss
        #AVAILABLE_THEMES = [
        #    ('default', 'Default', 'themes/default'),
        #    ('material', 'Material', 'themes/material'),
        #]

        LOGGING = {
            'version': 1,
            # When set to True this will disable all logging except
            # for loggers specified in this configuration dictionary. Note that
            # if nothing is specified here and disable_existing_loggers is True,
            # django.db.backends will still log unless it is disabled explicitly.
            'disable_existing_loggers': False,
            'formatters': {
                'operation': {
                    # The format of "%(message)s" is defined by
                    # OPERATION_LOG_OPTIONS['format']
                    'format': '%(asctime)s %(message)s'
                },
            },
            'handlers': {
                'null': {
                    'level': 'DEBUG',
                    'class': 'logging.NullHandler',
                },
                'console': {
                    # Set the level to "DEBUG" for verbose output logging.
                    'level': 'INFO',
                    'class': 'logging.StreamHandler',
                },
                'operation': {
                    'level': 'INFO',
                    'class': 'logging.StreamHandler',
                    'formatter': 'operation',
                },
            },
            'loggers': {
                # Logging from django.db.backends is VERY verbose, send to null
                # by default.
                'django.db.backends': {
                    'handlers': ['null'],
                    'propagate': False,
                },
                'requests': {
                    'handlers': ['null'],
                    'propagate': False,
                },
                'horizon': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'horizon.operation_log': {
                    'handlers': ['operation'],
                    'level': 'INFO',
                    'propagate': False,
                },
                'openstack_dashboard': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'novaclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'cinderclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'keystoneclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'glanceclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'neutronclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'heatclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'ceilometerclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'swiftclient': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'openstack_auth': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'nose.plugins.manager': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'django': {
                    'handlers': ['console'],
                    'level': 'DEBUG',
                    'propagate': False,
                },
                'iso8601': {
                    'handlers': ['null'],
                    'propagate': False,
                },
                'scss': {
                    'handlers': ['null'],
                    'propagate': False,
                },
            },
        }

        # 'direction' should not be specified for all_tcp/udp/icmp.
        # It is specified in the form.
        SECURITY_GROUP_RULES = {
            'all_tcp': {
                'name': _('All TCP'),
                'ip_protocol': 'tcp',
                'from_port': '1',
                'to_port': '65535',
            },
            'all_udp': {
                'name': _('All UDP'),
                'ip_protocol': 'udp',
                'from_port': '1',
                'to_port': '65535',
            },
            'all_icmp': {
                'name': _('All ICMP'),
                'ip_protocol': 'icmp',
                'from_port': '-1',
                'to_port': '-1',
            },
            'ssh': {
                'name': 'SSH',
                'ip_protocol': 'tcp',
                'from_port': '22',
                'to_port': '22',
            },
            'smtp': {
                'name': 'SMTP',
                'ip_protocol': 'tcp',
                'from_port': '25',
                'to_port': '25',
            },
            'dns': {
                'name': 'DNS',
                'ip_protocol': 'tcp',
                'from_port': '53',
                'to_port': '53',
            },
            'http': {
                'name': 'HTTP',
                'ip_protocol': 'tcp',
                'from_port': '80',
                'to_port': '80',
            },
            'pop3': {
                'name': 'POP3',
                'ip_protocol': 'tcp',
                'from_port': '110',
                'to_port': '110',
            },
            'imap': {
                'name': 'IMAP',
                'ip_protocol': 'tcp',
                'from_port': '143',
                'to_port': '143',
            },
            'ldap': {
                'name': 'LDAP',
                'ip_protocol': 'tcp',
                'from_port': '389',
                'to_port': '389',
            },
            'https': {
                'name': 'HTTPS',
                'ip_protocol': 'tcp',
                'from_port': '443',
                'to_port': '443',
            },
            'smtps': {
                'name': 'SMTPS',
                'ip_protocol': 'tcp',
                'from_port': '465',
                'to_port': '465',
            },
            'imaps': {
                'name': 'IMAPS',
                'ip_protocol': 'tcp',
                'from_port': '993',
                'to_port': '993',
            },
            'pop3s': {
                'name': 'POP3S',
                'ip_protocol': 'tcp',
                'from_port': '995',
                'to_port': '995',
            },
            'ms_sql': {
                'name': 'MS SQL',
                'ip_protocol': 'tcp',
                'from_port': '1433',
                'to_port': '1433',
            },
            'mysql': {
                'name': 'MYSQL',
                'ip_protocol': 'tcp',
                'from_port': '3306',
                'to_port': '3306',
            },
            'rdp': {
                'name': 'RDP',
                'ip_protocol': 'tcp',
                'from_port': '3389',
                'to_port': '3389',
            },
        }

        # Deprecation Notice:
        #
        # The setting FLAVOR_EXTRA_KEYS has been deprecated.
        # Please load extra spec metadata into the Glance Metadata Definition Catalog.
        #
        # The sample quota definitions can be found in:
        # <glance_source>/etc/metadefs/compute-quota.json
        #
        # The metadata definition catalog supports CLI and API:
        #  $glance --os-image-api-version 2 help md-namespace-import
        #  $glance-manage db_load_metadefs <directory_with_definition_files>
        #
        # See Metadata Definitions on: http://docs.openstack.org/developer/glance/

        # TODO: (david-lyle) remove when plugins support settings natively
        # Note: This is only used when the Sahara plugin is configured and enabled
        # for use in Horizon.
        # Indicate to the Sahara data processing service whether or not
        # automatic floating IP allocation is in effect.  If it is not
        # in effect, the user will be prompted to choose a floating IP
        # pool for use in their cluster.  False by default.  You would want
        # to set this to True if you were running Nova Networking with
        # auto_assign_floating_ip = True.
        #SAHARA_AUTO_IP_ALLOCATION_ENABLED = False

        # The hash algorithm to use for authentication tokens. This must
        # match the hash algorithm that the identity server and the
        # auth_token middleware are using. Allowed values are the
        # algorithms supported by Python's hashlib library.
        #OPENSTACK_TOKEN_HASH_ALGORITHM = 'md5'

        # AngularJS requires some settings to be made available to
        # the client side. Some settings are required by in-tree / built-in horizon
        # features. These settings must be added to REST_API_REQUIRED_SETTINGS in the
        # form of ['SETTING_1','SETTING_2'], etc.
        #
        # You may remove settings from this list for security purposes, but do so at
        # the risk of breaking a built-in horizon feature. These settings are required
        # for horizon to function properly. Only remove them if you know what you
        # are doing. These settings may in the future be moved to be defined within
        # the enabled panel configuration.
        # You should not add settings to this list for out of tree extensions.
        # See: https://wiki.openstack.org/wiki/Horizon/RESTAPI
        REST_API_REQUIRED_SETTINGS = ['OPENSTACK_HYPERVISOR_FEATURES',
                                      'LAUNCH_INSTANCE_DEFAULTS',
                                      'OPENSTACK_IMAGE_FORMATS']

        # Additional settings can be made available to the client side for
        # extensibility by specifying them in REST_API_ADDITIONAL_SETTINGS
        # !! Please use extreme caution as the settings are transferred via HTTP/S
        # and are not encrypted on the browser. This is an experimental API and
        # may be deprecated in the future without notice.
        #REST_API_ADDITIONAL_SETTINGS = []

        # DISALLOW_IFRAME_EMBED can be used to prevent Horizon from being embedded
        # within an iframe. Legacy browsers are still vulnerable to a Cross-Frame
        # Scripting (XFS) vulnerability, so this option allows extra security hardening
        # where iframes are not used in deployment. Default setting is True.
        # For more information see:
        # http://tinyurl.com/anticlickjack
        #DISALLOW_IFRAME_EMBED = True

        # Help URL can be made available for the client. To provide a help URL, edit the
        # following attribute to the URL of your choice.
        #HORIZON_CONFIG["help_url"] = "http://openstack.mycompany.org"

        # Settings for OperationLogMiddleware
        # OPERATION_LOG_ENABLED is flag to use the function to log an operation on
        # Horizon.
        # mask_targets is arrangement for appointing a target to mask.
        # method_targets is arrangement of HTTP method to output log.
        # format is the log contents.
        #OPERATION_LOG_ENABLED = False
        #OPERATION_LOG_OPTIONS = {
        #    'mask_fields': ['password'],
        #    'target_methods': ['POST'],
        #    'format': ("[%(domain_name)s] [%(domain_id)s] [%(project_name)s]"
        #        " [%(project_id)s] [%(user_name)s] [%(user_id)s] [%(request_scheme)s]"
        #        " [%(referer_url)s] [%(request_url)s] [%(message)s] [%(method)s]"
        #        " [%(http_status)s] [%(param)s]"),
        #}

        # The default date range in the Overview panel meters - either <today> minus N
        # days (if the value is integer N), or from the beginning of the current month
        # until today (if set to None). This setting should be used to limit the amount
        # of data fetched by default when rendering the Overview panel.
        #OVERVIEW_DAYS_RANGE = 1

        # To allow operators to require users provide a search criteria first
        # before loading any data into the views, set the following dict
        # attributes to True in each one of the panels you want to enable this feature.
        # Follow the convention <dashboard>.<view>
        #FILTER_DATA_FIRST = {
        #    'admin.instances': False,
        #    'admin.images': False,
        #    'admin.networks': False,
        #    'admin.routers': False,
        #    'admin.volumes': False
        #}

        # Dict used to restrict user private subnet cidr range.
        # An empty list means that user input will not be restricted
        # for a corresponding IP version. By default, there is
        # no restriction for IPv4 or IPv6. To restrict
        # user private subnet cidr range set ALLOWED_PRIVATE_SUBNET_CIDR
        # to something like
        #ALLOWED_PRIVATE_SUBNET_CIDR = {
        #    'ipv4': ['10.0.0.0/8', '192.168.0.0/16'],
        #    'ipv6': ['fc00::/7']
        #}
        ALLOWED_PRIVATE_SUBNET_CIDR = {'ipv4': [], 'ipv6': []}

        # Project and user can have any attributes by keystone v3 mechanism.
        # This settings can treat these attributes on Horizon.
        # It means, when you show Create/Update modal, attribute below is
        # shown and you can specify any value.
        # If you'd like to display these extra data in project or user index table,
        # Keystone v3 allows you to add extra properties to Project and Users.
        # Horizon's customization (http://docs.openstack.org/developer/horizon/topics/customizing.html#horizon-customization-module-overrides)
        # allows you to display this extra information in the Create/Update modal and
        # the corresponding tables.
        #PROJECT_TABLE_EXTRA_INFO = {
        #   'phone_num': _('Phone Number'),
        #}
        #USER_TABLE_EXTRA_INFO = {
        #   'phone_num': _('Phone Number'),
        #}
      '';
    };

    environment.etc."horizon/conf/ceilometer_policy.json" = {
      enable = true;
      uid = 111;
      gid = 111;
      mode = "0660";
      text = ''
        {
            "context_is_admin": "role:admin",
            "context_is_project": "project_id:%(target.project_id)s",
            "context_is_owner": "user_id:%(target.user_id)s",
            "segregation": "rule:context_is_admin"
        }
      '';
    };

    environment.etc."horizon/conf/cinder_policy.json" = {
      enable = true;
      uid = 111;
      gid = 111;
      mode = "0660";
      text = ''
        {
            "context_is_admin": "role:admin",
            "admin_or_owner":  "is_admin:True or project_id:%(project_id)s",
            "default": "rule:admin_or_owner",

            "admin_api": "is_admin:True",

            "volume:create": "",
            "volume:delete": "rule:admin_or_owner",
            "volume:get": "rule:admin_or_owner",
            "volume:get_all": "rule:admin_or_owner",
            "volume:get_volume_metadata": "rule:admin_or_owner",
            "volume:delete_volume_metadata": "rule:admin_or_owner",
            "volume:update_volume_metadata": "rule:admin_or_owner",
            "volume:get_volume_admin_metadata": "rule:admin_api",
            "volume:update_volume_admin_metadata": "rule:admin_api",
            "volume:get_snapshot": "rule:admin_or_owner",
            "volume:get_all_snapshots": "rule:admin_or_owner",
            "volume:create_snapshot": "rule:admin_or_owner",
            "volume:delete_snapshot": "rule:admin_or_owner",
            "volume:update_snapshot": "rule:admin_or_owner",
            "volume:get_snapshot_metadata": "rule:admin_or_owner",
            "volume:delete_snapshot_metadata": "rule:admin_or_owner",
            "volume:update_snapshot_metadata": "rule:admin_or_owner",
            "volume:extend": "rule:admin_or_owner",
            "volume:update_readonly_flag": "rule:admin_or_owner",
            "volume:retype": "rule:admin_or_owner",
            "volume:update": "rule:admin_or_owner",

            "volume_extension:types_manage": "rule:admin_api",
            "volume_extension:types_extra_specs": "rule:admin_api",
            "volume_extension:access_types_qos_specs_id": "rule:admin_api",
            "volume_extension:access_types_extra_specs": "rule:admin_api",
            "volume_extension:volume_type_access": "rule:admin_or_owner",
            "volume_extension:volume_type_access:addProjectAccess": "rule:admin_api",
            "volume_extension:volume_type_access:removeProjectAccess": "rule:admin_api",
            "volume_extension:volume_type_encryption": "rule:admin_api",
            "volume_extension:volume_encryption_metadata": "rule:admin_or_owner",
            "volume_extension:extended_snapshot_attributes": "rule:admin_or_owner",
            "volume_extension:volume_image_metadata": "rule:admin_or_owner",

            "volume_extension:quotas:show": "",
            "volume_extension:quotas:update": "rule:admin_api",
            "volume_extension:quotas:delete": "rule:admin_api",
            "volume_extension:quota_classes": "rule:admin_api",
            "volume_extension:quota_classes:validate_setup_for_nested_quota_use": "rule:admin_api",

            "volume_extension:volume_admin_actions:reset_status": "rule:admin_api",
            "volume_extension:snapshot_admin_actions:reset_status": "rule:admin_api",
            "volume_extension:backup_admin_actions:reset_status": "rule:admin_api",
            "volume_extension:volume_admin_actions:force_delete": "rule:admin_api",
            "volume_extension:volume_admin_actions:force_detach": "rule:admin_api",
            "volume_extension:snapshot_admin_actions:force_delete": "rule:admin_api",
            "volume_extension:backup_admin_actions:force_delete": "rule:admin_api",
            "volume_extension:volume_admin_actions:migrate_volume": "rule:admin_api",
            "volume_extension:volume_admin_actions:migrate_volume_completion": "rule:admin_api",

            "volume_extension:volume_actions:upload_public": "rule:admin_api",
            "volume_extension:volume_actions:upload_image": "rule:admin_or_owner",

            "volume_extension:volume_host_attribute": "rule:admin_api",
            "volume_extension:volume_tenant_attribute": "rule:admin_or_owner",
            "volume_extension:volume_mig_status_attribute": "rule:admin_api",
            "volume_extension:hosts": "rule:admin_api",
            "volume_extension:services:index": "rule:admin_api",
            "volume_extension:services:update" : "rule:admin_api",

            "volume_extension:volume_manage": "rule:admin_api",
            "volume_extension:volume_unmanage": "rule:admin_api",

            "volume_extension:capabilities": "rule:admin_api",

            "volume:create_transfer": "rule:admin_or_owner",
            "volume:accept_transfer": "",
            "volume:delete_transfer": "rule:admin_or_owner",
            "volume:get_transfer": "rule:admin_or_owner",
            "volume:get_all_transfers": "rule:admin_or_owner",

            "volume_extension:replication:promote": "rule:admin_api",
            "volume_extension:replication:reenable": "rule:admin_api",

            "volume:failover_host": "rule:admin_api",
            "volume:freeze_host": "rule:admin_api",
            "volume:thaw_host": "rule:admin_api",

            "backup:create" : "",
            "backup:delete": "rule:admin_or_owner",
            "backup:get": "rule:admin_or_owner",
            "backup:get_all": "rule:admin_or_owner",
            "backup:restore": "rule:admin_or_owner",
            "backup:backup-import": "rule:admin_api",
            "backup:backup-export": "rule:admin_api",

            "snapshot_extension:snapshot_actions:update_snapshot_status": "",
            "snapshot_extension:snapshot_manage": "rule:admin_api",
            "snapshot_extension:snapshot_unmanage": "rule:admin_api",

            "consistencygroup:create" : "group:nobody",
            "consistencygroup:delete": "group:nobody",
            "consistencygroup:update": "group:nobody",
            "consistencygroup:get": "group:nobody",
            "consistencygroup:get_all": "group:nobody",

            "consistencygroup:create_cgsnapshot" : "group:nobody",
            "consistencygroup:delete_cgsnapshot": "group:nobody",
            "consistencygroup:get_cgsnapshot": "group:nobody",
            "consistencygroup:get_all_cgsnapshots": "group:nobody",

            "scheduler_extension:scheduler_stats:get_pools" : "rule:admin_api",
            "message:delete": "rule:admin_or_owner",
            "message:get": "rule:admin_or_owner",
            "message:get_all": "rule:admin_or_owner"
        }
      '';
    };

    environment.etc."horizon/conf/glance_policy.json" = {
      enable = true;
      uid = 111;
      gid = 111;
      mode = "0660";
      text = ''
        {
            "context_is_admin":  "role:admin",
            "admin_or_owner":  "is_admin:True or project_id:%(project_id)s",
            "default": "rule:admin_or_owner",

            "add_image": "",
            "delete_image": "rule:admin_or_owner",
            "get_image": "",
            "get_images": "",
            "modify_image": "rule:admin_or_owner",
            "publicize_image": "",
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

            "get_task": "",
            "get_tasks": "",
            "add_task": "",
            "modify_task": "",

            "get_metadef_namespace": "",
            "get_metadef_namespaces":"",
            "modify_metadef_namespace":"",
            "add_metadef_namespace":"",
            "delete_metadef_namespace":"",

            "get_metadef_object":"",
            "get_metadef_objects":"",
            "modify_metadef_object":"",
            "add_metadef_object":"",

            "list_metadef_resource_types":"",
            "add_metadef_resource_type_association":"",

            "get_metadef_property":"",
            "get_metadef_properties":"",
            "modify_metadef_property":"",
            "add_metadef_property":""
        }
      '';
    };

    environment.etc."horizon/conf/heat_policy.json" = {
      enable = true;
      uid = 111;
      gid = 111;
      mode = "0660";
      text = ''
        {
            "context_is_admin":  "role:admin",
            "deny_stack_user": "not role:heat_stack_user",
            "deny_everybody": "!",

            "cloudformation:ListStacks": "rule:deny_stack_user",
            "cloudformation:CreateStack": "rule:deny_stack_user",
            "cloudformation:DescribeStacks": "rule:deny_stack_user",
            "cloudformation:DeleteStack": "rule:deny_stack_user",
            "cloudformation:UpdateStack": "rule:deny_stack_user",
            "cloudformation:CancelUpdateStack": "rule:deny_stack_user",
            "cloudformation:DescribeStackEvents": "rule:deny_stack_user",
            "cloudformation:ValidateTemplate": "rule:deny_stack_user",
            "cloudformation:GetTemplate": "rule:deny_stack_user",
            "cloudformation:EstimateTemplateCost": "rule:deny_stack_user",
            "cloudformation:DescribeStackResource": "",
            "cloudformation:DescribeStackResources": "rule:deny_stack_user",
            "cloudformation:ListStackResources": "rule:deny_stack_user",

            "cloudwatch:DeleteAlarms": "rule:deny_stack_user",
            "cloudwatch:DescribeAlarmHistory": "rule:deny_stack_user",
            "cloudwatch:DescribeAlarms": "rule:deny_stack_user",
            "cloudwatch:DescribeAlarmsForMetric": "rule:deny_stack_user",
            "cloudwatch:DisableAlarmActions": "rule:deny_stack_user",
            "cloudwatch:EnableAlarmActions": "rule:deny_stack_user",
            "cloudwatch:GetMetricStatistics": "rule:deny_stack_user",
            "cloudwatch:ListMetrics": "rule:deny_stack_user",
            "cloudwatch:PutMetricAlarm": "rule:deny_stack_user",
            "cloudwatch:PutMetricData": "",
            "cloudwatch:SetAlarmState": "rule:deny_stack_user",

            "actions:action": "rule:deny_stack_user",
            "build_info:build_info": "rule:deny_stack_user",
            "events:index": "rule:deny_stack_user",
            "events:show": "rule:deny_stack_user",
            "resource:index": "rule:deny_stack_user",
            "resource:metadata": "",
            "resource:signal": "",
            "resource:mark_unhealthy": "rule:deny_stack_user",
            "resource:show": "rule:deny_stack_user",
            "stacks:abandon": "rule:deny_stack_user",
            "stacks:create": "rule:deny_stack_user",
            "stacks:delete": "rule:deny_stack_user",
            "stacks:detail": "rule:deny_stack_user",
            "stacks:export": "rule:deny_stack_user",
            "stacks:generate_template": "rule:deny_stack_user",
            "stacks:global_index": "rule:deny_everybody",
            "stacks:index": "rule:deny_stack_user",
            "stacks:list_resource_types": "rule:deny_stack_user",
            "stacks:list_template_versions": "rule:deny_stack_user",
            "stacks:list_template_functions": "rule:deny_stack_user",
            "stacks:lookup": "",
            "stacks:preview": "rule:deny_stack_user",
            "stacks:resource_schema": "rule:deny_stack_user",
            "stacks:show": "rule:deny_stack_user",
            "stacks:template": "rule:deny_stack_user",
            "stacks:environment": "rule:deny_stack_user",
            "stacks:update": "rule:deny_stack_user",
            "stacks:update_patch": "rule:deny_stack_user",
            "stacks:preview_update": "rule:deny_stack_user",
            "stacks:preview_update_patch": "rule:deny_stack_user",
            "stacks:validate_template": "rule:deny_stack_user",
            "stacks:snapshot": "rule:deny_stack_user",
            "stacks:show_snapshot": "rule:deny_stack_user",
            "stacks:delete_snapshot": "rule:deny_stack_user",
            "stacks:list_snapshots": "rule:deny_stack_user",
            "stacks:restore_snapshot": "rule:deny_stack_user",
            "stacks:list_outputs": "rule:deny_stack_user",
            "stacks:show_output": "rule:deny_stack_user",

            "software_configs:global_index": "rule:deny_everybody",
            "software_configs:index": "rule:deny_stack_user",
            "software_configs:create": "rule:deny_stack_user",
            "software_configs:show": "rule:deny_stack_user",
            "software_configs:delete": "rule:deny_stack_user",
            "software_deployments:index": "rule:deny_stack_user",
            "software_deployments:create": "rule:deny_stack_user",
            "software_deployments:show": "rule:deny_stack_user",
            "software_deployments:update": "rule:deny_stack_user",
            "software_deployments:delete": "rule:deny_stack_user",
            "software_deployments:metadata": "",

            "service:index": "rule:context_is_admin",

            "resource_types:OS::Nova::Flavor": "rule:context_is_admin",
            "resource_types:OS::Cinder::EncryptedVolumeType": "rule:context_is_admin",
            "resource_types:OS::Cinder::VolumeType": "rule:context_is_admin",
            "resource_types:OS::Manila::ShareType": "rule:context_is_admin",
            "resource_types:OS::Neutron::QoSPolicy": "rule:context_is_admin",
            "resource_types:OS::Neutron::QoSBandwidthLimitRule": "rule:context_is_admin",
            "resource_types:OS::Nova::HostAggregate": "rule:context_is_admin"
        }
      '';
    };

    environment.etc."horizon/conf/keystone_policy.json" = {
      enable = true;
      uid = 111;
      gid = 111;
      mode = "0660";
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

            "identity:get_domain": "rule:admin_required",
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

            "identity:get_user": "rule:admin_required",
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

            "identity:list_projects_for_groups": "",
            "identity:list_domains_for_groups": "",

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

    environment.etc."horizon/conf/neutron_policy.json" = {
      enable = true;
      uid = 111;
      gid = 111;
      mode = "0660";
      text = ''
        {
            "context_is_admin":  "role:admin",
            "owner": "tenant_id:%(tenant_id)s",
            "admin_or_owner": "rule:context_is_admin or rule:owner",
            "context_is_advsvc":  "role:advsvc",
            "admin_or_network_owner": "rule:context_is_admin or tenant_id:%(network:tenant_id)s",
            "admin_owner_or_network_owner": "rule:owner or rule:admin_or_network_owner",
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
            "create_subnet:segment_id": "rule:admin_only",
            "get_subnet": "rule:admin_or_owner or rule:shared",
            "get_subnet:segment_id": "rule:admin_only",
            "update_subnet": "rule:admin_or_network_owner",
            "delete_subnet": "rule:admin_or_network_owner",

            "create_subnetpool": "",
            "create_subnetpool:shared": "rule:admin_only",
            "create_subnetpool:is_default": "rule:admin_only",
            "get_subnetpool": "rule:admin_or_owner or rule:shared_subnetpools",
            "update_subnetpool": "rule:admin_or_owner",
            "update_subnetpool:is_default": "rule:admin_only",
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
            "get_network_ip_availabilities": "rule:admin_only",
            "get_network_ip_availability": "rule:admin_only",
            "create_network:shared": "rule:admin_only",
            "create_network:router:external": "rule:admin_only",
            "create_network:is_default": "rule:admin_only",
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

            "create_segment": "rule:admin_only",
            "get_segment": "rule:admin_only",
            "update_segment": "rule:admin_only",
            "delete_segment": "rule:admin_only",

            "network_device": "field:port:device_owner=~^network:",
            "create_port": "",
            "create_port:device_owner": "not rule:network_device or rule:context_is_advsvc or rule:admin_or_network_owner",
            "create_port:mac_address": "rule:context_is_advsvc or rule:admin_or_network_owner",
            "create_port:fixed_ips": "rule:context_is_advsvc or rule:admin_or_network_owner",
            "create_port:port_security_enabled": "rule:context_is_advsvc or rule:admin_or_network_owner",
            "create_port:binding:host_id": "rule:admin_only",
            "create_port:binding:profile": "rule:admin_only",
            "create_port:mac_learning_enabled": "rule:context_is_advsvc or rule:admin_or_network_owner",
            "create_port:allowed_address_pairs": "rule:admin_or_network_owner",
            "get_port": "rule:context_is_advsvc or rule:admin_owner_or_network_owner",
            "get_port:queue_id": "rule:admin_only",
            "get_port:binding:vif_type": "rule:admin_only",
            "get_port:binding:vif_details": "rule:admin_only",
            "get_port:binding:host_id": "rule:admin_only",
            "get_port:binding:profile": "rule:admin_only",
            "update_port": "rule:admin_or_owner or rule:context_is_advsvc",
            "update_port:device_owner": "not rule:network_device or rule:context_is_advsvc or rule:admin_or_network_owner",
            "update_port:mac_address": "rule:admin_only or rule:context_is_advsvc",
            "update_port:fixed_ips": "rule:context_is_advsvc or rule:admin_or_network_owner",
            "update_port:port_security_enabled": "rule:context_is_advsvc or rule:admin_or_network_owner",
            "update_port:binding:host_id": "rule:admin_only",
            "update_port:binding:profile": "rule:admin_only",
            "update_port:mac_learning_enabled": "rule:context_is_advsvc or rule:admin_or_network_owner",
            "update_port:allowed_address_pairs": "rule:admin_or_network_owner",
            "delete_port": "rule:context_is_advsvc or rule:admin_owner_or_network_owner",

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
            "get_policy_dscp_marking_rule": "rule:regular_user",
            "create_policy_dscp_marking_rule": "rule:admin_only",
            "delete_policy_dscp_marking_rule": "rule:admin_only",
            "update_policy_dscp_marking_rule": "rule:admin_only",
            "get_rule_type": "rule:regular_user",

            "restrict_wildcard": "(not field:rbac_policy:target_tenant=*) or rule:admin_only",
            "create_rbac_policy": "",
            "create_rbac_policy:target_tenant": "rule:restrict_wildcard",
            "update_rbac_policy": "rule:admin_or_owner",
            "update_rbac_policy:target_tenant": "rule:restrict_wildcard and rule:admin_or_owner",
            "get_rbac_policy": "rule:admin_or_owner",
            "delete_rbac_policy": "rule:admin_or_owner",

            "create_flavor_service_profile": "rule:admin_only",
            "delete_flavor_service_profile": "rule:admin_only",
            "get_flavor_service_profile": "rule:regular_user",
            "get_auto_allocated_topology": "rule:admin_or_owner"
        }
      '';
    };

    environment.etc."horizon/conf/nova_policy.json" = {
      enable = true;
      uid = 111;
      gid = 111;
      mode = "0660";
      text = ''
        {
            "context_is_admin":  "role:admin",
            "admin_or_owner":  "is_admin:True or project_id:%(project_id)s",
            "default": "rule:admin_or_owner",

            "cells_scheduler_filter:TargetCellFilter": "is_admin:True",

            "compute:create": "rule:admin_or_owner",
            "compute:create:attach_network": "rule:admin_or_owner",
            "compute:create:attach_volume": "rule:admin_or_owner",
            "compute:create:forced_host": "is_admin:True",

            "compute:get": "rule:admin_or_owner",
            "compute:get_all": "rule:admin_or_owner",
            "compute:get_all_tenants": "is_admin:True",

            "compute:update": "rule:admin_or_owner",

            "compute:get_instance_metadata": "rule:admin_or_owner",
            "compute:get_all_instance_metadata": "rule:admin_or_owner",
            "compute:get_all_instance_system_metadata": "rule:admin_or_owner",
            "compute:update_instance_metadata": "rule:admin_or_owner",
            "compute:delete_instance_metadata": "rule:admin_or_owner",

            "compute:get_diagnostics": "rule:admin_or_owner",
            "compute:get_instance_diagnostics": "rule:admin_or_owner",

            "compute:start": "rule:admin_or_owner",
            "compute:stop": "rule:admin_or_owner",

            "compute:lock": "rule:admin_or_owner",
            "compute:unlock": "rule:admin_or_owner",
            "compute:unlock_override": "rule:admin_api",

            "compute:get_vnc_console": "rule:admin_or_owner",
            "compute:get_spice_console": "rule:admin_or_owner",
            "compute:get_rdp_console": "rule:admin_or_owner",
            "compute:get_serial_console": "rule:admin_or_owner",
            "compute:get_mks_console": "rule:admin_or_owner",
            "compute:get_console_output": "rule:admin_or_owner",

            "compute:reset_network": "rule:admin_or_owner",
            "compute:inject_network_info": "rule:admin_or_owner",
            "compute:add_fixed_ip": "rule:admin_or_owner",
            "compute:remove_fixed_ip": "rule:admin_or_owner",

            "compute:attach_volume": "rule:admin_or_owner",
            "compute:detach_volume": "rule:admin_or_owner",
            "compute:swap_volume": "rule:admin_api",

            "compute:attach_interface": "rule:admin_or_owner",
            "compute:detach_interface": "rule:admin_or_owner",

            "compute:set_admin_password": "rule:admin_or_owner",

            "compute:rescue": "rule:admin_or_owner",
            "compute:unrescue": "rule:admin_or_owner",

            "compute:suspend": "rule:admin_or_owner",
            "compute:resume": "rule:admin_or_owner",

            "compute:pause": "rule:admin_or_owner",
            "compute:unpause": "rule:admin_or_owner",

            "compute:shelve": "rule:admin_or_owner",
            "compute:shelve_offload": "rule:admin_or_owner",
            "compute:unshelve": "rule:admin_or_owner",

            "compute:snapshot": "rule:admin_or_owner",
            "compute:snapshot_volume_backed": "rule:admin_or_owner",
            "compute:backup": "rule:admin_or_owner",

            "compute:resize": "rule:admin_or_owner",
            "compute:confirm_resize": "rule:admin_or_owner",
            "compute:revert_resize": "rule:admin_or_owner",

            "compute:rebuild": "rule:admin_or_owner",
            "compute:reboot": "rule:admin_or_owner",
            "compute:delete": "rule:admin_or_owner",
            "compute:soft_delete": "rule:admin_or_owner",
            "compute:force_delete": "rule:admin_or_owner",

            "compute:security_groups:add_to_instance": "rule:admin_or_owner",
            "compute:security_groups:remove_from_instance": "rule:admin_or_owner",

            "compute:restore": "rule:admin_or_owner",

            "compute:volume_snapshot_create": "rule:admin_or_owner",
            "compute:volume_snapshot_delete": "rule:admin_or_owner",

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
            "compute_extension:attach_interfaces": "rule:admin_or_owner",
            "compute_extension:baremetal_nodes": "rule:admin_api",
            "compute_extension:cells": "rule:admin_api",
            "compute_extension:cells:create": "rule:admin_api",
            "compute_extension:cells:delete": "rule:admin_api",
            "compute_extension:cells:update": "rule:admin_api",
            "compute_extension:cells:sync_instances": "rule:admin_api",
            "compute_extension:certificates": "rule:admin_or_owner",
            "compute_extension:cloudpipe": "rule:admin_api",
            "compute_extension:cloudpipe_update": "rule:admin_api",
            "compute_extension:config_drive": "rule:admin_or_owner",
            "compute_extension:console_output": "rule:admin_or_owner",
            "compute_extension:consoles": "rule:admin_or_owner",
            "compute_extension:createserverext": "rule:admin_or_owner",
            "compute_extension:deferred_delete": "rule:admin_or_owner",
            "compute_extension:disk_config": "rule:admin_or_owner",
            "compute_extension:evacuate": "rule:admin_api",
            "compute_extension:extended_server_attributes": "rule:admin_api",
            "compute_extension:extended_status": "rule:admin_or_owner",
            "compute_extension:extended_availability_zone": "rule:admin_or_owner",
            "compute_extension:extended_ips": "rule:admin_or_owner",
            "compute_extension:extended_ips_mac": "rule:admin_or_owner",
            "compute_extension:extended_vif_net": "rule:admin_or_owner",
            "compute_extension:extended_volumes": "rule:admin_or_owner",
            "compute_extension:fixed_ips": "rule:admin_api",
            "compute_extension:flavor_access": "rule:admin_or_owner",
            "compute_extension:flavor_access:addTenantAccess": "rule:admin_api",
            "compute_extension:flavor_access:removeTenantAccess": "rule:admin_api",
            "compute_extension:flavor_disabled": "rule:admin_or_owner",
            "compute_extension:flavor_rxtx": "rule:admin_or_owner",
            "compute_extension:flavor_swap": "rule:admin_or_owner",
            "compute_extension:flavorextradata": "rule:admin_or_owner",
            "compute_extension:flavorextraspecs:index": "rule:admin_or_owner",
            "compute_extension:flavorextraspecs:show": "rule:admin_or_owner",
            "compute_extension:flavorextraspecs:create": "rule:admin_api",
            "compute_extension:flavorextraspecs:update": "rule:admin_api",
            "compute_extension:flavorextraspecs:delete": "rule:admin_api",
            "compute_extension:flavormanage": "rule:admin_api",
            "compute_extension:floating_ip_dns": "rule:admin_or_owner",
            "compute_extension:floating_ip_pools": "rule:admin_or_owner",
            "compute_extension:floating_ips": "rule:admin_or_owner",
            "compute_extension:floating_ips_bulk": "rule:admin_api",
            "compute_extension:fping": "rule:admin_or_owner",
            "compute_extension:fping:all_tenants": "rule:admin_api",
            "compute_extension:hide_server_addresses": "is_admin:False",
            "compute_extension:hosts": "rule:admin_api",
            "compute_extension:hypervisors": "rule:admin_api",
            "compute_extension:image_size": "rule:admin_or_owner",
            "compute_extension:instance_actions": "rule:admin_or_owner",
            "compute_extension:instance_actions:events": "rule:admin_api",
            "compute_extension:instance_usage_audit_log": "rule:admin_api",
            "compute_extension:keypairs": "rule:admin_or_owner",
            "compute_extension:keypairs:index": "rule:admin_or_owner",
            "compute_extension:keypairs:show": "rule:admin_or_owner",
            "compute_extension:keypairs:create": "rule:admin_or_owner",
            "compute_extension:keypairs:delete": "rule:admin_or_owner",
            "compute_extension:multinic": "rule:admin_or_owner",
            "compute_extension:networks": "rule:admin_api",
            "compute_extension:networks:view": "rule:admin_or_owner",
            "compute_extension:networks_associate": "rule:admin_api",
            "compute_extension:os-tenant-networks": "rule:admin_or_owner",
            "compute_extension:quotas:show": "rule:admin_or_owner",
            "compute_extension:quotas:update": "rule:admin_api",
            "compute_extension:quotas:delete": "rule:admin_api",
            "compute_extension:quota_classes": "rule:admin_or_owner",
            "compute_extension:rescue": "rule:admin_or_owner",
            "compute_extension:security_group_default_rules": "rule:admin_api",
            "compute_extension:security_groups": "rule:admin_or_owner",
            "compute_extension:server_diagnostics": "rule:admin_api",
            "compute_extension:server_groups": "rule:admin_or_owner",
            "compute_extension:server_password": "rule:admin_or_owner",
            "compute_extension:server_usage": "rule:admin_or_owner",
            "compute_extension:services": "rule:admin_api",
            "compute_extension:shelve": "rule:admin_or_owner",
            "compute_extension:shelveOffload": "rule:admin_api",
            "compute_extension:simple_tenant_usage:show": "rule:admin_or_owner",
            "compute_extension:simple_tenant_usage:list": "rule:admin_api",
            "compute_extension:unshelve": "rule:admin_or_owner",
            "compute_extension:users": "rule:admin_api",
            "compute_extension:virtual_interfaces": "rule:admin_or_owner",
            "compute_extension:virtual_storage_arrays": "rule:admin_or_owner",
            "compute_extension:volumes": "rule:admin_or_owner",
            "compute_extension:volume_attachments:index": "rule:admin_or_owner",
            "compute_extension:volume_attachments:show": "rule:admin_or_owner",
            "compute_extension:volume_attachments:create": "rule:admin_or_owner",
            "compute_extension:volume_attachments:update": "rule:admin_api",
            "compute_extension:volume_attachments:delete": "rule:admin_or_owner",
            "compute_extension:volumetypes": "rule:admin_or_owner",
            "compute_extension:availability_zone:list": "rule:admin_or_owner",
            "compute_extension:availability_zone:detail": "rule:admin_api",
            "compute_extension:used_limits_for_admin": "rule:admin_api",
            "compute_extension:migrations:index": "rule:admin_api",
            "compute_extension:os-assisted-volume-snapshots:create": "rule:admin_api",
            "compute_extension:os-assisted-volume-snapshots:delete": "rule:admin_api",
            "compute_extension:console_auth_tokens": "rule:admin_api",
            "compute_extension:os-server-external-events:create": "rule:admin_api",

            "network:get_all": "rule:admin_or_owner",
            "network:get": "rule:admin_or_owner",
            "network:create": "rule:admin_or_owner",
            "network:delete": "rule:admin_or_owner",
            "network:associate": "rule:admin_or_owner",
            "network:disassociate": "rule:admin_or_owner",
            "network:get_vifs_by_instance": "rule:admin_or_owner",
            "network:allocate_for_instance": "rule:admin_or_owner",
            "network:deallocate_for_instance": "rule:admin_or_owner",
            "network:validate_networks": "rule:admin_or_owner",
            "network:get_instance_uuids_by_ip_filter": "rule:admin_or_owner",
            "network:get_instance_id_by_floating_address": "rule:admin_or_owner",
            "network:setup_networks_on_host": "rule:admin_or_owner",
            "network:get_backdoor_port": "rule:admin_or_owner",

            "network:get_floating_ip": "rule:admin_or_owner",
            "network:get_floating_ip_pools": "rule:admin_or_owner",
            "network:get_floating_ip_by_address": "rule:admin_or_owner",
            "network:get_floating_ips_by_project": "rule:admin_or_owner",
            "network:get_floating_ips_by_fixed_address": "rule:admin_or_owner",
            "network:allocate_floating_ip": "rule:admin_or_owner",
            "network:associate_floating_ip": "rule:admin_or_owner",
            "network:disassociate_floating_ip": "rule:admin_or_owner",
            "network:release_floating_ip": "rule:admin_or_owner",
            "network:migrate_instance_start": "rule:admin_or_owner",
            "network:migrate_instance_finish": "rule:admin_or_owner",

            "network:get_fixed_ip": "rule:admin_or_owner",
            "network:get_fixed_ip_by_address": "rule:admin_or_owner",
            "network:add_fixed_ip_to_instance": "rule:admin_or_owner",
            "network:remove_fixed_ip_from_instance": "rule:admin_or_owner",
            "network:add_network_to_project": "rule:admin_or_owner",
            "network:get_instance_nw_info": "rule:admin_or_owner",

            "network:get_dns_domains": "rule:admin_or_owner",
            "network:add_dns_entry": "rule:admin_or_owner",
            "network:modify_dns_entry": "rule:admin_or_owner",
            "network:delete_dns_entry": "rule:admin_or_owner",
            "network:get_dns_entries_by_address": "rule:admin_or_owner",
            "network:get_dns_entries_by_name": "rule:admin_or_owner",
            "network:create_private_dns_domain": "rule:admin_or_owner",
            "network:create_public_dns_domain": "rule:admin_or_owner",
            "network:delete_dns_domain": "rule:admin_or_owner",
            "network:attach_external_network": "rule:admin_api",
            "network:get_vif_by_mac_address": "rule:admin_or_owner",

            "os_compute_api:servers:detail:get_all_tenants": "is_admin:True",
            "os_compute_api:servers:index:get_all_tenants": "is_admin:True",
            "os_compute_api:servers:confirm_resize": "rule:admin_or_owner",
            "os_compute_api:servers:create": "rule:admin_or_owner",
            "os_compute_api:servers:create:attach_network": "rule:admin_or_owner",
            "os_compute_api:servers:create:attach_volume": "rule:admin_or_owner",
            "os_compute_api:servers:create:forced_host": "rule:admin_api",
            "os_compute_api:servers:delete": "rule:admin_or_owner",
            "os_compute_api:servers:update": "rule:admin_or_owner",
            "os_compute_api:servers:detail": "rule:admin_or_owner",
            "os_compute_api:servers:index": "rule:admin_or_owner",
            "os_compute_api:servers:reboot": "rule:admin_or_owner",
            "os_compute_api:servers:rebuild": "rule:admin_or_owner",
            "os_compute_api:servers:resize": "rule:admin_or_owner",
            "os_compute_api:servers:revert_resize": "rule:admin_or_owner",
            "os_compute_api:servers:show": "rule:admin_or_owner",
            "os_compute_api:servers:show:host_status": "rule:admin_api",
            "os_compute_api:servers:create_image": "rule:admin_or_owner",
            "os_compute_api:servers:create_image:allow_volume_backed": "rule:admin_or_owner",
            "os_compute_api:servers:start": "rule:admin_or_owner",
            "os_compute_api:servers:stop": "rule:admin_or_owner",
            "os_compute_api:servers:trigger_crash_dump": "rule:admin_or_owner",
            "os_compute_api:servers:migrations:force_complete": "rule:admin_api",
            "os_compute_api:servers:migrations:delete": "rule:admin_api",
            "os_compute_api:servers:discoverable": "@",
            "os_compute_api:servers:migrations:index": "rule:admin_api",
            "os_compute_api:servers:migrations:show": "rule:admin_api",
            "os_compute_api:os-access-ips:discoverable": "@",
            "os_compute_api:os-access-ips": "rule:admin_or_owner",
            "os_compute_api:os-admin-actions": "rule:admin_api",
            "os_compute_api:os-admin-actions:discoverable": "@",
            "os_compute_api:os-admin-actions:reset_network": "rule:admin_api",
            "os_compute_api:os-admin-actions:inject_network_info": "rule:admin_api",
            "os_compute_api:os-admin-actions:reset_state": "rule:admin_api",
            "os_compute_api:os-admin-password": "rule:admin_or_owner",
            "os_compute_api:os-admin-password:discoverable": "@",
            "os_compute_api:os-aggregates:discoverable": "@",
            "os_compute_api:os-aggregates:index": "rule:admin_api",
            "os_compute_api:os-aggregates:create": "rule:admin_api",
            "os_compute_api:os-aggregates:show": "rule:admin_api",
            "os_compute_api:os-aggregates:update": "rule:admin_api",
            "os_compute_api:os-aggregates:delete": "rule:admin_api",
            "os_compute_api:os-aggregates:add_host": "rule:admin_api",
            "os_compute_api:os-aggregates:remove_host": "rule:admin_api",
            "os_compute_api:os-aggregates:set_metadata": "rule:admin_api",
            "os_compute_api:os-agents": "rule:admin_api",
            "os_compute_api:os-agents:discoverable": "@",
            "os_compute_api:os-attach-interfaces": "rule:admin_or_owner",
            "os_compute_api:os-attach-interfaces:discoverable": "@",
            "os_compute_api:os-baremetal-nodes": "rule:admin_api",
            "os_compute_api:os-baremetal-nodes:discoverable": "@",
            "os_compute_api:os-block-device-mapping-v1:discoverable": "@",
            "os_compute_api:os-cells": "rule:admin_api",
            "os_compute_api:os-cells:create": "rule:admin_api",
            "os_compute_api:os-cells:delete": "rule:admin_api",
            "os_compute_api:os-cells:update": "rule:admin_api",
            "os_compute_api:os-cells:sync_instances": "rule:admin_api",
            "os_compute_api:os-cells:discoverable": "@",
            "os_compute_api:os-certificates:create": "rule:admin_or_owner",
            "os_compute_api:os-certificates:show": "rule:admin_or_owner",
            "os_compute_api:os-certificates:discoverable": "@",
            "os_compute_api:os-cloudpipe": "rule:admin_api",
            "os_compute_api:os-cloudpipe:discoverable": "@",
            "os_compute_api:os-config-drive": "rule:admin_or_owner",
            "os_compute_api:os-config-drive:discoverable": "@",
            "os_compute_api:os-consoles:discoverable": "@",
            "os_compute_api:os-consoles:create": "rule:admin_or_owner",
            "os_compute_api:os-consoles:delete": "rule:admin_or_owner",
            "os_compute_api:os-consoles:index": "rule:admin_or_owner",
            "os_compute_api:os-consoles:show": "rule:admin_or_owner",
            "os_compute_api:os-console-output:discoverable": "@",
            "os_compute_api:os-console-output": "rule:admin_or_owner",
            "os_compute_api:os-remote-consoles": "rule:admin_or_owner",
            "os_compute_api:os-remote-consoles:discoverable": "@",
            "os_compute_api:os-create-backup:discoverable": "@",
            "os_compute_api:os-create-backup": "rule:admin_or_owner",
            "os_compute_api:os-deferred-delete": "rule:admin_or_owner",
            "os_compute_api:os-deferred-delete:discoverable": "@",
            "os_compute_api:os-disk-config": "rule:admin_or_owner",
            "os_compute_api:os-disk-config:discoverable": "@",
            "os_compute_api:os-evacuate": "rule:admin_api",
            "os_compute_api:os-evacuate:discoverable": "@",
            "os_compute_api:os-extended-server-attributes": "rule:admin_api",
            "os_compute_api:os-extended-server-attributes:discoverable": "@",
            "os_compute_api:os-extended-status": "rule:admin_or_owner",
            "os_compute_api:os-extended-status:discoverable": "@",
            "os_compute_api:os-extended-availability-zone": "rule:admin_or_owner",
            "os_compute_api:os-extended-availability-zone:discoverable": "@",
            "os_compute_api:extensions": "rule:admin_or_owner",
            "os_compute_api:extensions:discoverable": "@",
            "os_compute_api:extension_info:discoverable": "@",
            "os_compute_api:os-extended-volumes": "rule:admin_or_owner",
            "os_compute_api:os-extended-volumes:discoverable": "@",
            "os_compute_api:os-fixed-ips": "rule:admin_api",
            "os_compute_api:os-fixed-ips:discoverable": "@",
            "os_compute_api:os-flavor-access": "rule:admin_or_owner",
            "os_compute_api:os-flavor-access:discoverable": "@",
            "os_compute_api:os-flavor-access:remove_tenant_access": "rule:admin_api",
            "os_compute_api:os-flavor-access:add_tenant_access": "rule:admin_api",
            "os_compute_api:os-flavor-rxtx": "rule:admin_or_owner",
            "os_compute_api:os-flavor-rxtx:discoverable": "@",
            "os_compute_api:flavors": "rule:admin_or_owner",
            "os_compute_api:flavors:discoverable": "@",
            "os_compute_api:os-flavor-extra-specs:discoverable": "@",
            "os_compute_api:os-flavor-extra-specs:index": "rule:admin_or_owner",
            "os_compute_api:os-flavor-extra-specs:show": "rule:admin_or_owner",
            "os_compute_api:os-flavor-extra-specs:create": "rule:admin_api",
            "os_compute_api:os-flavor-extra-specs:update": "rule:admin_api",
            "os_compute_api:os-flavor-extra-specs:delete": "rule:admin_api",
            "os_compute_api:os-flavor-manage:discoverable": "@",
            "os_compute_api:os-flavor-manage": "rule:admin_api",
            "os_compute_api:os-floating-ip-dns": "rule:admin_or_owner",
            "os_compute_api:os-floating-ip-dns:discoverable": "@",
            "os_compute_api:os-floating-ip-dns:domain:update": "rule:admin_api",
            "os_compute_api:os-floating-ip-dns:domain:delete": "rule:admin_api",
            "os_compute_api:os-floating-ip-pools": "rule:admin_or_owner",
            "os_compute_api:os-floating-ip-pools:discoverable": "@",
            "os_compute_api:os-floating-ips": "rule:admin_or_owner",
            "os_compute_api:os-floating-ips:discoverable": "@",
            "os_compute_api:os-floating-ips-bulk": "rule:admin_api",
            "os_compute_api:os-floating-ips-bulk:discoverable": "@",
            "os_compute_api:os-fping": "rule:admin_or_owner",
            "os_compute_api:os-fping:discoverable": "@",
            "os_compute_api:os-fping:all_tenants": "rule:admin_api",
            "os_compute_api:os-hide-server-addresses": "is_admin:False",
            "os_compute_api:os-hide-server-addresses:discoverable": "@",
            "os_compute_api:os-hosts": "rule:admin_api",
            "os_compute_api:os-hosts:discoverable": "@",
            "os_compute_api:os-hypervisors": "rule:admin_api",
            "os_compute_api:os-hypervisors:discoverable": "@",
            "os_compute_api:images:discoverable": "@",
            "os_compute_api:image-size": "rule:admin_or_owner",
            "os_compute_api:image-size:discoverable": "@",
            "os_compute_api:os-instance-actions": "rule:admin_or_owner",
            "os_compute_api:os-instance-actions:discoverable": "@",
            "os_compute_api:os-instance-actions:events": "rule:admin_api",
            "os_compute_api:os-instance-usage-audit-log": "rule:admin_api",
            "os_compute_api:os-instance-usage-audit-log:discoverable": "@",
            "os_compute_api:ips:discoverable": "@",
            "os_compute_api:ips:index": "rule:admin_or_owner",
            "os_compute_api:ips:show": "rule:admin_or_owner",
            "os_compute_api:os-keypairs:discoverable": "@",
            "os_compute_api:os-keypairs": "rule:admin_or_owner",
            "os_compute_api:os-keypairs:index": "rule:admin_api or user_id:%(user_id)s",
            "os_compute_api:os-keypairs:show": "rule:admin_api or user_id:%(user_id)s",
            "os_compute_api:os-keypairs:create": "rule:admin_api or user_id:%(user_id)s",
            "os_compute_api:os-keypairs:delete": "rule:admin_api or user_id:%(user_id)s",
            "os_compute_api:limits:discoverable": "@",
            "os_compute_api:limits": "rule:admin_or_owner",
            "os_compute_api:os-lock-server:discoverable": "@",
            "os_compute_api:os-lock-server:lock": "rule:admin_or_owner",
            "os_compute_api:os-lock-server:unlock": "rule:admin_or_owner",
            "os_compute_api:os-lock-server:unlock:unlock_override": "rule:admin_api",
            "os_compute_api:os-migrate-server:discoverable": "@",
            "os_compute_api:os-migrate-server:migrate": "rule:admin_api",
            "os_compute_api:os-migrate-server:migrate_live": "rule:admin_api",
            "os_compute_api:os-multinic": "rule:admin_or_owner",
            "os_compute_api:os-multinic:discoverable": "@",
            "os_compute_api:os-networks": "rule:admin_api",
            "os_compute_api:os-networks:view": "rule:admin_or_owner",
            "os_compute_api:os-networks:discoverable": "@",
            "os_compute_api:os-networks-associate": "rule:admin_api",
            "os_compute_api:os-networks-associate:discoverable": "@",
            "os_compute_api:os-pause-server:discoverable": "@",
            "os_compute_api:os-pause-server:pause": "rule:admin_or_owner",
            "os_compute_api:os-pause-server:unpause": "rule:admin_or_owner",
            "os_compute_api:os-pci:pci_servers": "rule:admin_or_owner",
            "os_compute_api:os-pci:discoverable": "@",
            "os_compute_api:os-pci:index": "rule:admin_api",
            "os_compute_api:os-pci:detail": "rule:admin_api",
            "os_compute_api:os-pci:show": "rule:admin_api",
            "os_compute_api:os-personality:discoverable": "@",
            "os_compute_api:os-preserve-ephemeral-rebuild:discoverable": "@",
            "os_compute_api:os-quota-sets:discoverable": "@",
            "os_compute_api:os-quota-sets:show": "rule:admin_or_owner",
            "os_compute_api:os-quota-sets:defaults": "@",
            "os_compute_api:os-quota-sets:update": "rule:admin_api",
            "os_compute_api:os-quota-sets:delete": "rule:admin_api",
            "os_compute_api:os-quota-sets:detail": "rule:admin_api",
            "os_compute_api:os-quota-class-sets:update": "rule:admin_api",
            "os_compute_api:os-quota-class-sets:show": "is_admin:True or quota_class:%(quota_class)s",
            "os_compute_api:os-quota-class-sets:discoverable": "@",
            "os_compute_api:os-rescue": "rule:admin_or_owner",
            "os_compute_api:os-rescue:discoverable": "@",
            "os_compute_api:os-scheduler-hints:discoverable": "@",
            "os_compute_api:os-security-group-default-rules:discoverable": "@",
            "os_compute_api:os-security-group-default-rules": "rule:admin_api",
            "os_compute_api:os-security-groups": "rule:admin_or_owner",
            "os_compute_api:os-security-groups:discoverable": "@",
            "os_compute_api:os-server-diagnostics": "rule:admin_api",
            "os_compute_api:os-server-diagnostics:discoverable": "@",
            "os_compute_api:os-server-password": "rule:admin_or_owner",
            "os_compute_api:os-server-password:discoverable": "@",
            "os_compute_api:os-server-usage": "rule:admin_or_owner",
            "os_compute_api:os-server-usage:discoverable": "@",
            "os_compute_api:os-server-groups": "rule:admin_or_owner",
            "os_compute_api:os-server-groups:discoverable": "@",
            "os_compute_api:os-server-tags:index": "@",
            "os_compute_api:os-server-tags:show": "@",
            "os_compute_api:os-server-tags:update": "@",
            "os_compute_api:os-server-tags:update_all": "@",
            "os_compute_api:os-server-tags:delete": "@",
            "os_compute_api:os-server-tags:delete_all": "@",
            "os_compute_api:os-services": "rule:admin_api",
            "os_compute_api:os-services:discoverable": "@",
            "os_compute_api:server-metadata:discoverable": "@",
            "os_compute_api:server-metadata:index": "rule:admin_or_owner",
            "os_compute_api:server-metadata:show": "rule:admin_or_owner",
            "os_compute_api:server-metadata:delete": "rule:admin_or_owner",
            "os_compute_api:server-metadata:create": "rule:admin_or_owner",
            "os_compute_api:server-metadata:update": "rule:admin_or_owner",
            "os_compute_api:server-metadata:update_all": "rule:admin_or_owner",
            "os_compute_api:os-shelve:shelve": "rule:admin_or_owner",
            "os_compute_api:os-shelve:shelve:discoverable": "@",
            "os_compute_api:os-shelve:shelve_offload": "rule:admin_api",
            "os_compute_api:os-simple-tenant-usage:discoverable": "@",
            "os_compute_api:os-simple-tenant-usage:show": "rule:admin_or_owner",
            "os_compute_api:os-simple-tenant-usage:list": "rule:admin_api",
            "os_compute_api:os-suspend-server:discoverable": "@",
            "os_compute_api:os-suspend-server:suspend": "rule:admin_or_owner",
            "os_compute_api:os-suspend-server:resume": "rule:admin_or_owner",
            "os_compute_api:os-tenant-networks": "rule:admin_or_owner",
            "os_compute_api:os-tenant-networks:discoverable": "@",
            "os_compute_api:os-shelve:unshelve": "rule:admin_or_owner",
            "os_compute_api:os-user-data:discoverable": "@",
            "os_compute_api:os-virtual-interfaces": "rule:admin_or_owner",
            "os_compute_api:os-virtual-interfaces:discoverable": "@",
            "os_compute_api:os-volumes": "rule:admin_or_owner",
            "os_compute_api:os-volumes:discoverable": "@",
            "os_compute_api:os-volumes-attachments:index": "rule:admin_or_owner",
            "os_compute_api:os-volumes-attachments:show": "rule:admin_or_owner",
            "os_compute_api:os-volumes-attachments:create": "rule:admin_or_owner",
            "os_compute_api:os-volumes-attachments:update": "rule:admin_api",
            "os_compute_api:os-volumes-attachments:delete": "rule:admin_or_owner",
            "os_compute_api:os-volumes-attachments:discoverable": "@",
            "os_compute_api:os-availability-zone:list": "rule:admin_or_owner",
            "os_compute_api:os-availability-zone:discoverable": "@",
            "os_compute_api:os-availability-zone:detail": "rule:admin_api",
            "os_compute_api:os-used-limits": "rule:admin_api",
            "os_compute_api:os-used-limits:discoverable": "@",
            "os_compute_api:os-migrations:index": "rule:admin_api",
            "os_compute_api:os-migrations:discoverable": "@",
            "os_compute_api:os-assisted-volume-snapshots:create": "rule:admin_api",
            "os_compute_api:os-assisted-volume-snapshots:delete": "rule:admin_api",
            "os_compute_api:os-assisted-volume-snapshots:discoverable": "@",
            "os_compute_api:os-console-auth-tokens": "rule:admin_api",
            "os_compute_api:os-console-auth-tokens:discoverable": "@",
            "os_compute_api:os-server-external-events:create": "rule:admin_api",
            "os_compute_api:os-server-external-events:discoverable": "@"
        }
      '';
    };

    system.activationScripts.horizon = stringAfter [ "etc" "users" ]
      ''
        mkdir -m 0755 -p /var/lib/horizon/openstack_dashboard
        mkdir -m 0755 -p /var/lib/horizon/openstack_dashboard/local/enabled

        ln -sfn /etc/horizon/local_settings.py /var/lib/horizon/openstack_dashboard/local/local_settings.py

        touch /var/lib/horizon/openstack_dashboard/local/__init__.py
        touch /var/lib/horizon/openstack_dashboard/local/enabled/__init__.py

        mkdir -m 0755 -p /var/lib/horizon/openstack_dashboard/conf
        ln -sfn /etc/horizon/conf/ceilometer_policy.json /var/lib/horizon/openstack_dashboard/conf/ceilometer_policy.json
        ln -sfn /etc/horizon/conf/cinder_policy.json /var/lib/horizon/openstack_dashboard/conf/cinder_policy.json
        ln -sfn /etc/horizon/conf/glance_policy.json /var/lib/horizon/openstack_dashboard/conf/glance_policy.json
        ln -sfn /etc/horizon/conf/heat_policy.json /var/lib/horizon/openstack_dashboard/conf/heat_policy.json
        ln -sfn /etc/horizon/conf/keystone_policy.json /var/lib/horizon/openstack_dashboard/conf/keystone_policy.json
        ln -sfn /etc/horizon/conf/neutron_policy.json /var/lib/horizon/openstack_dashboard/conf/neutron_policy.json
        ln -sfn /etc/horizon/conf/nova_policy.json /var/lib/horizon/openstack_dashboard/conf/nova_policy.json

        ${pkgs.python27}/bin/python ${horizon}/bin/.manage.py-wrapped collectstatic --noinput
        chmod 0755 /var/lib/horizon/static

        chmod 0755 /var/lib/horizon
        chown horizon:nginx -R /var/lib/horizon
      '';

    networking.firewall.allowedTCPPorts = [
      80
    ];

    # Enable nginx
    services.nginx.enable = true;

    services.nginx.clientMaxBodySize = "5120m";
    services.nginx.virtualHosts."horizon" = {
      listen = [
        { addr = "0.0.0.0"; port = 80; }
      ];

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
            alias /var/lib/horizon/static;
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
        #logto = "/run/uwsgi/horizon.log";

        chdir = "/var/lib/horizon";

        plugin = "python2";

        wsgi-file = "${horizon}/bin/.horizon.wsgi-wrapped";
      };
    };
  };
}
