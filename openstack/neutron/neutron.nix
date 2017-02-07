{ stdenv
, fetchurl
, python2Packages
, xmlsec
, which
, dnsmasq
, openvswitch
, bridge-utils
, callPackage }:

with python2Packages;

let
  modpacks = callPackage ../python-packages.nix {};
  pythonHasOsloConcMod = python.buildEnv.override {
    extraLibs = [
      modpacks.oslo-concurrency
    ];
  };
in

buildPythonApplication rec {
  name = "neutron-${version}";
  version = "9.1.1";
  namePrefix = "";

  PBR_VERSION = "${version}";

  src = fetchurl {
    url = "https://github.com/openstack/neutron/archive/${version}.tar.gz";
    sha256 = "1dvadglb54lslqvyaayc2zablwjbisvi2ksya2hj45jqv257pphd";
  };

  # https://github.com/openstack/neutron/blob/stable/liberty/requirements.txt
  propagatedBuildInputs = [
    pbr
    paste
    PasteDeploy
    modpacks.routes
    modpacks.debtcollector
    modpacks.eventlet
    greenlet
    httplib2
    requests2
    jinja2
    modpacks.keystonemiddleware
    netaddr
    netifaces
    modpacks.neutron-lib
    retrying
    sqlalchemy
    modpacks.webob
    modpacks.keystoneauth1
    modpacks.alembic
    six
    modpacks.stevedore
    modpacks.pecan
    ryu
    #networking-hyperv
    MySQL_python

    pymysql
    memcached
    #bridge-utils

    # clients
    modpacks.keystoneclient
    modpacks.neutronclient
    modpacks.novaclient
    modpacks.designateclient

    # oslo components
    modpacks.oslo-cache
    #modpacks.oslo-concurrency
    modpacks.oslo-config
    modpacks.oslo-context
    modpacks.oslo-db
    modpacks.oslo-i18n
    modpacks.oslo-log
    modpacks.oslo-messaging
    modpacks.oslo-middleware
    modpacks.oslo-policy
    modpacks.oslo-reports
    modpacks.oslo-rootwrap
    modpacks.oslo-serialization
    modpacks.oslo-service
    modpacks.oslo-utils
    modpacks.oslo-versionedobjects
    modpacks.osprofiler
    openvswitch

    pythonHasOsloConcMod
    modpacks.networking-bgpvpn
  ];

  # make sure we include migrations
  prePatch = ''
    echo "graft neutron" >> MANIFEST.in
    substituteInPlace etc/neutron/rootwrap.d/dhcp.filters --replace "/sbin/dnsmasq" "${dnsmasq}/bin/dnsmasq"
  '';

  buildInputs = [
    modpacks.cliff
    coverage
    fixtures
    mock
    subunit
    requests-mock
    oslosphinx
    testrepository
    testtools
    testresources
    testscenarios
    modpacks.webtest
    modpacks.oslotest
    modpacks.os-testr
    modpacks.tempest-lib
    ddt
    pep8
  ];

  ## can't pass test
  doCheck = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/${python.libPrefix}/site-packages
    echo "import sys; sys.setdefaultencoding('utf-8')" > $out/lib/${python.libPrefix}/site-packages/sitecustomize.py

    export PYTHONPATH="$out/lib/${python.libPrefix}/site-packages:$PYTHONPATH"

    ${python.interpreter} setup.py install --prefix=$out \
      --install-lib=$out/lib/${python.libPrefix}/site-packages

    runHook postInstall
  '';
  ## it's failed
  postInstall = ''
    # check all binaries don't crash
    for i in $out/bin/*; do
      case "$i" in
      *neutron-pd-notify|*neutron-rootwrap-daemon|*neutron-rootwrap|\
        *neutron-debug|*neutron-hyperv-agent|*neutron-mlnx-agent|\
        *neutron-ovsvapp-agent|*neutron-restproxy-agent|\
        *neutron-rootwrap-xen-dom0)
        :
        ;;
      *)
         $i --help
      esac
    done
  '';

  meta = with stdenv.lib; {
    homepage = http://neutron.openstack.org/;
    description = "Virtual network service for Openstack";
    license = stdenv.lib.licenses.asl20;
    platforms = stdenv.lib.platforms.linux;
  };
}
