class CairoLite < Formula
  desc "Vector graphics library with cross-device output support"
  homepage "https://cairographics.org/"
  url "https://cairographics.org/releases/cairo-1.18.4.tar.xz"
  sha256 "445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb"
  license any_of: ["LGPL-2.1-only", "MPL-1.1"]
  head "https://gitlab.freedesktop.org/cairo/cairo.git", branch: "master"

  livecheck do
    url "https://cairographics.org/releases/?C=M&O=D"
    regex(%r{href=(?:["']?|.*?/)cairo[._-]v?(\d+\.\d*[02468](?:\.\d+)*)\.t}i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/cairo-lite-1.18.4"
    sha256 cellar: :any, arm64_ventura: "a9713623f6fad4f341be448d16b56063f91a672357fc3d97d49b7ead9b79c28d"
    sha256 cellar: :any, ventura:       "208bcde12c753c2f06450cd8d49a68d4c593e96e8255bedf4c8165f57be6869d"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]

  depends_on "freetype"
  depends_on "glib"
  depends_on "libpng"
  depends_on "lzo"
  depends_on "pixman"

  uses_from_macos "zlib"

  on_macos do
    depends_on "gettext"
  end

  def install
    args = %w[
      --default-library=both
      -Dfontconfig=disabled
      -Dfreetype=enabled
      -Dpng=enabled
      -Dglib=enabled
      -Dspectre=disabled
      -Dtests=disabled
      -Dfreetype=enabled
      -Dxlib=disabled
      -Dxcb=disabled
      -Dsymbol-lookup=disabled
    ]
    args << "-Dquartz=enabled" if OS.mac?

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <cairo.h>

      int main(int argc, char *argv[]) {

        cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 600, 400);
        cairo_t *context = cairo_create(surface);

        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs cairo").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
