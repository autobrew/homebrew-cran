class MariadbConnectorCStatic < Formula
  desc "MariaDB database connector for C applications"
  homepage "https://mariadb.org/download/?tab=connector&prod=connector-c"
  url "https://downloads.mariadb.com/Connectors/c/connector-c-3.3.4/mariadb-connector-c-3.3.4-src.tar.gz"
  mirror "https://fossies.org/linux/misc/mariadb-connector-c-3.3.4-src.tar.gz/"
  sha256 "486e5fdf976a8e7fadf583ae912128655e013ac575fa79b2d1af0fb8827a78ed"
  license "LGPL-2.1-or-later"
  head "https://github.com/mariadb-corporation/mariadb-connector-c.git", branch: "3.3"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/mariadb-connector-c-static-3.1.11"
    sha256 arm64_big_sur: "62842fe5c03658fddbf050aba71b95fa7f43401c91d20e94292e28a9fb22bab0"
    sha256 big_sur:       "1ea703722e4835ffe1eba3957c50ca12ddd601670d038af50f84c2b2cff2131f"
    sha256 catalina:      "ec1a9f9bab66c33e964fe44cecfe9593d1f27f0ff177d77ca8104149a3397025"
  end

  depends_on "cmake" => :build
  depends_on "openssl@1.1"

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
    args << "-DWITH_OPENSSL=On"
    args << "-DWITH_EXTERNAL_ZLIB=On"
    args << "-DOPENSSL_INCLUDE_DIR=#{Formula["openssl@1.1"].opt_include}"
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
