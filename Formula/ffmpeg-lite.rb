class FfmpegLite < Formula
  desc "Play, record, convert, and stream audio and video"
  homepage "https://ffmpeg.org/"
  # None of these parts are used by default, you have to explicitly pass `--enable-gpl`
  # to configure to activate them. In this case, FFmpeg's license changes to GPL v2+.
  license "GPL-2.0-or-later"
  head "https://github.com/FFmpeg/FFmpeg.git", branch: "master"

  stable do
    url "https://ffmpeg.org/releases/ffmpeg-6.0.tar.xz"
    sha256 "57be87c22d9b49c112b6d24bc67d42508660e6b718b3db89c44e47e289137082"

    # Fix bug in 6.0.0 with enable-hardcoded-tables
    patch do
      url "https://github.com/FFmpeg/FFmpeg/commit/814178f92647be2411516bbb82f48532373d2554.patch?full_index=1"
      sha256 "5e4e17e76d9fb045035064bed76812371136cbf3c86d2ddcaa98bd7c542cfcfa"
    end
  end

  livecheck do
    url "https://ffmpeg.org/download.html"
    regex(/href=.*?ffmpeg[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/ffmpeg-lite-6.0"
    sha256 arm64_big_sur: "5b5a39d041ac36b82bf623dd5b33ffe6e28c391506dd90da62ecacdf66980cad"
    sha256 ventura:       "9ea97312b8a06a0a97086ab5fa48e1197bad113e396d4c1acfb42526be74cca0"
    sha256 monterey:      "2605faa32021c83274d3f3393932a978ca36fe3a54b3f2a162c730e45d489f8c"
    sha256 big_sur:       "da4f4338d9cb17bb6a88d08beebe6832d701f2400e27c983fb0991e85f35ec07"
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
    assert_predicate mp4out, :exist?
  end
end
