class ImagemagickStatic < Formula
  desc "Tools and libraries to manipulate images in many formats"
  homepage "https://www.imagemagick.org/"
  # Please always keep the Homebrew mirror as the primary URL as the
  # ImageMagick site removes tarballs regularly which means we get issues
  # unnecessarily and older versions of the formula are broken.
  url "https://dl.bintray.com/homebrew/mirror/imagemagick%406-6.9.11-54.tar.xz"
  mirror "https://www.imagemagick.org/download/releases/ImageMagick-6.9.11-54.tar.xz"
  sha256 "d48d0d6710c02b821aa89338bcbcb5e83a4883ac4aafbc98b357bb9228d2e820"
  license "ImageMagick"
  head "https://github.com/imagemagick/imagemagick6.git"

  livecheck do
    url "https://www.imagemagick.org/download/"
    regex(/href=.*?ImageMagick[._-]v?(6(?:\.\d+)+(?:-\d+)?)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/imagemagick-static-6.9.11-54"
    sha256 "5c5d7c4115df2da74c0133605a14110ea1b061cd4fc00ecbcb8aa6e58a9b682a" => :big_sur
    sha256 "f6ba3d9fc4fb90827317e49b40824720c0bd368bd72863c543a4b86f0cd0683d" => :catalina
  end

  depends_on "pkg-config" => :build
  depends_on "gettext" => :test
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "ghostscript"
  depends_on "jpeg"
  depends_on "libpng"
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
      --with-gslib
      --with-gs-font-dir=/usr/local/share/ghostscript/fonts
      --without-fftw
      --without-perl
      --without-x
      --without-wmf
    ]

    # versioned stuff in main tree is pointless for us
    inreplace "configure", "${PACKAGE_NAME}-${PACKAGE_VERSION}", "${PACKAGE_NAME}"
    system "./configure", *args
    system "make", "install"
  end

  test do
    assert_match "PNG", shell_output("#{bin}/identify #{test_fixtures("test.png")}")
    # Check support for recommended features and delegates.
    features = shell_output("#{bin}/convert -version")
    %w[fontconfig pango cairo rsvg webp freetype jpeg jp2 png tiff].each do |feature|
      assert_match feature, features
    end
  end
end
