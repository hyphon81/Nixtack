#with import <nixpkgs> {};
{ stdenv, nasm, iasl, openssl, callPackage, fetchurl }:

let
  targetArch = if stdenv.isi686 then
    "Ia32"
  else if stdenv.isx86_64 then
    "X64"
  else
    throw "Unsupported architecture";

  edk2 = callPackage ./edk2.nix {};

  seabios = false;
  secureBoot = true;

  opensslSrc = fetchurl {
    url = "https://www.openssl.org/source/openssl-1.0.2j.tar.gz";
    sha256 = "0cf4ar97ijfc7mg35zdgpad6x8ivkdx9qii6mz35khi1ps9g5bz7";
  };
in

stdenv.mkDerivation (edk2.setup "OvmfPkg/OvmfPkg${targetArch}.dsc" {
  name = "OVMF-2016-12-16";

  # TODO: properly include openssl for secureBoot
  buildInputs = [nasm iasl] ++ stdenv.lib.optionals (secureBoot == true) [ openssl ];

  hardeningDisable = [ "stackprotector" "pic" "fortify" ];

  unpackPhase = ''
    for file in \
      "${edk2.src}"/{UefiCpuPkg,MdeModulePkg,IntelFrameworkModulePkg,PcAtChipsetPkg,FatPkg,FatBinPkg,EdkShellBinPkg,MdePkg,ShellPkg,OptionRomPkg,IntelFrameworkPkg};
    do
      ln -sv "$file" .
    done

    ${if (seabios == false) then ''
        ln -sv ${edk2.src}/OvmfPkg .
      '' else ''
        cp -r ${edk2.src}/OvmfPkg .
        chmod +w OvmfPkg/Csm/Csm16
        cp ${seabios}/Csm16.bin OvmfPkg/Csm/Csm16/Csm16.bin
      ''}

    ${if (secureBoot == true) then ''
        ln -sv ${edk2.src}/SecurityPkg .
        cp -r ${edk2.src}/CryptoPkg .
        chmod +w -R ./CryptoPkg 
        cp ${opensslSrc} ./CryptoPkg/Library/OpensslLib/openssl-1.0.2j.tar.gz
        cd ./CryptoPkg/Library/OpensslLib
        tar xvf ./openssl-1.0.2j.tar.gz
        cd ./openssl-1.0.2j
        patch -p1 -i ../EDKII_openssl-1.0.2j.patch
        cd ..
        ./Install.sh
        cd ../../../
      '' else ''
      ''}
    '';

  buildPhase = if (seabios == false) then ''
      build ${if secureBoot then "-DSECURE_BOOT_ENABLE=TRUE" else ""}
    '' else ''
      build -D CSM_ENABLE -D FD_SIZE_2MB ${if secureBoot then "-DSECURE_BOOT_ENABLE=TRUE" else ""}
    '';

  meta = {
    description = "Sample UEFI firmware for QEMU and KVM";
    homepage = http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=OVMF;
    license = stdenv.lib.licenses.bsd2;
    platforms = ["x86_64-linux" "i686-linux"];
  };
})
