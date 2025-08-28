class V8Static < Formula
  desc "Google's JavaScript engine"
  homepage "https://v8.dev/docs"
  # Track V8 version from Chrome stable: https://chromiumdash.appspot.com/releases?platform=Mac
  # Check `brew livecheck --resources v8` for any resource updates
  url "https://github.com/v8/v8/archive/refs/tags/13.6.233.10.tar.gz"
  sha256 "a1d9609a90bebd88d41efef9e6ee84829dbe88684e807d552bc9ae73850d2aca"
  license "BSD-3-Clause"

  livecheck do
    url "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Mac"
    regex(/(\d+\.\d+\.\d+\.\d+)/i)
    strategy :json do |json, regex|
      # Find the v8 commit hash for the newest Chromium release version
      v8_hash = json.max_by { |item| Version.new(item["version"]) }.dig("hashes", "v8")
      next if v8_hash.blank?

      # Check the v8 commit page for version text
      v8_page = Homebrew::Livecheck::Strategy.page_content(
        "https://chromium.googlesource.com/v8/v8.git/+/#{v8_hash}",
      )
      v8_page[:content]&.scan(regex)&.map { |match| match[0] }
    end
  end

  no_autobump! because: :requires_manual_review

  bottle do
    sha256 cellar: :any,                 arm64_sequoia: "ee9f92d890ff6d646db3b11554be91ed50219923f5a7900d7f3e980a8d00f9e8"
    sha256 cellar: :any,                 arm64_sonoma:  "7c4952b33dd522e79610eabb3beb9bbfdddc3378f41c2153041503e9f8f0a878"
    sha256 cellar: :any,                 arm64_ventura: "9d424966acb2e88b34d0b27bef9032dc0d789deff4b298cb6ad2d43321227de7"
    sha256 cellar: :any,                 sonoma:        "9e25c1646f1f395ec8f9466d96fd5bd2bf3ca6f770ebf69905a43fdbaa80169e"
    sha256 cellar: :any,                 ventura:       "c66e6c688dd73c1a6182461e765231385f2bebcafeabf64234b1c5f6d6d26576"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "7ecb114d91a7473d870fa935b34b9c45588ef16313a34027208bf1098656a6d8"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "17f7942f13ff8b10fb467c44c6af7d33c0b0f1d26c6bb4522b9d8e2164cfe19f"
  end

  depends_on "ninja" => :build
  depends_on xcode: ["10.0", :build] # for xcodebuild, min version required by v8

  uses_from_macos "python" => :build

  on_linux do
    depends_on "lld" => :build
    depends_on "pkgconf" => :build
    depends_on "glib"
  end

  # Look up the correct resource revisions in the DEP file of the specific releases tag
  # e.g. for CIPD dependency gn: https://chromium.googlesource.com/v8/v8.git/+/refs/tags/<version>/DEPS#74
  resource "gn" do
    url "https://gn.googlesource.com/gn.git",
        revision: "6e8e0d6d4a151ab2ed9b4a35366e630c55888444"
    version "6e8e0d6d4a151ab2ed9b4a35366e630c55888444"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(/["']gn_version["']:\s*["']git_revision:([0-9a-f]+)["']/i)
    end
  end

  resource "build" do
    url "https://chromium.googlesource.com/chromium/src/build.git",
        revision: "451ef881d77fff0b7a8bbfa61934f5e4a35b4c96"
    version "451ef881d77fff0b7a8bbfa61934f5e4a35b4c96"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/src/build\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "buildtools" do
    url "https://chromium.googlesource.com/chromium/src/buildtools.git",
        revision: "6f359296daa889aa726f3d05046b9f37be241169"
    version "6f359296daa889aa726f3d05046b9f37be241169"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/src/buildtools\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/abseil-cpp" do
    url "https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp.git",
        revision: "3fbb10e80d80e3430224b75add53c47c7a711612"
    version "3fbb10e80d80e3430224b75add53c47c7a711612"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/src/third_party/abseil-cpp\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/fast_float/src" do
    url "https://chromium.googlesource.com/external/github.com/fastfloat/fast_float.git",
        revision: "cb1d42aaa1e14b09e1452cfdef373d051b8c02a4"
    version "cb1d42aaa1e14b09e1452cfdef373d051b8c02a4"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/external/github.com/fastfloat/fast_float\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/fp16/src" do
    url "https://chromium.googlesource.com/external/github.com/Maratyszcza/FP16.git",
        revision: "0a92994d729ff76a58f692d3028ca1b64b145d91"
    version "0a92994d729ff76a58f692d3028ca1b64b145d91"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/external/github.com/Maratyszcza/FP16\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/googletest/src" do
    url "https://chromium.googlesource.com/external/github.com/google/googletest.git",
        revision: "52204f78f94d7512df1f0f3bea1d47437a2c3a58"
    version "52204f78f94d7512df1f0f3bea1d47437a2c3a58"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/external/github.com/google/googletest\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/highway/src" do
    url "https://chromium.googlesource.com/external/github.com/google/highway.git",
        revision: "00fe003dac355b979f36157f9407c7c46448958e"
    version "00fe003dac355b979f36157f9407c7c46448958e"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/external/github.com/google/highway\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/icu" do
    url "https://chromium.googlesource.com/chromium/deps/icu.git",
        revision: "d30b7b0bb3829f2e220df403ed461a1ede78b774"
    version "d30b7b0bb3829f2e220df403ed461a1ede78b774"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/deps/icu\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/jinja2" do
    url "https://chromium.googlesource.com/chromium/src/third_party/jinja2.git",
        revision: "5e1ee241ab04b38889f8d517f2da8b3df7cfbd9a"
    version "5e1ee241ab04b38889f8d517f2da8b3df7cfbd9a"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/src/third_party/jinja2\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/markupsafe" do
    url "https://chromium.googlesource.com/chromium/src/third_party/markupsafe.git",
        revision: "9f8efc8637f847ab1ba984212598e6fb9cf1b3d4"
    version "9f8efc8637f847ab1ba984212598e6fb9cf1b3d4"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/src/third_party/markupsafe\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/partition_alloc" do
    url "https://chromium.googlesource.com/chromium/src/base/allocator/partition_allocator.git",
        revision: "ab56923a27b2793f21994589b0c39bc3324ff49f"
    version "ab56923a27b2793f21994589b0c39bc3324ff49f"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(/["']partition_alloc_version["']:\s*["']([0-9a-f]+)["']/i)
    end
  end

  resource "third_party/simdutf" do
    url "https://chromium.googlesource.com/chromium/src/third_party/simdutf.git",
        revision: "40d1fa26cd5ca221605c974e22c001ca2fb12fde"
    version "40d1fa26cd5ca221605c974e22c001ca2fb12fde"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/src/third_party/simdutf["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  resource "third_party/zlib" do
    url "https://chromium.googlesource.com/chromium/src/third_party/zlib.git",
        revision: "788cb3c270e8700b425c7bdca1f9ce6b0c1400a9"
    version "788cb3c270e8700b425c7bdca1f9ce6b0c1400a9"

    livecheck do
      url "https://raw.githubusercontent.com/v8/v8/refs/tags/#{LATEST_VERSION}/DEPS"
      regex(%r{["']/chromium/src/third_party/zlib\.git["']\s*\+\s*["']@["']\s*\+\s*["']([0-9a-f]+)["']}i)
    end
  end

  def install
    resources.each { |r| r.stage(buildpath/r.name) }

    # Build gn from source and add it to the PATH
    cd "gn" do
      system "python3", "build/gen.py"
      system "ninja", "-C", "out/", "gn"
    end
    ENV.prepend_path "PATH", buildpath/"gn/out"
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

    # create gclient_args.gni
    (buildpath/"build/config/gclient_args.gni").write <<~GN
      declare_args() {
        checkout_google_benchmark = false
      }
    GN

    gn_args = {
      is_debug:                     false,
      is_component_build:           false,
      v8_monolithic:                true,
      v8_static_library:            true,
      is_asan:                      false,
      is_official_build:            false,
      v8_use_external_startup_data: false,
      v8_enable_fuzztest:           false,
      v8_enable_i18n_support:       false, # enables i18n support with icu
      clang_use_chrome_plugins:     false, # disable the usage of Google's custom clang plugins
      use_custom_libcxx:            false, # uses system libc++ instead of Google's custom one
      treat_warnings_as_errors:     false, # ignore not yet supported clang argument warnings
      enable_rust:                  false,
    }

    # uses Homebrew clang instead of Google clang
    gn_args[:clang_base_path] = "\"/usr/bin\""

    if OS.linux?
      ENV.llvm_clang
      ENV["AR"] = DevelopmentTools.locate("ar")
      ENV["NM"] = DevelopmentTools.locate("nm")
      gn_args[:use_sysroot] = false # don't use sysroot
      gn_args[:custom_toolchain] = "\"//build/toolchain/linux/unbundle:default\"" # uses system toolchain
      gn_args[:host_toolchain] = "\"//build/toolchain/linux/unbundle:default\"" # to respect passed LDFLAGS
      gn_args[:use_rbe] = false
    else
      ENV["DEVELOPER_DIR"] = ENV["HOMEBREW_DEVELOPER_DIR"] # help run xcodebuild when xcode-select is set to CLT
      gn_args[:use_lld] = false # upstream use LLD but this leads to build failure on ARM
      # Work around failure mixing newer `llvm` headers with older Xcode's libc++:
      # Undefined symbols for architecture x86_64:
      #   "std::__1::__libcpp_verbose_abort(char const*, ...)", referenced from:
      #       std::__1::__throw_length_error[abi:nn180100](char const*) in stack_trace.o
    end

    # Make sure private libraries can be found from lib
    ENV.prepend "LDFLAGS", "-Wl,-rpath,#{rpath(target: libexec)}"

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

    (testpath/"test.cpp").write <<~CPP
      #include <libplatform/libplatform.h>
      #include <v8.h>
      int main(){
        static std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
        v8::V8::InitializePlatform(platform.get());
        v8::V8::Initialize();
        return 0;
      }
    CPP

    # link against installed libc++
    system ENV.cxx, "-std=c++20", "test.cpp",
                    "-I#{include}", "-L#{lib}",
                    "-Wl,-rpath,#{libexec}",
                    "-lv8", "-lv8_libplatform", "-framework CoreFoundation"
  end
end
