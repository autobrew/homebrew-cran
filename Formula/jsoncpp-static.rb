class JsoncppStatic < Formula
  desc "Library for interacting with JSON"
  homepage "https://github.com/open-source-parsers/jsoncpp"
  url "https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.5.tar.gz"
  sha256 "f409856e5920c18d0c2fb85276e24ee607d2a09b5e7d5f0a371368903c275da2"
  license "MIT"
  head "https://github.com/open-source-parsers/jsoncpp.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/gaborcsardi/homebrew-cran/releases/download/jsoncpp-static-1.9.5"
    sha256 cellar: :any_skip_relocation, ventura:  "333ccacc9427645db38d9b7ffe59e45149b8f69a1cb8724a545d11c1fe56f694"
    sha256 cellar: :any_skip_relocation, monterey: "4cb326d668468f41f474ba4090fa0fcf88db7ea10f9b590e12a843113b4a7a20"
    sha256 cellar: :any_skip_relocation, big_sur:  "6a85793527db0df75132812cbcbeccea5328fde399b259684b9e798e939ecfd9"
  end

  # NOTE: Do not change this to use CMake, because the CMake build is deprecated.
  # See: https://github.com/open-source-parsers/jsoncpp/wiki/Building#building-and-testing-with-cmake
  #      https://github.com/Homebrew/homebrew-core/pull/103386
  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args,
      "-Ddefault_library=static",
      "-Dcpp_args=-mmacosx-version-min=11.0",
      "-Dcpp_link_args=-mmacosx-version-min=11.0"
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <json/json.h>
      int main() {
          Json::Value root;
          Json::CharReaderBuilder builder;
          std::string errs;
          std::istringstream stream1;
          stream1.str("[1, 2, 3]");
          return Json::parseFromStream(builder, stream1, &root, &errs) ? 0: 1;
      }
    EOS
    system ENV.cxx, "-std=c++11", testpath/"test.cpp", "-o", "test",
                  "-I#{include}/jsoncpp",
                  "-L#{lib}",
                  "-ljsoncpp"
    system "./test"
  end
end
