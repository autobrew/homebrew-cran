class V8Static < Formula
  desc "Google's JavaScript engine"
  homepage "https://github.com/v8/v8/wiki"
  # Track V8 version from Chrome stable: https://omahaproxy.appspot.com
  url "https://github.com/v8/v8/archive/8.7.220.29.tar.gz"
  sha256 "36ebf7a55ccc0f2c765a45f23ed152caceb7612f31ce29d3f49ff1614afbe54d"
  license "BSD-3-Clause"

  livecheck do
    url "https://omahaproxy.appspot.com/all.json?os=mac&channel=stable"
    regex(/"v8_version": "v?(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/v8-static-8.7.220.29"
    cellar :any_skip_relocation
    sha256 "f4b537c7cf411248f58045719a2e231e6d9d0671b09b468d5835e1da6d58f4b5" => :arm64_big_sur
    sha256 "6f3dd872f4d7407b811c853b730581b71859e55563e7aceaf5a303e42f4cd0fc" => :big_sur
    sha256 "c3be4811ff02c2eef39790ce1208996c3a76323556d1ed947814eb38f437acef" => :catalina
  end

  depends_on "llvm" => :build if DevelopmentTools.clang_build_version < 1200
  depends_on "ninja" => :build

  depends_on xcode: ["10.0", :build] # required by v8

  conflicts_with "v8", because: "both install V8"

  # Look up the correct resource revisions in the DEP file of the specific releases tag
  # e.g. for CIPD dependency gn: https://github.com/v8/v8/blob/8.7.220.29/DEPS#L44
  resource "gn" do
    url "https://gn.googlesource.com/gn.git",
        revision: "e002e68a48d1c82648eadde2f6aafa20d08c36f2"
  end

  # e.g.: https://github.com/v8/v8/blob/8.7.220.29/DEPS#L85 for the revision of build for v8 8.7.220.29
  resource "v8/build" do
    url "https://chromium.googlesource.com/chromium/src/build.git",
        revision: "38a49c12ded01dd8c4628b432cb7eebfb29e77f1"
  end

  resource "v8/third_party/icu" do
    url "https://chromium.googlesource.com/chromium/deps/icu.git",
        revision: "aef20f06d47ba76fdf13abcdb033e2a408b5a94d"
  end

  resource "v8/base/trace_event/common" do
    url "https://chromium.googlesource.com/chromium/src/base/trace_event/common.git",
        revision: "23ef5333a357fc7314630ef88b44c3a545881dee"
  end

  resource "v8/third_party/googletest/src" do
    url "https://chromium.googlesource.com/external/github.com/google/googletest.git",
        revision: "4fe018038f87675c083d0cfb6a6b57c274fb1753"
  end

  resource "v8/third_party/jinja2" do
    url "https://chromium.googlesource.com/chromium/src/third_party/jinja2.git",
        revision: "a82a4944a7f2496639f34a89c9923be5908b80aa"
  end

  resource "v8/third_party/markupsafe" do
    url "https://chromium.googlesource.com/chromium/src/third_party/markupsafe.git",
        revision: "f2fb0f21ef1e1d4ffd43be8c63fc3d4928dea7ab"
  end

  resource "v8/third_party/zlib" do
    url "https://chromium.googlesource.com/chromium/src/third_party/zlib.git",
        revision: "4668feaaa47973a6f9d9f9caeb14cd03731854f1"
  end

  def install
    (buildpath/"build").install resource("v8/build")
    (buildpath/"third_party/jinja2").install resource("v8/third_party/jinja2")
    (buildpath/"third_party/markupsafe").install resource("v8/third_party/markupsafe")
    (buildpath/"third_party/googletest/src").install resource("v8/third_party/googletest/src")
    (buildpath/"base/trace_event/common").install resource("v8/base/trace_event/common")
    (buildpath/"third_party/icu").install resource("v8/third_party/icu")
    (buildpath/"third_party/zlib").install resource("v8/third_party/zlib")

    # Build gn from source and add it to the PATH
    (buildpath/"gn").install resource("gn")
    cd "gn" do
      system "python", "build/gen.py"
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
      clang_base_path:              "\"/usr/\"", # uses system clang instead of Google clang
      clang_use_chrome_plugins:     false, # disable the usage of Google's custom clang plugins
      use_custom_libcxx:            false, # uses system libc++ instead of Google's custom one
      treat_warnings_as_errors:     false, # ignore not yet supported clang argument warnings
    }

    # use clang from homebrew llvm formula for XCode 11- , because the system clang is too old for V8
    if DevelopmentTools.clang_build_version < 1200
      ENV.remove "HOMEBREW_LIBRARY_PATHS", Formula["llvm"].opt_lib # but link against system libc++
      gn_args[:clang_base_path] = "\"#{Formula["llvm"].prefix}\""
    end

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
