{ stdenv
, fetchurl
, python
, python2Packages
, ipmitool
, ipmiutil
, callPackage }:

with python2Packages;

let
  modpacks = callPackage ../python-packages.nix {};
  pythonHasOsloConcMod = python.buildEnv.override {
    extraLibs = [
      modpacks.oslo-concurrency
    ];
  };
  qemu_25 = callPackage ../../qemu/qemu_25.nix {
    inherit (darwin.apple_sdk.frameworks) CoreServices Cocoa;
    inherit (darwin.stubs) rez setfile;
  };
in

buildPythonApplication rec {
  name = "ironic-${version}";
  version = "6.2.2";
  namePrefix = "";

  PBR_VERSION = "${version}";

  src = fetchurl {
    url = "https://github.com/openstack/ironic/archive/${version}.tar.gz";
    sha256 = "03mwkwky2z43a45d3j9y88nb21drxz118zfl9z1mbra6i5yialnj";
  };

  # otherwise migrate.cfg is not installed
  postPatch = ''
    echo "graft ironic" >> MANIFEST.in
  '';

  propagatedBuildInputs = [
    pbr
    sqlalchemy
    modpacks.alembic
    modpacks.automaton
    modpacks.eventlet
    modpacks.webob
    greenlet
    netaddr
    paramiko
    modpacks.neutronclient
    modpacks.glanceclient
    modpacks.keystoneauth1
    modpacks.ironic-lib
    modpacks.swiftclient
    pytz
    modpacks.stevedore
    pysendfile
    modpacks.pecan
    requests2
    six
    jsonpatch
    modpacks.WSME
    jinja2
    modpacks.keystonemiddleware
    retrying
    jsonschema
    psutil_1
    modpacks.futurist
    
    # oslo components
    #modpacks.oslo-concurrency
    modpacks.oslo-config
    modpacks.oslo-context
    modpacks.oslo-db
    modpacks.oslo-rootwrap
    modpacks.oslo-i18n
    modpacks.oslo-log
    modpacks.oslo-middleware
    modpacks.oslo-policy
    modpacks.oslo-serialization
    modpacks.oslo-service
    modpacks.oslo-utils
    modpacks.oslo-messaging
    modpacks.oslo-versionedobjects

    pythonHasOsloConcMod
    pymysql

    ipmitool
    ipmiutil
    qemu_25
  ];

  buildInputs = [
    coverage
    fixtures
    mock
    mox3
    subunit
    requests-mock
    pillow
    oslosphinx
    modpacks.oslotest
    testrepository
    testresources
    testtools
    modpacks.tempest-lib
    modpacks.bandit
    pep8
    modpacks.barbicanclient
    modpacks.ironicclient

  ];

  ## can't pass test
  doCheck = false;

  preInstall = ''
    mkdir -p $out/bin
    # set wsgi file
    cp ironic/api/app.wsgi $out/bin/ironic-app.wsgi
    chmod +x $out/bin/ironic-app.wsgi
    sed -i '1 s%^%#\!${pythonHasOsloConcMod}/bin/${python.libPrefix}\n%' $out/bin/ironic-app.wsgi
  '';

  postInstall = ''
    cp -prvd etc $out/etc

    # check all binaries don't crash
    for i in $out/bin/*; do
      sed -i "1 s%^#\!.*$%#\!${pythonHasOsloConcMod}/bin/${python.libPrefix}%g" $i
      chmod +x $i

      case "$i" in
      *ironic-rootwrap*|*ironic-app.wsgi*)
         :
         ;;
      *)
         $i --help
         ;;
      esac
    done
  '';

  meta = with stdenv.lib; {
    description = "OpenStack Bare Metal service (a.k.a. Ironic)";
    license = stdenv.lib.licenses.asl20;
    platforms = stdenv.lib.platforms.linux;
  };
}
