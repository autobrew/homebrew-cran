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

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libgit2-macos-1.9.7"
    sha256                               arm64_sonoma: "e7358f0ef1f475e5975f0510c951dccc8a825981ff7a32c758ac280ebc695d4e"
    sha256 cellar: :any_skip_relocation, sonoma:       "bd58693cdc7b8a85f979b911e7bf46bc8c347c9bb68cd79a45264d04b1827c71"
  end

  keg_only "it conflicts with `libgit2-static`"

  depends_on "cmake" => :build
  depends_on "libssh2" => :build
  depends_on "openssl@3" => :build
  depends_on "pkgconf" => :build
  depends_on "libressl3"

  uses_from_macos "zlib"

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

    # HTTPS in libgit2 uses libressl (which is also in MacOS), but libssh2 uses openssl@3.
    # To avoid symbol conflicts we prelink libssh2 with a private copy of openssl@3
    # into a single object that only exports the libssh2 API. The static libs get
    # custom names to make clear that they are not the regular libgit2 and libssh2.
    (buildpath/"libssh2_exports.txt").write "_libssh2_*\n"
    system ENV.cc, "-r", "-nostdlib", "-o", "libssh2_openssl.o",
           "-Wl,-exported_symbols_list,libssh2_exports.txt",
           "-Wl,-force_load,#{formula_opt_lib("libssh2")}/libssh2.a",
           "#{formula_opt_lib("openssl@3")}/libcrypto.a"
    lib.mkpath
    include.mkpath
    system "ar", "rcs", lib/"libssh2-openssl3.a", "libssh2_openssl.o"
    cp Dir["#{formula_opt_include("libssh2")}/libssh2*.h"], include
    (lib/"pkgconfig/libssh2.pc").write <<~EOS
      Name: libssh2
      Description: Library for SSH-based communication (with private openssl@3)
      Version: #{Formula["libssh2"].version}
      Libs: -L#{opt_lib} -lssh2-openssl3
      Libs.private: -lz
      Cflags: -I#{opt_include}
    EOS

    # Make sure libgit2 does not pick up openssl@3 headers or libs from superenv
    %w[HOMEBREW_INCLUDE_PATHS HOMEBREW_LIBRARY_PATHS].each do |var|
      ENV[var] = ENV[var].split(File::PATH_SEPARATOR).grep_v(/openssl@3/).join(File::PATH_SEPARATOR)
    end
    ENV.prepend_path "PKG_CONFIG_PATH", lib/"pkgconfig"
    args = %W[
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_CLI=OFF
      -DUSE_SSH=libssh2
      -DUSE_HTTPS=OpenSSL
      -DUSE_SHA256=CommonCrypto
      -DOPENSSL_ROOT_DIR=#{formula_opt_prefix("libressl3")}
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON
      -DCMAKE_REQUIRED_LIBRARIES=z
    ]
    # NB: CMAKE_REQUIRED_LIBRARIES is needed for libgit2 to detect libssh2 memory credentials
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    mv lib/"libgit2.a", lib/"libgit2-macos.a"
    inreplace lib/"pkgconfig/libgit2.pc", "-lgit2", "-lgit2-macos"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <git2.h>
      #include <assert.h>
      #include <string.h>

      int main(int argc, char *argv[]) {
        git_credential *cred = NULL;
        git_libgit2_init();
        assert(git_credential_ssh_key_memory_new(&cred, "git", NULL, "dummy", NULL) == 0);
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
      -lgit2-macos
      -lssh2-openssl3
      -lssl
      -lcrypto
      -lz
      -liconv
      -framework CoreFoundation
      -framework Security
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"

    # Only the libssh2 API may be exported, not the private openssl@3 symbols
    exported = shell_output("nm -gU #{lib}/libssh2-openssl3.a").lines.grep(/ [TDS] /)
    assert_empty exported.grep(/ _(EVP|SSL|OPENSSL|CRYPTO|BN|RSA)_/)
  end
end
