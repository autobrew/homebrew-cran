class OpencvStatic < Formula
  desc "Open source computer vision library"
  homepage "https://opencv.org/"
  url "https://github.com/opencv/opencv/archive/refs/tags/4.14.0.tar.gz"
  sha256 "ee8fb9b30eb60850431b4656447080e3737b56e45719c92b67f245950609f86e"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/opencv-static-4.14.0"
    sha256 arm64_sonoma: "a13e96871b33dcaa476c194a1f1977e484c57ac86ab080b17d5b17d44b04a278"
    sha256 sonoma:       "785950a254216386ebc006e9647e67bf02a3c6c215a8802f0a3eb83ccb2fff8a"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "eigen"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "protobuf"
  depends_on "tbb"
  depends_on "webp"

  uses_from_macos "zlib"

  fails_with gcc: "5" # ffmpeg is compiled with GCC

  resource "contrib" do
    url "https://github.com/opencv/opencv_contrib/archive/refs/tags/4.14.0.tar.gz"
    sha256 "4f17abd1bc7f88e19c3380c8de7cbf2d863aced5b5ee8d8934cc7902b67d42c9"
  end

  def python3
    "python3.14"
  end

  def install
    resource("contrib").stage buildpath/"opencv_contrib"

    # Avoid Accelerate.framework
    ENV["OpenBLAS_HOME"] = formula_opt_prefix("openblas")

    # Reset PYTHONPATH, workaround for https://github.com/Homebrew/homebrew-science/pull/4885
    ENV.delete("PYTHONPATH")

    # ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

    args = std_cmake_args + %W[
      -DCMAKE_OSX_DEPLOYMENT_TARGET=
      -DBUILD_EXAMPLES=OFF
      -DBUILD_opencv_apps=OFF
      -DBUILD_JASPER=OFF
      -DBUILD_ZLIB=OFF
      -DBUILD_JPEG=OFF
      -DBUILD_WEBP=OFF
      -DBUILD_OPENEXR=OFF
      -DBUILD_PERF_TESTS=OFF
      -DBUILD_PNG=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_TIFF=OFF
      -DBUILD_opencv_hdf=OFF
      -DBUILD_opencv_java=OFF
      -DBUILD_opencv_text=OFF
      -DOPENCV_ENABLE_NONFREE=ON
      -DOPENCV_EXTRA_MODULES_PATH=#{buildpath}/opencv_contrib/modules
      -DOPENCV_GENERATE_PKGCONFIG=ON
      -DWITH_ITT=OFF
      -DWITH_XINE=OFF
      -DWITH_1394=OFF
      -DWITH_CUDA=OFF
      -DWITH_EIGEN=ON
      -DWITH_FFMPEG=OFF
      -DWITH_GPHOTO2=OFF
      -DWITH_GSTREAMER=OFF
      -DWITH_JASPER=OFF
      -DWITH_OPENEXR=OFF
      -DWITH_OPENGL=OFF
      -DWITH_QT=OFF
      -DWITH_TBB=ON
      -DWITH_VTK=OFF
      -DWITH_PROTOBUF=ON
      -DWITH_ADE=OFF
      -DWITH_IPP=OFF
      -DWITH_QUIRC=ON
      -DWITH_CAROTENE=OFF
      -DBUILD_opencv_python2=OFF
      -DBUILD_opencv_python3=OFF
    ]

    # Ref: https://github.com/opencv/opencv/wiki/CPU-optimizations-build-options
    if Hardware::CPU.intel? && build.bottle?
      cpu_baseline = MacOS.version.requires_sse42? ? "SSE4_2" : "SSSE3"
      args += %W[-DCPU_BASELINE=#{cpu_baseline} -DCPU_BASELINE_REQUIRE=#{cpu_baseline}]
    end

    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF"
    inreplace "build_static/modules/core/version_string.inc", "#{Superenv.shims_path}/", ""
    system "cmake", "--build", "build_static"
    system "cmake", "--install", "build_static"

    # Prevent dependents from using fragile Cellar paths
    inreplace lib/"pkgconfig/opencv#{version.major}.pc", prefix, opt_prefix
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <opencv2/opencv.hpp>
      #include <iostream>
      int main() {
        std::cout << CV_VERSION << std::endl;
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++11", "test.cpp", "-I#{include}/opencv4", "-o", "test"
    assert_equal shell_output("./test").strip, version.to_s
  end
end
