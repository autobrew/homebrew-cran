class OpensslStatic < Formula
  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl-library.org"
  url "https://github.com/openssl/openssl/releases/download/openssl-3.5.8/openssl-3.5.8.tar.gz"
  mirror "http://fresh-center.net/linux/misc/openssl-3.5.8.tar.gz"
  sha256 "a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://openssl-library.org/source/"
    # Stick to the 3.5.x LTS series
    regex(/href=.*?openssl[._-]v?(3\.5(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/openssl-static-3.5.8"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "ab641c964bfc8fcea9c4e78bd58b6854a010648a5b6dc70d6a68e4d654906c41"
    sha256 cellar: :any_skip_relocation, sonoma:       "513a877192a43ac232c021264f3bd4993538afbb2d5035fb7825327a575350d7"
  end

  # Linking this keg into the prefix conflicts file-by-file with the linked
  # openssl@3 (pulled in by core formulae such as libssh2), which sends brew's
  # link conflict resolution into an hours-long spin when both are installed.
  # Dependents find this keg through superenv instead, which also guarantees
  # they compile against these headers rather than the linked openssl@3 ones.
  keg_only "it conflicts with openssl@3"

  on_linux do
    depends_on "ca-certificates"

    resource "Test::Harness" do
      url "https://cpan.metacpan.org/authors/id/L/LE/LEONT/Test-Harness-3.50.tar.gz"
      mirror "http://cpan.metacpan.org/authors/id/L/LE/LEONT/Test-Harness-3.50.tar.gz"
      sha256 "79b6acdc444f1924cd4c2e9ed868bdc6e09580021aca8ff078ede2ffef8a6f54"
    end

    resource "Test::More" do
      url "https://cpan.metacpan.org/authors/id/E/EX/EXODIST/Test-Simple-1.302201.tar.gz"
      mirror "http://cpan.metacpan.org/authors/id/E/EX/EXODIST/Test-Simple-1.302201.tar.gz"
      sha256 "956185dc96c1f2942f310a549a2b206cc5dd1487558f4e36d87af7a8aacbc87c"
    end

    resource "ExtUtils::MakeMaker" do
      url "https://cpan.metacpan.org/authors/id/B/BI/BINGOS/ExtUtils-MakeMaker-7.70.tar.gz"
      mirror "http://cpan.metacpan.org/authors/id/B/BI/BINGOS/ExtUtils-MakeMaker-7.70.tar.gz"
      sha256 "f108bd46420d2f00d242825f865b0f68851084924924f92261d684c49e3e7a74"
    end
  end

  # SSLv2 died with 1.1.0, so no-ssl2 no longer required.
  # SSLv3 & zlib are off by default with 1.1.0 but this may not
  # be obvious to everyone, so explicitly state it for now to
  # help debug inevitable breakage.
  def configure_args
    args = %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      --libdir=lib
      no-shared
      no-module
      no-ssl3
      no-ssl3-method
      no-zlib
    ]
    on_linux do
      args += (ENV.cflags || "").split
      args += (ENV.cppflags || "").split
      args += (ENV.ldflags || "").split
    end
    args
  end

  def install
    if OS.linux?
      ENV.prepend_create_path "PERL5LIB", buildpath/"lib/perl5"
      ENV.prepend_path "PATH", buildpath/"bin"

      %w[ExtUtils::MakeMaker Test::Harness Test::More].each do |r|
        resource(r).stage do
          system "perl", "Makefile.PL", "INSTALL_BASE=#{buildpath}"
          system "make", "PERL5LIB=#{ENV["PERL5LIB"]}", "CC=#{ENV.cc}"
          system "make", "install"
        end
      end
    end

    # This could interfere with how we expect OpenSSL to build.
    ENV.delete("OPENSSL_LOCAL_CONFIG_DIR")
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

    # This ensures where Homebrew's Perl is needed the Cellar path isn't
    # hardcoded into OpenSSL's scripts, causing them to break every Perl update.
    # Whilst our env points to opt_bin, by default OpenSSL resolves the symlink.
    ENV["PERL"] = formula_opt_bin("perl")/"perl" if which("perl") == formula_opt_bin("perl")/"perl"

    arch_args = []
    if OS.mac?
      arch_args += %W[darwin64-#{Hardware::CPU.arch}-cc enable-ec_nistp_64_gcc_128]
    elsif Hardware::CPU.intel?
      arch_args << (Hardware::CPU.is_64_bit? ? "linux-x86_64" : "linux-elf")
    elsif Hardware::CPU.arm?
      arch_args << (Hardware::CPU.is_64_bit? ? "linux-aarch64" : "linux-armv4")
    end

    openssldir.mkpath if OS.linux?
    system "perl", "./Configure", *(configure_args + arch_args)
    system "make"
    if OS.mac?
      # Skip the install_ssldirs target: OPENSSLDIR is the OS-owned /private/etc/ssl
      system "make", "install_sw", "install_docs", "MANDIR=#{man}", "MANSUFFIX=ssl"
    else
      system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
    end
    # AF_ALG support isn't always enabled (e.g. some containers), which breaks the tests.
    # AF_ALG is a kernel feature and failures are unlikely to be issues with the formula.
    system "make", "test", "TESTS=-test_afalg"

    # Prevent `brew` from pruning the `certs` and `private` directories.
    touch %w[certs private].map { |subdir| openssldir/subdir/".keepme" } if OS.linux?
  end

  def openssldir
    # On macOS we point OPENSSLDIR to the CA bundle that ships with the OS,
    # such that certificate verification also works for (static) builds on
    # machines without Homebrew. This matches CRAN's openssl recipe.
    OS.mac? ? Pathname("/private/etc/ssl") : etc/"openssl@3"
  end

  if OS.linux?
    post_install_steps do
      symlink "{{etc}}/ca-certificates/cert.pem", "{{etc}}/openssl@3/cert.pem", overwrite: true
    end
  end

  def caveats
    if OS.mac?
      <<~EOS
        Certificates are verified against the CA bundle that ships with macOS
        at #{openssldir}/cert.pem. Set SSL_CERT_FILE or SSL_CERT_DIR to
        override this with a custom CA bundle.
      EOS
    else
      <<~EOS
        A CA file has been bootstrapped using certificates from the system
        keychain. To add additional certificates, place .pem files in
          #{openssldir}/certs

        and run
          #{opt_bin}/c_rehash
      EOS
    end
  end

  test do
    # Check OpenSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system bin/"openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end
