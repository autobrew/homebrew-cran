class MariadbConnectorCStatic < Formula
  desc "MariaDB database connector for C applications"
  homepage "https://downloads.mariadb.org/connector-c/"
  url "https://downloads.mariadb.org/f/connector-c-3.1.11/mariadb-connector-c-3.1.11-src.tar.gz"
  mirror "https://fossies.org/linux/misc/mariadb-connector-c-3.1.11-src.tar.gz"
  sha256 "3e6f6c399493fe90efdc21a3fe70c30434b7480e8195642a959f1dd7a0fa5b0f"
  license "LGPL-2.1-or-later"
  head "https://github.com/mariadb-corporation/mariadb-connector-c.git"

  livecheck do
    url "https://downloads.mariadb.org/connector-c/+releases/"
    regex(%r{href=.*?connector-c/v?(\d+(?:\.\d+)+)/?["' >]}i)
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
    args << "-DCLIENT_PLUGIN_CLIENT_ED25519=STATIC"
    args << "-DCLIENT_PLUGIN_CACHING_SHA2_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_SHA256_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_MYSQL_CLEAR_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_MYSQL_OLD_PASSWORD=STATIC"
    args << "-DCLIENT_PLUGIN_REMOTE_IO=OFF"
    args << "-DWITH_OPENSSL=On"
    args << "-DWITH_EXTERNAL_ZLIB=On"
    args << "-DOPENSSL_INCLUDE_DIR=#{Formula["openssl@1.1"].opt_include}"
    args << "-DCOMPILATION_COMMENT=Homebrew"

    ENV["CFLAGS"] = "-DMYSQL_CLIENT=1" #hack to fix static plugin build

    system "cmake", ".", *args
    system "make", "install"
  end

  test do
    system "#{bin}/mariadb_config", "--cflags"
  end
end
