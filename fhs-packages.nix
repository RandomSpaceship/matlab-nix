# Libraries and tools in MATLAB's FHS environment, for `buildFHSEnv`'s
# `targetPkgs`. Follows MathWorks' own dependency list for R2026b on Ubuntu
# 24.04 (matlab-deps/r2026b/ubuntu24.04/base-dependencies-amd64.txt in
# https://github.com/mathworks-ref-arch/container-images), with the Debian names
# in comments where they differ. MATLAB bundles its own Boost, so the
# libboost-* entries there are left out.
pkgs:

with pkgs; [
  # Base system
  bashInteractive
  cacert # ca-certificates
  coreutils
  debianutils
  glibc
  glibcLocales # locales, locales-all
  gnumake # make
  net-tools
  procps
  unzip
  wget
  which

  # libc6, libgomp1, libatomic1 and a newer libstdc++ than MATLAB's own
  stdenv.cc.cc.lib
  # mex compiles with the system gcc
  gcc

  bzip2
  libcap
  libcap_ng
  libxcrypt # libcrypt1
  libxcrypt-legacy
  libtirpc
  libuuid
  pam
  pcre2
  xz # liblzma5
  zlib
  udev

  # Desktop and graphics
  alsa-lib
  at-spi2-core # libatk*, libatspi
  cups
  dbus
  fontconfig
  freetype
  fribidi
  glib
  gst_all_1.gst-plugins-base
  gst_all_1.gstreamer
  gtk3
  libdrm
  libgbm
  libGL # libgl1, libegl1, libglx0, libopengl0
  libglvnd
  libsndfile
  libxkbcommon
  nspr
  nss
  pango
  pixman
  xkbcomp # x11-xkb-utils
  xkeyboard-config # xkb-data

  libice
  libsm
  libx11
  libxcb # incl. libxcb-glx, libxcb-xinput
  libxcomposite
  libxcursor
  libxdamage
  libxext
  libxfixes
  libxfont_2
  libxft
  libxi
  libxinerama
  libxrandr
  libxrender
  libxt
  libxtst
  libxxf86vm

  # Parallel Computing (ibverbs, rdmacm, ucx, numa, psm2) and hardware
  # support packages (hidapi, mosquitto)
  hidapi
  libpsm2
  mosquitto
  numactl
  rdma-core
  ucx
]
