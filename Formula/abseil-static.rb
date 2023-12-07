class AbseilStatic < Formula
  desc "C++ Common Libraries"
  homepage "https://abseil.io"
  url "https://github.com/abseil/abseil-cpp/archive/refs/tags/20220623.1.tar.gz"
  sha256 "91ac87d30cc6d79f9ab974c51874a704de9c2647c40f6932597329a282217ba8"
  license "Apache-2.0"
  head "https://github.com/abseil/abseil-cpp.git", branch: "master"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/abseil-static-20220623.1"
    rebuild 1
    sha256 cellar: :any, ventura:  "caa3e14c515f6136e1a9c2cef2e37cbd900d95c373aed3c94c43f30812468820"
    sha256 cellar: :any, monterey: "ca36ca75e66c75d18df71ed3b4c68eb0e183bc88f9ec3648eba698f87915fa77"
    sha256 cellar: :any, big_sur:  "a5797588642ee1b4a953cf3bb5de1084dceefc4e050452eb68f1646372c1090e"
  end

  depends_on "cmake" => :build

  fails_with gcc: "5" # C++17

  def install
    args = %W[
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DCMAKE_CXX_STANDARD=17
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args, "-DBUILD_SHARED_LIBS=ON"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    system "cmake", "-S", ".", "-B", "static", *args, *std_cmake_args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "static"
    lib.install Dir["static/absl/*/*.a"]
  end

  test do
    (testpath/"test.cc").write <<~EOS
      #include <iostream>
      #include <string>
      #include <vector>
      #include "absl/strings/str_join.h"

      int main() {
        std::vector<std::string> v = {"foo","bar","baz"};
        std::string s = absl::StrJoin(v, "-");

        std::cout << "Joined string: " << s << "\\n";
      }
    EOS
    system ENV.cxx, "-std=c++17", "-I#{include}", "-L#{lib}", "-labsl_strings",
                    "test.cc", "-o", "test"
    assert_equal "Joined string: foo-bar-baz\n", shell_output("#{testpath}/test")
  end
end
