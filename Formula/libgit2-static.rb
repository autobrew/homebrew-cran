class Libgit2Static < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.github.com/"
  url "https://github.com/libgit2/libgit2/archive/refs/tags/v1.8.2.tar.gz"
  sha256 "184699f0d9773f96eeeb5cb245ba2304400f5b74671f313240410f594c566a28"
  license "GPL-2.0-only" => { with: "GCC-exception-2.0" }
  head "https://github.com/libgit2/libgit2.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libgit2-static-1.8.2"
    sha256 cellar: :any, arm64_sonoma:  "11b15383aa9cb6d54a43471c3c0ffb9867e12f80e2d6dc7f331a7ccb81318602"
    sha256 cellar: :any, arm64_ventura: "6dcd272c27baa1b30af554444d61b56e01db7dc7d80cede8961b3bef20594b93"
    sha256 cellar: :any, ventura:       "a064e7cee98c677ff5f9111ee2c7fa4c40145628f9dcfec33a86d3f1dc6f7fbb"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libssh2"
  depends_on "openssl@3"

  def install
    args = %w[-DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DUSE_SSH=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON]

    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build-static", "-DBUILD_SHARED_LIBS=OFF", *args, *std_cmake_args
    system "cmake", "--build", "build-static"
    lib.install "build-static/libgit2.a"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <git2.h>
      #include <assert.h>

      int main(int argc, char *argv[]) {
        int options = git_libgit2_features();
        assert(options & GIT_FEATURE_SSH);
        return 0;
      }
    EOS
    libssh2 = Formula["libssh2"]
    flags = %W[
      -I#{include}
      -I#{libssh2.opt_include}
      -L#{lib}
      -lgit2
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
