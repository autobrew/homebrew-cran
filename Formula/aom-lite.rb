class AomLite < Formula
  desc "Codec library for encoding and decoding AV1 video streams"
  homepage "https://aomedia.googlesource.com/aom"
  url "https://aomedia.googlesource.com/aom.git",
      tag:      "v3.6.0",
      revision: "3c65175b1972da4a1992c1dae2365b48d13f9a8d"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/aom-lite-3.6.0"
    sha256 cellar: :any, monterey: "2ece0adfdcd4c53a1575155d8960238b7278d322bf2d36220cef31603eefad56"
    sha256 cellar: :any, big_sur:  "6163e48178307151d1487334122d214e3797372a0d6165f258831be748fac390"
  end

  depends_on "cmake" => :build

  on_intel do
    depends_on "yasm" => :build
  end

  # Jeroen: this formula basically reverts: https://github.com/Homebrew/homebrew-core/commit/093d8417e3fd3

  resource "homebrew-bus_qcif_15fps.y4m" do
    url "https://media.xiph.org/video/derf/y4m/bus_qcif_15fps.y4m"
    sha256 "868fc3446d37d0c6959a48b68906486bd64788b2e795f0e29613cbb1fa73480e"
  end

  def install
    args = std_cmake_args + [
      "-DCMAKE_INSTALL_RPATH=#{rpath}",
      "-DENABLE_DOCS=off",
      "-DENABLE_EXAMPLES=on",
      "-DENABLE_TESTDATA=off",
      "-DENABLE_TESTS=off",
      "-DENABLE_TOOLS=off",
      "-DBUILD_SHARED_LIBS=on",
    ]
    # Runtime CPU detection is not currently enabled for ARM on macOS.
    args << "-DCONFIG_RUNTIME_CPU_DETECT=0" if Hardware::CPU.arm?

    system "cmake", "-S", ".", "-B", "brewbuild", *args
    system "cmake", "--build", "brewbuild"
    system "cmake", "--install", "brewbuild"
  end

  test do
    resource("homebrew-bus_qcif_15fps.y4m").stage do
      system "#{bin}/aomenc", "--webm",
                              "--tile-columns=2",
                              "--tile-rows=2",
                              "--cpu-used=8",
                              "--output=bus_qcif_15fps.webm",
                              "bus_qcif_15fps.y4m"

      system "#{bin}/aomdec", "--output=bus_qcif_15fps_decode.y4m",
                              "bus_qcif_15fps.webm"
    end
  end
end
