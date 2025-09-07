class ImagemagickStatic < Formula
  desc "Tools and libraries to manipulate images in many formats"
  homepage "https://legacy.imagemagick.org/"
  url "https://imagemagick.org/archive/releases/ImageMagick-6.9.13-29.tar.xz"
  sha256 "fd057bf7e3079b55cc60a64edf3c98a2bf01d3887d6339eef91c1ad1e74dfa44"
  license "ImageMagick"
  head "https://github.com/imagemagick/imagemagick6.git", branch: "main"

  livecheck do
    url "https://imagemagick.org/archive/"
    regex(/href=.*?ImageMagick[._-]v?(6(?:[.-]\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/imagemagick-static-6.9.13-29"
    rebuild 1
    sha256 arm64_ventura: "a630da7dc9ab2b14287a7055f0966d43b6aae4ab3e30f5b66310b1df671425fc"
    sha256 ventura:       "fb829047dfde217741c64915e73b4f3953fc8c5772bc40c8c288e07fbe081e98"
  end

  # Hardcode thresholds.xml
  depends_on "pkg-config" => :build
  depends_on "gettext" => :test
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "jpeg-turbo"
  depends_on "libheif"
  depends_on "libpng"
  depends_on "libraw"
  depends_on "librsvg"
  depends_on "libtiff"
  depends_on "libtool"
  depends_on "little-cms2"
  depends_on "openjpeg"
  depends_on "pango"
  depends_on "webp"
  depends_on "xz"

  skip_clean :la

  def install
    # Avoid references to shim
    inreplace Dir["**/*-config.in"], "@PKG_CONFIG@", Formula["pkg-config"].opt_bin/"pkg-config"

    args = %W[
      --enable-osx-universal-binary=no
      --prefix=#{prefix}
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-opencl
      --disable-openmp
      --without-modules
      --enable-zero-configuration
      --enable-shared
      --enable-static
      --with-freetype
      --with-fontconfig
      --with-webp
      --with-openjp2
      --with-pango
      --with-rsvg
      --with-raw
      --with-heic
      --with-gs-font-dir=/usr/local/share/ghostscript/fonts
      --without-gslib
      --without-fftw
      --without-perl
      --without-x
      --without-wmf
      --without-openexr
    ]

    system "./configure", *std_configure_args, *args
    system "make", "install"
  end

  test do
    assert_match "PNG", shell_output("#{bin}/identify #{test_fixtures("test.png")}")
    # Check support for recommended features and delegates.
    features = shell_output("#{bin}/convert -version")
    %w[raw heic fontconfig pango cairo rsvg webp freetype jpeg jp2 png tiff].each do |feature|
      assert_match feature, features
    end
  end
end
