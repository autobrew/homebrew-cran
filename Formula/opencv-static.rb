class OpencvStatic < Formula
  desc "Open source computer vision library"
  homepage "https://opencv.org/"
  url "https://github.com/opencv/opencv/archive/refs/tags/4.11.0.tar.gz"
  sha256 "9a7c11f924eff5f8d8070e297b322ee68b9227e003fd600d4b8122198091665f"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/opencv-static-4.10.0"
    sha256 arm64_sonoma:  "83835f44f800baf6bac5a5238c1c142fdd804fd340a90e4efadeb2d05ffcbbf1"
    sha256 arm64_ventura: "278facc4f9add0777deea834a1286cd715b07e48806ad26da629b43c25f9217b"
    sha256 ventura:       "489b97d679e8295b875193f6b326c41506b255bb11006b25718b55185a1341e4"
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
    url "https://github.com/opencv/opencv_contrib/archive/refs/tags/4.11.0.tar.gz"
    sha256 "2dfc5957201de2aa785064711125af6abb2e80a64e2dc246aca4119b19687041"
  end

  def python3
    "python3.12"
  end

  def install
    resource("contrib").stage buildpath/"opencv_contrib"

    # Avoid Accelerate.framework
    ENV["OpenBLAS_HOME"] = Formula["openblas"].opt_prefix

    # Reset PYTHONPATH, workaround for https://github.com/Homebrew/homebrew-science/pull/4885
    ENV.delete("PYTHONPATH")

    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

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
