class PopplerLite < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-23.04.0.tar.xz"
  sha256 "b6d893dc7dcd4138b9e9df59a13c59695e50e80dc5c2cacee0674670693951a1"
  license "GPL-2.0-only"
  head "https://gitlab.freedesktop.org/poppler/poppler.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?poppler[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/poppler-lite-22.02.0"
    sha256 arm64_big_sur: "cc18a52e806fbdb6ba944509dc8a9cca196bd325d4df4b3557328f328baed97c"
    sha256 big_sur:       "90ad6c4180eacd158ef25b73a5296e0aa274c7795ff94327cdc9d97dddef1202"
    sha256 catalina:      "edb09092f6ec9d6c8bb9e3481506997c0d1ce51ed4c62a5f924b4a2e4478b016"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "little-cms2"
  depends_on "openjpeg"

  uses_from_macos "gperf" => :build
  uses_from_macos "curl", since: :catalina # 7.55.0 required by poppler
  uses_from_macos "zlib"

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    because: "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  fails_with gcc: "5"

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.12.tar.gz"
    sha256 "c835b640a40ce357e1b83666aabd95edffa24ddddd49b8daff63adb851cdab74"
  end

  def install
    ENV.cxx11

    # removes /usr/include from CFLAGS (not clear why)
    ENV["PKG_CONFIG_SYSTEM_INCLUDE_PATH"] = "/usr/include" if MacOS.version < :mojave

    args = std_cmake_args + %w[
      -DBUILD_GTK_TESTS=OFF
      -DENABLE_BOOST=OFF
      -DENABLE_CMS=lcms2
      -DENABLE_GLIB=OFF
      -DENABLE_QT5=OFF
      -DENABLE_QT6=OFF
      -DENABLE_UNSTABLE_API_ABI_HEADERS=OFF
      -DENABLE_NSS3=OFF
      -DWITH_GObjectIntrospection=OFF
    ]

    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "build_static"
    system "cmake", "--install", "build_static"

    resource("font-data").stage do
      system "make", "install", "prefix=#{prefix}"
    end
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end
