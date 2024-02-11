class Libsndfile < Formula
  desc "C library for files containing sampled sound"
  homepage "https://libsndfile.github.io/libsndfile/"
  url "https://github.com/libsndfile/libsndfile/releases/download/1.2.2/libsndfile-1.2.2.tar.xz"
  sha256 "3799ca9924d3125038880367bf1468e53a1b7e3686a934f098b7e1d286cdb80e"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libsndfile-1.2.2"
    sha256 cellar: :any, ventura:  "b9a62d4d7deb29176e0d7e5e1f0f78742f38f50ed3eab3ad113cf16b0680fbe4"
    sha256 cellar: :any, monterey: "456141b03372c5f4ac333c6f7bd4a08b10ea661df0c581105e0cf6dd2d4e91bf"
    sha256 cellar: :any, big_sur:  "a98a80255b66bf15dee841be0428a0b2236adbcec12b6e82e829ff523ac008b3"
  end

  depends_on "cmake" => :build
  depends_on "flac"
  depends_on "lame"
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "mpg123"
  depends_on "opus"

  uses_from_macos "python" => :build, since: :catalina

  def install
    args = %W[
      -DBUILD_PROGRAMS=ON
      -DENABLE_PACKAGE_CONFIG=ON
      -DINSTALL_PKGCONFIG_MODULE=ON
      -DBUILD_EXAMPLES=OFF
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DPYTHON_EXECUTABLE=#{which("python3")}
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DBUILD_SHARED_LIBS=ON", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    system "cmake", "-S", ".", "-B", "static", *std_cmake_args, "-DBUILD_SHARED_LIBS=OFF", *args
    system "cmake", "--build", "static"
    lib.install "static/libsndfile.a"
  end

  test do
    output = shell_output("#{bin}/sndfile-info #{test_fixtures("test.wav")}")
    assert_match "Duration    : 00:00:00.064", output
  end
end
