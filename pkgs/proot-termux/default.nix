# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv, fetchFromGitHub, talloc, outputBinaryName ? "proot-static" }:

stdenv.mkDerivation {
  pname = "proot-termux";
  version = "unstable-2021-11-21";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "7d6bdd9f6cf31144e11ce65648dab2a1e495a7de";
    sha256 = "sha256-sbueMoqhOw0eChgp6KOZbhwRnSmDZhHq+jm06mGqxC4=";
  };

  # ashmem.h is rather small, our needs are even smaller, so just define these:
  preConfigure = ''
    mkdir -p fake-ashmem/linux; cat > fake-ashmem/linux/ashmem.h << EOF
    #include <linux/limits.h>
    #include <linux/ioctl.h>
    #define __ASHMEMIOC 0x77
    #define ASHMEM_NAME_LEN 256
    #define ASHMEM_SET_NAME _IOW(__ASHMEMIOC, 1, char[ASHMEM_NAME_LEN])
    #define ASHMEM_SET_SIZE _IOW(__ASHMEMIOC, 3, size_t)
    EOF
  '';

  buildInputs = [ talloc ];
  patches = [ ./detranslate-empty.patch ];
  makeFlags = [ "-Csrc" "V=1" ];
  CFLAGS = [ "-O3" "-static" "-I../fake-ashmem" ];
  LDFLAGS = [ "-static" ];
  preInstall = "${stdenv.cc.targetPrefix}strip src/proot";
  installPhase = "install -D -m 0755 src/proot $out/bin/${outputBinaryName}";
}
