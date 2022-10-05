class Libssh2Static < Formula
  desc "C library implementing the SSH2 protocol"
  homepage "https://www.libssh2.org/"
  url "https://github.com/libssh2/libssh2.git",
      revision: "6c59eea5a9ea77127ec0fa3d6815c8adc743dba3"
  version "1.10.1"
  license "BSD-3-Clause"
  revision 1

  livecheck do
    url "https://www.libssh2.org/download/"
    regex(/href=.*?libssh2[._-]v?(\d+(?:\.\d+)+)\./i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libssh2-static-1.10.1"
    sha256 cellar: :any,                 arm64_big_sur: "6eb820f4f9b826bbf048fd8d2ce43cd2a6429b3d1dd2f6ea3330c76465322e51"
    sha256 cellar: :any,                 monterey:      "40860f472dfcc2d6bf36db895bc31ab29c837da7ee78fe9b4479ee40d75670a9"
    sha256 cellar: :any,                 big_sur:       "8435566913758f3fbbac0e9bcbb661b04de4c0fb64203c9f7eea5af224a5ad35"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "4ec34528fcd35c090d8a344429d17d407c8be729f8c75ab459238570dce2ed72"
  end

  head do
    url "https://github.com/libssh2/libssh2.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "gcc@5" => [:build, :test]
  end

  uses_from_macos "zlib"

  def install
    args = %W[
      --disable-silent-rules
      --disable-examples-build
      --with-openssl
      --with-libz
      --with-libssl-prefix=#{Formula["openssl@3"].opt_prefix}
    ]

    args << "--with-pic" if OS.linux?

    system "autoreconf", "-fi"
    system "./configure", *std_configure_args, *args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <libssh2.h>

      int main(void)
      {
      libssh2_exit();
      return 0;
      }
    EOS

    system ENV.cc, "test.c", "-L#{lib}", "-lssh2", "-o", "test"
    system "./test"
  end
end
