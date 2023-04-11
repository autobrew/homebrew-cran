class HarfbuzzLite < Formula
  desc "OpenType text shaping engine"
  homepage "https://github.com/harfbuzz/harfbuzz"
  url "https://github.com/harfbuzz/harfbuzz/archive/7.1.0.tar.gz"
  sha256 "6c7a358c6e134bd6da4fe39f59ec273ff0ee461697945027b7538287b8c73b1e"
  license "MIT"
  head "https://github.com/harfbuzz/harfbuzz.git", branch: "main"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/harfbuzz-lite-2.7.4"
    sha256 cellar: :any, arm64_big_sur: "69976500f28a36e1d2377b3854adacbc0bc5aec750bdc404cc9f64f6f62424b4"
    sha256 cellar: :any, big_sur:       "28ed4df908d4b019db13e75f0c2732e274ccd64ae93844f27443f78b9faedd60"
    sha256 cellar: :any, catalina:      "72672e648846753c8d22f2903c17063ec6e2f3e850866f2bc2f69d7400b319c0"
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
