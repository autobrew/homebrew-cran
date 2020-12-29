class AwsSdkCppStatic < Formula
  desc "AWS SDK for C++"
  homepage "https://github.com/aws/aws-sdk-cpp"
  url "https://github.com/aws/aws-sdk-cpp/archive/1.8.110.tar.gz"
  sha256 "5448a7c99d385a83783d4b0243a2f2ba29c5d6f8534f103c781e844be8824778"
  license "Apache-2.0"

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
