class HarfbuzzLite < Formula
  desc "OpenType text shaping engine"
  homepage "https://github.com/harfbuzz/harfbuzz"
  url "https://github.com/harfbuzz/harfbuzz/archive/7.1.0.tar.gz"
  sha256 "6c7a358c6e134bd6da4fe39f59ec273ff0ee461697945027b7538287b8c73b1e"
  license "MIT"
  head "https://github.com/harfbuzz/harfbuzz.git", branch: "main"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/harfbuzz-lite-7.1.0"
    sha256 cellar: :any, monterey: "69d78c747c8cde91aeda9a6885e693910e57c7c36e009bc885eebdebd4d94261"
    sha256 cellar: :any, big_sur:  "1cfbff1118df2e7c1b664183c3c628e0f194f8527e3189bbda9c35e819634470"
  end

  depends_on "glib" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconfig" => :build
  depends_on "cairo"
  depends_on "freetype"

  resource "homebrew-test-ttf" do
    url "https://github.com/harfbuzz/harfbuzz/raw/fc0daafab0336b847ac14682e581a8838f36a0bf/test/shaping/fonts/sha1sum/270b89df543a7e48e206a2d830c0e10e5265c630.ttf"
    sha256 "9535d35dab9e002963eef56757c46881f6b3d3b27db24eefcc80929781856c77"
  end

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

  test do
    resource("homebrew-test-ttf").stage do
      shape = pipe_output("#{bin}/hb-shape 270b89df543a7e48e206a2d830c0e10e5265c630.ttf", "സ്റ്റ്").chomp
      assert_equal "[glyph201=0+1183|U0D4D=0+0]", shape
    end
  end
end
