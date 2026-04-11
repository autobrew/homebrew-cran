class LibrawLite < Formula
  desc "Library for reading RAW files from digital photo cameras"
  homepage "https://www.libraw.org/"
  url "https://www.libraw.org/data/LibRaw-0.22.1.tar.gz"
  sha256 "a789dc4e2409e2901d93793a4e0b80c7b49d0d97cf6ad71c850eb7616acfd786"
  license any_of: ["LGPL-2.1-only", "CDDL-1.0"]

  livecheck do
    url "https://www.libraw.org/download/"
    regex(/href=.*?LibRaw[._-]v?(\d+(?:\.\d+)*)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libraw-lite-0.22.1"
    sha256 cellar: :any, arm64_sonoma: "c9cfbce586417a9407cd830dbaab0909800d7e669f05a67232f37a8a99174b5d"
    sha256 cellar: :any, sonoma:       "50da83d55f008d483d66f784988acd043d6520edd064a800ceb0c886c6812683"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "jasper"
  depends_on "jpeg"
  depends_on "little-cms2"

  resource "librawtestfile" do
    url "https://www.rawsamples.ch/raws/nikon/d1/RAW_NIKON_D1.NEF"
    sha256 "7886d8b0e1257897faa7404b98fe1086ee2d95606531b6285aed83a0939b768f"
  end

  # Jeroen: removed OpenMP here
  def install
    system "autoreconf", "-fiv"
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking"
    system "make", "install"
    doc.install Dir["doc/*"]
    prefix.install "samples"
  end

  test do
    resource("librawtestfile").stage do
      filename = "RAW_NIKON_D1.NEF"
      system "#{bin}/raw-identify", "-u", filename
      system "#{bin}/simple_dcraw", "-v", "-T", filename
    end
  end
end
