class V8Static < Formula
  desc "Google's JavaScript engine"
  homepage "https://github.com/v8/v8/wiki"
  # Track V8 version from Chrome stable: https://omahaproxy.appspot.com
  # revert back to GitHub mirror tar.gz archives once it's synced again
  url "https://chromium.googlesource.com/v8/v8.git",
      tag:      "9.6.180.12",
      revision: "7a8373f18e2327d7dc52600fc9e52cc2f5b6abf6"
  license "BSD-3-Clause"

  livecheck do
    url "https://omahaproxy.appspot.com/all.json?os=mac&channel=stable"
    regex(/"v8_version": "v?(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/v8-static-8.7.220.29"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "f4b537c7cf411248f58045719a2e231e6d9d0671b09b468d5835e1da6d58f4b5"
    sha256 cellar: :any_skip_relocation, big_sur:       "6f3dd872f4d7407b811c853b730581b71859e55563e7aceaf5a303e42f4cd0fc"
    sha256 cellar: :any_skip_relocation, catalina:      "c3be4811ff02c2eef39790ce1208996c3a76323556d1ed947814eb38f437acef"
  end

  depends_on "ninja" => :build
  depends_on "python@3.9" => :build

  on_macos do
    depends_on "llvm"
#   depends_on "llvm" => :build if DevelopmentTools.clang_build_version < 1200
    depends_on xcode: ["10.0", :build] # required by v8
  end

  on_linux do
    depends_on "pkg-config" => :build
    depends_on "gcc"
    depends_on "glib"
  end

  conflicts_with "v8", because: "both install V8"
  fails_with gcc: "5"

  # Look up the correct resource revisions in the DEP file of the specific releases tag
  # e.g. for CIPD dependency gn: https://chromium.googlesource.com/v8/v8.git/+/refs/tags/9.6.180.12/DEPS#52
  resource "gn" do
    url "https://gn.googlesource.com/gn.git",
        revision: "0153d369bbccc908f4da4993b1ba82728055926a"
  end

  # e.g.: https://chromium.googlesource.com/v8/v8.git/+/refs/tags/9.6.180.12/DEPS#93
  resource "v8/base/trace_event/common" do
    url "https://chromium.googlesource.com/chromium/src/base/trace_event/common.git",
        revision: "68d816952258c9d817bba656ee2664b35507f01b"
  end

  resource "v8/build" do
    url "https://chromium.googlesource.com/chromium/src/build.git",
        revision: "ebad8533842661f66b9b905e0ee9890a32f628d5"
  end

  resource "v8/third_party/googletest/src" do
    url "https://chromium.googlesource.com/external/github.com/google/googletest.git",
        revision: "3b49be074d5c1340eeb447e6a8e78427051e675a"
  end

  resource "v8/third_party/jinja2" do
    url "https://chromium.googlesource.com/chromium/src/third_party/jinja2.git",
        revision: "6db8da1615a13fdfab925688bc4bf2eb394a73af"
  end

  resource "v8/third_party/markupsafe" do
    url "https://chromium.googlesource.com/chromium/src/third_party/markupsafe.git",
        revision: "1b882ef6372b58bfd55a3285f37ed801be9137cd"
  end

  resource "v8/third_party/zlib" do
    url "https://chromium.googlesource.com/chromium/src/third_party/zlib.git",
        revision: "dfa96e81458fb3b39676e45f7e9e000dff789b05"
  end

  def install
    (buildpath/"build").install resource("v8/build")
    (buildpath/"third_party/jinja2").install resource("v8/third_party/jinja2")
    (buildpath/"third_party/markupsafe").install resource("v8/third_party/markupsafe")
    (buildpath/"third_party/googletest/src").install resource("v8/third_party/googletest/src")
    (buildpath/"base/trace_event/common").install resource("v8/base/trace_event/common")
    (buildpath/"third_party/zlib").install resource("v8/third_party/zlib")

    # Build gn from source and add it to the PATH
    (buildpath/"gn").install resource("gn")
    cd "gn" do
      system "python3", "build/gen.py"
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
    system ENV.cxx, "-std=c++14", "test.cpp",
      "-I#{libexec}/include",
      "-L#{libexec}", "-lv8", "-lv8_libplatform"
  end
end
