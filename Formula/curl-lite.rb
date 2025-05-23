class CurlLite < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.se"
  # Don't forget to update both instances of the version in the GitHub mirror URL.
  # `url` goes below this comment when the `stable` block is removed.
  url "https://curl.se/download/curl-8.13.0.tar.bz2"
  mirror "https://github.com/curl/curl/releases/download/curl-8_13_0/curl-8.13.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/curl-8.13.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/legacy/curl-8.13.0.tar.bz2"
  sha256 "e0d20499260760f9865cb6308928223f4e5128910310c025112f592a168e1473"
  license "curl"

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/curl-lite-8.11.1_1"
    sha256 arm64_ventura: "bdcdb2227a095a4004b3ed3de3d021e28c94de5a2bbcf4467cbdaf6d9695af05"
    sha256 arm64_big_sur: "f6e8cc4cd8d4addb94d440717fc45feac8146b4e4c1ca0d96c491a36921f1f40"
    sha256 ventura:       "c82d4126f07931ffdfe59e9be76d28ca65ab7865a34697fc94f349597d3ae35a"
    sha256 big_sur:       "17403b0647fd32972f411e116d0ebda9f895670e7b64ff7371cc1ee656e69124"
  end

  head do
    url "https://github.com/curl/curl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  keg_only "it conflicts with `curl`"

  depends_on "autobrew/cran/pkgconf" => [:build, :test]
  depends_on "libnghttp2-static"
  depends_on "openssl-static"

  uses_from_macos "krb5"
  uses_from_macos "openldap"
  uses_from_macos "zlib"

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"
    tag_name = "curl-#{version.to_s.tr(".", "_")}"
    if build.stable? && stable.mirrors.grep(/github\.com/).first.exclude?(tag_name)
      odie "Tag name #{tag_name} is not found in the GitHub mirror URL! " \
           "Please make sure the URL is correct."
    end

    system "./buildconf" if build.head?

    # cf https://github.com/apple-oss-distributions/curl/blob/HEAD/config_mac/curl_config.h
    args = %W[
      --disable-silent-rules
      --with-ssl=#{Formula["openssl-static"].opt_prefix}
      --with-ca-bundle=/etc/ssl/cert.pem
      --without-ca-path
      --with-ca-fallback
      --with-secure-transport
      --with-default-ssl-backend=openssl
      --without-librtmp
      --without-libssh2
      --without-libpsl
      --without-libidn2
      --with-zsh-functions-dir=#{zsh_completion}
      --with-fish-functions-dir=#{fish_completion}
    ]

    args << if OS.mac?
      "--with-gssapi"
    else
      "--with-gssapi=#{Formula["krb5"].opt_prefix}"
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
    system bin/"curl", "--ca-native", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    # Check cases that requires ca-native
    system bin/"curl", "--ca-native", "-vOL", "https://www.transtats.bts.gov"
    system bin/"curl", "--ca-native", "-vOL", "https://health-products.canada.ca"

    # Check dependencies linked correctly
    curl_features = shell_output("#{bin}/curl-config --features").split("\n")
    %w[GSS-API HTTP2 libz SSL].each do |feature|
      assert_includes curl_features, feature
    end

    with_env(PKG_CONFIG_PATH: lib/"pkgconfig") do
      system "pkgconf", "--cflags", "libcurl"
    end
  end
end
