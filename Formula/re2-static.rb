class Re2Static < Formula
  desc "Alternative to backtracking PCRE-style regular expression engines"
  homepage "https://github.com/google/re2"
  url "https://github.com/google/re2/archive/refs/tags/2023-11-01.tar.gz"
  version "20231101"
  sha256 "4e6593ac3c71de1c0f322735bc8b0492a72f66ffccfad76e259fa21c41d27d8a"
  license "BSD-3-Clause"
  head "https://github.com/google/re2.git", branch: "main"

  # The `strategy` block below is used to massage upstream tags into the
  # YYYYMMDD format used in the `version`. This is necessary for livecheck
  # to be able to do proper `Version` comparison.
  livecheck do
    url :stable
    regex(/^(\d{2,4}-\d{2}-\d{2})$/i)
    strategy :git do |tags, regex|
      tags.map { |tag| tag[regex, 1]&.gsub(/\D/, "") }.compact
    end
  end

  bottle do
    root_url "https://github.com/gaborcsardi/homebrew-cran/releases/download/re2-static-20231101"
    sha256 cellar: :any_skip_relocation, ventura:  "cf349d1c366f1a2bf77d4dd240d7061cc2615e5c61b8acb856194b8e785f9a71"
    sha256 cellar: :any_skip_relocation, monterey: "d8e86cd04ba7e1ddee99c68d818b10e4b2edce06bc3f1f0541065f9226d5dbad"
    sha256 cellar: :any_skip_relocation, big_sur:  "c0ebcc5c8924eb18f518874becda8653c26cc352458e992ebc1c4477564d76df"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "3f0d60a9771dac960f7ed37f7ab4e289dec0459527526a0135ea02d9b6d032b7"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :test
  depends_on "abseil-static"

  def install
    # Build and install static library
    ENV["CXXFLAGS"] = "-mmacosx-version-min=11.0"
    ENV["LDFLAGS"] = "-mmacosx-version-min=11.0"
    system "cmake", "-S", ".", "-B", "build-static",
                    "-DRE2_BUILD_TESTING=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build-static"
    system "cmake", "--install", "build-static"

    return unless OS.mac?

    inreplace lib.glob("pkgconfig/re2.pc"),
              /^Libs: /,
              "Libs: -framework CoreFoundation "
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <re2/re2.h>
      #include <assert.h>
      int main() {
        assert(!RE2::FullMatch("hello", "e"));
        assert(RE2::PartialMatch("hello", "e"));
        return 0;
      }
    EOS
    cflags = `pkg-config --cflags re2`
    libs = `pkg-config --libs --static re2`
    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test",
                    *cflags.split, *libs.split
    system "./test"
  end
end
