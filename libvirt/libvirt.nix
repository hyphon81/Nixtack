{ stdenv, fetchurl, fetchpatch
, pkgconfig, makeWrapper
, libxml2, gnutls, devicemapper, perl, python2
, iproute, iptables, readline, lvm2, utillinux, systemd, libpciaccess, gettext
, libtasn1, ebtables, libgcrypt, yajl, pmutils, libcap_ng
, dnsmasq, libnl, libpcap, libxslt, xhtml1, numad, numactl, perlPackages
, curl, libiconv, gmp, xen, zfs
, callPackage
}:
# if you update, also bump pythonPackages.libvirt or it will break

let
  OVMF = callPackage ../ovmf/OVMF.nix {};
in

stdenv.mkDerivation rec {
  name = "libvirt-${version}";
  version = "2.5.0";

  src = fetchurl {
    url = "http://libvirt.org/sources/${name}.tar.xz";
    sha256 = "07nbh6zhaxx5i1s1acnppf8rzkzb2ppgv35jw7grbbnnpzpzz7c1";
  };

  nativeBuildInputs = [ makeWrapper pkgconfig ];
  buildInputs = [
    libxml2 gnutls perl python2 readline
    gettext libtasn1 libgcrypt yajl
    libxslt xhtml1 perlPackages.XMLXPath curl libpcap
    OVMF
  ] ++ stdenv.lib.optionals stdenv.isLinux [
    libpciaccess devicemapper lvm2 utillinux systemd libcap_ng
    libnl numad numactl xen zfs
  ] ++ stdenv.lib.optionals stdenv.isDarwin [
     libiconv gmp
  ];

  preConfigure = stdenv.lib.optionalString stdenv.isLinux ''
    PATH=${stdenv.lib.makeBinPath [ iproute iptables ebtables lvm2 systemd ]}:$PATH
    substituteInPlace configure \
      --replace 'as_dummy="/bin:/usr/bin:/usr/sbin"' 'as_dummy="${numad}/bin"'
  '' + ''
    PATH=${dnsmasq}/bin:$PATH
    patchShebangs . # fixes /usr/bin/python references
  '';

  configureFlags = [
    "--localstatedir=/var"
    "--sysconfdir=/var/lib"
    "--with-libpcap"
    "--with-vmware"
    "--with-vbox"
    "--with-test"
    "--with-esx"
    "--with-remote"
    "--with-loader-nvram=${OVMF}/FV/OVMF.fd:${OVMF}/FV/OVMF_VARS.fd"
  ] ++ stdenv.lib.optionals stdenv.isLinux [
    "--with-numad"
    "--with-macvtap"
    "--with-virtualport"
    "--with-init-script=redhat"
    "--with-storage-zfs"
  ] ++ stdenv.lib.optionals stdenv.isDarwin [
    "--with-init-script=none"
  ];

  installFlags = [
    "localstatedir=$(TMPDIR)/var"
    "sysconfdir=$(out)/var/lib"
  ];

  postInstall = ''
    sed -i 's/ON_SHUTDOWN=suspend/ON_SHUTDOWN=''${ON_SHUTDOWN:-suspend}/' $out/libexec/libvirt-guests.sh
    substituteInPlace $out/libexec/libvirt-guests.sh \
      --replace "$out/bin" "${gettext}/bin"
    cat <<NVRAM > $out/var/lib/libvirt/qemu.conf
    nvram = [
      "${OVMF}/FV/OVMF.fd:${OVMF}/FV/OVMF_VARS.fd"
    ]
    NVRAM
    cat <<LIBVIRTD > $out/var/lib/libvirt/libvirtd.conf
    unix_sock_group = "libvirtd"
    unix_sock_rw_perms = "0770"
    auth_unix_ro = "none"
    auth_unix_rw = "none"
    LIBVIRTD
  '' + stdenv.lib.optionalString stdenv.isLinux ''
    wrapProgram $out/sbin/libvirtd \
      --prefix PATH : ${stdenv.lib.makeBinPath [ iptables iproute pmutils numad numactl ]}
  '';

  enableParallelBuilding = true;

  NIX_CFLAGS_COMPILE = "-fno-stack-protector";

  meta = with stdenv.lib; {
    homepage = http://libvirt.org/;
    repositories.git = git://libvirt.org/libvirt.git;
    description = ''
      A toolkit to interact with the virtualization capabilities of recent
      versions of Linux (and other OSes)
    '';
    license = licenses.lgpl2Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ fpletz ];
  };
}
