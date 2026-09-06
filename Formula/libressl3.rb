class Libressl3 < Formula
  desc "Version of the SSL/TLS protocol forked from OpenSSL"
  homepage "https://www.libressl.org/"
  # Please ensure when updating version the release is from stable branch.
  url "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.3.5.tar.gz"
  mirror "https://mirrorservice.org/pub/OpenBSD/LibreSSL/libressl-3.3.5.tar.gz"
  sha256 "0a51393f0df1cf27e070054a2788a4d073339f363d79cd594076a1b4c48be9a5"
  license "OpenSSL"

  livecheck do
    url :homepage
    regex(/latest stable release is (\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libressl3-3.3.5"
    sha256 arm64_ventura: "bccbff07e6f36747adfa5554e7a4cb86b9c3bab8c02fe381bc6a87e50ea8a36d"
    sha256 arm64_big_sur: "89c9d3f5f3b724c063ef60bbde6a37daedf32018fa552fa4f1477094cd490950"
    sha256 ventura:       "9c085da6b919badfabdf10c3f7749ebf577af2af663888b2a9925c70b845a61d"
    sha256 big_sur:       "7792c1b0995384fe8212dd1898694ff7ceb6d5e6fb9b74394f417e76cf930481"
  end

  head do
    url "https://github.com/libressl/portable.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  keg_only "is in macos"

  depends_on "ca-certificates"

  on_linux do
    keg_only "it conflicts with OpenSSL formula"
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --with-openssldir=#{etc}/libressl
      --sysconfdir=#{etc}/libressl
    ]

    system "./autogen.sh" if build.head?
    system "./configure", *args
    system "make"
    # system "make", "check"
    system "make", "install"
  end

  post_install_steps do
    symlink "{{etc}}/ca-certificates/cert.pem", "{{etc}}/libressl/cert.pem", overwrite: true
  end

  def caveats
    <<~EOS
      A CA file has been bootstrapped using certificates from the SystemRoots
      keychain. To add additional certificates (e.g. the certificates added in
      the System keychain), place .pem files in
        #{etc}/libressl/certs

      and run
        #{opt_bin}/openssl certhash #{etc}/libressl/certs

      This certificate bundle is a symlink to the `ca-certificates` formula's
      certificate bundle, which is also generated from the SystemRoots keychain
      but merged with the Mozilla-curated CA bundle.
    EOS
  end

  test do
    # Make sure the necessary .cnf file exists, otherwise LibreSSL gets moody.
    assert_path_exists HOMEBREW_PREFIX/"etc/libressl/openssl.cnf",
"LibreSSL requires the .cnf file for some functionality"

    # Check LibreSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system "#{bin}/openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end
