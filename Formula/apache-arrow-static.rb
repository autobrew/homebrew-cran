class ApacheArrowStatic < Formula
  desc "Columnar in-memory analytics layer designed to accelerate big data"
  homepage "https://arrow.apache.org/"
  url "https://downloads.apache.org/arrow/arrow-10.0.0/apache-arrow-10.0.0.tar.gz"
  # Uncomment and update to test on a release candidate
  mirror "https://dist.apache.org/repos/dist/dev/arrow/apache-arrow-10.0.0-rc0/apache-arrow-10.0.0.tar.gz"
  sha256 "5b46fa4c54f53e5df0019fe0f9d421e93fc906b625ebe8e89eed010d561f1f12"
  head "https://github.com/apache/arrow.git"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/apache-arrow-static-10.0.0"
    sha256 cellar: :any, arm64_big_sur: "307e6499bdb1d3a93e6694c1c78cd23d338cca5fb4274c637bd1fb52fe844829"
    sha256 cellar: :any, big_sur:       "e9025220969caf4abb34e41ef2e2db0c72e85ee53425fac964c5621f603db89c"
    sha256 cellar: :any, catalina:      "f685186fd3403c58ec10a824af1e32367d8e639967a1a221f0af4f66f3218848"
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
    ENV.cxx17
    args = %W[
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
