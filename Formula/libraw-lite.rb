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
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/libraw-lite-0.21.1"
    sha256 cellar: :any, arm64_big_sur: "0ad8e5839ebd2a04aec536445381ffb005ed0d94c4dd98d0dc7947e44ae5ebfd"
    sha256 cellar: :any, monterey:      "46665da99188841e6afbab46c97969757ec646c356e02a143459a80b582c6b71"
    sha256 cellar: :any, big_sur:       "8774046bb598df137823ac542378f8c4d015b57c02c8fdae3210577754aa6dc3"
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
