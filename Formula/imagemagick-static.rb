class ImagemagickStatic < Formula
  desc "Tools and libraries to manipulate images in many formats"
  homepage "https://legacy.imagemagick.org/"
  url "https://imagemagick.org/archive/releases/ImageMagick-6.9.13-16.tar.xz"
  sha256 "a2ca04c37ef56e669f442954d878bab7d096fadabdc75f6027f755bfdbf89a98"
  license "ImageMagick"
  head "https://github.com/imagemagick/imagemagick6.git", branch: "main"

  livecheck do
    url "https://imagemagick.org/archive/"
    regex(/href=.*?ImageMagick[._-]v?(6(?:[.-]\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/imagemagick-static-6.9.13-16"
    sha256 arm64_sonoma:  "5066017814623024ee4224dcb0d662ee71f9c5cb98e70b33f45cb5f31f9661cb"
    sha256 arm64_ventura: "ac96d64a043270f67a8fdb18f5e2f32e2333802e5c4cfc3a27bc62e1a206f8f5"
    sha256 ventura:       "18e9645bb0f27b3abae25f7767b8db9ba43ab3a689e53fff32487243a6b248c6"
  end

  # Hardcode thresholds.xml
  depends_on "pkg-config" => :build
  depends_on "gettext" => :test
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "jpeg"
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
