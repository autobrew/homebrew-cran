class ApacheArrowStatic < Formula
  desc "Columnar in-memory analytics layer designed to accelerate big data"
  homepage "https://arrow.apache.org/"
  url "https://downloads.apache.org/arrow/arrow-6.0.0/apache-arrow-6.0.0.tar.gz"
  # Uncomment and update to test on a release candidate
  mirror "https://dist.apache.org/repos/dist/dev/arrow/apache-arrow-6.0.0-rc3/apache-arrow-6.0.0.tar.gz"
  sha256 "69d268f9e82d3ebef595ad1bdc83d4cb02b20c181946a68631f6645d7c1f7a90"
  head "https://github.com/apache/arrow.git"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/apache-arrow-static-6.0.0"
    sha256 cellar: :any, big_sur:  "ff163d5ee818481395d164d60d37497f623a3b59f03bb97fa5284303d5a225a7"
    sha256 cellar: :any, catalina: "96a102779d0e9ff26922edae8a8fc9cb6c386a6246e12270d00620515bfd9f68"
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
