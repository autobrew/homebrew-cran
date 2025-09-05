class HarfbuzzLite < Formula
  desc "OpenType text shaping engine"
  homepage "https://github.com/harfbuzz/harfbuzz"
  url "https://github.com/harfbuzz/harfbuzz/archive/refs/tags/11.4.5.tar.gz"
  sha256 "5bc7a571b476eeda0c1996a04006da7c25f8edbc01cdf394ef729a6ecd1296d6"
  license "MIT"
  head "https://github.com/harfbuzz/harfbuzz.git", branch: "main"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/harfbuzz-lite-11.4.5"
    sha256 cellar: :any, arm64_ventura: "d0bbda9bb59416b6e5ef0ac249d5cd23257d95cf1d8f6014ede5db702a1c6a5e"
    sha256 cellar: :any, ventura:       "bd8c58b77456cbc5c3b8b0ee945880d00f1a63308f696869bbe96c83ad3dfb2c"
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
