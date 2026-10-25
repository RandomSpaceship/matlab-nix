# The Debian package names in MathWorks' dependency lists, and the nixpkgs
# attributes for them, for scripts/update-deps.py. A value is an attribute path
# (in a string), a list of them, or null for a package that is left out (with
# the reason in a comment). The script stops at a name that is not here.
{
  # Base system
  "ca-certificates" = "cacert";
  "debianutils" = "debianutils";
  "locales" = "glibcLocales";
  "locales-all" = "glibcLocales";
  "make" = "gnumake";
  "net-tools" = "net-tools";
  "procps" = "procps";
  "unzip" = "unzip";
  "wget" = "wget";
  # A setuid program does not work in the bubblewrap environment.
  "sudo" = null;

  "libc6" = "glibc";
  # libgomp1 and libatomic1 come with gcc's runtime libraries.
  "libatomic1" = "stdenv.cc.cc.lib";
  "libgomp1" = "stdenv.cc.cc.lib";
  "libbz2-1.0" = "bzip2";
  "libcap2" = "libcap";
  "libcap-ng0" = "libcap_ng";
  # libcrypt.so.1 is in libxcrypt-legacy (libxcrypt has libcrypt.so.2).
  "libcrypt1" = [
    "libxcrypt"
    "libxcrypt-legacy"
  ];
  "libltdl7" = "libtool";
  "liblzma5" = "xz";
  "libmd0" = "libmd";
  "libnettle8t64" = "nettle";
  "libpam0g" = "pam";
  "libpcre2-8-0" = "pcre2";
  "libtirpc3t64" = "libtirpc";
  "libudev1" = "udev";
  "libuuid1" = "libuuid";
  "zlib1g" = "zlib";

  # MATLAB bundles its own Boost.
  "libboost-atomic1.74.0" = null;
  "libboost-chrono1.74.0t64" = null;
  "libboost-date-time1.74.0" = null;
  "libboost-filesystem1.74.0" = null;
  "libboost-log1.74.0" = null;
  "libboost-program-options1.74.0" = null;
  "libboost-regex1.74.0" = null;
  "libboost-system1.74.0" = null;
  "libboost-thread1.74.0" = null;

  # Desktop and graphics
  "libasound2t64" = "alsa-lib";
  "libatk1.0-0t64" = "at-spi2-core";
  "libatk-bridge2.0-0t64" = "at-spi2-core";
  "libatspi2.0-0t64" = "at-spi2-core";
  "libcairo2" = "cairo";
  "libcairo-gobject2" = "cairo";
  "libcups2t64" = "cups";
  "libdrm2" = "libdrm";
  "libegl1" = "libGL";
  "libfontconfig1" = "fontconfig";
  "libfribidi0" = "fribidi";
  "libgbm1" = "libgbm";
  "libgdk-pixbuf-2.0-0" = "gdk-pixbuf";
  "libgl1" = "libGL";
  "libglib2.0-0t64" = "glib";
  "libglx0" = "libGL";
  "libgstreamer1.0-0" = "gst_all_1.gstreamer";
  "libgstreamer-plugins-base1.0-0" = "gst_all_1.gst-plugins-base";
  "libgtk-3-0t64" = "gtk3";
  "libnspr4" = "nspr";
  "libnss3" = "nss";
  "libopengl0" = "libGL";
  "libpango-1.0-0" = "pango";
  "libpangocairo-1.0-0" = "pango";
  "libpangoft2-1.0-0" = "pango";
  "libpixman-1-0" = "pixman";
  "libsndfile1" = "libsndfile";
  "libwayland-client0" = "wayland";
  "x11-xkb-utils" = "xkbcomp";
  "xkb-data" = "xkeyboard-config";

  "libice6" = "libice";
  "libxcb-glx0" = "libxcb";
  "libxcb-xinput0" = "libxcb";
  "libxcomposite1" = "libxcomposite";
  "libxcursor1" = "libxcursor";
  "libxdamage1" = "libxdamage";
  "libxfixes3" = "libxfixes";
  "libxfont2" = "libxfont_2";
  "libxft2" = "libxft";
  "libxinerama1" = "libxinerama";
  "libxrandr2" = "libxrandr";
  "libxt6t64" = "libxt";
  "libxtst6" = "libxtst";
  "libxxf86vm1" = "libxxf86vm";

  # Parallel Computing Toolbox
  "ibverbs-providers" = "rdma-core";
  "libibverbs1" = "rdma-core";
  "librdmacm1t64" = "rdma-core";
  "libnuma1" = "numactl";
  "libpsm2-2" = "libpsm2";
  "libucx0" = "ucx";

  # Database Toolbox (ODBC)
  "libodbc2" = "unixodbc";
  "libodbcinst2" = "unixodbc";

  # Hardware support packages
  "libhidapi-libusb0" = "hidapi";
  "libmosquitto1" = "mosquitto";
  "libmosquittopp1" = "mosquitto";
  # COVESA DLT (automotive logging) is not in nixpkgs. The R2026b desktop
  # starts without it.
  "libdlt2" = null;
  # The list names libuhd.so.4.6.0 exactly, and nixpkgs has a later UHD with a
  # different soname.
  "libuhd4.6.0-dpdk" = null;
}
