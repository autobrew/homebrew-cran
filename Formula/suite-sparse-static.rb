class SuiteSparseStatic < Formula
  desc "Suite of Sparse Matrix Software"
  homepage "https://people.engr.tamu.edu/davis/suitesparse.html"
  url "https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/refs/tags/v5.10.1.tar.gz"
  sha256 "acb4d1045f48a237e70294b950153e48dce5b5f9ca8190e86c2b8c54ce00a7ee"
  license all_of: [
    "BSD-3-Clause",
    "LGPL-2.1-or-later",
    "GPL-2.0-or-later",
    "Apache-2.0",
    "GPL-3.0-only",
    any_of: ["LGPL-3.0-or-later", "GPL-2.0-or-later"],
  ]

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/autobrew/homebrew-cran/releases/download/suite-sparse-static-5.10.1"
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "9d12c651781bc77d6b29fb72fdd65433b06b03b6d6daa489b7e2720f80f0dd94"
    sha256 cellar: :any_skip_relocation, big_sur:       "78a1de5e34f0217f77a304f08e368d067ea9a6e1cf071a054c48645d63ff1a59"
    sha256 cellar: :any_skip_relocation, catalina:      "2ac7df3ed45f7cb40cf7e102532a9d1396a61e64713058e9cfc7429a45f1ff72"
  end

  depends_on "cmake" => :build
  depends_on "gmp" => :build
  depends_on "mpfr" => :build

  uses_from_macos "m4"

  def install
    args = [
      "INSTALL=#{prefix}",
      "BLAS=-framework Accelerate",
      "LAPACK=$(BLAS)",
      "CHOLMOD_CONFIG=-DNPARTITION",
      "CMAKE_OPTIONS=#{std_cmake_args.join(" ")}",
      "JOBS=#{ENV.make_jobs}",
    ]

    # Parallelism is managed through the `JOBS` make variable and not with `-j`.
    ENV.deparallelize
    system "make", "library", *args
    system "make", "install", *args
    rm_r(bin)
    rm_r(lib)
    lib.install Dir["**/*.a"]
    pkgshare.install "KLU/Demo/klu_simple.c"
  end

  test do
    system ENV.cc, "-o", "test", pkgshare/"klu_simple.c",
     "-L#{lib}", "-lsuitesparseconfig", "-lklu", "-lbtf", "-lcolamd", "-lamd"
    assert_predicate testpath/"test", :exist?
    assert_match "x [0] = 1", shell_output("./test")
  end
end
