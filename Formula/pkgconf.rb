class Pkgconf < Formula
  desc "Package compiler and linker metadata toolkit"
  homepage "https://github.com/pkgconf/pkgconf"
  url "https://distfiles.ariadne.space/pkgconf/pkgconf-2.3.0.tar.xz"
  mirror "http://distfiles.ariadne.space/pkgconf/pkgconf-2.3.0.tar.xz"
  sha256 "3a9080ac51d03615e7c1910a0a2a8df08424892b5f13b0628a204d3fcce0ea8b"
  license "ISC"

  livecheck do
    url "https://distfiles.ariadne.space/pkgconf/"
    regex(/href=.*?pkgconf[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/pkgconf-2.3.0"
    sha256 arm64_ventura: "4bf8f1de9bf9f6601a888a2a2a86a2ac92f95d5dd81d19e590a37ee94a643207"
    sha256 arm64_big_sur: "e384b5334e9274448863eca322b6742ceadbcae5ad9f85e073d91f9c61b474dd"
    sha256 ventura:       "9b47ff11a69a57e3847dae1c75a14dcb663adf9903f2422f5a14f97a773bb11a"
    sha256 big_sur:       "06153b154662c2c658783dc6d8673a48abcd91df6e72c3c1989298ef8163cd1d"
  end

  head do
    url "https://github.com/pkgconf/pkgconf.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  # FIXME: The bottle is mistakenly considered relocatable on Linux.
  # See https://github.com/Homebrew/homebrew-core/pull/85032.
  pour_bottle? only_if: :default_prefix

  def install
    if build.head?
      ENV["LIBTOOLIZE"] = "glibtoolize"
      system "./autogen.sh"
    end

    pc_path = %W[
      #{HOMEBREW_PREFIX}/lib/pkgconfig
      #{HOMEBREW_PREFIX}/share/pkgconfig
    ]
    pc_path += if OS.mac?
      %W[
        /usr/local/lib/pkgconfig
        /usr/lib/pkgconfig
        #{HOMEBREW_LIBRARY}/Homebrew/os/mac/pkgconfig/#{MacOS.version}
      ]
    else
      ["#{HOMEBREW_LIBRARY}/Homebrew/os/linux/pkgconfig"]
    end

    args = %W[
      --disable-silent-rules
      --with-pkg-config-dir=#{pc_path.uniq.join(File::PATH_SEPARATOR)}
      --with-system-includedir=#{MacOS.sdk_path_if_needed if OS.mac?}/usr/include
      --with-system-libdir=/usr/lib
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"

    # Make `pkgconf` a drop-in replacement for `pkg-config` by adding symlink[^1].
    # Similar to Debian[^2], Fedora, ArchLinux and MacPorts.
    #
    # [^1]: https://github.com/pkgconf/pkgconf/#pkg-config-symlink
    # [^2]: https://salsa.debian.org/debian/pkgconf/-/blob/debian/unstable/debian/pkgconf.links?ref_type=heads
    bin.install_symlink "pkgconf" => "pkg-config"
    man1.install_symlink "pkgconf.1" => "pkg-config.1"
  end

  test do
    (testpath/"foo.pc").write <<~PC
      prefix=/usr
      exec_prefix=${prefix}
      includedir=${prefix}/include
      libdir=${exec_prefix}/lib

      Name: foo
      Description: The foo library
      Version: 1.0.0
      Cflags: -I${includedir}/foo
      Libs: -L${libdir} -lfoo
    PC

    ENV["PKG_CONFIG_LIBDIR"] = testpath
    system bin/"pkgconf", "--validate", "foo"
    assert_equal "1.0.0", shell_output("#{bin}/pkgconf --modversion foo").strip
    assert_equal "-lfoo", shell_output("#{bin}/pkgconf --libs-only-l foo").strip
    assert_equal "-I/usr/include/foo", shell_output("#{bin}/pkgconf --cflags foo").strip

    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <libpkgconf/libpkgconf.h>

      int main(void) {
        assert(pkgconf_compare_version(LIBPKGCONF_VERSION_STR, LIBPKGCONF_VERSION_STR) == 0);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}/pkgconf", "-L#{lib}", "-lpkgconf"
    system "./a.out"

    # Make sure system-libdir is removed as it can cause problems in superenv
    if OS.mac?
      ENV.delete "PKG_CONFIG_LIBDIR"
      refute_match "-L/usr/lib", shell_output("#{bin}/pkgconf --libs libcurl")
    end
  end
end
