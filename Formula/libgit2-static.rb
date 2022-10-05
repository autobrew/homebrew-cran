class Libgit2Static < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.github.com/"
  url "https://github.com/libgit2/libgit2/archive/v1.4.2.tar.gz"
  sha256 "901c2b4492976b86477569502a41c31b274b69adc177149c02099ea88404ef19"
  license "GPL-2.0-only"
  revision 1
  head "https://github.com/libgit2/libgit2.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libgit2-static-1.4.2"
    sha256 cellar: :any,                 arm64_big_sur: "26dd42597778392ac4a8700eaea72367fd68f50552c683cec8d401a5f88d3db7"
    sha256 cellar: :any,                 monterey:      "faa500483e8818fd4ae5338802de995f522e9f6798cc6cc54e191fa7a36cfb0b"
    sha256 cellar: :any,                 big_sur:       "ab9d52eb06edd8328df913e026dc4ca360e872d322805268448135a932f67ce7"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "08ec03081ce7d9fa0514a934f697a3288476c505bc9a3dda016e1bd130276d83"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libssh2-static"

  on_linux do
    depends_on "gcc@5"
    conflicts_with "gcc"
  end

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
