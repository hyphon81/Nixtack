{ stdenv, fetchurl, python2, python2Packages, xmlsec, which, openssl, callPackage }:

with python2Packages;

let
  modpacks = callPackage ./python-packages.nix {};
in

buildPythonPackage rec {
  name = "openstackclient-${version}";
  version = "3.2.1";

  PBR_VERSION = "${version}";

  src = fetchurl {
    url = "https://github.com/openstack/python-openstackclient/archive/${version}.tar.gz";
    sha256 = "04sk43lkm3wsz41jnlhyjx2qvv9c3z6n9n55rk5vrsc6x9mb7fpf";
  };

  propagatedBuildInputs = [
    pbr
    six
    Babel
    modpacks.cliff
    modpacks.os-client-config
    modpacks.oslo-config
    modpacks.oslo-i18n
    modpacks.oslo-utils
    modpacks.glanceclient
    modpacks.keystoneclient
    modpacks.novaclient
    modpacks.cinderclient
    modpacks.neutronclient
    requests2
    modpacks.stevedore
    modpacks.cliff-tablib
    modpacks.osc-lib
    modpacks.openstacksdk
  ];
  buildInputs = [
    requests-mock
  ];

  ## can't pass test
  doCheck = false;
  
  patchPhase = ''
    sed -i 's@python@${python.interpreter}@' .testr.conf
  '';

  meta = with stdenv.lib; {
    homepage = "http://wiki.openstack.org/OpenStackClient";
  };
}
