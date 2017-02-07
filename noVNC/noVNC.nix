{ stdenv, fetchurl, python27Packages }:

let
  #websockifySrc = fetchurl {
  #  url = "https://github.com/novnc/websockify/archive/v0.8.0.tar.gz";
  #  sha256 = "0cf4ar97ijfc7mg35zdgpad6x8ivkdx9qii6mz35khi1ps9g5bz7";
  #};
in

stdenv.mkDerivation rec {
  name = "novnc-${version}";
  version = "0.6.2";

  src = fetchurl {
    url = "https://github.com/novnc/noVNC/archive/v${version}.tar.gz";
    sha256 = "16ygbdzdmnfg9a26d9il4a6fr16qmq0ix9imfbpzl0drfbj7z8kh";
  };

  propagatedBuildInputs = [
    python27Packages.websockify
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp utils/launch.sh $out/bin/launch-novnc.sh
    chmod +x $out/bin/launch-novnc.sh
    mkdir -p $out/images
    cp -r images/* $out/images/
    mkdir -p $out/include
    cp -r include/* $out/include/
    cp favicon.ico $out
    cp vnc.html $out
    cp vnc_auto.html $out
  '';

  meta = with stdenv.lib; {
    homepage = http://novnc.com/info.html;
    repositories.git = git://github.com/novnc/noVNC.git;
    description = ''
      A HTML5 VNC Client
    '';
    license = licenses.mpl20;
  };
}
