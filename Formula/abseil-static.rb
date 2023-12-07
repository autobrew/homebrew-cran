class AbseilStatic < Formula
  desc "C++ Common Libraries"
  homepage "https://abseil.io"
  url "https://github.com/abseil/abseil-cpp/archive/refs/tags/20220623.1.tar.gz"
  sha256 "91ac87d30cc6d79f9ab974c51874a704de9c2647c40f6932597329a282217ba8"
  license "Apache-2.0"
  head "https://github.com/abseil/abseil-cpp.git", branch: "master"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/abseil-static-20220623.1"
    sha256 cellar: :any, ventura:  "8d2075e672a1a2cc80cf581bb995e060356a1a122a47df8e44f269a007094acd"
    sha256 cellar: :any, monterey: "456f5a844fc48a32f84129a4422178ea44d8eec85b3f1efb33913c722e6850a3"
    sha256 cellar: :any, big_sur:  "b7eb4a5fb4f12fa8cdefa291a74d32130299b6e4b674f4e760101ad01c6cb311"
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
