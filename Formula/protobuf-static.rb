class ProtobufStatic < Formula
  desc "Protocol buffers (Google's data interchange format)"
  homepage "https://github.com/protocolbuffers/protobuf/"
  url "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v3.21.12.tar.gz"
  sha256 "930c2c3b5ecc6c9c12615cf5ad93f1cd6e12d0aba862b572e076259970ac3a53"
  license "BSD-3-Clause"
  head "https://github.com/protocolbuffers/protobuf.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/protobuf-static-21.12"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "a64a86e937912c5f47289e1eb741611cd2a45e265d60e149a952d1da3165a699"
    sha256 cellar: :any_skip_relocation, monterey:      "b3510fbd4df29e0da0e919ca8cc44e6dd1104ce61def72821684a627a6ba6d67"
    sha256 cellar: :any_skip_relocation, big_sur:       "13a90333e98e16863035bd63e31b2519a1c3a22ab540a8844ce990f047d4ddee"
  end

  depends_on "cmake" => :build
  depends_on "python@3.10" => [:build, :test]
  depends_on "python@3.11" => [:build, :test]

  uses_from_macos "zlib"

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.match?(/^python@\d\.\d+$/) }
        .map { |f| f.opt_libexec/"bin/python" }
  end

  # Jeroen: make sure protoc executable is only statically linked
  def install
    cmake_args = %w[
      -Dprotobuf_BUILD_LIBPROTOC=ON
      -Dprotobuf_INSTALL_EXAMPLES=ON
      -Dprotobuf_BUILD_TESTS=OFF
    ] + std_cmake_args

    system "cmake", "-S", ".", "-B", "build", "-Dprotobuf_BUILD_SHARED_LIBS=OFF", *cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "editors/proto.vim"
    elisp.install "editors/protobuf-mode.el"

    ENV.append_to_cflags "-I#{include}"
    ENV.append_to_cflags "-L#{lib}"
    ENV["PROTOC"] = bin/"protoc"

    cd "python" do
      pythons.each do |python|
        pyext_dir = prefix/Language::Python.site_packages(python)/"google/protobuf/pyext"
        with_env(LDFLAGS: "-Wl,-rpath,#{rpath(source: pyext_dir)} #{ENV.ldflags}") do
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

    pythons.each do |python|
      system python, "-c", "import google.protobuf"
    end
  end
end
