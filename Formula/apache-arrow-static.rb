class ApacheArrowStatic < Formula
  desc "Columnar in-memory analytics layer designed to accelerate big data"
  homepage "https://arrow.apache.org/"
  url "https://downloads.apache.org/arrow/arrow-3.0.0/apache-arrow-3.0.0.tar.gz"
  # Uncomment and update to test on a release candidate
  # url "https://dist.apache.org/repos/dist/dev/arrow/apache-arrow-3.0.0-rc0/apache-arrow-3.0.0.tar.gz"
  sha256 "73c2cc3be537aa1f3fd9490cfec185714168c9bfd599d23e287ab0cc0558e27a"
  head "https://github.com/apache/arrow.git"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/apache-arrow-static-3.0.0"
    cellar :any
    sha256 "9348f39d8e10876f446f734729a25c340a888b27e1c4be9642495279633818c0" => :arm64_big_sur
    sha256 "7132f09b2f65a9e14c4cabd76b2cefbb6663ec5d4b235c6469ab18b4f4a42d59" => :big_sur
    sha256 "f34c2242f9e2d3747ff2c1837c31285ee7c16394cf01eebe80c657095d2e82ee" => :catalina
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
      -DARROW_WITH_UTF8PROC=OFF
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
