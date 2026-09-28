class CurlMacos < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.se"
  url "https://github.com/autobrew/libcurl.git",
      revision: "f2ba0d0b1bf03644d680e1d5c451b6ba39d6ecc7"
  version "8.14.2"
  license "curl"
  revision 1
  head "https://github.com/curl/curl.git", branch: "master"

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/curl-macos-8.14.2"
    sha256 cellar: :any, arm64_sonoma: "3ceabd468dbf29f68600f65c0c8a01999c2256f43fb17f4d5b277229b3602f6f"
    sha256 cellar: :any, sonoma:       "fc1c5cc27fc79c40b7101a18c6847bfe296b0acff380ad02b6288f4049c11e21"
  end

  keg_only "it conflicts with `curl`"

  # autotools needed because the git sources have no pre-generated configure script
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "libnghttp2-static"
  depends_on "libressl3"

  uses_from_macos "krb5"
  uses_from_macos "openldap"
  uses_from_macos "zlib"

  # Fix for MacOS-12
  patch do
    url "https://github.com/curl/curl/commit/360099340d5a3086ca87c4d344ef40d317efc45c.patch?full_index=1"
    sha256 "73970e167a59675c3e1ce6c127153fc863869761937a25097f5ee08322e204be"
  end

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"
    system "autoreconf", "--force", "--install"

    # cf https://github.com/apple-oss-distributions/curl/blob/HEAD/config_mac/curl_config.h
    args = %W[
      --disable-silent-rules
      --with-ssl=#{formula_opt_prefix("libressl3")}
      --with-nghttp2=#{formula_opt_prefix("libnghttp2-static")}
      --with-ca-bundle=/etc/ssl/cert.pem
      --without-ca-path
      --without-ca-fallback
      --with-secure-transport
      --with-default-ssl-backend=openssl
      --without-librtmp
      --without-libssh2
      --without-libpsl
      --without-libidn2
      --enable-threaded-resolver
      --disable-unit-tests
      --with-gssapi
      --with-zsh-functions-dir=#{zsh_completion}
      --with-fish-functions-dir=#{fish_completion}
    ]

    args << if OS.mac?
      "--with-gssapi"
    else
      "--with-gssapi=#{formula_opt_prefix("krb5")}"
    end

    args += if OS.mac? && MacOS.version >= :ventura
      %w[
        --with-apple-idn
      ]
    else
      %w[
        --without-apple-idn
      ]
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"
    system "make", "install", "-C", "scripts"
    libexec.install "scripts/mk-ca-bundle.pl"
  end

  test do
    # Fetch a file from the pinned source revision over HTTPS.
    # This requires a network connection, but so does Homebrew in general.
    filename = testpath/"sectransp.c"
    revision = stable.specs[:revision]
    url = "https://raw.githubusercontent.com/autobrew/libcurl/#{revision}/lib/vtls/sectransp.c"
    system bin/"curl", "-L", url, "-o", filename
    assert_match "Secure Transport", filename.read

    # Check dependencies linked correctly
    curl_features = shell_output("#{bin}/curl-config --features").split("\n")
    %w[GSS-API HTTP2 libz SSL].each do |feature|
      assert_includes curl_features, feature
    end

    # system libexec/"mk-ca-bundle.pl", "test.pem"
    # assert_path_exists testpath/"test.pem"
    # assert_path_exists testpath/"certdata.txt"

    # with_env(PKG_CONFIG_PATH: lib/"pkgconfig") do
    #  system "pkgconf", "--cflags", "libcurl"
    # end
  end
end
