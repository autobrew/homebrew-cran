class MariadbConnectorCStatic < Formula
  desc "MariaDB database connector for C applications"
  homepage "https://mariadb.org/download/?tab=connector&prod=connector-c"
  url "https://archive.mariadb.org/connector-c-3.4.1/mariadb-connector-c-3.4.1-src.tar.gz"
  mirror "https://fossies.org/linux/misc/mariadb-connector-c-3.4.1-src.tar.gz/"
  sha256 "0a7f2522a44a7369c1dda89676e43485037596a7b1534898448175178aedeb4d"
  license "LGPL-2.1-or-later"
  head "https://github.com/mariadb-corporation/mariadb-connector-c.git", branch: "3.3"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/mariadb-connector-c-static-3.3.4"
    sha256 arm64_big_sur: "7c71bafe46b53fcf25f91f87e8574b8c9be20711ff28a6ce3ed1754314fd18a9"
    sha256 monterey:      "04a0a7042ea1ca69513ea17b6f76f5cf2b586cd35101324c2514be8f90763c6d"
    sha256 big_sur:       "ac1110311eb477f744f9d8bc77f5d3e5601f0181f0cdd16b2cdabbd97d0da38c"
  end

  depends_on "cmake" => :build
  depends_on "openssl@3"

  uses_from_macos "curl"
  uses_from_macos "zlib"

  conflicts_with "mariadb", because: "both install `mariadb_config`"

  def install
    args = std_cmake_args
    args << "-DWITH_MYSQLCOMPAT=OFF"
    args << "-DCLIENT_PLUGIN_AUTH_GSSAPI_CLIENT=STATIC"
    args << "-DCLIENT_PLUGIN_DIALOG=STATIC"
    args << "-DCLIENT_PLUGIN_PVIO_NPIPE=STATIC"
    args << "-DCLIENT_PLUGIN_PVIO_SHMEM=STATIC"
    args << "-DCLIENT_PLUGIN_CLIENT_ED25519=STATIC"
    args << "-DCLIENT_PLUGIN_CACHING_SHA2_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_SHA256_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_MYSQL_CLEAR_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_MYSQL_OLD_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_REMOTE_IO=OFF"
    args << "-DWITH_SSL=OPENSSL"
    args << "-DWITH_EXTERNAL_ZLIB=On"
    args << "-DOPENSSL_INCLUDE_DIR=#{Formula["openssl@3"].opt_include}"
    args << "-DINSTALL_MANDIR=#{share}"
    args << "-DCOMPILATION_COMMENT=Homebrew"

    # Fixes static plugin build
    ENV["CFLAGS"] = "-DMYSQL_CLIENT=1"

    system "cmake", ".", *args
    system "make", "install"
  end

  test do
    system "#{bin}/mariadb_config", "--cflags"
  end
end
