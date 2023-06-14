class ApacheArrowStatic < Formula
  desc "Columnar in-memory analytics layer designed to accelerate big data"
  homepage "https://arrow.apache.org/"
  url "https://downloads.apache.org/arrow/arrow-12.0.1/apache-arrow-12.0.1.tar.gz"
  # Uncomment and update to test on a release candidate
  mirror "https://dist.apache.org/repos/dist/dev/arrow/apache-arrow-12.0.1-rc1/apache-arrow-12.0.1.tar.gz"
  sha256 "3481c411393aa15c75e88d93cf8315faf7f43e180fe0790128d3840d417de858"
  head "https://github.com/apache/arrow.git"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/apache-arrow-static-12.0.1"
    sha256 cellar: :any, monterey: "b37a4fab39b16106f611d6023b0ae0c87ebfe6d4fe8c536814b325ab2659827c"
    sha256 cellar: :any, big_sur:  "419f54b929caa22462349e686c98550780b8c86efb90148d746806671bbd2328"
  end

  depends_on "boost" => :build
  depends_on "cmake" => :build
  depends_on "aws-sdk-cpp-static"
  depends_on "brotli"
  depends_on "lz4"
  depends_on "snappy"
  depends_on "thrift"
  depends_on "zstd"

  conflicts_with "apache-arrow", because: "both install Arrow"

  def install
    args = %W[
      -DARROW_ACERO=ON
      -DARROW_BUILD_SHARED=OFF
      -DARROW_BUILD_UTILITIES=ON
      -DARROW_COMPUTE=ON
      -DARROW_CSV=ON
      -DARROW_DATASET=ON
      -DARROW_FILESYSTEM=ON
      -DARROW_GCS=ON
      -DARROW_HDFS=OFF
      -DARROW_JEMALLOC=ON
      -DARROW_JSON=ON
      -DARROW_MIMALLOC=ON
      -DARROW_PARQUET=ON
      -DARROW_PYTHON=OFF
      -DARROW_S3=ON
      -DARROW_USE_GLOG=OFF
      -DARROW_VERBOSE_THIRDPARTY_BUILD=ON
      -DARROW_WITH_BROTLI=ON
      -DARROW_WITH_BZ2=ON
      -DARROW_WITH_LZ4=ON
      -DARROW_WITH_SNAPPY=ON
      -DARROW_WITH_ZLIB=ON
      -DARROW_WITH_ZSTD=ON
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
    system ENV.cxx, "test.cpp", "-std=c++17", "-I#{include}", "-L#{lib}", \
      "-larrow", "-larrow_bundled_dependencies", "-o", "test"
    system "./test"
  end
end
