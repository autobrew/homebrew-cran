class ApacheArrowStatic < Formula
  desc "Columnar in-memory analytics layer designed to accelerate big data"
  homepage "https://arrow.apache.org/"
  url "https://downloads.apache.org/arrow/arrow-13.0.0/apache-arrow-13.0.0.tar.gz"
  # Uncomment and update to test on a release candidate
  mirror "https://dist.apache.org/repos/dist/dev/arrow/apache-arrow-13.0.0-rc3/apache-arrow-13.0.0.tar.gz"
  sha256 "35dfda191262a756be934eef8afee8d09762cad25021daa626eb249e251ac9e6"
  head "https://github.com/apache/arrow.git", branch: "main"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/apache-arrow-static-13.0.0"
    sha256 cellar: :any, ventura:  "25fc50e8e513cc941ee15afb836e880adbf4fe52a2d7d5c50fd2b8c5f991f10a"
    sha256 cellar: :any, monterey: "b7de89021c595e984a6e76ae8980bcfcf5caeb3b132f0dd1e78e70890f9c9d7a"
    sha256 cellar: :any, big_sur:  "4d8940c9a4616e194cfba4f76dae2fb559a26748280f704523b0474b7dbf7efc"
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
