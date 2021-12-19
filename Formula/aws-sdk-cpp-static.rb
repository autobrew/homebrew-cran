class AwsSdkCppStatic < Formula
  desc "AWS SDK for C++"
  homepage "https://github.com/aws/aws-sdk-cpp"
  url "https://github.com/aws/aws-sdk-cpp.git",
      tag:      "1.9.163",
      revision: "6140db4ffa9ae018a2a9b94b43d07d011dae006b"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/aws-sdk-cpp-static-1.8.110"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "13a225bea1577c25a8c14c42a70be4e571468ecf08acdb9b676ef8e307bce57e"
    sha256 cellar: :any_skip_relocation, big_sur:       "4a3ef7ce846997ecbdbba9542a5f53246430d7b76935c6be0ff4f400a5a7232d"
    sha256 cellar: :any_skip_relocation, catalina:      "ee5afee9ccc9c2dd2c94817a27a9e310fc82d497f3543a7436cddc7d6c4914a7"
  end

  depends_on "cmake" => :build

  uses_from_macos "curl"

  conflicts_with "aws-sdk-cpp", because: "both install AWS-SDK headers"

  def install
    mkdir "build" do
      system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF", \
        "-DBUILD_ONLY=config;s3;transfer;identity-management;sts", "-DENABLE_UNITY_BUILD=ON", *std_cmake_args
      system "make"
      system "make", "install"
    end

    lib.install Dir[lib/"mac/Release/*"].select { |f| File.file? f }
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <aws/core/Version.h>
      #include <iostream>

      int main() {
          std::cout << Aws::Version::GetVersionString() << std::endl;
          return 0;
      }
    EOS
    system ENV.cxx, "-std=c++11", "test.cpp", "-L#{lib}", "-laws-cpp-sdk-core", "-lcurl",
           "-o", "test"
    system "./test"
  end
end
