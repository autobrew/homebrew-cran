class Libnghttp2Static < Formula
  desc "HTTP/2 C Library"
  homepage "https://nghttp2.org/"
  url "https://github.com/nghttp2/nghttp2/releases/download/v1.64.0/nghttp2-1.64.0.tar.gz"
  mirror "http://fresh-center.net/linux/www/nghttp2-1.64.0.tar.gz"
  # this legacy mirror is for user to install from the source when https not working for them
  # see discussions in here, https://github.com/Homebrew/homebrew-core/pull/133078#discussion_r1221941917
  sha256 "20e73f3cf9db3f05988996ac8b3a99ed529f4565ca91a49eb0550498e10621e8"
  license "MIT"

  livecheck do
    formula "nghttp2"
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libnghttp2-static-1.64.0"
    sha256 cellar: :any, arm64_ventura: "07d11b0786641150528a78d28299aba3afa72c8dd7b676044143917d54d476b5"
    sha256 cellar: :any, arm64_big_sur: "e80423c15b8db847b62a0ee06d18c4d5e44eadbd13eb0bfee2ee8f495986aa14"
    sha256 cellar: :any, ventura:       "ae033518e37a0bdd710a357febcd590ef85f7c8155f65ed44883099b9f6cc384"
    sha256 cellar: :any, big_sur:       "ed0eed067538804eeb8e23be780fa30c0ac3eacef657fff3ca619e110593e2be"
  end

  head do
    url "https://github.com/nghttp2/nghttp2.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "autobrew/cran/pkgconf" => :build

  # These used to live in `nghttp2`.
  link_overwrite "include/nghttp2"
  link_overwrite "lib/libnghttp2.a"
  link_overwrite "lib/libnghttp2.dylib"
  link_overwrite "lib/libnghttp2.14.dylib"
  link_overwrite "lib/libnghttp2.so"
  link_overwrite "lib/libnghttp2.so.14"
  link_overwrite "lib/pkgconfig/libnghttp2.pc"

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--enable-lib-only", *std_configure_args
    system "make", "-C", "lib"
    system "make", "-C", "lib", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <nghttp2/nghttp2.h>
      #include <stdio.h>

      int main() {
        nghttp2_info *info = nghttp2_version(0);
        printf("%s", info->version_str);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lnghttp2", "-o", "test"
    assert_equal version.to_s, shell_output("./test")
  end
end
