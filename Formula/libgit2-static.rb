class Libgit2Static < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.github.com/"
  url "https://github.com/libgit2/libgit2/archive/v1.4.2.tar.gz"
  sha256 "901c2b4492976b86477569502a41c31b274b69adc177149c02099ea88404ef19"
  license "GPL-2.0-only"
  head "https://github.com/libgit2/libgit2.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any,                 arm64_monterey: "1a3d957e46a244f78689420ad9c5d3fa0072ff08672bae7d5f2ce3ec426a82d3"
    sha256 cellar: :any,                 arm64_big_sur:  "914aa3e7cae6be1ee2eb580859114df902a495f1169219f57225180684d401ff"
    sha256 cellar: :any,                 monterey:       "a377a03747dbd5e8cebc9ea437bad644a41f60c24bafaf3ae239f42edb69e992"
    sha256 cellar: :any,                 big_sur:        "81760fb5880774ed47c470aca07bdcf1945a241c7a2bc9c9727ba4c1d8f18bca"
    sha256 cellar: :any,                 catalina:       "ecfb9a5ac0a3d99b576ea500dbde84c6370bac68a1d896b7c7deb1b2d3c5f704"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "5645a27c2804fb54b79a269690d7cdba4a59f5f65859dcca866eb5f80af707b9"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libssh2"

  def install
    args = std_cmake_args
    args << "-DBUILD_EXAMPLES=YES"
    args << "-DBUILD_TESTS=OFF" # Don't build tests.
    args << "-DUSE_SSH=YES"
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    args << "-DREGEX_BACKEND=builtin"

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
      cd "examples" do
        (pkgshare/"examples").install "lg2"
      end
      system "make", "clean"
      system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF", *args
      system "make"
      lib.install "libgit2.a"
    end
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
