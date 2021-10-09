class Hdf4 < Formula
  desc "Legacy HDF4 driver for GDAL"
  homepage "https://www.hdfgroup.org"
  url "https://support.hdfgroup.org/ftp/HDF/releases/HDF4.2.15/src/hdf-4.2.15.tar.gz"
  sha256 "dbeeef525af7c2d01539906c28953f0fdab7dba603d1bc1ec4a5af60d002c459"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/hdf4-4.2.15"
    sha256 cellar: :any, arm64_big_sur:  "020df5ea763c951097819f58cc8f2f51b3160c7835b97021f3fb8a749750ea1e"
    sha256 cellar: :any, big_sur:  "9bb7d63d507734ee2ac425432d61f060c1e36601ddeb030040b6d5fcb114b9ea"
    sha256 cellar: :any, catalina: "c93355cf4fb1853fbda30ad0943c9ee8d9fa189b536c4982e84a2411eacd2f53"
  end

  depends_on "gcc" => :build
  depends_on "jpeg"
  depends_on "szip"

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --with-szlib=#{Formula["szip"].opt_prefix}
      --enable-build-mode=production
      --enable-fortran
      --disable-netcdf
      --disable-deprecated-symbols
    ]

    # Flag for compatibility with GCC 10
    args << "FFLAGS=-fallow-argument-mismatch"

    system "./configure", *args
    system "make", "install"
    (lib/"libhdf4.settings").unlink
    (bin/"ncdump").unlink
    (bin/"ncgen").unlink
    (share/"man/man1/ncdump.1").unlink
    (share/"man/man1/ncgen.1").unlink
  end

  test do
    system "#{bin}/h4cc", "-show"
  end
end
