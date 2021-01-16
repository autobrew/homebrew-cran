class ApacheArrowStatic < Formula
  desc "Columnar in-memory analytics layer designed to accelerate big data"
  homepage "https://arrow.apache.org/"
  # url "https://downloads.apache.org/arrow/arrow-3.0.0/apache-arrow-3.0.0.tar.gz"
  # Uncomment and update to test on a release candidate
  url "https://dist.apache.org/repos/dist/dev/arrow/apache-arrow-3.0.0-rc0/apache-arrow-3.0.0.tar.gz"
  sha256 "47fc0aa552ed207b45b10c1580bd21f886d77d40229d60ec48b35736607bb416"
  head "https://github.com/apache/arrow.git"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/apache-arrow-static-3.0.0"
    cellar :any
    sha256 "3783c16c7f4168bc53fe0ec8dae9274f83fa4e03360ef8849b5a283e372f2c9e" => :arm64_big_sur
    sha256 "d751dba6846b3f3e092914a684e5ed7d5a33a13711d370fa724bc3b3bc5ece05" => :big_sur
    sha256 "ff3f4d7d8e99e71b09740ac478d32f7c4ef05ebc6252058b69c57b4604b11912" => :catalina
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
      -DARROW_MIMALLOC=ON
      -DARROW_USE_GLOG=OFF
      -DARROW_PYTHON=OFF
      -DARROW_S3=ON
      -DARROW_WITH_LZ4=ON
      -DARROW_WITH_SNAPPY=ON
      -DARROW_WITH_UTF8PROC=OFF
      -DARROW_WITH_ZLIB=ON
      -DARROW_WITH_ZSTD=ON
      -DARROW_BUILD_UTILITIES=ON
      -DCMAKE_UNITY_BUILD=OFF
      -DPARQUET_BUILD_EXECUTABLES=ON
      -DLZ4_HOME=#{Formula["lz4"].prefix}
      -DTHRIFT_HOME=#{Formula["thrift"].prefix}
    ]

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
