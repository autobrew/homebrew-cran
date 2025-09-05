class HarfbuzzLite < Formula
  desc "OpenType text shaping engine"
  homepage "https://github.com/harfbuzz/harfbuzz"
  url "https://github.com/harfbuzz/harfbuzz/archive/refs/tags/11.4.5.tar.gz"
  sha256 "5bc7a571b476eeda0c1996a04006da7c25f8edbc01cdf394ef729a6ecd1296d6"
  license "MIT"
  head "https://github.com/harfbuzz/harfbuzz.git", branch: "main"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/harfbuzz-lite-7.1.0"
    sha256 cellar: :any, arm64_big_sur: "4cefdbf6f2b315380b958e7659621a0b4fdbe4f2477530bf863af47c5537936f"
    sha256 cellar: :any, monterey:      "69d78c747c8cde91aeda9a6885e693910e57c7c36e009bc885eebdebd4d94261"
    sha256 cellar: :any, big_sur:       "1cfbff1118df2e7c1b664183c3c628e0f194f8527e3189bbda9c35e819634470"
  end

  depends_on "glib" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconfig" => :build
  depends_on "cairo"
  depends_on "freetype"

  def install
    args = %w[
      --default-library=both
      -Dcairo=enabled
      -Dcoretext=enabled
      -Dfreetype=enabled
      -Dglib=enabled
      -Dgobject=disabled
      -Dgraphite=disabled
      -Dicu=disabled
      -Dintrospection=disabled
    ]

    system "meson", "setup", "build", *std_meson_args, *args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end
end
