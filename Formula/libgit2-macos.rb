class Libgit2Macos < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.org/"
  url "https://github.com/libgit2/libgit2/archive/refs/tags/v1.9.7.tar.gz"
  sha256 "1a4fbe7589e814777ae76b64734ad80f4ecad22cd33a22682a2aaea4ae5375e7"
  license "GPL-2.0-only" => { with: "GCC-exception-2.0" }
  head "https://github.com/libgit2/libgit2.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  keg_only "it conflicts with `libgit2-static`"

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "libressl3"

  uses_from_macos "zlib"

  # Bundle a static libssh2 built against libressl3, because the core libssh2
  # links to openssl@3. We use libssh2 master which has the recent CVE fixes.
  resource "libssh2" do
    url "https://github.com/libssh2/libssh2.git",
        revision: "18aebe08962c1878d84c373ad85caff25ec67771"
  end

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"
    libressl = formula_opt_prefix("libressl3")

    resource("libssh2").stage do
      # libssh2 requires LibreSSL >= 3.7 but works with 3.3 (as shipped by MacOS)
      # if we disable ed25519 and alias the GCM ctrl that was renamed in 1.1.
      inreplace "src/openssl.h" do |s|
        s.gsub! "#  if LIBRESSL_VERSION_NUMBER < 0x3070000fL\n#    error \"LibreSSL 3.7.0 or greater required\"",
                "#ifndef EVP_CTRL_AEAD_SET_IV_FIXED\n#define EVP_CTRL_AEAD_SET_IV_FIXED EVP_CTRL_GCM_SET_IV_FIXED"
        s.gsub! "#ifdef LIBSSH2_WOLFSSL\n# define LIBSSH2_ED25519 0",
                "#if defined(LIBSSH2_WOLFSSL) || defined(LIBRESSL_VERSION_NUMBER)\n# define LIBSSH2_ED25519 0"
      end

      args = %W[
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_STATIC_LIBS=ON
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTING=OFF
        -DCRYPTO_BACKEND=OpenSSL
        -DOPENSSL_ROOT_DIR=#{libressl}
        -DENABLE_ZLIB_COMPRESSION=ON
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
      ]
      system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    ENV.prepend_path "PKG_CONFIG_PATH", lib/"pkgconfig"
    args = %W[
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_CLI=OFF
      -DUSE_SSH=libssh2
      -DUSE_HTTPS=OpenSSL
      -DUSE_SHA256=CommonCrypto
      -DOPENSSL_ROOT_DIR=#{libressl}
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <git2.h>
      #include <assert.h>
      #include <string.h>

      int main(int argc, char *argv[]) {
        int options = git_libgit2_features();
        assert(options & GIT_FEATURE_SSH);
        assert(options & GIT_FEATURE_HTTPS);
        assert(strcmp(git_libgit2_feature_backend(GIT_FEATURE_HTTPS), "openssl") == 0);
        assert(strcmp(git_libgit2_feature_backend(GIT_FEATURE_SSH), "libssh2") == 0);
        return 0;
      }
    EOS
    libressl = Formula["libressl3"]
    flags = %W[
      -I#{include}
      -L#{lib}
      -L#{libressl.opt_lib}
      -lgit2
      -lssh2
      -lssl
      -lcrypto
      -lz
      -liconv
      -framework CoreFoundation
      -framework Security
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
