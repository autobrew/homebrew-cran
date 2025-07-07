class Libxml2Static < Formula
  desc "GNOME XML library"
  homepage "http://xmlsoft.org/"
  url "https://download.gnome.org/sources/libxml2/2.14/libxml2-2.14.4.tar.xz"
  sha256 "24175ec30a97cfa86bdf9befb7ccf4613f8f4b2713c5103e0dd0bc9c711a2773"
  license "MIT"

  # We use a common regex because libxml2 doesn't use GNOME's "even-numbered
  # minor is stable" version scheme.
  livecheck do
    url :stable
    regex(/libxml2[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libxml2-static-2.14.4"
    sha256 cellar: :any, arm64_ventura: "e1e60f1b05e241dde38cd9949bbb312f529ccbe68de0ee4c6bf1910ae0c1da97"
    sha256 cellar: :any, arm64_big_sur: "93221f6031fcf5ad6635bc9c82c7df804caf177e76759c2a456bd23e6f10aa5f"
    sha256 cellar: :any, ventura:       "182b6880cb40589819a931441fc4c5d9d4e706bcea669dd24d3543e424246e3e"
    sha256 cellar: :any, big_sur:       "bdd8a616e678c405f8feb7d1f6acb502159bb0c820dfbcf829158e4cff9c7460"
  end

  head do
    url "https://gitlab.gnome.org/GNOME/libxml2.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  keg_only "conflicts with libxml2 formula"

  depends_on "autobrew/cran/pkgconf" => [:build, :test]

  uses_from_macos "zlib"

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--disable-silent-rules",
                          "--sysconfdir=#{etc}",
                          "--without-history",
                          "--without-lzma",
                          "--without-python",
                          "--enable-static",
                          "--enable-shared",
                          "--without-modules",
                          *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libxml/tree.h>

      int main()
      {
        xmlDocPtr doc = xmlNewDoc(BAD_CAST "1.0");
        xmlNodePtr root_node = xmlNewNode(NULL, BAD_CAST "root");
        xmlDocSetRootElement(doc, root_node);
        xmlFreeDoc(doc);
        return 0;
      }
    C

    # Test build with xml2-config
    args = shell_output("#{bin}/xml2-config --cflags --libs").split
    system ENV.cc, "test.c", "-o", "test", *args
    system "./test"

    # Test build with pkg-config
    ENV.append "PKG_CONFIG_PATH", lib/"pkgconfig"
    args = shell_output("#{Formula["pkgconf"].opt_bin}/pkgconf --cflags --libs libxml-2.0").split
    system ENV.cc, "test.c", "-o", "test", *args
    system "./test"
  end
end
