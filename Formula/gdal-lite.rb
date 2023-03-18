class GdalLite < Formula
  desc "Geospatial Data Abstraction Library"
  homepage "https://www.gdal.org/"
  url "https://download.osgeo.org/gdal/3.5.3/gdal-3.5.3.tar.xz"
  sha256 "d32223ddf145aafbbaec5ccfa5dbc164147fb3348a3413057f9b1600bb5b3890"
  license "MIT"

  livecheck do
    url "https://download.osgeo.org/gdal/CURRENT/"
    regex(/href=.*?gdal[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/gdal-lite-3.4.2"
    sha256 arm64_big_sur: "b069b7a607693b75e2015d25bf000721ae37723c37f5f78539dc34d5e983a971"
    sha256 big_sur:       "befc608e3e3846554ce5ec04158ebc7cf4071fdab57642cea1fe220896a6ea42"
    sha256 catalina:      "ad2a724ada531c4f1aaff4b15f1fc516996fa5947e2a75c9d43259eb07a985af"
  end

  head do
    url "https://github.com/OSGeo/gdal.git"
    depends_on "doxygen" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "expat"
  depends_on "freexl"
  depends_on "geos"
  depends_on "giflib"
  depends_on "hdf4"
  depends_on "hdf5"
  depends_on "jpeg"
  depends_on "json-c"
  depends_on "libdap"
  depends_on "libgeotiff"
  depends_on "libpng"
  depends_on "libpq"
  depends_on "libspatialite"
  depends_on "libxml2"
  depends_on "netcdf"
  depends_on "openjpeg"
  depends_on "pcre"
  depends_on "proj"
  depends_on "sqlite" # To ensure compatibility with SpatiaLite
  depends_on "unixodbc" # macOS version is not complete enough
  depends_on "webp"
  depends_on "xz" # get liblzma compression algorithm library from XZutils
  depends_on "zstd"

  on_linux do
    depends_on "bash-completion"
  end

  conflicts_with "cpl", because: "both install cpl_error.h"

  def install
    args = [
      # Base configuration
      "--prefix=#{prefix}",
      "--mandir=#{man}",
      "--disable-debug",
      "--with-libtool",
      "--with-local=#{prefix}",
      "--with-opencl",
      "--with-threads",

      # GDAL native backends
      "--with-pam",
      "--with-pcidsk=internal",
      "--with-pcraster=internal",

      # Homebrew backends
      "--with-expat=#{Formula["expat"].prefix}",
      "--with-freexl=#{Formula["freexl"].opt_prefix}",
      "--with-geos=#{Formula["geos"].opt_prefix}/bin/geos-config",
      "--with-geotiff=#{Formula["libgeotiff"].opt_prefix}",
      "--with-gif=#{Formula["giflib"].opt_prefix}",
      "--with-jpeg=#{Formula["jpeg"].opt_prefix}",
      "--with-libjson-c=#{Formula["json-c"].opt_prefix}",
      "--with-libtiff=internal",
      "--with-pg=yes",
      "--with-png=#{Formula["libpng"].opt_prefix}",
      "--with-spatialite=#{Formula["libspatialite"].opt_prefix}",
      "--with-sqlite3=#{Formula["sqlite"].opt_prefix}",
      "--with-proj=#{Formula["proj"].opt_prefix}",
      "--with-zstd=#{Formula["zstd"].opt_prefix}",
      "--with-liblzma=yes",
      "--with-hdf4=#{Formula["hdf4"].opt_prefix}",
      "--with-hdf5=#{Formula["hdf5"].opt_prefix}",
      "--with-netcdf=#{Formula["netcdf"].opt_prefix}",
      "--with-openjpeg",
      "--with-odbc=#{Formula["unixodbc"].opt_prefix}",
      "--with-dods-root=#{Formula["libdap"].opt_prefix}",
      "--with-webp=#{Formula["webp"].opt_prefix}",

      # Explicitly disable some features
      "--with-armadillo=no",
      "--with-qhull=no",
      "--without-grass",
      "--without-jasper",
      "--without-jpeg12",
      "--without-libgrass",
      "--without-mysql",
      "--without-perl",
      "--without-python",
      "--without-poppler",
      "--without-xerces",
      "--without-cfitsio",

      # Unsupported backends are either proprietary or have no compatible version
      # in Homebrew. Podofo is disabled because Poppler provides the same
      # functionality and then some.
      "--without-ecw",
      "--without-fgdb",
      "--without-fme",
      "--without-gta",
      "--without-idb",
      "--without-ingres",
      "--without-jp2mrsid",
      "--without-kakadu",
      "--without-mrsid",
      "--without-mrsid_lidar",
      "--without-msg",
      "--without-oci",
      "--without-ogdi",
      "--without-podofo",
      "--without-rasdaman",
      "--without-sde",
      "--without-sosi",
    ]

    # Work around "Symbol not found: _curl_mime_addpart"
    # due to mismatched SDK version in Mojave.
    args << if MacOS.version == :mojave
      "--with-curl=#{Formula["curl"].opt_prefix}/bin/curl-config"
    else
      "--with-curl=/usr/bin/curl-config"
    end

    system "./configure", *args
    system "make"
    system "make", "install"

    system "make", "man" if build.head?
    # Force man installation dir: https://trac.osgeo.org/gdal/ticket/5092
    system "make", "install-man", "INST_MAN=#{man}"
    # Clean up any stray doxygen files
    Dir.glob("#{bin}/*.dox") { |p| rm p }
  end

  test do
    # basic tests to see if third-party dylibs are loading OK
    system "#{bin}/gdalinfo", "--formats"
    system "#{bin}/ogrinfo", "--formats"
  end
end
