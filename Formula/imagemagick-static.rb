class ImagemagickStatic < Formula
  desc "Tools and libraries to manipulate images in many formats"
  homepage "https://www.imagemagick.org/"
  # Please always keep the Homebrew mirror as the primary URL as the
  # ImageMagick site removes tarballs regularly which means we get issues
  # unnecessarily and older versions of the formula are broken.
  url "https://dl.bintray.com/homebrew/mirror/imagemagick%406-6.9.11-57.tar.xz"
  mirror "https://www.imagemagick.org/download/releases/ImageMagick-6.9.11-57.tar.xz"
  sha256 "1a1d35a6e702a498d34b4a4f9fbf5aab228ee233d18b83f742163071fc6b7e05"
  license "ImageMagick"
  head "https://github.com/imagemagick/imagemagick6.git"

  livecheck do
    url "https://www.imagemagick.org/download/"
    regex(/href=.*?ImageMagick[._-]v?(6(?:\.\d+)+(?:-\d+)?)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/imagemagick-static-6.9.11-55"
    sha256 "45ab73f4b09b9efa8b5133eb4265bf293fc6d3ad93e873e1fed005bde62925bb" => :arm64_big_sur
    sha256 "18f882fab384940ce9911ac7d4b62997249bc11b6766cb18a5bc2291f649384e" => :big_sur
    sha256 "5d11ad785c9b8b912bf41fd5bdba282b812afd734c829b0bd7c5e062cc89b552" => :catalina
  end

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
    ]

    # versioned stuff in main tree is pointless for us
    inreplace "configure", "${PACKAGE_NAME}-${PACKAGE_BASE_VERSION}", "${PACKAGE_NAME}"
    system "./configure", *args
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
