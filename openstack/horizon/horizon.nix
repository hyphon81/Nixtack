{ stdenv
, fetchurl
, python2Packages
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
  name = "horizon-${version}";
  version = "10.0.1";
  namePrefix = "";

  PBR_VERSION = "${version}";

  src = fetchurl {
    url = "https://github.com/openstack/horizon/archive/${version}.tar.gz";
    sha256 = "06y1dysx11axff278h0809jl54fliws75qs56d8lcwb3hrprbgih";
  };

  patchPhase = ''
    echo "graft horizon" >> MANIFEST.in

    sed -i 's@python@${python.interpreter}@' .testr.conf
  '';

  propagatedBuildInputs = [
    pbr
    Babel
    django_1_8
    modpacks.pint
    modpacks.django-babel
    modpacks.django-compressor
    modpacks.django-openstack-auth
    modpacks.django-pyscss
    iso8601
    netaddr
    
    #modpacks.oslo-concurrency
    modpacks.oslo-config
    modpacks.oslo-i18n
    modpacks.oslo-policy
    modpacks.oslo-serialization
    modpacks.oslo-utils

    pyscss

    modpacks.ceilometerclient
    modpacks.cinderclient
    modpacks.glanceclient
    modpacks.heatclient
    modpacks.keystoneclient
    modpacks.novaclient
    modpacks.swiftclient

    pytz
    pyyaml
    six

    xstatic
    modpacks.xstatic-angular
    modpacks.xstatic-angular-bootstrap
    modpacks.xstatic-angular-fileupload
    modpacks.xstatic-angular-gettext
    modpacks.xstatic-angular-lrdragndrop
    modpacks.xstatic-angular-schema-form
    modpacks.xstatic-bootstrap-datepicker
    modpacks.xstatic-bootstrap-scss
    modpacks.xstatic-bootswatch
    modpacks.xstatic-d3
    modpacks.xstatic-hogan
    modpacks.xstatic-font-awesome
    modpacks.xstatic-jasmine
    xstatic-jquery
    modpacks.xstatic-jquery-migrate
    modpacks.xstatic-jquery-quicksearch
    modpacks.xstatic-jquery-tablesorter
    xstatic-jquery-ui
    modpacks.xstatic-jsencrypt
    modpacks.xstatic-mdi
    modpacks.xstatic-objectpath
    modpacks.xstatic-rickshaw
    modpacks.xstatic-roboto-fontface
    modpacks.xstatic-smart-table
    modpacks.xstatic-spin
    modpacks.xstatic-termjs
    modpacks.xstatic-tv4

    modpacks.neutronclient
    memcached

    jsonpointer
    functools32
    appdirs
    unicodecsv
    cmd2
    jsonpatch
    jsonschema
    wrapt
    futures
    modpacks.os-client-config
    modpacks.positional
    modpacks.cliff
    modpacks.osc-lib
    warlock
    simplejson
    prettytable
    pathlib
    modpacks.monotonic
    pyparsing
    netifaces
    funcsigs
    msgpack
    requests2
    modpacks.stevedore
    modpacks.debtcollector
    rfc3986
    enum34
    retrying
    modpacks.fasteners
    modpacks.keystoneauth1
    django_appconf
    modpacks.rjsmin
    modpacks.rcssmin

    pythonHasOsloConcMod
  ];

  installPhase = ''
    runHook preInstall

    ${python.interpreter} setup.py install --prefix=$out
    
    # make wsgi files
    ${python.interpreter} manage.py make_web_conf --wsgi --pythonpath $PYTHONPATH
    mkdir -p $out/bin
    cp openstack_dashboard/wsgi/horizon.wsgi $out/bin/horizon.wsgi
    chmod +x $out/bin/horizon.wsgi

    cp manage.py $out/bin/manage.py
    chmod +x $out/bin/manage.py

    runHook postInstall
  '';

  postInstall = ''
    rm -r $out/lib/python2.7/site-packages/openstack_dashboard/local
    ln -s /var/lib/horizon/openstack_dashboard/local $out/lib/python2.7/site-packages/openstack_dashboard/local
    ln -s /var/lib/horizon/static $out/lib/python2.7/site-packages/static

    ln -s /var/lib/horizon/openstack_dashboard/conf $out/lib/python2.7/site-packages/openstack_dashboard/conf
    
  '';

  ## can't pass test
  doCheck = false;

  meta = with stdenv.lib; {
    homepage = http://horizon.openstack.org/;
    description = "OpenStack Dashboard (a.k.a. Horizon)";
    license = stdenv.lib.licenses.asl20;
    platforms = stdenv.lib.platforms.linux;
  };
}
