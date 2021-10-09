class Hdf4 < Formula
  desc "Legacy HDF4 driver for GDAL"
  homepage "https://www.hdfgroup.org"
  url "https://support.hdfgroup.org/ftp/HDF/releases/HDF4.2.15/src/hdf-4.2.15.tar.gz"
  sha256 "dbeeef525af7c2d01539906c28953f0fdab7dba603d1bc1ec4a5af60d002c459"

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/hdf4-4.2.15"
    rebuild 1
    sha256 cellar: :any, big_sur:  "fc324305399b9b6c304c5e038e7a7da5ee461b345da323807487b9f80a22aa56"
    sha256 cellar: :any, catalina: "63899d481d7819e161473e7fc61c366306790649a9360c115553934cc1eb16e4"
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
