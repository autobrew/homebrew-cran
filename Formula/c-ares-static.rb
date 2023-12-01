class CAresStatic < Formula
  desc "Asynchronous DNS library"
  homepage "https://c-ares.org/"
  url "https://c-ares.org/download/c-ares-1.22.1.tar.gz"
  mirror "https://github.com/c-ares/c-ares/releases/download/cares-1_22_1/c-ares-1.22.1.tar.gz"
  mirror "http://fresh-center.net/linux/misc/dns/c-ares-1.22.1.tar.gz"
  sha256 "f67c180deb799c670d9dda995a18ce06f6c7320b6c6363ff8fa85b77d0da9db8"
  license "MIT"
  head "https://github.com/c-ares/c-ares.git", branch: "main"

  livecheck do
    url :homepage
    regex(/href=.*?c-ares[._-](\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/gaborcsardi/homebrew-cran/releases/download/c-ares-static-1.22.1"
    sha256 cellar: :any_skip_relocation, ventura:  "615343f28d4dd28cefe03f497b122efb0f92dd01d27c7615ef877ebcb61f65ff"
    sha256 cellar: :any_skip_relocation, monterey: "db38615feafee734844036a8ac8c31819763210435ea1d1c3cabf34fde02d5e4"
    sha256 cellar: :any_skip_relocation, big_sur:  "07f9882240c0055de0242c077ad94367fa81d9bbca3b36586d7e875a742d422a"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "d5a12ed452c281c5aa90c3a5df91374c033da5d3e2e5b8f2c368924e4ea6dae1"
  end

  depends_on "cmake" => :build

  def install
    ENV["CFLAGS"] = "-mmacosx-version-min=11.0"
    ENV["CXXFLAGS"] = "-mmacosx-version-min=11.0"
    ENV["LDFLAGS"] = "-mmacosx-version-min=11.0"
    system "cmake", "-S", ".", "-B", "build",
      *std_cmake_args, "-DCMAKE_INSTALL_RPATH=#{rpath}",
      "-DCARES_STATIC=ON", "-DCARES_SHARED=OFF"
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
