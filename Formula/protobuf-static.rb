class ProtobufStatic < Formula
  desc "Protocol buffers (Google's data interchange format)"
  homepage "https://protobuf.dev/"
  url "https://github.com/protocolbuffers/protobuf/releases/download/v25.1/protobuf-25.1.tar.gz"
  sha256 "9bd87b8280ef720d3240514f884e56a712f2218f0d693b48050c836028940a42"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/gaborcsardi/homebrew-cran/releases/download/protobuf-static-25.1"
    sha256 cellar: :any_skip_relocation, ventura:  "fb8a96057572b62d055ecfcf49dd56996bdf1f150de5eea2da7df8f255a9c444"
    sha256 cellar: :any_skip_relocation, monterey: "f23f292d8b6976213d9cd2c091dc15f96f89df21b2ae5526032eb438857a2b04"
    sha256 cellar: :any_skip_relocation, big_sur:  "57e9caf0361953aed8d43d47bc898382c3abd3cbacf9d9698cb4f5fc685bd2f3"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "b38e306386f2b9ac21deeff8dbc814030f700a97d3d56047f849e633616d7a4d"
  end

  depends_on "cmake" => :build
  depends_on "python@3.10" => [:build, :test]
  depends_on "python@3.11" => [:build, :test]
  depends_on "abseil-static"
  depends_on "jsoncpp-static"

  uses_from_macos "zlib"

  on_monterey :or_newer do
    depends_on "python-setuptools" => :build
    depends_on "python@3.12" => [:build, :test]
  end

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.match?(/^python@\d\.\d+$/) }
        .map { |f| f.opt_libexec/"bin/python" }
  end

  def install
    # Keep `CMAKE_CXX_STANDARD` in sync with the same variable in `abseil.rb`.
    abseil_cxx_standard = 17
    ENV["CFLAGS"] = "-mmacosx-version-min=11.0"
    ENV["CXXFLAGS"] = "-mmacosx-version-min=11.0"
    ENV["LDFLAGS"] = "-mmacosx-version-min=11.0"
    cmake_args = %w[
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_STATIC_LIBS=ON
      -Dprotobuf_BUILD_LIBPROTOC=ON
      -Dprotobuf_BUILD_SHARED_LIBS=OFF
      -Dprotobuf_BUILD_STATIC_LIBS=ON
      -Dprotobuf_INSTALL_EXAMPLES=ON
      -Dprotobuf_BUILD_TESTS=OFF
      -Dprotobuf_ABSL_PROVIDER=package
      -Dprotobuf_JSONCPP_PROVIDER=package
    ]
    cmake_args << "-DCMAKE_CXX_STANDARD=#{abseil_cxx_standard}"

    system "cmake", "-S", ".", "-B", "build", *cmake_args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    (share/"vim/vimfiles/syntax").install "editors/proto.vim"
    elisp.install "editors/protobuf-mode.el"

    ENV.append_to_cflags "-I#{include}"
    ENV.append_to_cflags "-L#{lib}"
    ENV["PROTOC"] = bin/"protoc"

    cd "python" do
      # Keep C++ standard in sync with `abseil.rb`.
      inreplace "setup.py", "extra_compile_args.append('-std=c++14')",
                            "extra_compile_args.append('-std=c++#{abseil_cxx_standard}')"

      pythons.each do |python|
        pyext_dir = prefix/Language::Python.site_packages(python)/"google/protobuf/pyext"
        with_env(LDFLAGS: "-Wl,-rpath,#{rpath(source: pyext_dir)} #{ENV.ldflags}".strip) do
          system python, *Language::Python.setup_install_args(prefix, python), "--cpp_implementation"
        end
      end
    end
  end

  test do
    testdata = <<~EOS
      syntax = "proto3";
      package test;
      message TestCase {
        string name = 4;
      }
      message Test {
        repeated TestCase case = 1;
      }
    EOS
    (testpath/"test.proto").write testdata
    system bin/"protoc", "test.proto", "--cpp_out=."
  end
end
