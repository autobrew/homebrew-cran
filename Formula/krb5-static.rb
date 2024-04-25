class Krb5Static < Formula
  desc "Network authentication protocol"
  homepage "https://web.mit.edu/kerberos/"
  url "https://kerberos.org/dist/krb5/1.21/krb5-1.21.2.tar.gz"
  sha256 "9560941a9d843c0243a71b17a7ac6fe31c7cebb5bce3983db79e52ae7e850491"
  license :cannot_represent

  livecheck do
    url :homepage
    regex(/Current release: .*?>krb5[._-]v?(\d+(?:\.\d+)+)</i)
  end

  depends_on "pkgconfig" => :build
  depends_on "openssl@3"

  uses_from_macos "bison" => :build
  uses_from_macos "libedit"

  def install
    # https://mailman.mit.edu/pipermail/krbdev/2024-January/013652.html
    ENV["LDFLAGS"] = "-framework Kerberos"
    cd "src" do
      system "./configure", *std_configure_args,
                            "--enable-static",
                            "--disable-shared",
                            "--disable-nls",
                            "--disable-silent-rules",
                            "--without-system-verto",
                            "--without-keyutils"
      system "make", "||", "true"
      system "make", "install"
    end
  end

  test do
    system "#{bin}/krb5-config", "--version"
    assert_match include.to_s,
      shell_output("#{bin}/krb5-config --cflags")
  end
end
