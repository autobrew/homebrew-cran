class HarfbuzzLite < Formula
  desc "OpenType text shaping engine"
  homepage "https://github.com/harfbuzz/harfbuzz"
  url "https://github.com/harfbuzz/harfbuzz/releases/download/2.6.8/harfbuzz-2.6.8.tar.xz"
  sha256 "6648a571a27f186e47094121f0095e1b809e918b3037c630c7f38ffad86e3035"
  license "MIT"
  head "https://github.com/harfbuzz/harfbuzz.git"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/harfbuzz-lite-2.7.4"
    cellar :any
    sha256 "69976500f28a36e1d2377b3854adacbc0bc5aec750bdc404cc9f64f6f62424b4" => :arm64_big_sur
    sha256 "28ed4df908d4b019db13e75f0c2732e274ccd64ae93844f27443f78b9faedd60" => :big_sur
    sha256 "72672e648846753c8d22f2903c17063ec6e2f3e850866f2bc2f69d7400b319c0" => :catalina
  end

  depends_on "glib" => :build
  depends_on "pkgconfig" => :build
  depends_on "cairo"
  depends_on "freetype"

  resource "ttf" do
    url "https://github.com/harfbuzz/harfbuzz/raw/fc0daafab0336b847ac14682e581a8838f36a0bf/test/shaping/fonts/sha1sum/270b89df543a7e48e206a2d830c0e10e5265c630.ttf"
    sha256 "9535d35dab9e002963eef56757c46881f6b3d3b27db24eefcc80929781856c77"
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --enable-introspection=no
      --enable-static
      --with-cairo=yes
      --with-coretext=yes
      --with-freetype=yes
      --with-glib=yes
      --with-gobject=no
      --with-graphite2=no
      --with-icu=no
    ]

    system "./autogen.sh" if build.head?
    system "./configure", *args
    system "make", "install"
  end

  test do
    resource("ttf").stage do
      shape = `echo 'സ്റ്റ്' | #{bin}/hb-shape 270b89df543a7e48e206a2d830c0e10e5265c630.ttf`.chomp
      assert_equal "[glyph201=0+1183|U0D4D=0+0]", shape
    end
  end
end
