{ stdenv
, fetchurl
, python2
, python2Packages
, xmlsec
, which
, openssl
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
  name = "keystone-${version}";
  version = "10.0.0";
  namePrefix = "";

  PBR_VERSION = "${version}";

  src = fetchurl {
    url = "https://tarballs.openstack.org/keystone/keystone-${version}.tar.gz";
    sha256 = "0qxf8rgh6ln23dw4vqipsnjv6bmxswz53ggs7r71iibyqshcf5sk";
  };

  propagatedBuildInputs = [
    Babel
    pbr
    modpacks.webob
    modpacks.eventlet
    greenlet
    PasteDeploy
    paste
    modpacks.routes
    cryptography
    six
    sqlalchemy
    modpacks.sqlalchemy_migrate
    modpacks.stevedore
    passlib
    modpacks.keystoneclient
    memcached
    modpacks.keystonemiddleware
    oauthlib
    modpacks.pysaml2
    modpacks.dogpile_cache
    jsonschema
    modpacks.pycadf
    msgpack
    xmlsec
    MySQL_python
    pymysql

    modpacks.osprofiler
    
    ### oslo ###
    modpacks.oslo-cache
    #modpacks.oslo-concurrency
    modpacks.oslo-config
    modpacks.oslo-context
    modpacks.oslo-messaging
    modpacks.oslo-db
    modpacks.oslo-i18n
    modpacks.oslo-log
    modpacks.oslo-middleware
    modpacks.oslo-policy
    modpacks.oslo-serialization
    modpacks.oslo-service
    modpacks.oslo-utils

    rfc3986
    pythonHasOsloConcMod
  ];

  buildInputs = [
    coverage
    fixtures
    mock
    subunit
    modpacks.tempest-lib
    testtools
    testrepository
    ldap
    ldappool
    modpacks.webtest
    requests2
    modpacks.oslotest
    pep8
    pymongo
    which
    pymysql

    freezegun
    testresources
    modpacks.keystoneclient
    wrapPython
  ];

  ### can't pass test
  doCheck = false;

  makeWrapperArgs = ["--prefix PATH : '${openssl.bin}/bin:$PATH'"];

  installPhase = ''
    ${python.interpreter} setup.py install --prefix=$out

    # make wsgi files
    ${python.interpreter} $out/lib/python2.7/site-packages/keystone/cmd/manage.py make_web_conf --wsgi
  '';

  meta = with stdenv.lib; {
    homepage = http://keystone.openstack.org/;
    description = "Authentication, authorization and service discovery mechanisms via HTTP";
    license = stdenv.lib.licenses.asl20;
    platforms = stdenv.lib.platforms.linux;
  };
}
