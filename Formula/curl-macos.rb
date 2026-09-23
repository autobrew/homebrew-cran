class CurlMacos < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.se"
  # Rock-solid LTS releases have no release tarball, so we build from the git tag.
  url "https://github.com/curl/curl/archive/refs/tags/rocksolid-8.14.2.tar.gz"
  sha256 "9d525ca5517586133ff656124a83e577a4dc4d269be3b087e50d82f97cdd2f68"
  license "curl"
  head "https://github.com/curl/curl.git", branch: "master"

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/curl-macos-8.14.1"
    sha256 cellar: :any, arm64_ventura: "c0b1fe1241d48183e5fcec041d01d611fbbd3039d66afaf0fa71a102c0b61d88"
    sha256 cellar: :any, arm64_big_sur: "e390ac521ade65c46ac9660cf29fbfbedbbdc731448a2731ccfb8db23af32b52"
    sha256 cellar: :any, ventura:       "6f45e93ba4cedc64d605f874d75ddb67d3792bf41f9b0745e847d7a80dbdf20a"
    sha256 cellar: :any, big_sur:       "351ffdcd968e1ab89dcff02c549f80f7ee4f3df64f94af42dc71a2607beab1bf"
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
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = testpath/"test.tar.gz"
    system bin/"curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

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
