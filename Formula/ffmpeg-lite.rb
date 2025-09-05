class FfmpegLite < Formula
  desc "Play, record, convert, and stream audio and video"
  homepage "https://ffmpeg.org/"
  url "https://ffmpeg.org/releases/ffmpeg-8.0.tar.xz"
  sha256 "b2751fccb6cc4c77708113cd78b561059b6fa904b24162fa0be2d60273d27b8e"
  # None of these parts are used by default, you have to explicitly pass `--enable-gpl`
  # to configure to activate them. In this case, FFmpeg's license changes to GPL v2+.
  license "GPL-2.0-or-later"
  head "https://github.com/FFmpeg/FFmpeg.git", branch: "master"

  livecheck do
    url "https://ffmpeg.org/download.html"
    regex(/href=.*?ffmpeg[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/ffmpeg-lite-8.0"
    sha256 arm64_ventura: "2ca78adbb510072719166cf77f93073b2e2d24dbe93484f4599d994c16be8628"
    sha256 ventura:       "bbb7e97360c1bdccf41bd608472d252cd1bc5df4350b2b93d9a7fb8c893b0d37"
  end

  depends_on "pkg-config" => :build
  depends_on "lame"
  depends_on "libvorbis"
  depends_on "libvpx"
  depends_on "x264"
  depends_on "xvid"

  uses_from_macos "bzip2"
  uses_from_macos "libxml2"
  uses_from_macos "zlib"

  on_intel do
    depends_on "nasm" => :build
  end

  fails_with gcc: "5"

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-shared
      --enable-pthreads
      --enable-version3
      --enable-hardcoded-tables
      --cc=#{ENV.cc}
      --host-cflags=#{ENV.cflags}
      --host-ldflags=#{ENV.ldflags}
      --enable-ffplay
      --enable-gpl
      --enable-libmp3lame
      --enable-libvorbis
      --enable-libvpx
      --enable-libx264
      --enable-libxvid
      --disable-libjack
      --disable-indev=jack
    ]

    args += %w[--enable-videotoolbox --enable-audiotoolbox] if OS.mac?

    system "./configure", *args
    system "make", "install"

    # Build and install additional FFmpeg tools
    # system "make", "alltools"
    # bin.install Dir["tools/*"].select { |f| File.executable? f }

    # Fix for Non-executables that were installed to bin/
    # mv bin/"python", pkgshare/"python", force: true
  end

  test do
    # Create an example mp4 file
    mp4out = testpath/"video.mp4"
    system bin/"ffmpeg", "-filter_complex", "testsrc=rate=1:duration=1", mp4out
    assert_path_exists mp4out
  end
end
