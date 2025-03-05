class LibpqStatic < Formula
  desc "Postgres C API library"
  homepage "https://www.postgresql.org/docs/current/libpq.html"
  url "https://ftp.postgresql.org/pub/source/v16.8/postgresql-16.8.tar.bz2"
  sha256 "55f7d9e99b8e2d4e0e193b2f0275501e6d9c1ebd29cadbea6a0da48a8587e3e0"
  license "PostgreSQL"

  livecheck do
    url "https://ftp.postgresql.org/pub/source/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libpq-static-16.2"
    sha256 arm64_ventura: "b008702b6e85424db465be445e4af9508521306f51a7e052882f09becd1f8651"
    sha256 arm64_big_sur: "7f7ad93fd07844ee7335a72eccd44ccfbac1566a5659b68148d046cffa77a90d"
    sha256 ventura:       "7443b643809f59acd703c546ad574564e83a443ef86832e23cadbf43bbebb52d"
    sha256 monterey:      "9e6cd22cb7a62c9e040a23d90a9b9af7b2c953f3572f75cb3b9ccd8292a04d81"
    sha256 big_sur:       "4f2a439d6ff5ea46c4125025f67397ee7ff1999e9dc1ba93642a6195a883bb18"
  end

  keg_only "conflicts with postgres formula"

  depends_on "pkg-config" => :build
  # GSSAPI provided by Kerberos.framework crashes when forked.
  # See https://github.com/Homebrew/homebrew-core/issues/47494.
  depends_on "krb5"
  depends_on "openssl@3"

  uses_from_macos "zlib"

  on_linux do
    depends_on "readline"
  end

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--with-gssapi",
                          "--with-openssl",
                          "--libdir=#{opt_lib}",
                          "--includedir=#{opt_include}"
                          "--without-icu"
    dirs = %W[
      libdir=#{lib}
      includedir=#{include}
      pkgincludedir=#{include}/postgresql
      includedir_server=#{include}/postgresql/server
      includedir_internal=#{include}/postgresql/internal
    ]
    system "make"
    system "make", "-C", "src/bin", "install", *dirs
    system "make", "-C", "src/include", "install", *dirs
    system "make", "-C", "src/interfaces", "install", *dirs
    system "make", "-C", "src/common", "install", *dirs
    system "make", "-C", "src/port", "install", *dirs
    system "make", "-C", "doc", "install", *dirs
  end

  test do
    (testpath/"libpq.c").write <<~EOS
      #include <stdlib.h>
      #include <stdio.h>
      #include <libpq-fe.h>

      int main()
      {
          const char *conninfo;
          PGconn     *conn;

          conninfo = "dbname = postgres";

          conn = PQconnectdb(conninfo);

          if (PQstatus(conn) != CONNECTION_OK) // This should always fail
          {
              printf("Connection to database attempted and failed");
              PQfinish(conn);
              exit(0);
          }

          return 0;
        }
    EOS
    system ENV.cc, "libpq.c", "-L#{lib}", "-I#{include}", "-lpq", "-o", "libpqtest"
    assert_equal "Connection to database attempted and failed", shell_output("./libpqtest")
  end
end
