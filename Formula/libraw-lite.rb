class LibrawLite < Formula
  desc "Library for reading RAW files from digital photo cameras"
  homepage "https://www.libraw.org/"
  url "https://www.libraw.org/data/LibRaw-0.21.1.tar.gz"
  sha256 "630a6bcf5e65d1b1b40cdb8608bdb922316759bfb981c65091fec8682d1543cd"
  license any_of: ["LGPL-2.1-only", "CDDL-1.0"]

  livecheck do
    url "https://www.libraw.org/download/"
    regex(/href=.*?LibRaw[._-]v?(\d+(?:\.\d+)*)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libraw-lite-0.20.2"
    sha256 cellar: :any, arm64_big_sur: "11ce15f578546d3c886328cc5ce8e8e9bbed64364877bcf68cecd13da56ff5dd"
    sha256 cellar: :any, big_sur:       "05c8c0eaea41486861b29a8c66a0b574eefcb50cddf88c0ed692f19287bfde94"
    sha256 cellar: :any, catalina:      "4d712244d01291bfb15580043ac85ecec7d30344022f664c8ed4e46c6343f2fe"
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
