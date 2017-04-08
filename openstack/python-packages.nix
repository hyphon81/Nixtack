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

  sqlite3 = if builtins.hasAttr "sqlite3" then pkgs.sqlite3 else pkgs.sqlite;
in

with python2Packages;
{
  oslo-policy = buildPythonPackage rec {
    name = "oslo.policy-${version}";
    version = "1.14.0";

    PBR_VERSION = "${version}";

    src = fetchurl {
      url = "https://github.com/openstack/oslo.policy/archive/${version}.tar.gz";
      sha256 = "0xn5pk1480ndagph3dw41i1mj4vmlhqayg8zzb45q2jpgzrwyg7n";
    };

    propagatedBuildInputs = [
      requests2
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-serialization
      modpacks.oslo-utils
      six
      
      rfc3986
      funcsigs
      pyyaml

      modpacks.stevedore
    ];
    buildInputs = [
      oslosphinx
      modpacks.httpretty
      modpacks.oslotest

    ];

    nativeBuildInputs = [
      modpacks.oslo-config
      modpacks.oslo-i18n
      #rfc3986
      requests-mock
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
      argparse
      pbr
      six
      netaddr
      modpacks.stevedore
      modpacks.oslo-i18n
      modpacks.debtcollector

      rfc3986
      wrapt
    ];
    buildInputs = [
      mock
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
      pbr
      Babel
      six
      #oslo-config
    ];
    buildInputs = [
      mock
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
      pbr
      Babel
      six
      wrapt
      funcsigs
    ];

    buildInputs = [
      testtools
      testscenarios
      testrepository
      subunit
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
      pbr
      six
      argparse
    ];

    buildInputs = [
      oslosphinx
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
      pbr
      Babel
      six
      iso8601
      pytz
      netaddr
      netifaces
      modpacks.monotonic
      modpacks.oslo-i18n
      wrapt
      modpacks.debtcollector

      pyparsing
      funcsigs
    ];
    buildInputs = [
      modpacks.oslotest
      mock
      coverage
      oslosphinx

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
      pbr
      Babel
      six
      iso8601
      pytz
      modpacks.oslo-utils
      msgpack
      netaddr
    ];
    buildInputs = [
      modpacks.oslotest
      mock
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
      pbr
      fixtures
      subunit
      six
      testrepository
      testscenarios
      testtools
      mock
      mox3
      #modpacks.oslo-config
      modpacks.os-client-config
    ];
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
      pbr
      testtools
      testscenarios
      testrepository
      fixtures
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
      argparse
      iso8601
      requests2
      six
      modpacks.stevedore
      modpacks.webob
      #modpacks.oslo-config

      lxml
      modpacks.positional
      pyyaml
      betamax
      pbr
      oauthlib
      modpacks.requests-kerberos
    ];
    buildInputs = [
      testtools
      testresources
      testrepository
      mock
      pep8
      fixtures
      mox3
      requests-mock

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
      requests2
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
      pbr
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
      pbr
      modpacks.oslo-serialization
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-utils
      Babel
      argparse
      prettytable
      requests2
      six
      iso8601
      modpacks.stevedore
      netaddr
      modpacks.debtcollector
      modpacks.bandit
      modpacks.webob
      mock
      pycrypto
      modpacks.positional

      rfc3986
      modpacks.keystoneauth1
    ];
    buildInputs = [
      testtools
      testresources
      testrepository
      requests-mock
      fixtures
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
      pbr
      Babel
      modpacks.oslo-config
      modpacks.oslo-context
      modpacks.oslo-i18n
      modpacks.oslo-serialization
      modpacks.oslo-utils
      requests2
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
      fixtures
      mock
      pycrypto
      oslosphinx
      modpacks.oslotest
      modpacks.stevedore
      testrepository
      testresources
      testtools
      modpacks.bandit
      requests-mock
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
      oslosphinx
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
     argparse
     six
     wrapt
     modpacks.oslo-utils
     pbr
     enum34
     Babel
     netaddr
     modpacks.monotonic
     iso8601
     modpacks.oslo-config
     pytz
     netifaces
     modpacks.stevedore
     modpacks.debtcollector
     retrying
     modpacks.fasteners
     modpacks.eventlet

     oslosphinx
     fixtures
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
      pbr
      Babel
      modpacks.debtcollector
      modpacks.positional
    ];
    buildInputs = [
      modpacks.oslotest
      coverage
      oslosphinx
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
      pbr
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
      mock
      mox3
      subunit
      testtools
      testscenarios
      testrepository
      fixtures
      oslosphinx

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
      sqlalchemy
      modpacks.oslo-utils
      modpacks.oslo-context
      modpacks.oslo-config
      modpacks.oslo-i18n
      iso8601
      Babel
      modpacks.alembic
      pbr
      psycopg2

      rfc3986
    ];
    buildInputs = [
      modpacks.tempest-lib
      testresources
      mock
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
      pbr
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
      oslosphinx

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
      pbr
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
      testtools
      oslosphinx
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
      argparse
      modpacks.oslo-utils
      pbr
      enum34
      netaddr
      modpacks.stevedore
      netifaces
      pyinotify
      modpacks.webob
      retrying
      pyinotify

      modpacks.fasteners
      pythonHasOsloConcMod
    ];
    buildInputs = [
      oslosphinx
      modpacks.oslotest
      pkgs.procps
      mock
      mox3
      fixtures
      subunit
      testrepository
      testtools
      testscenarios
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
      pbr
      Babel
      testrepository
      subunit
      testtools
    ];
    buildInputs = [
      coverage
      oslosphinx
      modpacks.oslotest
      testscenarios
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
    buildInputs = pkgs.lib.optionals isPy27 [ mock unittest2 nose redis qpid-python pymongo sqlalchemy pyyaml msgpack modpacks.boto ];

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

    buildInputs = [ mock coverage nose-cover3 unittest2 ];

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
       pbr
       six
       modpacks.monotonic
       futures
       modpacks.eventlet
     ];
     buildInputs = [
       testtools
       testscenarios
       testrepository
       modpacks.oslotest
       subunit
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
      argparse
      six
      wrapt
      modpacks.oslo-utils
      pbr
      modpacks.oslo-config
      Babel
      netaddr
      modpacks.monotonic
      iso8601
      pytz
      modpacks.stevedore
      modpacks.oslo-serialization
      msgpack
      modpacks.debtcollector
      netifaces
    ];
    buildInputs = [
      oslosphinx
      testtools
      testrepository
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
      testtools
      testrepository
      subunit
      modpacks.oslotest

      rfc3986
    ];
    propagatedBuildInputs = [
      pbr
      six
      paramiko
      httplib2
      jsonschema
      iso8601
      fixtures
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
      testtools
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
      pbr
      six
      pyyaml
      appdirs
      modpacks.stevedore
    ];
    buildInputs = [
      beautifulsoup4
      oslosphinx
      testtools
      testscenarios
      testrepository
      fixtures
      mock
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
      pyopenssl
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

    # XXX: skipping two tests fails in python2.6
    doCheck = ! isPy26;

    buildInputs = pkgs.lib.optionals isPy26 [
      ordereddict
      unittest2
    ];

    propagatedBuildInputs = [
      nose
      modpacks.webob
      six
      beautifulsoup4
      waitress
      mock
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
      pbr
      argparse
      six
      modpacks.webob
      
      netaddr
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
      oslosphinx
      coverage
      mock
      subunit
      testrepository
      testtools

      rfc3986
    ];

    #nativeBuildInputs = [
    #  rfc3986
    #];

    patchPhase = ''
      sed -i 's@python@${python.interpreter}@' .testr.conf
    '';
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
      cryptography
      pycrypto
      pyopenssl
      ipaddress
      six
      cffi
      idna
      enum34
      pytz
      setuptools
      zope_interface
      dateutil
      requests2
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
      mock
      coverage
    ];
    propagatedBuildInputs = [
      Mako
      sqlalchemy
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
      funcsigs
      pbr
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
      mock
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
      fixtures
      xattr
      testtools
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
      argparse
      pyyaml
      pbr
      six
      cmd2
      modpacks.stevedore
      unicodecsv
      prettytable
      pyparsing
    ];
    buildInputs = [
      httplib2
      oslosphinx
      coverage
      mock
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
      mock
      
    ];

    doCheck = false;
  };

  sqlalchemy_migrate_func = sqlalchemy: buildPythonPackage rec {
    name = "sqlalchemy-migrate-0.10.0";

    src = fetchurl {
      url = "mirror://pypi/s/sqlalchemy-migrate/${name}.tar.gz";
      sha256 = "00z0lzjs4ksr9yr31zs26csyacjvavhpz6r74xaw1r89kk75qg7q";
    };

    buildInputs = [
      unittest2
      scripttest
      pytz
      pylint
      modpacks.tempest-lib
      mock
      testtools
    ];
    propagatedBuildInputs = [
      pbr
      tempita
      decorator
      sqlalchemy
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

  sqlalchemy_migrate = modpacks.sqlalchemy_migrate_func sqlalchemy;

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
      funcsigs
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
      argparse
      pyyaml
      pbr
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
      pbr
      six
      Babel
      modpacks.cliff
      modpacks.keystoneauth1
      modpacks.os-client-config
      modpacks.oslo-i18n
      modpacks.oslo-utils
      modpacks.stevedore
      simplejson
      funcsigs
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
      pbr
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
      requests2
      modpacks.keystoneclient
      prettytable
      Babel
      pbr
      argparse
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
      requests-mock
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
      pbr
      testtools
      testscenarios
      testrepository
      requests-mock
      fixtures
    ];
    propagatedBuildInputs = [
      Babel
      argparse
      prettytable
      requests2
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
      requests2
      modpacks.keystoneclient
      prettytable
      argparse
      pbr
      modpacks.keystoneauth1
      ddt
    ];
    buildInputs = [
      testrepository
      requests-mock
    ];
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
      pbr
      six
      simplejson
      modpacks.keystoneclient
      requests2
      modpacks.oslo-utils
      modpacks.oslo-serialization
      modpacks.oslo-i18n
      netaddr
      iso8601
      modpacks.cliff
      argparse
      modpacks.osc-lib
    ];
    buildInputs = [
      modpacks.tempest-lib
      mox3
      modpacks.oslotest
      requests-mock
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
      pbr
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
      cryptography
      lxml
      netifaces
      modpacks.oslo-i18n
      modpacks.oslo-serialization
      modpacks.oslo-utils
      pbr
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
      pbr
      modpacks.oslo-utils
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.oslo-context
      modpacks.oslo-config
      modpacks.oslo-policy
      modpacks.keystoneauth1
      cryptography
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
      requests2
      #pbr
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
      pbr
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
      requests2
      pbr
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
      pbr
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
      oslosphinx
      pymysql
      psycopg2
      modpacks.alembic
      redis
      modpacks.eventlet
      kazoo
      zake
      kombu
      testscenarios
      testtools
      mock
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
      pbr
      Babel
      six
      pytz
      prettytable
      modpacks.debtcollector

      funcsigs
    ];
    buildInputs = [
      testtools
      testscenarios
      testrepository
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
      sqlalchemy
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
      pbr
      six
      simplegeneric
      netaddr
      pytz
      modpacks.webob
    ];
    buildInputs = [
      modpacks.cornice
      nose
      modpacks.webtest
      modpacks.pecan
      transaction
      cherrypy
      sphinx
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
    ] ++ stdenv.lib.optional isPy26 unittest2;

    propagatedBuildInputs = [
      PasteDeploy
      repoze_lru
      repoze_sphinx_autointerface
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
     pbr
     requests2

     modpacks.castellan
   ];
   buildInputs = [
     testtools
     testscenarios
     testrepository
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
      pbr
      modpacks.oslo-versionedobjects
      modpacks.oslo-privsep
      modpacks.oslo-log
      modpacks.oslo-i18n
      modpacks.oslo-config
      #modpacks.oslo-concurrency
      netaddr
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
      pbr
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
      oslosphinx
      testrepository
      testtools
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
      pbr

      modpacks.oslo-config
      rfc3986
    ];
    buildInputs = [
      coverage
      greenlet
      modpacks.eventlet
      oslosphinx
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
      pbr
      modpacks.eventlet
    ];

    buildInputs = [
      mock
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
      funcsigs
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
      funcsigs
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
      fixtures
      mock

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
      oslosphinx
      testtools
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
      pbr
      modpacks.stevedore
      netaddr
      iso8601
      six
      modpacks.oslo-i18n
      modpacks.oslo-utils
      Babel
      pyyaml
      modpacks.eventlet
      requests2
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
      oslosphinx
      coverage
      testtools
      testscenarios
      testrepository
      mock
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
      pbr
      requests2
      mod-openstackclient
      modpacks.oslo-serialization
      modpacks.osc-lib
      modpacks.keystoneauth1
      jsonschema
      pyyaml

      requests-mock
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
      ipaddress
      certifi
      idna
      cryptography
      pyopenssl

      psutil_1
    ];
    
    buildInputs = [
      coverage
      tornado
      mock
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
      requests2
    ];
    buildInputs = [
      nosexcover
      mock
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
      requests2
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
      mock
    ];
    propagatedBuildInputs = [
      requests2
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
      sqlalchemy
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
      pbr

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
      requests2
      pbr
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
      pbr
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
      requests2
      modpacks.swiftclient
      pbr
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
      pbr
      requests2
      futures
      six
      modpacks.keystoneclient
    ];
    buildInputs = [
      testtools
      testrepository
      mock
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
      sqlalchemy
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
      sha256 = "0p4vz0wz63r94riaj1dsvhr3v6j0340qw6sbbmy0mn9myf4xrkbh";
    };

    propagatedBuildInputs = [
      pbr
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
      blockdiag
      sphinx_1_2
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
      seqdiag
      sphinx_1_2
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
      pbr
      modpacks.oslo-config
      modpacks.oslo-i18n
      modpacks.oslo-service
      modpacks.oslo-utils
      requests2
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
      pbr
      requests2
      six
    ];

    ## can't pass test
    doCheck = false;
  };
}
