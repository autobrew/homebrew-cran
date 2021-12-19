class AwsSdkCppStatic < Formula
  desc "AWS SDK for C++"
  homepage "https://github.com/aws/aws-sdk-cpp"
  url "https://github.com/aws/aws-sdk-cpp.git",
      tag:      "1.9.163",
      revision: "6140db4ffa9ae018a2a9b94b43d07d011dae006b"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/aws-sdk-cpp-static-1.9.163"
    sha256 cellar: :any_skip_relocation, big_sur:  "a341ae23be8bfbd70125219ff8bc52e71e6c22dbd5b630808c6bac0088ffac4e"
    sha256 cellar: :any_skip_relocation, catalina: "4f6586822f8b61083a4dcec09a550a2bb2e018dc5804f6d84686d57e6123feaa"
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
