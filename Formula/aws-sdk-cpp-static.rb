class AwsSdkCppStatic < Formula
  desc "AWS SDK for C++"
  homepage "https://github.com/aws/aws-sdk-cpp"
  url "https://github.com/aws/aws-sdk-cpp.git",
      tag:      "1.9.163",
      revision: "6140db4ffa9ae018a2a9b94b43d07d011dae006b"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/aws-sdk-cpp-static-1.9.163"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "2a1ecb1a4165569bbc2d8ac77f44bdb7afb94f21767be47e3411c949a76abb6b"
    sha256 cellar: :any_skip_relocation, ventura:       "78c65c772a69903337f0b3d674c65f2df739e43428b7f9d9d73232ae3da5807c"
    sha256 cellar: :any_skip_relocation, big_sur:       "a341ae23be8bfbd70125219ff8bc52e71e6c22dbd5b630808c6bac0088ffac4e"
    sha256 cellar: :any_skip_relocation, catalina:      "4f6586822f8b61083a4dcec09a550a2bb2e018dc5804f6d84686d57e6123feaa"
    sha256 cellar: :any_skip_relocation, monterey:      "7e12a0802b447ac7b3c5ee22c0ab8f362212d1cfd1e8ee613014dfba1b6224c7"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "07a90b8b0831d0efb38c29a024c9791acc95b67fdd71fadbc2f4c9151386efda"
  end

  depends_on "cmake" => :build

  uses_from_macos "curl"

  conflicts_with "aws-sdk-cpp", because: "both install AWS-SDK headers"

  def install
    mkdir "build" do
      system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF",
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
