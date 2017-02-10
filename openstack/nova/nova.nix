{ stdenv
, fetchurl
, python
, python2Packages
, makeWrapper
, openssl
, openssh
#, spice
#, spice-protocol
, callPackage }:

with python2Packages;

let
  modpacks = callPackage ../python-packages.nix {};
  pythonHasOsloConcMod = python.buildEnv.override {
    extraLibs = [
      modpacks.oslo-concurrency
    ];
  };
  OVMF = callPackage ../../ovmf/OVMF.nix {};
in

buildPythonApplication rec {
  name = "nova-${version}";
  version = "14.0.3";
  namePrefix = "";

  PBR_VERSION = "${version}";

  src = fetchurl {
    url = "https://github.com/openstack/nova/archive/${version}.tar.gz";
    sha256 = "06q3mghiai3lwhikyj4a0kkyyza9rcq66c08arn2adrpaq9wl984";
  };
  patches = [
    ./for_gpu_passthrough.patch
    ./for_undefine_xml_with_nvram.patch
  ];
  
  # otherwise migrate.cfg is not installed
  postPatch = ''
    echo "graft nova" >> MANIFEST.in

    # remove transient error test, see http://hydra.nixos.org/build/40203534
    rm nova/tests/unit/compute/test_{shelve,compute_utils}.py

    # change OVMF path
    substituteInPlace nova/virt/libvirt/driver.py --replace "/usr/share/OVMF/OVMF_CODE.fd" "${OVMF}/FV/OVMF.fd"
  '';

  # https://github.com/openstack/nova/blob/stable/liberty/requirements.txt
  propagatedBuildInputs = [
    pbr
    sqlalchemy
    modpacks.boto
    decorator
    modpacks.eventlet
    jinja2
    lxml
    modpacks.routes
    cryptography
    modpacks.webob
    greenlet
    PasteDeploy
    paste
    prettytable
    modpacks.sqlalchemy_migrate
    netaddr
    netifaces
    paramiko
    Babel
    iso8601
    jsonschema
    modpacks.cinderclient
    modpacks.keystoneauth1
    modpacks.neutronclient
    modpacks.glanceclient
    modpacks.keystoneclient
    requests2
    six
    modpacks.stevedore
    modpacks.websockify
    rfc3986
    modpacks.os-brick
    modpacks.os-vif
    modpacks.os-win
    modpacks.castellan
    modpacks.microversion-parse
    modpacks.wsgi-intercept
    psutil_1
    modpacks.alembic
    psycopg2
    pymysql
    modpacks.keystonemiddleware
    MySQL_python

    # oslo components
    modpacks.oslo-cache
    #modpacks.oslo-concurrency
    modpacks.oslo-config
    modpacks.oslo-context
    modpacks.oslo-log
    modpacks.oslo-reports
    modpacks.oslo-serialization
    modpacks.oslo-utils
    modpacks.oslo-db
    modpacks.oslo-rootwrap
    modpacks.oslo-messaging
    modpacks.oslo-policy
    modpacks.oslo-privsep
    modpacks.oslo-i18n
    modpacks.oslo-service
    modpacks.oslo-versionedobjects
    modpacks.oslo-middleware 

    libvirt
    memcached
    pythonHasOsloConcMod
    #spice
    #spice-protocol
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
    modpacks.oslo-vmware
    pep8
    modpacks.barbicanclient
    modpacks.ironicclient
    openssl
    openssh
    
  ];

  ## can't pass test
  doCheck = false;

  postInstall = ''
    cp -prvd etc $out/etc

    # check all binaries don't crash
    for i in $out/bin/*; do
      sed -e "1 s%^#\!.*$%#\!${pythonHasOsloConcMod}/bin/${python.libPrefix}%g" $i > _tmp
      rm $i
      mv _tmp $i
      chmod +x $i

      case "$i" in
      *nova-dhcpbridge*)
         :
         ;;
      *nova-rootwrap*)
         :
         ;;
      *)
         $i --help
         ;;
      esac
    done
  '';

  meta = with stdenv.lib; {
    homepage = http://nova.openstack.org/;
    description = "OpenStack Compute (a.k.a. Nova), a cloud computing fabric controller";
    license = stdenv.lib.licenses.asl20;
    platforms = stdenv.lib.platforms.linux;
  };
}
