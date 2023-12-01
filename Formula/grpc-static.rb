class GrpcStatic < Formula
  desc "Next generation open source RPC library and framework"
  homepage "https://grpc.io/"
  url "https://github.com/grpc/grpc.git",
      tag:      "v1.59.3",
      revision: "35df344f5e17a9cb290ebf0f5b0f03ddb1ff0a97"
  license "Apache-2.0"
  head "https://github.com/grpc/grpc.git", branch: "master"

  # There can be a notable gap between when a version is tagged and a
  # corresponding release is created, so we check releases instead of the Git
  # tags. Upstream maintains multiple major/minor versions and the "latest"
  # release may be for an older version, so we have to check multiple releases
  # to identify the highest version.
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_releases
  end

  bottle do
    root_url "https://github.com/gaborcsardi/homebrew-cran/releases/download/grpc-static-1.59.3"
    sha256 ventura:  "d7a41c88395275109d60fefb9bd6f864a9dcd427555b04a07bbe9809fd94555b"
    sha256 monterey: "fbe07a4a0b80b77b30845ae248dcbef4af5e883b604d09d10261c051ebea2287"
    sha256 big_sur:  "1a4b1c9e628df4986212398c911b614ca6cc403a4a356555c1b13e3bbc569d8f"
    rebuild 1
    sha256 arm64_big_sur: "3e53293ad12ed7bb541624198f7e61f895fba22eec2c05c1aba515778179a024"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "cmake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :test
  depends_on "abseil-static"
  depends_on "c-ares-static"
  # this is temporary
  depends_on "gaborcsardi/cran/openssl-static"
  depends_on "gaborcsardi/cran/protobuf-static"
  depends_on "re2-static"

  uses_from_macos "zlib"

  on_macos do
    depends_on "llvm" => :build if DevelopmentTools.clang_build_version <= 1100
  end

  fails_with :clang do
    build 1100
    cause "Requires C++17 features not yet implemented"
  end

  fails_with gcc: "5" # C++17

  def install
    ENV.llvm_clang if OS.mac? && (DevelopmentTools.clang_build_version <= 1100)
    mkdir "cmake/build" do
      args = %W[
        ../..
        -DCMAKE_CXX_STANDARD=17
        -DCMAKE_CXX_STANDARD_REQUIRED=TRUE
        -DCMAKE_INSTALL_RPATH=#{rpath}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_STATIC_LIBS=ON
        -DgRPC_BUILD_TESTS=OFF
        -DgRPC_INSTALL=ON
        -DgRPC_ABSL_PROVIDER=package
        -DgRPC_CARES_PROVIDER=package
        -DgRPC_PROTOBUF_PROVIDER=package
        -DgRPC_SSL_PROVIDER=package
        -DgRPC_ZLIB_PROVIDER=package
        -DgRPC_RE2_PROVIDER=package
      ] + std_cmake_args

      system "cmake", *args
      system "make", "install"

      args = %W[
        ../..
        -DCMAKE_INSTALL_RPATH=#{rpath}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_STATIC_LIBS=ON
        -DgRPC_BUILD_TESTS=ON
      ] + std_cmake_args
      ENV["CFLAGS"] = "-mmacosx-version-min=11.0"
      ENV["CXXFLAGS"] = "-mmacosx-version-min=11.0"
      ENV["LDFLAGS"] = "-mmacosx-version-min=11.0"
      system "cmake", *args
      system "make", "grpc_cli"
      bin.install "grpc_cli"

      if OS.mac?
        # These are installed manually, so need to be relocated manually as well
        MachO::Tools.add_rpath(bin/"grpc_cli", rpath)
      end
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <grpc/grpc.h>
      int main() {
        grpc_init();
        grpc_shutdown();
        return GRPC_STATUS_OK;
      }
    EOS
    pkg_config_flags = shell_output("pkg-config --cflags --libs --static grpc++").chomp.split
    system ENV.cc, "test.cpp", *pkg_config_flags, "-lc++", "-o", "test"
    system "./test"

    output = shell_output("#{bin}/grpc_cli ls localhost:#{free_port} 2>&1", 1)
    assert_match "Received an error when querying services endpoint.", output
  end
end
