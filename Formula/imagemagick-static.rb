class ImagemagickStatic < Formula
  desc "Tools and libraries to manipulate images in many formats"
  homepage "https://legacy.imagemagick.org/"
  url "https://imagemagick.org/archive/releases/ImageMagick-6.9.12-93.tar.xz"
  sha256 "288f16a1aefce49aae4696d0dc3fb58a15750d9705191f6da56cd4aedc96e2f6"
  license "ImageMagick"
  head "https://github.com/imagemagick/imagemagick6.git", branch: "main"

  livecheck do
    url "https://imagemagick.org/archive/"
    regex(/href=.*?ImageMagick[._-]v?(6(?:[.-]\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/imagemagick-static-6.9.12-93"
    sha256 arm64_big_sur: "0cb8f382a641fb8dab0dcd508ca5a73a53978e09a43c088f25482d03bbaf9e36"
    sha256 ventura:       "f4cd9d3d2d2be434e353fdd3b3a5cc28378a8a6f2a0c5f47087ec79bfdfd1655"
    sha256 monterey:      "ae563636adb181af2c630c43296fe133b98f9dcf36ec8e26b7f5e4afcc8bd3f2"
    sha256 big_sur:       "2b92fa32391de0dfeef3299dafca62726127e2cb77c4a40792eae9d0085bc943"
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
