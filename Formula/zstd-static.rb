class ZstdStatic < Formula
  desc "Zstandard is a real-time compression algorithm"
  homepage "https://facebook.github.io/zstd/"
  url "https://github.com/facebook/zstd/archive/refs/tags/v1.5.5.tar.gz"
  mirror "http://fresh-center.net/linux/misc/zstd-1.5.5.tar.gz"
  sha256 "98e9c3d949d1b924e28e01eccb7deed865eefebf25c2f21c702e5cd5b63b85e1"
  license "BSD-3-Clause"
  head "https://github.com/facebook/zstd.git", branch: "dev"

  # The upstream repository contains old, one-off tags (5.5.5, 6.6.6) that are
  # higher than current versions, so we check the "latest" release instead.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/zstd-static-1.5.5"
    sha256 cellar: :any, arm64_big_sur: "a8056714100b81ee2117b71f0b693f88ea33aa93178e0ef2c255c98578cd7642"
    sha256 cellar: :any, ventura:       "f9ed83172ff36f0f06d501e9e7a37f93a6de6d1c976511da728cc80a1af9cd19"
    sha256 cellar: :any, monterey:      "d6b2e793368199b0859e9758e7d86b26aa33b00e50b55879627606db71cf589c"
    sha256 cellar: :any, big_sur:       "fe2f51dc73d9a3f0d71171a3f7775f954b445e289268d058673cbaa44df62933"
  end

  keg_only "it conflicts with `zstd`"

  depends_on "cmake" => :build
  uses_from_macos "zlib"

  def install
    # Legacy support is the default after
    # https://github.com/facebook/zstd/commit/db104f6e839cbef94df4df8268b5fecb58471274
    # Set it to `ON` to be explicit about the configuration.
    system "cmake", "-S", "build/cmake", "-B", "builddir",
                    "-DZSTD_PROGRAMS_LINK_SHARED=OFF", # link `zstd` to `libzstd`
                    "-DZSTD_BUILD_CONTRIB=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    "-DZSTD_LEGACY_SUPPORT=ON",
                    "-DZSTD_ZLIB_SUPPORT=ON",
                    "-DZSTD_LZMA_SUPPORT=OFF",
                    "-DZSTD_LZ4_SUPPORT=OFF",
                    "-DCMAKE_CXX_STANDARD=11",
                    *std_cmake_args
    system "cmake", "--build", "builddir"
    system "cmake", "--install", "builddir"

    # Prevent dependents from relying on fragile Cellar paths.
    # https://github.com/ocaml/ocaml/issues/12431
    inreplace lib/"pkgconfig/libzstd.pc", prefix, opt_prefix
  end

  test do
    [bin/"zstd", bin/"pzstd", "gzip"].each do |prog|
      data = "Hello, #{prog}"
      assert_equal data, pipe_output("#{bin}/zstd -d", pipe_output(prog, data))
      if prog.to_s.end_with?("zstd")
        # `pzstd` can only decompress zstd-compressed data.
        assert_equal data, pipe_output("#{bin}/pzstd -d", pipe_output(prog, data))
      else
        assert_equal data, pipe_output("#{prog} -d", pipe_output("#{bin}/zstd --format=#{prog}", data))
      end
    end
  end
end
