class ApacheArrowStatic < Formula
  desc "Columnar in-memory analytics layer designed to accelerate big data"
  homepage "https://arrow.apache.org/"
  # url "https://downloads.apache.org/arrow/arrow-4.0.0/apache-arrow-4.0.0.tar.gz"
  # Uncomment and update to test on a release candidate
  url "https://dist.apache.org/repos/dist/dev/arrow/apache-arrow-4.0.1-rc1/apache-arrow-4.0.1.tar.gz"
  sha256 "75ccbfa276b925c6b1c978a920ff2f30c4b0d3fdf8b51777915b6f69a211896e"
  head "https://github.com/apache/arrow.git"
  revision 1

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/apache-arrow-static-4.0.1"
    sha256 cellar: :any, arm64_big_sur:  "f0880024fddc620ee57b0aae6f1d4305e34be888b9cf1a936a905f21035cba1f"
    sha256 cellar: :any, big_sur:  "55fa5b9204c8152d05ecb69f0950c0237e4456b9713909c5fbffce6351d20cc9"
    sha256 cellar: :any, catalina: "87cc2596aa3b76a2ce629f3bb18ac77c287c447592e0ea7651b3fdf5c90f8755"
  end

  depends_on "boost" => :build
  depends_on "cmake" => :build
  depends_on "aws-sdk-cpp-static"
  depends_on "lz4"
  depends_on "snappy"
  depends_on "thrift"
  depends_on "zstd"

  conflicts_with "apache-arrow", because: "both install Arrow"

  def install
    ENV.cxx11
    args = %W[
      -DARROW_COMPUTE=ON
      -DARROW_CSV=ON
      -DARROW_DATASET=ON
      -DARROW_FILESYSTEM=ON
      -DARROW_HDFS=OFF
      -DARROW_JSON=ON
      -DARROW_PARQUET=ON
      -DARROW_BUILD_SHARED=OFF
      -DARROW_JEMALLOC=ON
      -DARROW_USE_GLOG=OFF
      -DARROW_PYTHON=OFF
      -DARROW_S3=ON
      -DARROW_WITH_LZ4=ON
      -DARROW_WITH_SNAPPY=ON
      -DARROW_WITH_ZLIB=ON
      -DARROW_WITH_ZSTD=ON
      -DARROW_BUILD_UTILITIES=ON
      -DCMAKE_UNITY_BUILD=OFF
      -DPARQUET_BUILD_EXECUTABLES=ON
      -DLZ4_HOME=#{Formula["lz4"].prefix}
      -DTHRIFT_HOME=#{Formula["thrift"].prefix}
    ]

    args << "-DARROW_MIMALLOC=ON" unless Hardware::CPU.arm?

    mkdir "build"
    cd "build" do
      system "cmake", "../cpp", *std_cmake_args, *args
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include "arrow/api.h"
      int main(void) {
        arrow::int64();
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-std=c++11", "-I#{include}", "-L#{lib}", \
      "-larrow", "-larrow_bundled_dependencies", "-o", "test"
    system "./test"
  end
end
