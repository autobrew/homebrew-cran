class V8Static < Formula
  desc "Google's JavaScript engine"
  homepage "https://github.com/v8/v8/wiki"
  # Track V8 version from Chrome stable: https://chromiumdash.appspot.com/releases?platform=Mac
  url "https://github.com/v8/v8/archive/refs/tags/11.7.439.14.tar.gz"
  sha256 "487f9c714fec0c2a0270c84105fc55c5a1a16143947385270ac3660b2934adca"
  license "BSD-3-Clause"

  livecheck do
    url "https://omahaproxy.appspot.com/all.json?os=mac&channel=stable"
    regex(/"v8_version": "v?(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/v8-static-11.7.439.14"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "babd5f6860236645b041950bfdf6655334e0b66c5147609c91ef6ee977252ab1"
    sha256 cellar: :any_skip_relocation, ventura:       "a373e84707429869026bcddb9b5e9186b76a019fe9da2604fc02c3d412bc450d"
    sha256 cellar: :any_skip_relocation, monterey:      "6024fe33f3c82a3a919c63a3029f7db9adc2902ac7e1752237aef9b45a8c9424"
    sha256 cellar: :any_skip_relocation, big_sur:       "3edb1292162ef7101ea0232d82e75fe56045b3df63137fdd9c62ae345da179a7"
  end

  depends_on "ninja" => :build
  depends_on "python@3.11" => :build

  on_macos do
    depends_on "llvm" => :build
    depends_on xcode: ["10.0", :build] # required by v8
  end

  on_linux do
    depends_on "pkg-config" => :build
    depends_on "glib"
  end

  fails_with gcc: "5"

  # Look up the correct resource revisions in the DEP file of the specific releases tag
  # e.g. for CIPD dependency gn: https://chromium.googlesource.com/v8/v8.git/+/refs/tags/<version>/DEPS#59
  resource "gn" do
    url "https://gn.googlesource.com/gn.git",
        revision: "811d332bd90551342c5cbd39e133aa276022d7f8"
  end

  resource "v8/base/trace_event/common" do
    url "https://chromium.googlesource.com/chromium/src/base/trace_event/common.git",
        revision: "147f65333c38ddd1ebf554e89965c243c8ce50b3"
  end

  resource "v8/build" do
    url "https://chromium.googlesource.com/chromium/src/build.git",
        revision: "afe0125ef9e10b400d9ec145aa18fca932369346"
  end

  resource "v8/third_party/abseil-cpp" do
    url "https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp.git",
        revision: "583dc6d1b3a0dd44579718699e37cad2f0c41a26"
  end

  resource "v8/third_party/googletest/src" do
    url "https://chromium.googlesource.com/external/github.com/google/googletest.git",
        revision: "af29db7ec28d6df1c7f0f745186884091e602e07"
  end

  resource "v8/third_party/jinja2" do
    url "https://chromium.googlesource.com/chromium/src/third_party/jinja2.git",
        revision: "515dd10de9bf63040045902a4a310d2ba25213a0"
  end

  resource "v8/third_party/markupsafe" do
    url "https://chromium.googlesource.com/chromium/src/third_party/markupsafe.git",
        revision: "006709ba3ed87660a17bd4548c45663628f5ed85"
  end

  resource "v8/third_party/zlib" do
    url "https://chromium.googlesource.com/chromium/src/third_party/zlib.git",
        revision: "526382e41c9c5275dc329db4328b54e4f344a204"
  end

  def install
    (buildpath/"build").install resource("v8/build")
    (buildpath/"third_party/abseil-cpp").install resource("v8/third_party/abseil-cpp")
    (buildpath/"third_party/jinja2").install resource("v8/third_party/jinja2")
    (buildpath/"third_party/markupsafe").install resource("v8/third_party/markupsafe")
    (buildpath/"third_party/googletest/src").install resource("v8/third_party/googletest/src")
    (buildpath/"base/trace_event/common").install resource("v8/base/trace_event/common")
    (buildpath/"third_party/zlib").install resource("v8/third_party/zlib")

    # Build gn from source and add it to the PATH
    (buildpath/"gn").install resource("gn")
    cd "gn" do
      system "python3.11", "build/gen.py"
      system "ninja", "-C", "out/", "gn"
    end
    ENV.prepend_path "PATH", buildpath/"gn/out"

    # create gclient_args.gni
    (buildpath/"build/config/gclient_args.gni").write <<~EOS
      declare_args() {
        checkout_google_benchmark = false
      }
    EOS

    # setup gn args
    gn_args = {
      v8_enable_reverse_jsargs:     false,
      v8_monolithic:                true,
      v8_static_library:            true,
      is_debug:                     false,
      is_asan:                      false,
      is_official_build:            false,
      use_gold:                     false,
      v8_use_external_startup_data: false,
      v8_enable_i18n_support:       false, # enables i18n support with icu
      clang_base_path:              "\"#{Formula["llvm"].opt_prefix}\"", # uses Homebrew clang instead of Google clang
      clang_use_chrome_plugins:     false, # disable the usage of Google's custom clang plugins
      use_custom_libcxx:            false, # uses system libc++ instead of Google's custom one
      treat_warnings_as_errors:     false, # ignore not yet supported clang argument warnings
    }

    # use clang from homebrew llvm formula, because the system clang is unreliable
    ENV.remove "HOMEBREW_LIBRARY_PATHS", Formula["llvm"].opt_lib # but link against system libc++
    # Make sure private libraries can be found from lib
    ENV.prepend "LDFLAGS", "-Wl,-rpath,#{libexec}"

    # Transform to args string
    gn_args_string = gn_args.map { |k, v| "#{k}=#{v}" }.join(" ")

    # Build with gn + ninja
    system "gn", "gen", "--args=#{gn_args_string}", "out.gn"
    system "ninja", "-j", ENV.make_jobs, "-C", "out.gn", "-v", "v8_monolith"
    system "ninja", "-j", ENV.make_jobs, "-C", "out.gn", "-v", "d8"

    # Jeroen: somehow is_debug doesnt help
    system "strip", "-S", "out.gn/obj/libv8_monolith.a"

    # Install all the things
    include.install Dir["include/*"]
    lib.install "out.gn/obj/libv8_monolith.a"
    lib.install_symlink "libv8_monolith.a" => "libv8.a"
    lib.install_symlink "libv8_monolith.a" => "libv8_libplatform.a"
    bin.install "out.gn/d8"
    prefix.install_symlink "lib" => "libexec"
  end

  test do
    assert_equal "Hello World!", shell_output("#{bin}/d8 -e 'print(\"Hello World!\");'").chomp

    (testpath/"test.cpp").write <<~EOS
      #include <libplatform/libplatform.h>
      #include <v8.h>
      int main(){
        static std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
        v8::V8::InitializePlatform(platform.get());
        v8::V8::Initialize();
        return 0;
      }
    EOS

    # link against installed libc++
    system ENV.cxx, "-std=c++17", "test.cpp",
                    "-I#{include}", "-L#{lib}",
                    "-Wl,-rpath,#{libexec}",
                    "-lv8", "-lv8_libplatform"
  end
end
