class CAres < Formula
  desc "Asynchronous DNS library"
  homepage "https://c-ares.org/"
  url "https://c-ares.org/download/c-ares-1.23.0.tar.gz"
  mirror "https://github.com/c-ares/c-ares/releases/download/cares-1_23_0/c-ares-1.23.0.tar.gz"
  sha256 "cb614ecf78b477d35963ebffcf486fc9d55cc3d3216f00700e71b7d4868f79f5"
  license "MIT"
  head "https://github.com/c-ares/c-ares.git", branch: "main"

  livecheck do
    url :homepage
    regex(/href=.*?c-ares[._-](\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/c-ares-1.23.0"
    sha256 cellar: :any, ventura:  "d066b042d43f109f6635cbb01a5719f1473ef42f6430ef35b64d9decda0fca5a"
    sha256 cellar: :any, monterey: "2e85ff3c9eb60b7a1a804eb4046dcf07ada26efa8eadacdb92251caffa07e054"
    sha256 cellar: :any, big_sur:  "3a499f10ab5e97dd1321bd1e79c5d9c2b49567fca6152e93fd27e811a68fdadf"
  end

  depends_on "cmake" => :build

  def install
    args = %W[
      -DCARES_STATIC=ON
      -DCARES_SHARED=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <ares.h>

      int main()
      {
        ares_library_init(ARES_LIB_INIT_ALL);
        ares_library_cleanup();
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-lcares", "-o", "test"
    system "./test"

    system "#{bin}/ahost", "127.0.0.1"
  end
end
