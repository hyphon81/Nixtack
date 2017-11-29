{ pkgs
, stdenv
, fetchurl
, python
, python2Packages
, callPackage
, makeWrapper
, buildEnv
}:

let
  modpacks = callPackage ./python-packages.nix {};
  mod-openstackclient = callPackage ./openstackclient.nix {};
  pythonHasOsloConcMod = python.buildEnv.override {
    extraLibs = [
      modpacks.oslo-concurrency
    ];
  };

  sqlite3 = if builtins.hasAttr "sqlite3" pkgs then pkgs.sqlite3 else pkgs.sqlite;
  mod-libvirt = callPackage ../libvirt/libvirt.nix {};
in

with python2Packages;
{
  requests = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "requests";
    version = "2.13.0";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1s0wg4any4dsv5l3hqjxqk2zgb7pdbqhy9rhc8kh3aigfq4ws8jp";
    };

    outputs = [ "out" "dev" ];

    nativeBuildInputs = [ pytest ];
    propagatedBuildInputs = [
      modpacks.urllib3
      modpacks.idna
      chardet
      certifi
    ];
    # sadly, tests require networking
    doCheck = false;
  };

  pbr = buildPythonPackage rec {
    name = "pbr-${version}";
    version = "1.9.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack-dev/pbr/archive/${version}.tar.gz";
      sha256 = "19l3xj0p71y234z1zwlxxm5rg9z943jps47k2i9mvdcvnsn3944w";
    };

    doCheck = false;
  };

  oslo-policy = buildPythonPackage rec {
    name = "oslo.policy-${version}";
    version = "1.14.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.policy/archive/${version}.tar.gz";
      sha256 = "0xn5pk1480ndagph3dw41i1mj4vmlhqayg8zzb45q2jpgzrwyg7n";
    };

    propagatedBuildInputs = [
      modpacks.requests
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-serialization
      modpacks.oslo-utils
      six
      
      rfc3986
      modpacks.funcsigs
      pyyaml

      modpacks.stevedore
    ];
    buildInputs = [
      modpacks.oslosphinx_4_10
      modpacks.httpretty
      modpacks.oslotest

    ];

    nativeBuildInputs = [
      modpacks.oslo-config
      modpacks.oslo-i18n
      #rfc3986
      modpacks.requests-mock
    ];

  };

  oslo-config = buildPythonPackage rec {
    name = "oslo.config-${version}";
    version = "3.14.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.config/archive/${version}.tar.gz";
      sha256 = "0f18xkryvvr8klfdng4g1sq8by6jcdigzg9ikg60mv7dwcgry270";
    };

    propagatedBuildInputs = [
      modpacks.argparse
      modpacks.pbr
      six
      modpacks.netaddr
      modpacks.stevedore
      modpacks.oslo-i18n
      modpacks.debtcollector

      rfc3986
      wrapt
    ];
    buildInputs = [
      modpacks.mock
    ];

    # TODO: circular import on oslo-i18n
    doCheck = false;
  };

  oslo-i18n = buildPythonPackage rec {
    name = "oslo.i18n-${version}";
    version = "3.9.0";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/openstack/oslo.i18n/archive/${version}.tar.gz";
      sha256 = "0m8l253msn6kh6pa82ki03yy0wd3sihhzzr4yxi1429k7lm2ax30";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      six
      #oslo-config
    ];
    buildInputs = [
      modpacks.mock
      coverage
      modpacks.oslotest
    ];

    doCheck = false;
    
    #patchPhase = ''
    #  sed -i 's@python@${python.interpreter}@' .testr.conf
    #'';
  };

  debtcollector = buildPythonPackage rec {
    name = "debtcollector-${version}";
    version = "1.8.0";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/openstack/debtcollector/archive/${version}.tar.gz";
      sha256 = "0bnn6404cj6303mi8c3jbmzys9rdalbvmyw8yr0gzzi8w3rmzc9q";
    };
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      six
      wrapt
      modpacks.funcsigs
    ];

    buildInputs = [
      modpacks.testtools
      modpacks.testscenarios
      modpacks.testrepository
      modpacks.subunit
      coverage
      modpacks.oslotest
    ];
  };

  stevedore = buildPythonPackage rec {
    name = "stevedore-${version}";

    version = "1.17.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/stevedore/archive/${version}.tar.gz";
      sha256 = "035wf0k2mndgg263rhd87p1a5zykbafzrks1wbjvrhicj7vyh9i8";
    };

    doCheck = false;

    propagatedBuildInputs = [
      modpacks.pbr
      six
      modpacks.argparse
    ];

    buildInputs = [
      modpacks.oslosphinx_4_10
    ];
  };

  oslo-utils = buildPythonPackage rec {
    name = "oslo.utils-${version}";
    version = "3.16.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.utils/archive/${version}.tar.gz";
      sha256 = "1ils9j5s9xav5qsx5962bwb4pa9ada9jsy7vjpxxbawl3mz8hl7w";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      six
      iso8601
      pytz
      modpacks.netaddr
      modpacks.netifaces
      modpacks.monotonic
      modpacks.oslo-i18n
      wrapt
      modpacks.debtcollector

      pyparsing
      modpacks.funcsigs
    ];
    buildInputs = [
      modpacks.oslotest
      modpacks.mock
      coverage
      modpacks.oslosphinx_4_10

      #modpacks.monotonic
    ];
    
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  };

  oslo-serialization = buildPythonPackage rec {
    name = "oslo.serialization-${version}";
    version = "2.13.0";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/openstack/oslo.serialization/archive/${version}.tar.gz";
      sha256 = "0jkqk5z890zaf8k8v1rbqsi14a22j3kra8i6sh47hx23arrd5p5r";
    };

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      six
      iso8601
      pytz
      modpacks.oslo-utils
      msgpack
      modpacks.netaddr
    ];
    buildInputs = [
      modpacks.oslotest
      modpacks.mock
      coverage
      simplejson
      modpacks.oslo-i18n
    ];

    doCheck = false;
  };

  monotonic = buildPythonPackage rec {
    name = "monotonic-${version}";
    version = "1.2";

    src = fetchurl {
      url = "https://github.com/atdt/monotonic/archive/${version}.tar.gz";
      sha256 = "16papg8p85jgvwdlrzwpzw13r7i4fx0b90bdhjkb2yy8k1vf2qys";
    };
    
  };

  oslotest = buildPythonPackage rec {
    name = "oslotest-${version}";
    version = "1.12.0";

    src = fetchurl {
      url = "mirror://pypi/o/oslotest/${name}.tar.gz";
      sha256 = "17i92hymw1dwmmb5yv90m2gam2x21mc960q1pr7bly93x49h8666";
    };

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.fixtures
      modpacks.subunit
      six
      modpacks.testrepository
      modpacks.testscenarios
      modpacks.testtools
      modpacks.mock
      modpacks.mox3
      #modpacks.oslo-config
      modpacks.os-client-config
    ];

    doCheck = false;
  };

  os-client-config = buildPythonPackage rec {
    name = "os-client-config-${version}";
    version = "1.21.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/os-client-config/archive/${version}.tar.gz";
      sha256 = "0hfyhaswhh0wzyf24577l8rcgqxhn3lfgx1f3n4i35asrshx41f4";
    };

    propagatedBuildInputs = [
      appdirs
      pyyaml
      modpacks.keystoneauth1
      
      modpacks.positional
      modpacks.requestsexceptions
      jsonschema
    ];
    buildInputs = [
      modpacks.pbr
      modpacks.testtools
      modpacks.testscenarios
      modpacks.testrepository
      modpacks.fixtures
    ];

    ## can't pass test
    doCheck = false;

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
    # TODO: circular import on oslotest
    preCheck = ''
      rm os_client_config/tests/{test_config,test_cloud_config,test_environ}.py
    '';

    postInstall = ''
      cp os_client_config/*.json $out/lib/${python.libPrefix}/site-packages/os_client_config/
    '';
  };

  keystoneauth1 = buildPythonPackage rec {
    name = "keystoneauth1-${version}";
    version = "2.12.2";
    disabled = isPyPy; # a test fails

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/keystoneauth/archive/${version}.tar.gz";
      sha256 = "130k7hyp6dflh2dw2vryggnd6dmw8papsd7r1p2zicyj0jxayy64";
    };

    propagatedBuildInputs = [
      modpacks.argparse
      iso8601
      modpacks.requests
      six
      modpacks.stevedore
      modpacks.webob
      #modpacks.oslo-config

      lxml
      modpacks.positional
      pyyaml
      modpacks.betamax
      modpacks.pbr
      modpacks.oauthlib
      modpacks.requests-kerberos
    ];
    buildInputs = [
      modpacks.testtools
      testresources
      modpacks.testrepository
      modpacks.mock
      pep8
      modpacks.fixtures
      modpacks.mox3
      modpacks.requests-mock

    ];

    doCheck = false;
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  };

  requests-kerberos = buildPythonPackage rec {
    name = "requests-kerberos-${version}";
    version = "0.11.0";

    src = fetchurl {
      url = "https://github.com/requests/requests-kerberos/archive/v${version}.tar.gz";
      sha256 = "0y1rfcdn8zjnpjhli62zkiqh7v2j1ac2wxywcxw659fqi9h4sk0h";
    };

    propagatedBuildInputs = [
      modpacks.requests
      modpacks.pykerberos
    ];
  };

  pykerberos = buildPythonPackage rec {
    name = "pykerberos-${version}";
    version = "1.1.9";

    src = fetchurl {
      url = "https://github.com/02strich/pykerberos/releases/download/v1.1.9/pykerberos-${version}.tar.gz";
      sha256 = "0xamj6fszbzx6mkdqgnhyrh9nsdv0wkh9x059z0p125y4sc9ykm9";
    };

    propagatedBuildInputs = [
      pkgs.kerberos
    ];
  };

  positional = buildPythonPackage rec {
    name = "positional-${version}";
    version = "1.1.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/morganfainberg/positional/archive/${version}.tar.gz";
      sha256 = "0h4kkkxmxp79a72i3rijlg57pcs2bib0bp8p6rsqlavxc4wz6fq2";
    };

    propagatedNativeBuildInputs = [
      modpacks.pbr
      wrapt
    ];

    doCheck = false;
  };

  keystoneclient = buildPythonPackage rec {
    name = "python-keystoneclient-${version}";
    version = "3.5.0";

    src = fetchurl {
      url = "https://github.com/openstack/python-keystoneclient/archive/${version}.tar.gz";
      sha256 = "0dzfc0xdjlw5srws182fkzjakxsc0psxn2gs26vwid1mjc1xbbwr";
    };

    PBR_VERSION = "${version}";

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.oslo-serialization
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-utils
      Babel
      modpacks.argparse
      prettytable
      modpacks.requests
      six
      iso8601
      modpacks.stevedore
      modpacks.netaddr
      modpacks.debtcollector
      modpacks.bandit
      modpacks.webob
      modpacks.mock
      pycrypto
      modpacks.positional

      rfc3986
      modpacks.keystoneauth1
    ];
    buildInputs = [
      modpacks.testtools
      testresources
      modpacks.testrepository
      modpacks.requests-mock
      modpacks.fixtures
      pkgs.openssl
      modpacks.oslotest
      pep8
    ];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    doCheck = false; # The checkPhase below is broken

    checkPhase = ''
      patchShebangs run_tests.sh
      ./run_tests.sh
    '';

  };

  keystonemiddleware = buildPythonPackage rec {
    name = "keystonemiddleware-${version}";
    version = "4.9.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/keystonemiddleware/archive/${version}.tar.gz";
      sha256 = "19j4ic2k39fka75chdi5i4barpf62nwxhzfw2a6n8zl51cj5nb0l";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      modpacks.oslo-config
      modpacks.oslo-context
      modpacks.oslo-i18n
      modpacks.oslo-serialization
      modpacks.oslo-utils
      modpacks.requests
      six
      modpacks.webob
      modpacks.keystoneclient
      modpacks.pycadf
      modpacks.oslo-messaging

      memcached
      pkgs.openssl
      rfc3986
      modpacks.positional
      modpacks.oslo-log
      modpacks.keystoneauth1
    ];
    buildInputs = [
      modpacks.fixtures
      modpacks.mock
      pycrypto
      modpacks.oslosphinx_4_10
      modpacks.oslotest
      modpacks.stevedore
      modpacks.testrepository
      testresources
      modpacks.testtools
      modpacks.bandit
      modpacks.requests-mock
    ];

    # lots of "unhashable type" errors
    doCheck = false;
  };

  oslo-cache = buildPythonPackage rec {
    name = "oslo.cache-${version}";
    version = "1.14.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.cache/archive/${version}.tar.gz";
      sha256 = "0kn03jbl182fankc7abf2rf6bm4hi81r6rpgxzxqi12335jvwvdw";
    };

    propagatedBuildInputs = [
      Babel
      modpacks.dogpile_cache
      six
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-log
      modpacks.oslo-utils

      memcached
      pymongo

      rfc3986
    ];
    buildInputs = [
      modpacks.oslosphinx_4_10
      modpacks.oslotest

    ];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  };

  oslo-concurrency = buildPythonPackage rec {
   name = "oslo.concurrency-${version}";
   version = "3.14.0";

   PBR_VERSION = "${version}";

   src = fetchurl {
     url = "https://github.com/openstack/oslo.concurrency/archive/${version}.tar.gz";
     sha256 = "0slhabyc5r0gvymjlpivz71x8k9bv5hmakmh27v74w3lbjbjsdx4";
   };

   buildInputs = [
     modpacks.oslo-i18n
     modpacks.argparse
     six
     wrapt
     modpacks.oslo-utils
     modpacks.pbr
     enum34
     Babel
     modpacks.netaddr
     modpacks.monotonic
     iso8601
     modpacks.oslo-config
     pytz
     modpacks.netifaces
     modpacks.stevedore
     modpacks.debtcollector
     retrying
     modpacks.fasteners
     modpacks.eventlet

     modpacks.oslosphinx_4_10
     modpacks.fixtures
     futures
     coverage
     modpacks.oslotest

     rfc3986
   ];
   
   # too much magic in tests
   doCheck = false;

  };

  oslo-context = buildPythonPackage rec {
    name = "oslo.context-${version}";
    version = "2.9.0";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/openstack/oslo.context/archive/${version}.tar.gz";
      sha256 = "1k32r3fyd4n37k42y1ad2dhw248865aq629zgac4kd9kgm60yjdl";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      modpacks.debtcollector
      modpacks.positional
    ];
    buildInputs = [
      modpacks.oslotest
      coverage
      modpacks.oslosphinx_4_10
    ];
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  }; 

  oslo-messaging = buildPythonPackage rec {
    name = "oslo.messaging-${version}";
    version = "5.10.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.messaging/archive/${version}.tar.gz";
      sha256 = "0rgy5xa1162kwnnwhbkwnx9q3wmmz6vn0agc0iz6kvyn76jwhg0d";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.oslo-config
      modpacks.oslo-context
      modpacks.oslo-log
      modpacks.oslo-utils
      modpacks.oslo-serialization
      modpacks.oslo-i18n
      modpacks.stevedore
      six
      modpacks.eventlet
      greenlet
      modpacks.webob
      pyyaml
      modpacks.kombu_3
      trollius
      modpacks.aioeventlet
      cachetools
      modpacks.oslo-middleware
      modpacks.futurist
      redis
      modpacks.oslo-service
      modpacks.eventlet
      pyzmq

      modpacks.tenacity
      prettytable
      statsd
      modpacks.pifpaf
      modpacks.python-kafka
      rfc3986

      futures
      modpacks.pika-pool
      pika
      modpacks.monotonic
      modpacks.debtcollector
      modpacks.amqp_1
    ];

    buildInputs = [
      modpacks.oslotest
      modpacks.mock
      modpacks.mox3
      modpacks.subunit
      modpacks.testtools
      modpacks.testscenarios
      modpacks.testrepository
      modpacks.fixtures
      modpacks.oslosphinx_4_10

      modpacks.pika-pool
    ];

    doCheck = false;

    preBuild = ''
      # transient failure https://bugs.launchpad.net/oslo.messaging/+bug/1510481
      sed -i 's/test_send_receive/noop/' oslo_messaging/tests/drivers/test_impl_rabbit.py
    '';
  };

  oslo-db = buildPythonPackage rec {
    name = "oslo.db-${version}";
    version = "4.13.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.db/archive/${version}.tar.gz";
      sha256 = "06hf8mv4wkigvqcpvgsb9gcds4nyp1f79mahn3b4p9f8xsf31pcw";
    };

    propagatedBuildInputs = [
      six
      modpacks.stevedore
      modpacks.sqlalchemy_migrate
      modpacks.sqlalchemy
      modpacks.oslo-utils
      modpacks.oslo-context
      modpacks.oslo-config
      modpacks.oslo-i18n
      iso8601
      Babel
      modpacks.alembic
      modpacks.pbr
      psycopg2

      rfc3986
    ];
    buildInputs = [
      modpacks.tempest-lib
      testresources
      modpacks.mock
      modpacks.oslotest

    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];
  };

  oslo-log = buildPythonPackage rec {
    name = "oslo.log-${version}";
    version = "3.16.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.log/archive/${version}.tar.gz";
      sha256 = "1npizh25pwz3f55pqg8cx9yz51idq508966c9516gykdxrnwa52h";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      six
      iso8601
      modpacks.debtcollector
      modpacks.oslo-utils
      modpacks.oslo-i18n
      modpacks.oslo-config
      modpacks.oslo-serialization
      modpacks.oslo-context

      dateutil
    ] ++ stdenv.lib.optional stdenv.isLinux pyinotify;
    buildInputs = [
      modpacks.oslotest
      modpacks.oslosphinx_4_10

      #dateutil
      rfc3986
    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];

    doCheck = false;
    
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  };

  oslo-middleware = buildPythonPackage rec {
    name = "oslo.middleware-${version}";
    version = "3.19.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.middleware/archive/${version}.tar.gz";
      sha256 = "0c6g3fgf2wqfspnlwhwv2vp9mrjldq4h42d3k478zzq5kxfg5d87";
    };

    propagatedBuildInputs = [
      modpacks.oslo-i18n
      six
      modpacks.oslo-utils
      modpacks.pbr
      modpacks.oslo-config
      Babel
      modpacks.oslo-context
      modpacks.stevedore
      jinja2
      modpacks.webob
      modpacks.debtcollector
    ];
    buildInputs = [
      coverage
      modpacks.testtools
      modpacks.oslosphinx_4_10
      modpacks.oslotest

      statsd
      rfc3986
    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];

    doCheck = false;
    
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
      sed -i '/ordereddict/d' requirements.txt
    '';

  };

  oslo-service = buildPythonPackage rec {
    name = "oslo.service-${version}";
    version = "1.16.0";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/openstack/oslo.service/archive/${version}.tar.gz";
      sha256 = "1blnwhy418yqaab2gpmnjvf7lj83y2vjmnan4w29vi1a4g9plmy5";
    };

    propagatedBuildInputs = [
      repoze_lru
      PasteDeploy
      Babel
      modpacks.oslo-context
      modpacks.debtcollector
      #modpacks.oslo-concurrency
      wrapt
      modpacks.eventlet
      six
      modpacks.oslo-serialization
      greenlet
      paste
      modpacks.oslo-config
      modpacks.monotonic
      iso8601
      modpacks.oslo-log
      pytz
      modpacks.routes
      msgpack
      modpacks.oslo-i18n
      modpacks.argparse
      modpacks.oslo-utils
      modpacks.pbr
      enum34
      modpacks.netaddr
      modpacks.stevedore
      modpacks.netifaces
      pyinotify
      modpacks.webob
      retrying

      modpacks.fasteners
      pythonHasOsloConcMod
    ];
    buildInputs = [
      modpacks.oslosphinx_4_10
      modpacks.oslotest
      pkgs.procps
      modpacks.mock
      modpacks.mox3
      modpacks.fixtures
      modpacks.subunit
      modpacks.testrepository
      modpacks.testtools
      modpacks.testscenarios
      modpacks.eventlet

      rfc3986
    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];

    # failing tests
    preCheck = ''
      rm oslo_service/tests/test_service.py
    '';

    doCheck = false;
    
  };

  os-testr = buildPythonPackage rec {
    name = "os-testr-${version}";
    version = "0.4.2";

    src = fetchurl {
      url = "mirror://pypi/o/os-testr/${name}.tar.gz";
      sha256 = "0474z0mxb7y3vfk4s097wf1mzji5d135vh27cvlh9q17rq3x9r3w";
    };

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
      sed -i 's@python@${python.interpreter}@' os_testr/tests/files/testr-conf
    '';

    checkPhase = ''
      export PATH=$PATH:$out/bin
      ${python.interpreter} setup.py test
    '';

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      modpacks.testrepository
      modpacks.subunit
      modpacks.testtools
    ];
    buildInputs = [
      coverage
      modpacks.oslosphinx_4_10
      modpacks.oslotest
      modpacks.testscenarios
      six
      ddt
    ];
  };
  

  setuptools = stdenv.mkDerivation rec {
    name = "${python.libPrefix}-setuptools-${version}";
    version = "33.1.1";
  
    src = fetchurl {
      url = "https://github.com/pypa/setuptools/archive/v${version}.tar.gz";
      sha256 = "1927qjxy3ld5kn8y7fdcjaih7d1w7wm25mh3mdv6cb0f7b7fpkm1";
    };

    buildInputs = [ makeWrapper python wrapPython pip ];
    nativeBuildInputs = [
      pip
      six
      modpacks.packaging
      appdirs
      #modpacks.rwt
    ];
    doCheck = false;  # requires pytest
    installPhase = ''
      dst=$out/${python.sitePackages}
      mkdir -p $dst
      export PYTHONPATH="$dst:$PYTHONPATH"
      ${python.interpreter} bootstrap.py
      ${python.interpreter} setup.py install --prefix=$out
      wrapPythonPrograms
    '';

    pythonPath = [];
  };

  packaging = buildPythonPackage rec {
    name = "packaging-${version}";
    version = "16.8";

    src = fetchurl {
      url = "https://github.com/pypa/packaging/archive/16.8.tar.gz";
      sha256 = "1xpkjbka7p5d99b2c51g4nyymzkgvs4niq5xaaj576w68z4k10m4";
    };

    propagatedBuildInputs = [
      pyparsing
      six
    ];
  };

  rwt = buildPythonPackage rec {
    name = "rwt-${version}";
    version = "2.13";

    src = fetchurl {
      url = "https://github.com/jaraco/rwt/archive/${version}.tar.gz";
      sha256 = "1jszrb2ip45b9akcm8b7qkphbcncw9l53dq36fn9xx0agjyamfhw";
    };

  };

  kombu_3 = buildPythonPackage rec {
    name = "kombu-${version}";
    version = "3.0.35";

    disabled = pkgs.lib.versionOlder python.pythonVersion "2.6";

    src = fetchurl {
      url = "mirror://pypi/k/kombu/${name}.tar.gz";
      sha256 = "09xpxpjz9nk8d14dj361dqdwyjwda3jlf1a7v6jif9wn2xm37ar2";
    };

    # most of these are simply to allow the test suite to do its job
    buildInputs = pkgs.lib.optionals isPy27 [ modpacks.mock modpacks.unittest2 nose redis qpid-python pymongo modpacks.sqlalchemy pyyaml msgpack modpacks.boto ];

    propagatedBuildInputs = [ modpacks.amqp_1 anyjson ] ++
      (pkgs.lib.optionals (pkgs.lib.versionOlder python.pythonVersion "2.7") [ importlib ordereddict ]);

    # tests broken on python 2.6? https://github.com/nose-devs/nose/issues/806
    doCheck = isPy27;
  };

  amqp_1 = buildPythonPackage rec {
    name = "amqp-${version}";
    version = "1.4.9";
    disabled = pkgs.lib.versionOlder python.pythonVersion "2.6";

    src = fetchurl {
      url = "mirror://pypi/a/amqp/${name}.tar.gz";
      sha256 = "06n6q0kxhjnbfz3vn8x9yz09lwmn1xi9d6wxp31h5jbks0b4vsid";
    };

    buildInputs = [ modpacks.mock coverage nose-cover3 modpacks.unittest2 ];

  };

  futurist = buildPythonPackage rec {
     name = "futurist-${version}";
     version = "0.14.0";

     PBR_VERSION = "${version}";

     src = fetchurl {
       url = "https://github.com/openstack/futurist/archive/${version}.tar.gz";
       sha256 = "0b6p69bj7vf0wz5x8lz33dyihjhnrc91s6a3mlb7qz7grcg4d0g8";
     };

     patchPhase = ''
       sed -i "s/test_gather_stats/noop/" futurist/tests/test_executors.py
     '';

     propagatedBuildInputs = [
       contextlib2
       modpacks.pbr
       six
       modpacks.monotonic
       futures
       modpacks.eventlet
     ];
     buildInputs = [
       modpacks.testtools
       modpacks.testscenarios
       modpacks.testrepository
       modpacks.oslotest
       modpacks.subunit
       prettytable
     ];

   };

  pycadf = buildPythonPackage rec {
    name = "pycadf-${version}";
    version = "1.1.0";

    src = fetchurl {
      url = "mirror://pypi/p/pycadf/pycadf-1.1.0.tar.gz";
      sha256 = "0lv9nhbvj1pa8qgn3qvyk9k4q8f7w541074n1rhdjnjkinh4n4dg";
    };

    propagatedBuildInputs = [
      modpacks.oslo-i18n
      modpacks.argparse
      six
      wrapt
      modpacks.oslo-utils
      modpacks.pbr
      modpacks.oslo-config
      Babel
      modpacks.netaddr
      modpacks.monotonic
      iso8601
      pytz
      modpacks.stevedore
      modpacks.oslo-serialization
      msgpack
      modpacks.debtcollector
      modpacks.netifaces
    ];
    buildInputs = [
      modpacks.oslosphinx_4_10
      modpacks.testtools
      modpacks.testrepository
      modpacks.oslotest

      rfc3986
    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

  };

  tempest-lib = buildPythonPackage rec {
    name = "tempest-lib-${version}";
    version = "0.10.0";

    src = fetchurl {
      url = "mirror://pypi/t/tempest-lib/${name}.tar.gz";
      sha256 = "0x842a67k9f7yk3zr6755s4qldkfngljqy5whd4jb553y4hn5lyj";
    };

    patchPhase = ''
      substituteInPlace tempest_lib/tests/cli/test_execute.py --replace "/bin/ls" "${pkgs.coreutils}/bin/ls"
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    buildInputs = [
      modpacks.testtools
      modpacks.testrepository
      modpacks.subunit
      modpacks.oslotest

      rfc3986
    ];
    propagatedBuildInputs = [
      modpacks.pbr
      six
      modpacks.paramiko
      httplib2
      jsonschema
      iso8601
      modpacks.fixtures
      Babel
      modpacks.oslo-log
      modpacks.os-testr
    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];

  };

  fasteners = buildPythonPackage rec {
    name = "fasteners-${version}";
    version = "0.14.1";

    src = fetchurl {
      url = "mirror://pypi/f/fasteners/${name}.tar.gz";
      sha256 = "063y20kx01ihbz2mziapmjxi2cd0dq48jzg587xdsdp07xvpcz22";
    };

    propagatedBuildInputs = [
      six
      modpacks.monotonic
      modpacks.testtools
    ];

    checkPhase = ''
      ${python.interpreter} -m unittest discover
    '';
    # Tests are written for Python 3.x only (concurrent.futures)
    doCheck = isPy3k;

  };

  bandit = buildPythonPackage rec {
    name = "bandit-${version}";
    version = "0.16.1";
    disabled = isPy33;
    doCheck = !isPyPy; # a test fails

    src = fetchurl {
      url = "mirror://pypi/b/bandit/${name}.tar.gz";
      sha256 = "0qd9kxknac5n5xfl5zjnlmk6jr94krkcx29zgyna8p9lyb828hsk";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      six
      pyyaml
      appdirs
      modpacks.stevedore
    ];
    buildInputs = [
      beautifulsoup4
      modpacks.oslosphinx_4_10
      modpacks.testtools
      modpacks.testscenarios
      modpacks.testrepository
      modpacks.fixtures
      modpacks.mock
    ];
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  };

  webob = buildPythonPackage rec {
    version = "1.7.1";
    name = "webob-${version}";

    src = fetchurl {
      url = "https://github.com/Pylons/webob/archive/${version}.tar.gz";
      sha256 = "0cj8py0q3n4i3ps74v6rq9wmvfc0mz7xbkj5abysdlra9c88yf9k";
    };

    propagatedBuildInputs = [
      nose
    ];

  };

  dogpile_cache = buildPythonPackage rec {
    name = "dogpile.cache-${version}";
    version = "0.6.2";

    propagatedBuildInputs = [
      dogpile_core
    ];

    src = fetchurl {
      url = "mirror://pypi/d/dogpile.cache/dogpile.cache-${version}.tar.gz";
      sha256 = "0vbja38pw05bylvmaqaclfm0q8m4mjzml0gfng2nvbq7mxqk8ybk";
    };

    doCheck = false;

  };

  eventlet = buildPythonPackage rec {
    name = "eventlet-${version}";
    version = "0.18.2";

    src = fetchurl {
      url = "mirror://pypi/e/eventlet/eventlet-${version}.tar.gz";
      sha256 = "1mcy0vk30z7xdygr80i7nbwy536qwk8sfl4j5zmcbqwhiziy0qgr";
    };

    buildInputs = [
      nose
      httplib2
      modpacks.pyopenssl
    ];

    doCheck = false;  # too much transient errors to bother

    propagatedBuildInputs = pkgs.lib.optionals (!isPyPy) [
      greenlet
    ];

  };

  pyquery = buildPythonPackage rec {
    name = "pyquery-${version}";
    version = "1.2.9";

    src = fetchurl {
      url = "mirror://pypi/p/pyquery/${name}.zip";
      sha256 = "00p6f1dfma65192hc72dxd506491lsq3g5wgxqafi1xpg2w1xia6";
    };

    propagatedBuildInputs = [
      cssselect
      lxml
      modpacks.webob
    ];
    # circular dependency on webtest
    doCheck = false;
  };

  wsgiproxy2 = buildPythonPackage rec {
    name = "WSGIProxy2-0.4.2";

    src = fetchurl {
      url = "mirror://pypi/W/WSGIProxy2/${name}.zip";
      sha256 = "13kf9bdxrc95y9vriaz0viry3ah11nz4rlrykcfvb8nlqpx3dcm4";
    };

    # circular dep on webtest
    doCheck = false;
    propagatedBuildInputs = [
      six
      modpacks.webob
    ];

  };

  webtest = buildPythonPackage rec {
    version = "2.0.20";
    name = "webtest-${version}";

    src = fetchurl {
      url = "mirror://pypi/W/WebTest/WebTest-${version}.tar.gz";
      sha256 = "0bv0qhdjakdsdgj4sk21gnpp8xp8bga4x03p6gjb83ihrsb7n4xv";
    };

    preConfigure = ''
      substituteInPlace setup.py --replace "nose<1.3.0" "nose"
    '';

    doCheck = false;

    buildInputs = pkgs.lib.optionals isPy26 [
      ordereddict
      modpacks.unittest2
    ];

    propagatedBuildInputs = [
      nose
      modpacks.webob
      six
      beautifulsoup4
      waitress
      modpacks.mock
      modpacks.pyquery
      modpacks.wsgiproxy2
      PasteDeploy
      coverage
    ];

  };

  osprofiler = buildPythonPackage rec {
    name = "osprofiler-${version}";
    version = "1.5.0";
    disabled = isPyPy;

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/osprofiler/archive/${version}.tar.gz";
      sha256 = "1zh0h34j61hv9gphx4dnvd2cnv5r5m8isvfpddfl3nn526yysqn5";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.argparse
      six
      modpacks.webob
      
      modpacks.netaddr
      #modpacks.oslo-concurrency
      modpacks.oslo-log
      modpacks.oslo-messaging
      modpacks.pika-pool
      modpacks.positional
      ddt
      pymongo
      modpacks.elasticsearch
      modpacks.ceilometerclient
      pythonHasOsloConcMod
    ];
    buildInputs = [
      modpacks.oslosphinx_4_10
      coverage
      modpacks.mock
      modpacks.subunit
      modpacks.testrepository
      modpacks.testtools

      rfc3986
    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    doCheck = false;
  };

  repoze_who = buildPythonPackage rec {
    name = "repoze.who-${version}";
    version = "2.2";

    src = fetchurl {
      url = "mirror://pypi/r/repoze.who/${name}.tar.gz";
      sha256 = "12wsviar45nwn35w2y4i8b929dq2219vmwz8013wx7bpgkn2j9ij";
    };

    propagatedBuildInputs = [
      zope_interface
      modpacks.webob
    ];
    buildInputs = [

    ];

  };

  pysaml2 = buildPythonPackage rec {
    name = "pysaml2-${version}";
    version = "3.0.2";

    src = fetchurl {
      url = "mirror://pypi/p/pysaml2/${name}.tar.gz";
      sha256 = "0y2iw1dddcvi13xjh3l52z1mvnrbc41ik9k4nn7lwj8x5kimnk9n";
    };

    propagatedBuildInputs = [
      modpacks.repoze_who
      paste
      modpacks.cryptography
      pycrypto
      modpacks.pyopenssl
      modpacks.ipaddress
      six
      cffi
      modpacks.idna
      enum34
      pytz
      setuptools
      zope_interface
      dateutil
      modpacks.requests
      pyasn1
      modpacks.webob
      decorator
      pycparser
    ];
    buildInputs = [
      Mako
      pytest
      memcached
      pymongo
      mongodict
      pkgs.xmlsec
    ];

    preConfigure = ''
      sed -i 's/pymongo==3.0.1/pymongo/' setup.py
    '';

    # 16 failed, 427 passed, 17 error in 88.85 seconds
    doCheck = false;

  };

  routes = buildPythonPackage rec {
    name = "routes-1.12.3";

    src = fetchurl {
      url = "mirror://pypi/R/Routes/Routes-1.12.3.tar.gz";
      sha256 = "eacc0dfb7c883374e698cebaa01a740d8c78d364b6e7f3df0312de042f77aa36";
    };

    propagatedBuildInputs = [
      paste
      modpacks.webtest
    ];

  };

  alembic = buildPythonPackage rec {
    name = "alembic-${version}";
    version = "0.8.10";

    src = fetchurl {
      url = "mirror://pypi/a/alembic/${name}.tar.gz";
      sha256 = "06br9sfqypnjlal6fsbnky3zb0askwcn3diz8k3kwa0qcblm0fqf";
    };

    buildInputs = [
      pytest
      pytestcov
      modpacks.mock
      coverage
    ];
    propagatedBuildInputs = [
      Mako
      modpacks.sqlalchemy
      python-editor
    ];

  };

  pika-pool = buildPythonPackage rec {
    name = "pika-pool-${version}";
    version = "0.1.3";

    src = fetchurl {
      url = "https://github.com/bninja/pika-pool/archive/v${version}.tar.gz";
      sha256 = "188x7ds0i9vbnwqv263cn1g66f936z9daksghr75lw5bq6yd3p4b";
    };

    propagatedBuildInputs = [
      pika
    ];
  };

  tenacity = buildPythonPackage rec {
    name = "tenacity-${version}";
    version = "3.7.1";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/jd/tenacity/archive/${version}.tar.gz";
      sha256 = "1zbwllfb74imrcfjxsjhwbzbpw6gd6npgqw2jbbk85kjypnp7q6d";
    };

    propagatedBuildInputs = [
      modpacks.monotonic
      modpacks.debtcollector
      futures
      six
      wrapt
      modpacks.funcsigs
      modpacks.pbr
    ];
  };

  aioeventlet = buildPythonPackage rec {
    name = "aioeventlet-${version}";
    version = "0.4";

    src = fetchurl {
      url = "mirror://pypi/a/aioeventlet/aioeventlet-0.4.tar.gz";
      sha256 = "19krvycaiximchhv1hcfhz81249m3w3jrbp2h4apn1yf4yrc4y7y";
    };

    propagatedBuildInputs = [
      modpacks.eventlet
      trollius
      asyncio
    ];
    buildInputs = [
      modpacks.mock
    ];

    # 2 tests error out
    doCheck = false;
    checkPhase = ''
      ${python.interpreter} runtests.py
    '';
  };

  pifpaf = buildPythonPackage rec {
    name = "pifpaf-${version}";
    version = "0.23.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/jd/pifpaf/archive/${version}.tar.gz";
      sha256 = "0q0i02hzgzavm29g3j7hbnj2a1pvzsh36fxh5d8h2z2vc5shpymf";
    };

    propagatedBuildInputs = [
      six
      modpacks.stevedore
      modpacks.cliff
      modpacks.fixtures
      xattr
      modpacks.testtools
    ];
  };

  cliff = buildPythonPackage rec {
    name = "cliff-${version}";
    version = "2.4.0";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/openstack/cliff/archive/${version}.tar.gz";
      sha256 = "1713ignsip94mfrvjy21g08daysyf37arvs72ikxp06h3qxcwcfr";
    };

    propagatedBuildInputs = [
      modpacks.argparse
      pyyaml
      modpacks.pbr
      six
      cmd2
      modpacks.stevedore
      unicodecsv
      prettytable
      pyparsing
    ];
    buildInputs = [
      httplib2
      modpacks.oslosphinx_4_10
      coverage
      modpacks.mock
      nose
      modpacks.tempest-lib

      #modpacks.stevedore
    ];

    doCheck = false;

  };

  python-kafka = buildPythonPackage rec {
    name = "python-kafka-${version}";
    version = "1.3.2";

    src = fetchurl {
      url = "https://github.com/dpkp/kafka-python/archive/${version}.tar.gz";
      sha256 = "1wdhgxpa9jwbcvk1ihs59zl9316q85zzjx23p4d2qxrbh10jw4p9";
    };

    propagatedBuildInputs = [
      tox
      pytest
      modpacks.mock
      
    ];

    doCheck = false;
  };

  sqlalchemy_migrate = buildPythonPackage rec {
    name = "sqlalchemy-migrate-0.10.0";

    src = fetchurl {
      url = "mirror://pypi/s/sqlalchemy-migrate/${name}.tar.gz";
      sha256 = "00z0lzjs4ksr9yr31zs26csyacjvavhpz6r74xaw1r89kk75qg7q";
    };

    buildInputs = [
      modpacks.unittest2
      scripttest
      pytz
      modpacks.pylint
      modpacks.tempest-lib
      modpacks.mock
      modpacks.testtools
    ];
    propagatedBuildInputs = [
      modpacks.pbr
      tempita
      decorator
      modpacks.sqlalchemy
      six
      sqlparse
    ];

    checkPhase = ''
      export PATH=$PATH:$out/bin
      echo sqlite:///__tmp__ > test_db.cfg
      # depends on ibm_db_sa
      rm migrate/tests/changeset/databases/test_ibmdb2.py
      # wants very old testtools
      rm migrate/tests/versioning/test_schema.py
      # transient failures on py27
      substituteInPlace migrate/tests/versioning/test_util.py --replace "test_load_model" "noop"
      ${python.interpreter} setup.py test
    '';

  };

  ceilometerclient = buildPythonPackage rec {
    name = "python-ceilometerclient-${version}";
    version = "2.6.2";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-ceilometerclient/archive/${version}.tar.gz";
      sha256 = "19a7qh0g5vw2n60gk6lvq0a8s5czqkwhx38s6nsyw845ld6frxiy";
    };

    propagatedBuildInputs = [
      prettytable
      modpacks.keystoneauth1
      modpacks.oslo-utils
      modpacks.oslo-serialization
      modpacks.positional
      modpacks.funcsigs
    ];

    doCheck = false;
  };

  cliff-tablib = buildPythonPackage rec {
    name = "cliff-tablib-${version}";
    version = "1.1";

    src = fetchurl {
      url = "mirror://pypi/c/cliff-tablib/cliff-tablib-${version}.tar.gz";
      sha256 = "0fa1qw41lwda5ac3z822qhzbilp51y6p1wlp0h76vrvqcqgxi3ja";
    };

    propagatedBuildInputs = [
      modpacks.argparse
      pyyaml
      modpacks.pbr
      six
      cmd2
      tablib
      unicodecsv
      prettytable
      modpacks.stevedore
      pyparsing
      modpacks.cliff
    ];
    buildInputs = [

    ];

  };

  osc-lib = buildPythonPackage rec {
    name = "osc-lib-${version}";
    version = "1.1.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/osc-lib/archive/${version}.tar.gz";
      sha256 = "1by3k53fvy3zgaav929hs8sswliplhwfk961r60grpln1x37gic2";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      six
      Babel
      modpacks.cliff
      modpacks.keystoneauth1
      modpacks.os-client-config
      modpacks.oslo-i18n
      modpacks.oslo-utils
      modpacks.stevedore
      simplejson
      modpacks.funcsigs
    ];

    ## can't pass test
    doCheck = false;
  };

  openstacksdk = buildPythonPackage rec {
    name = "python-openstacksdk-${version}";
    version = "0.9.8";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-openstacksdk/archive/${version}.tar.gz";
      sha256 = "0ngk63nlb08g2986w7fy7sg890w5b2jd49842inwfa9jp9nhz8wn";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      six
      modpacks.stevedore
      modpacks.os-client-config
      modpacks.keystoneauth1
    ];

    ## can't pass test
    doCheck = false;
  };

  glanceclient = buildPythonPackage rec {
    name = "python-glanceclient-${version}";
    version = "2.5.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-glanceclient/archive/${version}.tar.gz";
      sha256 = "0qn07g7f2xfqb2cvp757hz2agn6axy177hrg06753jkfk0bv4qbp";
    };
    patches = [
      ./workaround_for_create_size_0_images.patch
    ];

    propagatedBuildInputs = [
      modpacks.oslo-i18n
      modpacks.oslo-utils
      six
      modpacks.requests
      modpacks.keystoneclient
      prettytable
      Babel
      modpacks.pbr
      modpacks.argparse
      warlock
      modpacks.keystoneauth1
      rfc3986
      jsonpointer
      functools32
      jsonpatch
      jsonschema
    ];
    buildInputs = [
      modpacks.tempest-lib
      modpacks.requests-mock
    ];

    checkPhase = ''
      ${python.interpreter} -m subunit.run discover -t ./ .
    '';

  };

  novaclient = buildPythonPackage rec {
    name = "python-novaclient-${version}";
    version = "6.0.0";

    src = fetchurl {
      url = "https://github.com/openstack/python-novaclient/archive/${version}.tar.gz";
      sha256 = "0cdgap5jlp797zbjz7igbv4i4g9xr583jawzgv17kj26rhnv7l05";
    };

    PBR_VERSION = "${version}";

    buildInputs = [
      modpacks.pbr
      modpacks.testtools
      modpacks.testscenarios
      modpacks.testrepository
      modpacks.requests-mock
      modpacks.fixtures
    ];
    propagatedBuildInputs = [
      Babel
      modpacks.argparse
      prettytable
      modpacks.requests
      simplejson
      six
      iso8601
      modpacks.keystoneclient
      modpacks.tempest-lib
      modpacks.keystoneauth1
    ];

    # TODO: check if removing this test is really harmless
    preCheck = ''
      substituteInPlace novaclient/tests/unit/v2/test_servers.py --replace "test_get_password" "noop"
    '';

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

  };

  cinderclient = buildPythonPackage rec {
    name = "python-cinderclient-${version}";
    version = "1.9.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-cinderclient/archive/${version}.tar.gz";
      sha256 = "10az7d71j92135pc5nd2ngj10gqqd6k57zvj34vbd72smfwjr7hl";
    };

    propagatedBuildInputs = [
      six
      Babel
      simplejson
      modpacks.requests
      modpacks.keystoneclient
      prettytable
      modpacks.argparse
      modpacks.pbr
      modpacks.keystoneauth1
      ddt
    ];
    buildInputs = [
      modpacks.testrepository
      modpacks.requests-mock
    ];

    ## can't pass test
    doCheck = false;

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

  };

  neutronclient = buildPythonPackage rec {
    name = "python-neutronclient-${version}";
    version = "6.0.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-neutronclient/archive/${version}.tar.gz";
      sha256 = "1qcssq1k81263k3kam7pyi650g9wcsfsnhbwdzs19yxaxjzp807m";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      six
      simplejson
      modpacks.keystoneclient
      modpacks.requests
      modpacks.oslo-utils
      modpacks.oslo-serialization
      modpacks.oslo-i18n
      modpacks.netaddr
      iso8601
      modpacks.cliff
      modpacks.argparse
      modpacks.osc-lib
    ];
    buildInputs = [
      modpacks.tempest-lib
      modpacks.mox3
      modpacks.oslotest
      modpacks.requests-mock
    ];

    ## can't pass test
    doCheck = false;

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
      # test fails on py3k
      ${if isPy3k then "substituteInPlace neutronclient/tests/unit/test_cli20_port.py --replace 'test_list_ports_with_fixed_ips_in_csv' 'noop'" else ""}
    '';

  };

  requestsexceptions = buildPythonPackage rec {
    name = "requestsexceptions-${version}";
    version = "1.1.3";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack-infra/requestsexceptions/archive/${version}.tar.gz";
      sha256 = "10kj0ix6xbkc8zr3rr3d79wh2zvrf1hjkafgpq2wgqkaa9yv787b";
    };

    propagatedBuildInputs = [
      modpacks.pbr
    ];
  };

  cursive = buildPythonPackage rec {
    name = "cursive-${version}";
    version = "0.1.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/cursive/archive/${version}.tar.gz";
      sha256 = "0m29xypy4n180mqrj7s5wkqs61wn3h6znddp0a3w6d2ifx5fqr9h";
    };

    propagatedBuildInputs = [
      modpacks.castellan
      modpacks.cryptography
      lxml
      modpacks.netifaces
      modpacks.oslo-i18n
      modpacks.oslo-serialization
      modpacks.oslo-utils
      modpacks.pbr
      six
    ];

    ## can't pass test
    doCheck = false;
  };

  castellan = buildPythonPackage rec {
    name = "castellan-${version}";
    version = "0.4.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/castellan/archive/${version}.tar.gz";
      sha256 = "0jxcgyc0hivxvf78xyd2phfbjxsxsafy21vg7yxaba2bbvkh67qk";
    };

    propagatedBuildInputs = [
      modpacks.barbicanclient
      modpacks.pbr
      modpacks.oslo-utils
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.oslo-context
      modpacks.oslo-config
      modpacks.oslo-policy
      modpacks.keystoneauth1
      modpacks.cryptography
      Babel
    ];

    ## can't pass test
    doCheck = false;
  };

  barbicanclient = buildPythonPackage rec {
    name = "python-barbicanclient-${version}";
    version = "4.1.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-barbicanclient/archive/${version}.tar.gz";
      sha256 = "1af6dh9zpsasrjnwc930plxyf3pvbmn26askdpihnysd9mmmrvkv";
    };

    propagatedBuildInputs = [
      six
      modpacks.requests
      #modpacks.pbr
      modpacks.oslo-utils
      modpacks.oslo-serialization
      modpacks.oslo-i18n
      modpacks.oslo-config
      modpacks.keystoneauth1
      modpacks.cliff

      modpacks.keystoneclient
      rfc3986
    ];

    buildInputs = [
      modpacks.pbr
    ];

    ## can't pass test
    doCheck = false;
  };

  glance_store = buildPythonPackage rec {
    name = "glance_store-${version}";
    version = "0.18.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/glance_store/archive/${version}.tar.gz";
      sha256 = "1ykqg8n7yd16051g56wd3sghwzg3z4gizn616w50523svl72wd3b";
    };

    propagatedBuildInputs = [
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-serialization
      modpacks.oslo-utils
      #modpacks.oslo-concurrency
      modpacks.stevedore
      enum34
      modpacks.eventlet
      six
      modpacks.debtcollector
      jsonschema
      modpacks.keystoneclient
      modpacks.requests
      modpacks.pbr
      modpacks.keystoneauth1
      rfc3986

      modpacks.fasteners
      retrying
      pythonHasOsloConcMod
    ];

    ## can't pass test
    doCheck = false;
  };

  taskflow = buildPythonPackage rec {
    name = "taskflow-${version}";
    version = "2.6.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/taskflow/archive/${version}.tar.gz";
      sha256 = "16xnq8pfdwnhvl5vy66yl7v6x3k2iqv59b9cl9kg24ja9vgy0aix";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      six
      enum34
      modpacks.futurist
      modpacks.fasteners
      networkx
      contextlib2
      modpacks.stevedore
      futures
      modpacks.monotonic
      jsonschema
      modpacks.automaton
      modpacks.oslo-utils
      modpacks.oslo-serialization
      retrying
      cachetools
      modpacks.debtcollector
    ];

    buildInputs = [
      modpacks.oslosphinx_4_10
      pymysql
      psycopg2
      modpacks.alembic
      redis
      modpacks.eventlet
      kazoo
      zake
      kombu
      modpacks.testscenarios
      modpacks.testtools
      modpacks.mock
      modpacks.oslotest
      modpacks.debtcollector
      modpacks.sqlalchmy_utils
      modpacks.pydotplus
    ];

    preBuild = ''
      # too many transient failures
      rm taskflow/tests/unit/test_engines.py
    '';

  };

  automaton = buildPythonPackage rec {
    name = "automaton-${version}";
    version = "1.4.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/automaton/archive/${version}.tar.gz";
      sha256 = "0nh212him8vbnw5l1g9wi50i50ravc2gw9d6li984l34karm25kg";
    };

    propagatedBuildInputs = [
      wrapt
      modpacks.pbr
      Babel
      six
      pytz
      prettytable
      modpacks.debtcollector

      modpacks.funcsigs
    ];
    buildInputs = [
      modpacks.testtools
      modpacks.testscenarios
      modpacks.testrepository
    ];
    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  };

  sqlalchmy_utils = buildPythonPackage rec {
    name = "sqlalchemy-utils-${version}";
    version = "0.32.12";

    src = fetchurl {
      url = "https://github.com/kvesteri/sqlalchemy-utils/archive/${version}.tar.gz";
      sha256 = "1qjy8n52x3bp2kys53157ydc7w7jpbih6ha1fgf5hpym005zpqzq";
    };

    propagatedBuildInputs = [
      modpacks.sqlalchemy
      six
    ];
  };

  pydotplus = buildPythonPackage rec {
    name = "pydotplus-${version}";
    version = "2.0.2";

    src = fetchurl {
      url = "mirror://pypi/p/pydotplus/${name}.tar.gz";
      sha256 = "1i05cnk3yh722fdyaq0asr7z9xf7v7ikbmnpxa8j6pdqx6g5xs4i";
    };

    propagatedBuildInputs = [
      pyparsing
    ];
  };

  WSME = buildPythonPackage rec {
    name = "WSME-${version}";
    version = "0.8.0";

    src = fetchurl {
      url = "mirror://pypi/W/WSME/${name}.tar.gz";
      sha256 = "1nw827iz5g9jlfnfbdi8kva565v0kdjzba2lccziimj09r71w900";
    };

    checkPhase = ''
      # remove turbogears tests as we don't have it packaged
      rm tests/test_tg*
      # remove flask since we don't have flask-restful
      rm tests/test_flask*
      # https://bugs.launchpad.net/wsme/+bug/1510823
      ${if isPy3k then "rm tests/test_cornice.py" else ""}

      nosetests tests/
    '';

    propagatedBuildInputs = [
      modpacks.pbr
      six
      simplegeneric
      modpacks.netaddr
      pytz
      modpacks.webob
    ];
    buildInputs = [
      modpacks.cornice
      nose
      modpacks.webtest
      modpacks.pecan
      modpacks.transaction
      cherrypy
      modpacks.sphinx
    ];
  };

  cornice = buildPythonPackage rec {
    name = "cornice-${version}";
    version = "1.2.1";
    src = pkgs.fetchgit {
      url = https://github.com/mozilla-services/cornice.git;
      rev = "refs/tags/${version}";
      sha256 = "0688vrkl324jmpi8jkjh1s8nsyjinw149g3x8qlis8vz6j6a01wv";
    };

    propagatedBuildInputs = [
      modpacks.pyramid
      simplejson
    ];

    doCheck = false; # lazy packager
  };

  pyramid = buildPythonPackage rec {
    name = "pyramid-1.7";

    src = fetchurl {
      url = "mirror://pypi/p/pyramid/${name}.tar.gz";
      sha256 = "161qacv7qqln3q02kcqll0q2mmaypm701hn1llwdwnkaywkb3xi6";
    };

    buildInputs = [
      docutils
      virtualenv
      modpacks.webtest
      zope_component
      zope_interface
    ] ++ stdenv.lib.optional isPy26 modpacks.unittest2;

    propagatedBuildInputs = [
      PasteDeploy
      repoze_lru
      modpacks.repoze_sphinx_autointerface
      translationstring
      venusian
      modpacks.webob
      zope_deprecation
      zope_interface
    ];

    ## can't pass test
    doCheck = false;

  };

  os-brick = buildPythonPackage rec {
   name = "os-brick-${version}";
   version = "1.6.1";

   PBR_VERSION = "${version}";

   src = fetchurl {
     url = "https://github.com/openstack/os-brick/archive/${version}.tar.gz";
     sha256 = "1lw5iw8phf0j2nqwl8b34l7ir2n6apdmygqrvi4jgqg1m66iv5wy";
   };

   propagatedBuildInputs = [
     six
     retrying
     modpacks.oslo-utils
     modpacks.oslo-service
     modpacks.oslo-i18n
     modpacks.oslo-serialization
     modpacks.oslo-log
     #modpacks.oslo-concurrency
     modpacks.oslo-privsep
     modpacks.os-win
     modpacks.eventlet
     Babel
     modpacks.pbr
     modpacks.requests

     modpacks.castellan
   ];
   buildInputs = [
     modpacks.testtools
     modpacks.testscenarios
     modpacks.testrepository
   ];

   checkPhase = ''
     ${python.interpreter} -m subunit.run discover -t ./ .
   '';

  };

  os-vif = buildPythonPackage rec {
    name = "os-vif-${version}";
    version = "1.2.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/os-vif/archive/${version}.tar.gz";
      sha256 = "01rhwjmfwnh02iavzjddwhgh2q6g7r1sj3zwwi46prfhrv93fqz2";
    };

    propagatedBuildInputs = [
      modpacks.stevedore
      six
      modpacks.pbr
      modpacks.oslo-versionedobjects
      modpacks.oslo-privsep
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.oslo-config
      #modpacks.oslo-concurrency
      modpacks.netaddr
    ];

    ## can't pass test
    doCheck = false;
  };

  os-win = buildPythonPackage rec {
    name = "os-win-${version}";
    version = "1.2.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/os-win/archive/${version}.tar.gz";
      sha256 = "12s2ay4wsy8d9l8rxskfvfjkqngn2b8794kgbx4f3vawmr99gymg";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.oslo-utils
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.oslo-config
      #modpacks.oslo-concurrency
      modpacks.eventlet
      Babel

      modpacks.oslo-service
      rfc3986
      modpacks.positional
    ];

    ## can't pass test
    doCheck = false;
  };

  microversion-parse = buildPythonPackage rec {
    name = "microversion-parse-${version}";
    version = "0.1.4";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/microversion-parse/archive/${version}.tar.gz";
      sha256 = "0sz3qwmchgpax7ljilxp0hz33b13lg2qynyzgw8h0j41f7rjsa33";
    };

    buildInputs = [
      coverage
      modpacks.oslosphinx_4_10
      modpacks.testrepository
      modpacks.testtools
      modpacks.webob
    ];
  };

  wsgi-intercept = buildPythonPackage rec {
    name = "wsgi-intercept-${version}";
    version = "1.4.1";

    src = fetchurl {
      url = "mirror://pypi/w/wsgi_intercept/wsgi_intercept-${version}.tar.gz";
      sha256 = "0n0ldx60h4s49l1vcf5a6rfpxmqjv6882rk9sx9snvx0x5ywsi52";
    };

    propagatedBuildInputs = [
      six
    ];
  };

  oslo-reports = buildPythonPackage rec {
    name = "oslo.reports-${version}";
    version = "1.14.0";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.reports/archive/${version}.tar.gz";
      sha256 = "1ddxg0ix05bqpds92i1pdls076rndfrln9szfbgzmdam7fjf7cgi";
    };

    PBR_VERSION = "${version}";

    propagatedBuildInputs = [
      modpacks.oslo-i18n
      modpacks.oslo-utils
      modpacks.oslo-serialization
      six
      psutil_1
      Babel
      jinja2
      modpacks.pbr

      modpacks.oslo-config
      rfc3986
    ];
    buildInputs = [
      coverage
      greenlet
      modpacks.eventlet
      modpacks.oslosphinx_4_10
      modpacks.oslotest
    ];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
  };

  oslo-rootwrap = buildPythonPackage rec {
    name = "oslo.rootwrap-${version}";
    version = "5.1.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.rootwrap/archive/${version}.tar.gz";
      sha256 = "0b86bmq1dy0k6d8m0909jvlq7maxbjsf8igj9sjssd8qg3g6csfh";
    };

    propagatedBuildInputs = [
      six
      modpacks.pbr
      modpacks.eventlet
    ];

    buildInputs = [
      modpacks.mock
      modpacks.oslotest
    ];

    # way too many assumptions
    doCheck = false;

    # https://bugs.launchpad.net/oslo.rootwrap/+bug/1519839
    patchPhase = ''
     substituteInPlace oslo_rootwrap/filters.py \
       --replace "/bin/cat" "${pkgs.coreutils}/bin/cat" \
       --replace "/bin/kill" "${pkgs.coreutils}/bin/kill"
    '';
    
  };

  privsep-helper = buildPythonPackage rec {
    name = "privsep-helper-${version}";
    version = "1.13.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.privsep/archive/1.13.1.tar.gz";
      sha256 = "0ip5hx29264863zhf3r6q88ab2j4rh4fcpv0blvwa6mgh6xpgm3f";
    };

    propagatedBuildInputs = [
      enum34
      modpacks.oslo-utils
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.oslo-config
      msgpack
      greenlet
      modpacks.eventlet
      cffi
      
      rfc3986
      modpacks.funcsigs
      modpacks.positional
      modpacks.os-vif
    ];

    ## can't pass test
    doCheck = false;

    installPhase = ''
      runHook preInstall

      ${python.interpreter} setup.py install --prefix=$out

      runHook postInstall
    '';
  };

  oslo-privsep = buildPythonPackage rec {
    name = "oslo-privsep-${version}";
    version = "1.13.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.privsep/archive/1.13.1.tar.gz";
      sha256 = "0ip5hx29264863zhf3r6q88ab2j4rh4fcpv0blvwa6mgh6xpgm3f";
    };

    propagatedBuildInputs = [
      enum34
      modpacks.oslo-utils
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.oslo-config
      msgpack
      greenlet
      modpacks.eventlet
      cffi
      
      rfc3986
      modpacks.funcsigs
      modpacks.positional
      #modpacks.os-vif
    ];

    ## can't pass test
    doCheck = false;
  };

  oslo-versionedobjects = buildPythonPackage rec {
    name = "oslo.versionedobjects-${version}";
    version = "1.17.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.versionedobjects/archive/1.17.0.tar.gz";
      sha256 = "0pmmvd59fiqsaz5jq5flapqqqk8ynd9hkycp4n1dv6paawi3xc7f";
    };

    propagatedBuildInputs = [
      six
      Babel
      #modpacks.oslo-concurrency
      modpacks.oslo-config
      modpacks.oslo-context
      modpacks.oslo-messaging
      modpacks.oslo-serialization
      modpacks.oslo-utils
      iso8601
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.webob
      modpacks.fixtures
      modpacks.mock

      rfc3986
      modpacks.pika-pool
      pythonHasOsloConcMod
    ];
    buildInputs = [
      modpacks.oslo-middleware
      cachetools
      modpacks.oslo-service
      modpacks.futurist
      anyjson
      modpacks.oslosphinx_4_10
      modpacks.testtools
      modpacks.oslotest
    ];

  };

  oslo-vmware = buildPythonPackage rec {
    name = "oslo.vmware-${version}";
    version = "2.14.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.vmware/archive/${version}.tar.gz";
      sha256 = "0c44i5b3cmqspf84mx7k5ak9lggab6bzcw6xnb3yc2bhp70307jx";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.stevedore
      modpacks.netaddr
      iso8601
      six
      modpacks.oslo-i18n
      modpacks.oslo-utils
      Babel
      pyyaml
      modpacks.eventlet
      modpacks.requests
      modpacks.urllib3
      #modpacks.oslo-concurrency
      suds-jurko
      lxml

      rfc3986
      modpacks.oslo-config
      modpacks.fasteners
      retrying
      pythonHasOsloConcMod
    ];
    buildInputs = [
      modpacks.bandit
      modpacks.oslosphinx_4_10
      coverage
      modpacks.testtools
      modpacks.testscenarios
      modpacks.testrepository
      modpacks.mock
    ];
  };

  ironicclient = buildPythonPackage rec {
    name = "python-ironicclient-${version}";
    version = "1.7.1";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-ironicclient/archive/${version}.tar.gz";
      sha256 = "05gz6ak4jpl3bg7sip0wl2fmw4ivnj80rc80mavkcz7mjvp2101q";
    };

    propagatedBuildInputs = [
      six
      modpacks.keystoneclient
      prettytable
      modpacks.oslo-utils
      modpacks.oslo-i18n
      lxml
      httplib2
      modpacks.cliff
      modpacks.dogpile_cache
      appdirs
      anyjson
      modpacks.pbr
      modpacks.requests
      mod-openstackclient
      modpacks.oslo-serialization
      modpacks.osc-lib
      modpacks.keystoneauth1
      jsonschema
      pyyaml

      modpacks.requests-mock
      ddt
    ];
    buildInputs = [
      modpacks.httpretty

      modpacks.oslotest
    ];

    ## can't pass test
    doCheck = false;
  };

  urllib3 = buildPythonPackage rec {
    name = "urllib3-${version}";
    version = "1.20";

    src = fetchurl {
      url = "https://github.com/shazow/urllib3/archive/${version}.tar.gz";
      sha256 = "19n07zlr0rir39d7143dkwmrkd5cpg4kyjl942m3lipp516gscl2";
    };

    checkPhase = ''
      # Not worth the trouble
      rm test/with_dummyserver/test_poolmanager.py
      rm test/with_dummyserver/test_proxy_poolmanager.py
      rm test/with_dummyserver/test_socketlevel.py
      # pypy: https://github.com/shazow/urllib3/issues/736
      rm test/with_dummyserver/test_connectionpool.py

      nosetests -v --cover-min-percentage 1
    '';

    propagatedBuildInputs = [
      modpacks.pysocks
      modpacks.ipaddress
      certifi
      modpacks.idna
      modpacks.cryptography
      modpacks.pyopenssl

      psutil_1
    ];
    
    buildInputs = [
      coverage
      tornado
      modpacks.mock
      nose
    ];

    ## can't pass test
    doCheck = false;
  };

  pysocks = buildPythonPackage rec {
    name = "pysocks-${version}";
    version = "1.6.5";

    src = fetchurl {
      url    = "https://github.com/Anorov/PySocks/archive/${version}.tar.gz";
      sha256 = "0k98dilryj8ammxc675z77dax0nva9hx3g6jh67amj6azfycjp3n";
    };

    doCheck = false;

  };

  elasticsearch = buildPythonPackage rec {
    name = "elasticsearch-1.9.0";

    src = fetchurl {
      url = "mirror://pypi/e/elasticsearch/${name}.tar.gz";
      sha256 = "091s60ziwhyl9kjfm833i86rcpjx46v9h16jkgjgkk5441dln3gb";
    };

    # Check is disabled because running them destroy the content of the local cluster!
    # https://github.com/elasticsearch/elasticsearch-py/tree/master/test_elasticsearch
    doCheck = false;
    propagatedBuildInputs = [
      modpacks.urllib3
      modpacks.requests
    ];
    buildInputs = [
      nosexcover
      modpacks.mock
    ];

  };

  httpretty = buildPythonPackage rec {
    name = "httpretty-${version}";
    version = "0.8.10";
    doCheck = false;

    src = fetchurl {
      url = "mirror://pypi/h/httpretty/${name}.tar.gz";
      sha256 = "1nmdk6d89z14x3wg4yxywlxjdip16zc8bqnfb471z1365mr74jj7";
    };

    buildInputs = [
      tornado
      modpacks.requests
      httplib2
      sure
      nose
      coverage
      certifi
    ];

    propagatedBuildInputs = [
      modpacks.urllib3
    ];

    postPatch = ''
      sed -i -e 's/==.*$//' *requirements.txt
      # XXX: Drop this after version 0.8.4 is released.
      patch httpretty/core.py <<DIFF
      ***************
      *** 566 ****
      !                 'content-length': len(self.body)
      --- 566 ----
      !                 'content-length': str(len(self.body))
      DIFF

      # Explicit encoding flag is required with python3, unless locale is set.
      ${if !isPy3k then "" else
        "patch -p0 -i ${../development/python-modules/httpretty/setup.py.patch}"}
    '';

  };

  boto = buildPythonPackage rec {
    name = "boto-${version}";
    version = "2.42.0";

    src = fetchurl {
      url = "https://github.com/boto/boto/archive/${version}.tar.gz";
      sha256 = "04ywn8xszk57s87jnkv4j1hswc6ra7z811y9lawfvhvnfshrpx5d";
    };

    checkPhase = ''
      ${python.interpreter} tests/test.py default
    '';

    buildInputs = [
      nose
      modpacks.mock
    ];
    propagatedBuildInputs = [
      modpacks.requests
      modpacks.httpretty
    ];
  };

  neutron-lib = buildPythonPackage rec {
    name = "neutron-lib-${version}";
    version = "0.4.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/neutron-lib/archive/${version}.tar.gz";
      sha256 = "1kbn6qs79jxa48caa3lz05y9wa9yk3mfx1gxfhb2hb3q6myq7izn";
    };

    propagatedBuildInputs = [
      Babel
      modpacks.sqlalchemy
      modpacks.debtcollector
      modpacks.oslo-config
      modpacks.oslo-context
      modpacks.oslo-db
      modpacks.oslo-i18n
      modpacks.oslo-log
      modpacks.oslo-messaging
      modpacks.oslo-policy
      modpacks.oslo-service
      modpacks.oslo-utils
      modpacks.pbr

      modpacks.positional
      modpacks.pika-pool
    ];

    ## can't pass test
    doCheck = false;
  };

  designateclient = buildPythonPackage rec {
    name = "python-designateclient-${version}";
    version = "2.3.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-designateclient/archive/${version}.tar.gz";
      sha256 = "19sqa7hcpf00g84r8pr9zjr6n010rn98wr3i23s5hxbvq38229dg";
    };

    propagatedBuildInputs = [
      modpacks.stevedore
      six
      modpacks.requests
      modpacks.pbr
      modpacks.oslo-utils
      modpacks.osc-lib
      modpacks.keystoneauth1
      jsonschema
      modpacks.debtcollector
      modpacks.cliff
    ];

    ## can't pass test
    doCheck = false;
  };

  pint = buildPythonPackage rec {
    name = "pint-${version}";
    version = "0.7.2";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/hgrecco/pint/archive/${version}.tar.gz";
      sha256 = "0d4pwxsx6i5qrp480jxzi0h30gva9r24bran2db3j2ncc8qy81k5";
    };

  };

  django-babel = buildPythonPackage rec {
    name = "django-babel-${version}";
    version = "0.5.1";

    src = fetchurl {
      url = "https://github.com/python-babel/django-babel/archive/${version}.tar.gz";
      sha256 = "03bmv5al20ynpfvw7qqjnnkmwqdgk0qn98iivfhxr9iqbg976grn";
    };

    propagatedBuildInputs = [
      django_1_8
      Babel
    ];
  };

  django-compressor = buildPythonPackage rec {
    name = "django-compressor-${version}";
    version = "2.1";

    src = fetchurl {
      url = "https://github.com/django-compressor/django-compressor/archive/${version}.tar.gz";
      sha256 = "0xmpm813s4rpf90x3f7ha0532fgqhmd0rd0fimvlx7ls9b9vzqiz";
    };

    propagatedBuildInputs = [
      modpacks.rcssmin
      modpacks.rjsmin
      django_appconf
    ];

  };

  django-openstack-auth = buildPythonPackage rec {
    name = "django-openstack-auth-${version}";
    version = "2.4.2";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/django_openstack_auth/archive/${version}.tar.gz";
      sha256 = "1dxx1lqghrxc060057xj38whzz51wmmr2bpalvbf8fqgw14gfd05";
    };

    propagatedBuildInputs = [
      six
      modpacks.keystoneclient
      modpacks.pbr
      modpacks.oslo-policy
      modpacks.oslo-config
      modpacks.keystoneauth1
      django_1_8
    ];

    ## can't pass test
    doCheck = false;
  };

  django-pyscss = buildPythonPackage rec {
    name = "django-pyscss-${version}";
    version = "2.0.2";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/fusionbox/django-pyscss/archive/${version}.tar.gz";
      sha256 = "0nzd5b1pqnjy2r84i4h9nlkljjwsfj1iych8z9kp7ci57ymw40bz";
    };

    propagatedBuildInputs = [
      django_1_8
      pathlib
      pyscss
      pillow
      pysqlite
      sqlite3
    ];

    doCheck = false;

  };

  heatclient = buildPythonPackage rec {
    name = "python-heatclient-${version}";
    version = "1.5.0";

    PBR_VERSION = "${version}";
    
    src = fetchurl {
      url = "https://github.com/openstack/python-heatclient/archive/${version}.tar.gz";
      sha256 = "0y0ihgdvgabf29ixy7rncdk95pjlvdd8sy5653yjlm9nfra7az66";
    };

    propagatedBuildInputs = [
      six
      modpacks.requests
      modpacks.swiftclient
      modpacks.pbr
      modpacks.oslo-utils
      modpacks.oslo-serialization
      modpacks.oslo-i18n
      modpacks.osc-lib
      modpacks.keystoneauth1
      iso8601
      modpacks.cliff
      pyyaml
      prettytable
      Babel
    ];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    ## can't pass test
    doCheck = false;
  };

  swiftclient = buildPythonPackage rec {
    name = "python-swiftclient-${version}";
    version = "3.1.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/python-swiftclient/archive/${version}.tar.gz";
      sha256 = "187h247sk24pyrjranlpkbzpqc7kf1nzwzhna5193v2whg7ibvq4";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.requests
      futures
      six
      modpacks.keystoneclient
    ];
    buildInputs = [
      modpacks.testtools
      modpacks.testrepository
      modpacks.mock
    ];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    meta = with stdenv.lib; {
      description = "Python bindings to the OpenStack Object Storage API";
      homepage = "http://www.openstack.org/";
    };
  };

  xstatic-angular = buildPythonPackage rec {
    name = "xstatic-angular-${version}";
    version = "1.5.8.0";

    src = fetchurl {
      url = "mirror://pypi/X/XStatic-Angular/XStatic-Angular-${version}.tar.gz";
      sha256 = "0cxhkq9k7b72r87z2lgm0mxl9hpzh322mflbd4jic16kcrxdvp5i";
    };
  };

  xstatic-angular-bootstrap = buildPythonPackage rec {
    name = "xstatic-angular-bootstrap-${version}";
    version = "0.11.0.8";

    src = fetchurl {
      url = "mirror://pypi/X/XStatic-Angular-Bootstrap/XStatic-Angular-Bootstrap-${version}.tar.gz";
      sha256 = "1l5hkqfdsfwi1mpkl7m9qz17p4dfv7w5dbc9djxpy2jk0rsb28xg";
    };
  };

  xstatic-angular-fileupload = buildPythonPackage rec {
    name = "xstatic-angular-fileupload-${version}";
    version = "12.0.4";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-angular-fileupload.git";
      rev = "d964a4e6473158c978ef8acaea2c95b7a0627e83";
      sha256 = "1pzq5b7w9z59wypl9bn7ynnz1m986fabqz9xs9176rzhr8m6l7ij";
    };
  };

  xstatic-angular-gettext = buildPythonPackage rec {
    name = "xstatic-angular-gettext-${version}";
    version = "2.1.0.2";

    src = fetchurl {
      url = "mirror://pypi/X/XStatic-Angular-Gettext/XStatic-Angular-Gettext-${version}.tar.gz";
      sha256 = "14x4kz1sx2fnr0xrqc1nqwl537q8r685dmnd4a17vy5j7d1myx60";
    };
  };

  xstatic-angular-lrdragndrop = buildPythonPackage rec {
    name = "xstatic-angular-lrdragndrop-${version}";
    version = "1.0.2.3";

    src = fetchurl {
      url = "https://github.com/openstack/xstatic-angular-lrdragndrop/archive/${version}.tar.gz";
      sha256 = "1j833mxpcc1b3709grhq38ja1ic2589vafa4x8hy1hkjvgpwscz3";
    };
  };

  xstatic-angular-schema-form = buildPythonPackage rec {
    name = "xstatic-angular-schema-form";
    version = "0.8.13.0";

    src = fetchurl {
      url = "https://github.com/openstack/deb-python-xstatic-angular-schema-form/archive/${version}.tar.gz";
      sha256 = "0qhf8fbn55v15clrsf7d9nkxx1mx4v9h3gr1s8g56pszk4j7f642";
    };
  };

  xstatic-bootstrap-datepicker = buildPythonPackage rec {
    name = "xstatic-bootstrap-datepicker-${version}";
    version = "1.4.0.0";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-bootstrap-datepicker.git";
      rev = "461f683bae68b479a3cb236a972a98bf5e6d53fb";
      sha256 = "0vb8fm063hz38rh6s0j00fzdv951b4x64xqcjjs7yyys1ywq18pk";
    };
  };

  xstatic-bootstrap-scss = buildPythonPackage rec {
    name = "xstatic-bootstrap-scss-${version}";
    version = "3.3.7.1";

    src = fetchurl {
      url = "https://github.com/openstack/xstatic-bootstrap-scss/archive/${version}.tar.gz";
      sha256 = "0wh4cpim4sggg9jkzyyjzqia3xig666d79b448jkgsvpjmsx54l3";
    };
  };

  xstatic-bootswatch = buildPythonPackage rec {
    name = "xstatic-bootswatch-${version}";
    version = "3.3.7.0";

    src = fetchurl {
      url = "https://github.com/openstack/xstatic-bootswatch/archive/${version}.tar.gz";
      sha256 = "0npqcl9dgys9hhl7q7402rjsrmc6iz24kqdg5p4ga1pic70g3yci";
    };
  };

  xstatic-d3 = buildPythonPackage rec {
    name = "xstatic-d3-${version}";
    version = "3.5.17.0";

    src = fetchurl {
      url = "https://github.com/openstack/xstatic-d3/archive/${version}.tar.gz";
      sha256 = "1bz75kn9msccdx767a4l9ahppfw54d1pp3kdf61cj98ipkcyh06l";
    };
  };

  xstatic-hogan = buildPythonPackage rec {
    name = "xstatic-hogan-${version}";
    version = "2016-7-20";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-hogan.git";
      rev = "8051e59dcad57430a578c736b519507f53c0ff38";
      sha256 = "0pfia0pq0dl2gl3mcc18qs9lv387xci0frpx1sns2zawzl0m8f5d";
    };
  };

  xstatic-font-awesome = buildPythonPackage rec {
    name = "xstatic-font-awesome-${version}";
    version = "4.7.0.0";

    src = fetchurl {
      url = "https://github.com/openstack/xstatic-font-awesome/archive/${version}.tar.gz";
      sha256 = "0ilfbbnly0qrklyr85mda26ggw9gp6hwdfssvqf5lh032ndwhd3b";
    };
  };

  xstatic-jasmine = buildPythonPackage rec {
    name = "xstatic-jasmine-${version}";
    version = "2.4.1.1";

    PBR_VERSION="${version}";

    src = fetchurl {
      url = "mirror://pypi/X/XStatic-Jasmine/XStatic-Jasmine-${version}.tar.gz";
      sha256 = "0h27piyjnfi28la2k4gv8ykixrg9jzqrbb8a5k687xhw1qybzs6i";
    };
  };

  xstatic-jquery-migrate = buildPythonPackage rec {
    name = "xstatic-jquery-migrate-${version}";
    version = "2016-7-20";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-jquery-migrate.git";
      rev = "c13b1c0f8b827fb1f56ae9ca51eb75acc14b454f";
      sha256 = "1rfszz979r8xwy32hc0wmh85j51cjiyj5mvw73g7mihdy6mq09bz";
    };
  };

  xstatic-jquery-quicksearch = buildPythonPackage rec {
    name = "xstatic-jquery.quicksearch-${version}";
    version = "2016-7-20";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-jquery.quicksearch.git";
      rev = "7244a86a25f9eac7ca8dcb4bd388b2180609bf23";
      sha256 = "0fi5x1dhmzkwwglyhh7bzsb6z5v83vaj04kdzq1cafkp3k0rrgac";
    };
  };

  xstatic-jquery-tablesorter = buildPythonPackage rec {
    name = "xstatic-jquery.tablesorter-${version}";
    version = "2016-7-20";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-jquery.tablesorter.git";
      rev = "ec6d278271b84f709e8cef47dd22b56ffc99a3c1";
      sha256 = "1f8fz6d2wn5hp7fj3jlj47a5r004b34zb54f6s03ss7v9kzcvxq7";
    };
  };

  xstatic-jsencrypt = buildPythonPackage rec {
    name = "xstatic-jsencrypt-${version}";
    version = "2.0.0.2";

    src = fetchurl {
      url = "mirror://pypi/X/XStatic-JSEncrypt/XStatic-JSEncrypt-${version}.tar.gz";
      sha256 = "1d9699prd7dfmrxdcwc2j3mlm9chs7dbc421iy2cg03gzhm8jljq";
    };
  };

  xstatic-mdi = buildPythonPackage rec {
    name = "xstatic-mdi-${version}";
    version = "1.4.57.0";

    src = fetchurl {
      url = "mirror://pypi/X/XStatic-mdi/XStatic-mdi-${version}.tar.gz";
      sha256 = "0lwa189lxwxxirqg6qsxp6lapss5rxzi8f9vi7igwqpsz0idbd0r";
    };
  };

  xstatic-objectpath = buildPythonPackage rec {
    name = "xstatic-objectpath-${version}";
    version = "1.2.1.0";

    src = fetchurl {
      url = "https://github.com/openstack/deb-python-xstatic-objectpath/archive/${version}.tar.gz";
      sha256 = "1h7xa87sinwgc52983q9kyahdd324b8h0my2d3qvj2v0ivxl7hwa";
    };
  };

  xstatic-rickshaw = buildPythonPackage rec {
    name = "xstatic-rickshaw-${version}";
    version = "2016-4-21";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-rickshaw.git";
      rev = "8f31ba8d1597427b67f9d4844dc2b99a4e08b445";
      sha256 = "00v92zmjxkll21a3ajybgvvckp5fgfc3yfq7pads970mmc5dpnqd";
    };
  };

  xstatic-roboto-fontface = buildPythonPackage rec {
    name = "xstatic-roboto-fontface-${version}";
    version = "0.5.0.0";

    src = fetchurl {
      url = "https://github.com/openstack/xstatic-roboto-fontface/archive/${version}.tar.gz";
      sha256 = "0cakqd75kcv6wp7myf5mbkhsfba7sm2scd3kg2b877j8ppgrmq57";
    };
  };

  xstatic-smart-table = buildPythonPackage rec {
    name = "xstatic-smart-table-${version}";
    version = "1.4.13.2";

    src = fetchurl {
      url = "https://github.com/openstack/deb-python-xstatic-smart-table/archive/${version}.tar.gz";
      sha256 = "0kj3y8a8pcdqgifd1m6cgiar8vpwk8iw9dxcdj38l89jhvzpcl0c";
    };
  };

  xstatic-spin = buildPythonPackage rec {
    name = "xstatic-spin-${version}";
    version = "2016-7-20";

    src = pkgs.fetchgit {
      url = "https://github.com/openstack/xstatic-spin.git";
      rev = "01e63261361c9d083ad4c933c70b3c961eb84a82";
      sha256 = "1imi5rgy58ajwkwg9qbcd855c3zjs90j3kl1a57w8z6raf82rr1d";
    };
  };

  xstatic-termjs = buildPythonPackage rec {
    name = "xstatic-term.js-${version}";
    version = "0.0.7.0";

    src = fetchurl {
      url = "mirror://pypi/X/XStatic-term.js/XStatic-term.js-${version}.tar.gz";
      sha256 = "0cdx8baadib4lnv1pf65a4nqxc5an88km4al8bq930v3rdlspwxm";
    };
    
  };

  xstatic-tv4 = buildPythonPackage rec {
    name = "xstatic-tv4-${version}";
    version = "1.2.7.0";

    src = fetchurl {
      url = "https://github.com/openstack/deb-python-xstatic-tv4/archive/${version}.tar.gz";
      sha256 = "008p12q3idqdh3dv60yg08cnjzcl3hc6j8kpb223lr2chz141cnl";
    };
  };

  rcssmin = buildPythonPackage rec {
    name = "rcssmin-${version}";
    version = "1.0.6";

    src = fetchurl {
      url = "http://storage.perlig.de/rcssmin/rcssmin-${version}.tar.gz";
      sha256 = "0w42l4dhxghcz7pj3q7hkxp015mvb8z2cq9sfxbl31npsfavd1ya";
    };
  };

  rjsmin = buildPythonPackage rec {
    name = "rjsmin-${version}";
    version = "1.0.12";

    src = fetchurl {
      url = "http://storage.perlig.de/rjsmin/rjsmin-${version}.tar.gz";
      sha256 = "1wc62d0f80kw1kjv8nlxychh0iy66a6pydi4vfvhh2shffm935fx";
    };
  };

  pecan = buildPythonPackage rec {
    name = "pecan-${version}";
    version = "1.2.1";

    src = fetchurl {
      url = "https://github.com/pecan/pecan/archive/${version}.tar.gz";
      sha256 = "0521ak2d4ybxzsp4j7rkqsy28nshcn0y1cdhc0060chiwxg4cvks";
    };

    propagatedBuildInputs = [
      singledispatch
      logutils
      modpacks.webob
      six
    ];

    buildInputs = [
      modpacks.webtest
      Mako
      genshi
      Kajiki
      modpacks.sqlalchemy
      gunicorn
      jinja2
      virtualenv
    ];
  };

  websockify = buildPythonPackage rec {
    name = "websockify-${version}";
    version = "0.8.0";

    src = fetchurl {
      url = "https://github.com/novnc/websockify/archive/v${version}.tar.gz";
      sha256 = "1kjq6gibsvbb6zx5gi8hgh7110x62pbwcqkwapf3k7s27w5y907h";
    };

    propagatedBuildInputs = [
      numpy
    ];

  };

  networking-bgpvpn = buildPythonPackage rec {
    name = "networking-bgpvpn-${version}";
    version = "5.0.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/networking-bgpvpn/archive/${version}.tar.gz";
      sha256 = "0cczg7ggrngv5nw0n5x6zmrqsa7raijgcz5w1avxf1zly8lbpd6z";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      Babel
      modpacks.oslo-config
      modpacks.oslo-db
      modpacks.oslo-i18n
      modpacks.oslo-log
      modpacks.oslo-utils
      modpacks.sphinxcontrib-blockdiag
      modpacks.sphinxcontrib-seqdiag
      modpacks.neutron-lib
    ];

    ## can't pass test
    doCheck = false;
  };

  sphinxcontrib-blockdiag = buildPythonPackage rec {
    name = "sphinxcontrib-blockdiag-${version}";
    version = "1.5.5";

    src = fetchurl {
      url = "https://github.com/blockdiag/sphinxcontrib-blockdiag/archive/${version}.tar.gz";
      sha256 = "0p19bkifa95nr0f2ashfqh2382j7vhy76w1pygik6bsv2avqb47b";
    };

    propagatedBuildInputs = [
      modpacks.blockdiag
      modpacks.sphinx
    ];
  };

  sphinxcontrib-seqdiag = buildPythonPackage rec {
    name = "sphinxcontrib-seqdiag-${version}";
    version = "0.8.5";

    src = fetchurl {
      url = "https://github.com/blockdiag/sphinxcontrib-seqdiag/archive/${version}.tar.gz";
      sha256 = "15723i0vf4rxkrffmagq1p0ax1820dggq4vcksabyvifn3mpf619";
    };

    propagatedBuildInputs = [
      modpacks.seqdiag
      modpacks.sphinx
    ];
  };

  ironic-lib = buildPythonPackage rec {
    name = "ironic-lib-${version}";
    version = "2.1.3";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/ironic-lib/archive/${version}.tar.gz";
      sha256 = "0c76bxmyn1q3qajl0c24b2w17njgpf051svm4i05p56wdyw0m37d";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-service
      modpacks.oslo-utils
      modpacks.requests
      six
      modpacks.oslo-log

      pythonHasOsloConcMod
    ];

    ## can't pass test
    doCheck = false;
  };

  dib-utils = buildPythonPackage rec {
    name = "dib-utils-${version}";
    version = "0.0.11";

    src = fetchurl {
      url = "mirror://pypi/d/dib-utils/dib-utils-${version}.tar.gz";
      sha256 = "0b47f0sn5sgbsmf2hwd4hkikzsxh52m50gnj6d24ssk24ip37ijr";
    };
  };

  oslosphinx_4_10 = buildPythonPackage rec {
    name = "oslosphinx-${version}";
    version = "4.10.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslosphinx/archive/${version}.tar.gz";
      sha256 = "1l139gl52xfx2cccjsg2s4rcj9g8cjz3ridb0c56j9j553005807";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.requests
      six
    ];

    ## can't pass test
    doCheck = false;
  };

  ryu = buildPythonPackage rec {
    name = "ryu-${version}";
    version = "4.13";

    src = fetchurl {
      url = "mirror://pypi/r/ryu/ryu-${version}.tar.gz";
      sha256 = "11glcd5mrd4l2blgxcdkmmi8xnbs63aks63lb1w0453vanibadgr";
    };

    propagatedBuildInputs = [
      modpacks.paramiko
      lxml
      modpacks.ncclient
      modpacks.sqlalchemy

      modpacks.webob
      modpacks.oslo-config
      modpacks.eventlet
      modpacks.ovs
      modpacks.tinyrpc
      msgpack
      modpacks.routes
    ];
  };

  ncclient = buildPythonPackage rec {
    name = "ncclient-${version}";
    version = "0.5.3";

    src = fetchurl {
      url = "mirror://pypi/n/ncclient/ncclient-${version}.tar.gz";
      sha256 = "0aykgcqdpj5k0qf8z4afxdlxz6qsv7ylp9qxb7sj26szxlb9qszy";
    };

    propagatedBuildInputs = [
      modpacks.paramiko
      lxml
      pkgs.libxml2
      pkgs.libxslt
    ];
  };

  ovs = buildPythonPackage rec {
    name = "ovs-${version}";
    version = "2.7.0";

    src = fetchurl {
      url = "mirror://pypi/o/ovs/ovs-${version}.tar.gz";
      sha256 = "0jlydirj1zvrp8w30nq0vciw1zjqmfx8s97ls3q5pr12059hmg59";
    };
  };

  tinyrpc = buildPythonPackage rec {
    name = "tinyrpc-${version}";
    version = "0.5";

    src = fetchurl {
      url = "mirror://pypi/t/tinyrpc/tinyrpc-${version}.tar.gz";
      sha256 = "07s27177nwzrlgalgwvg14p295flzng8jm9vz2n8lca7lfij72q4";
    };
  };

  sphinx = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "Sphinx";
    version = "1.6.5";
    src = fetchPypi {
      inherit pname version;
      sha256 = "c6de5dbdbb7a0d7d2757f4389cc00e8f6eb3c49e1772378967a12cfcf2cfe098";
    };
    LC_ALL = "en_US.UTF-8";

    checkInputs = [
      pytest
    ];
    buildInputs = [
      simplejson
      modpacks.mock
      pkgs.glibcLocales
      html5lib
      enum34
    ];
    # Disable two tests that require network access.
    checkPhase = ''
      cd tests; ${python.interpreter} run.py --ignore py35 -k 'not test_defaults and not test_anchors_ignored'
    '';
    
    propagatedBuildInputs = [
      docutils
      jinja2
      pygments
      alabaster
      Babel
      snowballstemmer
      six
      modpacks.sqlalchemy
      whoosh
      imagesize
      modpacks.requests
      modpacks.sphinxcontrib-websupport
      typing
    ];

    # Lots of tests. Needs network as well at some point.
    doCheck = false;

    # https://github.com/NixOS/nixpkgs/issues/22501
    # Do not run `python sphinx-build arguments` but `sphinx-build arguments`.
    postPatch = ''
      substituteInPlace sphinx/make_mode.py --replace "sys.executable, " ""
    '';
  };

  testtools = buildPythonPackage rec {
    pname = "testtools";
    version = "1.9.0";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "b46eec2ad3da6e83d53f2b0eca9a8debb687b4f71343a074f83a16bbdb3c0644";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      python_mimeparse
      extras
      lxml
      modpacks.unittest2
      pyrsistent
    ];
    buildInputs = [
      modpacks.traceback2
    ];

    # No tests in archive
    doCheck = false;
  };

  mock = buildPythonPackage rec {
    name = "mock-2.0.0";

    src = pkgs.fetchurl {
      url = "mirror://pypi/m/mock/${name}.tar.gz";
      sha256 = "1flbpksir5sqrvq2z0dp8sl4bzbadg21sj4d42w3klpdfvgvcn5i";
    };

    buildInputs = [
      modpacks.unittest2
    ];
    propagatedBuildInputs = [
      modpacks.funcsigs
      six
      modpacks.pbr
    ];

    checkPhase = ''
      ${python.interpreter} -m unittest discover
    '';
  };

  unittest2 = buildPythonPackage rec {
    name = "unittest2-1.1.0";

    src = pkgs.fetchurl {
      url = "mirror://pypi/u/unittest2/${name}.tar.gz";
      sha256 = "0y855kmx7a8rnf81d3lh5lyxai1908xjp0laf4glwa4c8472m212";
    };

    doCheck = false;

    postPatch = ''
      # argparse is needed for python < 2.7, which we do not support anymore.
      substituteInPlace setup.py --replace "argparse" ""
      # # fixes a transient error when collecting tests, see https://bugs.launchpad.net/python-neutronclient/+bug/1508547
      sed -i '510i\        return None, False' unittest2/loader.py
      # https://github.com/pypa/packaging/pull/36
      sed -i 's/version=VERSION/version=str(VERSION)/' setup.py
    '';

    propagatedBuildInputs = [
      six
      modpacks.traceback2
    ];
    buildInputs = [
      ddt
    ];
  };

  funcsigs = buildPythonPackage rec {
    pname = "funcsigs";
    version = "1.0.2";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0l4g5818ffyfmfs1a924811azhjj8ax9xd1cffr1mzd3ycn0zfx7";
    };

    buildInputs = [
      modpacks.unittest2
    ];
  };

  traceback2 = buildPythonPackage rec {
    version = "1.4.0";
    name = "traceback2-${version}";

    src = pkgs.fetchurl {
      url = "mirror://pypi/t/traceback2/traceback2-${version}.tar.gz";
      sha256 = "0c1h3jas1jp1fdbn9z2mrgn3jj0hw1x3yhnkxp7jw34q15xcdb05";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      linecache2
    ];
    # circular dependencies for tests
    doCheck = false;
  };

  testrepository = buildPythonPackage rec {
    name = "testrepository-${version}";
    version = "0.0.20";

    src = pkgs.fetchurl {
      url = "mirror://pypi/t/testrepository/${name}.tar.gz";
      sha256 = "1ssqb07c277010i6gzzkbdd46gd9mrj0bi0i8vn560n2k2y4j93m";
    };

    buildInputs = [
      modpacks.testtools
      testresources
    ];
    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.subunit
      modpacks.fixtures
    ];

    checkPhase = ''
      ${python.interpreter} ./testr
    '';
  };

  subunit = buildPythonPackage rec {
    name = pkgs.subunit.name;
    src = pkgs.subunit.src;

    propagatedBuildInputs = [
      modpacks.testtools
      modpacks.testscenarios
    ];

    buildInputs = [
      pkgs.pkgconfig
      pkgs.check
      pkgs.cppunit
    ];

    patchPhase = ''
      sed -i 's/version=VERSION/version="${pkgs.subunit.version}"/' setup.py
    '';
  };

  testscenarios = buildPythonPackage rec {
    name = "testscenarios-${version}";
    version = "0.4";

    src = pkgs.fetchurl {
      url = "mirror://pypi/t/testscenarios/${name}.tar.gz";
      sha256 = "1671jvrvqlmbnc42j7pc5y6vc37q44aiwrq0zic652pxyy2fxvjg";
    };

    propagatedBuildInputs = [
      modpacks.testtools
    ];
  };

  fixtures = buildPythonPackage rec {
    pname = "fixtures";
    version = "3.0.0";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "fcf0d60234f1544da717a9738325812de1f42c2fa085e2d9252d8fff5712b2ef";
    };

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.testtools
      modpacks.mock
    ];

    checkPhase = ''
      ${python.interpreter} -m testtools.run fixtures.test_suite
    '';
  };

  requests-mock = buildPythonPackage rec {
    name = "requests-mock-${version}";
    version = "1.3.0";

    src = pkgs.fetchurl {
      url = "mirror://pypi/r/requests-mock/${name}.tar.gz";
      sha256 = "0jr997dvk6zbmhvbpcv3rajrgag69mcsm1ai3w3rgk2jdh6rg1mx";
    };

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    buildInputs = [
      modpacks.pbr
      modpacks.testtools
      modpacks.testrepository
      modpacks.mock
    ];
    propagatedBuildInputs = [
      six
      modpacks.requests
    ];
  };

  mox3 = buildPythonPackage rec {
    name = "mox3-${version}";
    version = "0.20.0";

    src = pkgs.fetchurl {
      url = "mirror://pypi/m/mox3/${name}.tar.gz";
      sha256 = "01jnb5rp5dyf1vspv66360yk5k72dwcfyd2pf1dwrxjk4ci4j5bv";
    };

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';

    buildInputs = [
      modpacks.subunit
      modpacks.testrepository
      modpacks.testtools
      six
    ];

    propagatedBuildInputs = [
      modpacks.pbr
      modpacks.fixtures
    ];
  };

  betamax = buildPythonPackage rec {
    name = "betamax-0.8.0";

    src = pkgs.fetchurl {
      url = "mirror://pypi/b/betamax/${name}.tar.gz";
      sha256 = "18f8v5gng3j773jlbbzx4rg1i4y2zw3m2l1zpmbvp8bh5a2q1i42";
    };

    propagatedBuildInputs = [
      modpacks.requests
    ];

    doCheck = false;
  };

  sqlalchemy = buildPythonPackage rec {
    pname = "SQLAlchemy";
    name = "${pname}-${version}";
    version = "1.0.19";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1dcyxs72r74gy58088gl0mw8kq5rj2f2na45v9pq35k78q4adg3x";
    };

    checkInputs = [
      pytest_30
      modpacks.mock
      pysqlite
    ];

    checkPhase = ''
      py.test
    '';
  };

  pylint = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "pylint";
    version = "1.7.4";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1f65b3815c3bf7524b845711d54c4242e4057dd93826586620239ecdfe591fb1";
    };

    buildInputs = [
      pytest
      pytestrunner
      mccabe
      configparser
      backports_functools_lru_cache
    ];

    propagatedBuildInputs = [
      modpacks.astroid
      configparser
      modpacks.isort
    ];

    postPatch = ''
      # Remove broken darwin tests
      sed -i -e '/test_parallel_execution/,+2d' pylint/test/test_self.py
      sed -i -e '/test_py3k_jobs_option/,+4d' pylint/test/test_self.py
      rm -vf pylint/test/test_functional.py
    '';

    checkPhase = ''
      cd pylint/test
      ${python.interpreter} -m unittest discover -p "*test*"
    '';

    postInstall = ''
      mkdir -p $out/share/emacs/site-lisp
      cp "elisp/"*.el $out/share/emacs/site-lisp/
    '';
  };

  isort = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "isort";
    version = "4.2.5";
    src = fetchurl {
      url = "mirror://pypi/i/${pname}/${name}.tar.gz";
      sha256 = "0p7a6xaq7zxxq5vr5gizshnsbk2afm70apg97xwfdxiwyi201cjn";
    };
    buildInputs = [
      modpacks.mock
      pytest
    ];
    # No tests distributed
    doCheck = false;
  };

  astroid = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "astroid";
    version = "1.5.3";

    src = fetchPypi {
      inherit pname version;
      sha256 = "492c2a2044adbf6a84a671b7522e9295ad2f6a7c781b899014308db25312dd35";
    };

    propagatedBuildInputs = [
      modpacks.logilab_common
      six
      lazy-object-proxy
      wrapt
      enum34
      singledispatch
      backports_functools_lru_cache
    ];

    postPatch = ''
      cd astroid/tests
      for i in $(ls unittest*); do mv -v $i test_$i; done
      cd ../..
      rm -vf astroid/tests/test_unittest_inference.py
      rm -vf astroid/tests/test_unittest_manager.py
    '';

    checkPhase = ''
      ${python.interpreter} -m unittest discover
    '';
  };

  logilab_common = buildPythonPackage rec {
    pname = "logilab-common";
    version = "1.4.1";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "02in5555iak50gzn35bnnha9s85idmh0wwxaxz13v81z5krn077d";
    };

    propagatedBuildInputs = [
      modpacks.unittest2
      six
    ];

    doCheck = false;
  };

  blockdiag = buildPythonPackage rec {
    name = "blockdiag-${version}";
    version = "1.5.3";

    src = pkgs.fetchurl {
      url = "https://bitbucket.org/blockdiag/blockdiag/get/${version}.tar.bz2";
      sha256 = "0r0qbmv0ijnqidsgm2rqs162y9aixmnkmzgnzgk52hiy7ydm4k8f";
    };

    buildInputs = [
      pep8
      nose
      modpacks.unittest2
      docutils
    ];

    propagatedBuildInputs = [
      pillow
      webcolors
      funcparserlib
    ];

    doCheck = false;
  };

  seqdiag = buildPythonPackage rec {
    name = "seqdiag-0.9.4";

    src = pkgs.fetchurl {
      url = "mirror://pypi/s/seqdiag/${name}.tar.gz";
      sha256 = "1qa7d0m1wahvmrj95rxkb6128cbwd4w3gy8gbzncls66h46bifiz";
    };

    buildInputs = [
      pep8
      nose
      modpacks.unittest2
      docutils
    ];

    propagatedBuildInputs = [
      modpacks.blockdiag
    ];

    doCheck = false;
  };

  netaddr = buildPythonPackage rec {
    pname = "netaddr";
    version = "0.7.18";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "06dxjlbcicq7q3vqy8agq11ra01kvvd47j4mk6dmghjsyzyckxd1";
    };

    LC_ALL = "en_US.UTF-8";
    buildInputs = [
      pkgs.glibcLocales
      pytest
    ];

    checkPhase = ''
      py.test netaddr/tests
    '';

    patches = [
      (pkgs.fetchpatch {
        url = https://github.com/drkjam/netaddr/commit/2ab73f10be7069c9412e853d2d0caf29bd624012.patch;
        sha256 = "08rn1s3w9424jhandy4j9sksy852ny00088zh15nirw5ajqg1dn7";
      })
    ];
  };

  netifaces = buildPythonPackage rec {
    version = "0.10.5";
    name = "netifaces-${version}";

    src = pkgs.fetchurl {
      url = "mirror://pypi/n/netifaces/${name}.tar.gz";
      sha256 = "12v2bm77dgaqjm9vmb8in0zpip2hn98mf5sycfvgq5iivm9avn2r";
    };
  };

  argparse = buildPythonPackage rec {
    version = "1.4.0";
    name = "argparse-${version}";

    src = pkgs.fetchurl {
      url = "mirror://pypi/a/argparse/${name}.tar.gz";
      sha256 = "1r6nznp64j68ih1k537wms7h57nvppq0szmwsaf99n71bfjqkc32";
    };
  };

  ipaddress = buildPythonPackage rec {
    name = "ipaddress-1.0.16";

    src = pkgs.fetchurl {
      url = "mirror://pypi/i/ipaddress/${name}.tar.gz";
      sha256 = "1c3imabdrw8nfksgjjflzg7h4ynjckqacb188rf541m74arq4cas";
    };

    checkPhase = ''
      ${python.interpreter} test_ipaddress.py
    '';
  };

  idna = buildPythonPackage rec {
    pname = "idna";
    version = "2.0";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0frxgmgi234lr9hylg62j69j4ik5zhg0wz05w5dhyacbjfnrl68n";
    };
  };

  cryptography = buildPythonPackage rec {
    # also bump cryptography_vectors
    pname = "cryptography";
    name = "${pname}-${version}";
    version = "1.7.2";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1ad9zmzi31fnz31qfchxcwiydvlxq88xndlgsvzr7m537n5vd347";
    };

    outputs = [ "out" "dev" ];

    buildInputs = [
      pkgs.openssl
      modpacks.cryptography_vectors
    ];
    propagatedBuildInputs = [
      modpacks.idna
      modpacks.asn1crypto
      pyasn1
      packaging
      six
      enum34
      modpacks.ipaddress
      cffi
    ];

    checkInputs = [
      pytest
      pretend
      iso8601
      pytz
      hypothesis
    ];

    # The test assumes that if we're on Sierra or higher, that we use `getentropy`, but for binary
    # compatibility with pre-Sierra for binary caches, we hide that symbol so the library doesn't
    # use it. This boils down to them checking compatibility with `getentropy` in two different places,
    # so let's neuter the second test.
    postPatch = ''
      substituteInPlace ./tests/hazmat/backends/test_openssl.py --replace '"16.0"' '"99.0"'
    '';

    # IOKit's dependencies are inconsistent between OSX versions, so this is the best we
    # can do until nix 1.11's release
    __impureHostDeps = [ "/usr/lib" ];
  };

  cryptography_vectors = buildPythonPackage rec {
      # also bump cryptography
    pname = "cryptography_vectors";
    version = modpacks.cryptography.version;
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1p5cw3dzgcpzmp81qb9860hn9qlcvr4rnf0fy31fbvhxl7lfxr2b";
    };

    # No tests included
    doCheck = false;
  };

  pyopenssl = buildPythonPackage rec {
    pname = "pyOpenSSL";
    name = "${pname}-${version}";
    version = "17.0.0";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1pdg1gpmkzj8yasg6cmkhcivxcdp4c12nif88y4qvsxq5ffzxas8";
    };

    patches = pkgs.fetchpatch {
      url = "https://github.com/pyca/pyopenssl/commit/"
          + "a40898b5f1d472f9449a344f703fa7f90cddc21d.patch";
      sha256 = "0bdfrhfvdfxhfknn46s4db23i3hww6ami2r1l5rfrri0pn8b8mh7";
    };

    preCheck = ''
      sed -i 's/test_set_default_verify_paths/noop/' tests/test_ssl.py
    '';

    checkPhase = ''
      runHook preCheck
      export LANG="en_US.UTF-8"
      py.test
      runHook postCheck
    '';

    buildInputs = [
      pkgs.openssl
      pytest
      pkgs.glibcLocales
      pretend
      flaky
    ];
    propagatedBuildInputs = [
      modpacks.cryptography
      pyasn1
      modpacks.idna
    ];
  };

  oauthlib = buildPythonPackage rec {
    version = "2.0.0";
    name = "oauthlib-${version}";

    src = fetchurl {
      url = "https://github.com/idan/oauthlib/archive/v${version}.tar.gz";
      sha256 = "02b645a8rqh4xfs1cmj8sss8wqppiadd1ndq3av1cdjz2frfqcjf";
    };

    buildInputs = [
      modpacks.mock
      nose
      modpacks.unittest2
    ];

    propagatedBuildInputs = [
      modpacks.cryptography
      blinker
      modpacks.pyjwt
    ];
  };

  pyjwt = buildPythonPackage rec {
    version = "1.5.3";
    name = "pyjwt-${version}";

    src = pkgs.fetchFromGitHub {
      owner = "progrium";
      repo = "pyjwt";
      rev = version;
      sha256 = "109zb3ka2lvp00r9nawa0lmljfikvhcj5yny19kcipz8mqia1gs8";
    };

    buildInputs = [
      pytestrunner
      pytestcov
      pytest
      coverage
    ];
    propagatedBuildInputs = [
      modpacks.cryptography
      ecdsa
    ];

    # We don't need this specific version
    postPatch = ''
      substituteInPlace setup.py --replace "pytest==2.7.3" "pytest"
    '';
  };

  paramiko = buildPythonPackage rec {
    pname = "paramiko";
    version = "2.1.1";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0xdmamqgx2ymhdm46q8flpj4fncj4wv2dqxzz0bc2dh7mnkss7fm";
    };

    propagatedBuildInputs = [
      modpacks.cryptography
      pyasn1
    ];

    checkPhase = ''
      # test_util needs to resolve an hostname, thus failing when the fw blocks it
      sed '/UtilTest/d' -i test.py
      ${python}/bin/${python.executable} test.py --no-sftp --no-big-file
    '';
  };

  libvirt = let
    version = "2.5.0";
  in assert version == mod-libvirt.version; pkgs.stdenv.mkDerivation rec {
    name = "libvirt-python-${version}";

    src = pkgs.fetchurl {
      url = "http://libvirt.org/sources/python/${name}.tar.gz";
      sha256 = "1lanyrk4invs5j4jrd7yvy7g8kilihjbcrgs5arx8k3bs9x7izgl";
    };

    buildInputs = [
      python
      pkgs.pkgconfig
      mod-libvirt
      lxml
    ];

    buildPhase = "${python.interpreter} setup.py build";

    installPhase = "${python.interpreter} setup.py install --prefix=$out";
  };

  transaction = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "transaction";
    version = "2.1.2";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1mab0r3grmgz9d97y8pynhg0r34v0am35vpxyvh7ff5sgmg3dg5r";
    };

    propagatedBuildInputs = [
      zope_interface
      modpacks.mock
    ];
  };

  repoze_sphinx_autointerface = buildPythonPackage rec {
    name = "repoze.sphinx.autointerface-0.7.1";

    src = pkgs.fetchurl {
      url = "mirror://pypi/r/repoze.sphinx.autointerface/${name}.tar.gz";
      sha256 = "97ef5fac0ab0a96f1578017f04aea448651fa9f063fc43393a8253bff8d8d504";
    };

    propagatedBuildInputs = [
      zope_interface
      modpacks.sphinx
    ];
  };

  asn1crypto = buildPythonPackage rec {
    pname = "asn1crypto";
    version = "0.23.0";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0874981329cfebb366d6584c3d16e913f2a0eb026c9463efcc4aaf42a9d94d70";
    };

    # No tests included
    doCheck = false;
  };

  sphinxcontrib-websupport = buildPythonPackage rec {
    pname = "sphinxcontrib-websupport";
    version = "1.0.1";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "7a85961326aa3a400cd4ad3c816d70ed6f7c740acd7ce5d78cd0a67825072eb9";
    };

    propagatedBuildInputs = [ six ];

    doCheck = false;
  };

}
