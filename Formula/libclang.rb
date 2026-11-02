class Libclang < Formula
  desc "C interface to the Clang compiler frontend"
  homepage "https://clang.llvm.org/docs/LibClang.html"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.2/llvm-project-23.1.2.src.tar.xz"
  sha256 "c98bbef08a2b4c2613cd50e9aa9ae7b69b1fe6c16b2c40373bc0ab6116fdf78a"
  license "Apache-2.0" => { with: "LLVM-exception" }

  livecheck do
    url :stable
    regex(/^llvmorg[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  keg_only "it conflicts with `llvm`"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  uses_from_macos "python" => :build

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

    # Only build libclang and the clang/llvm static libraries that it needs
    args = %w[
      -DLLVM_ENABLE_PROJECTS=clang
      -DLLVM_TARGETS_TO_BUILD=AArch64;X86
      -DLLVM_BUILD_LLVM_DYLIB=OFF
      -DLLVM_LINK_LLVM_DYLIB=OFF
      -DLLVM_ENABLE_ZLIB=OFF
      -DLLVM_ENABLE_ZSTD=OFF
      -DLLVM_ENABLE_LIBXML2=OFF
      -DLLVM_ENABLE_LIBEDIT=OFF
      -DLLVM_ENABLE_FFI=OFF
      -DLLVM_ENABLE_BINDINGS=OFF
      -DLLVM_INCLUDE_BENCHMARKS=OFF
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_INCLUDE_EXAMPLES=OFF
      -DLLVM_INCLUDE_TESTS=OFF
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DCLANG_ENABLE_STATIC_ANALYZER=OFF
      -DCLANG_ENABLE_OBJC_REWRITER=OFF
      -DCLANG_INCLUDE_DOCS=OFF
      -DCLANG_INCLUDE_TESTS=OFF
      -DCLANG_PLUGIN_SUPPORT=OFF
      -DLIBCLANG_BUILD_STATIC=ON
    ]
    system "cmake", "-S", "llvm", "-B", "build", "-G", "Ninja", *args, *std_cmake_args
    system "cmake", "--build", "build", "--target", "libclang", "libclang_static", "clang-resource-headers"

    # The upstream libclang.a only has the libclang objects. We prelink it with all
    # clang and llvm libraries into a single object that only exports the C API, so
    # the static lib is self-contained and does not export llvm C++ symbols.
    (buildpath/"libclang_exports.txt").write "_clang_*\n"
    # NB: the build also creates an empty build/lib/liblibclang_static.a stamp file
    deps = Dir["build/lib/lib{LLVM,clang[A-Z]}*.a"]
    system ENV.cc, "-r", "-nostdlib", "-o", "libclang_prelinked.o",
           "-Wl,-exported_symbols_list,libclang_exports.txt",
           "-Wl,-force_load,build/lib/libclang.a", *deps
    lib.mkpath
    system "ar", "rcs", lib/"libclang.a", "libclang_prelinked.o"

    # Install the libclang headers and the clang builtin headers (stddef.h etc.)
    # which must be passed to libclang via -resource-dir when linking statically.
    %w[libclang-headers clang-resource-headers].each do |component|
      system "cmake", "--install", "build", "--component", component
    end
  end

  def caveats
    <<~EOS
      When linking libclang statically, it cannot find its builtin headers by itself.
      Pass these arguments to clang_parseTranslationUnit():
        -resource-dir #{opt_lib}/clang/#{version.major}
    EOS
  end

  test do
    (testpath/"test.h").write <<~EOS
      #include <stddef.h>
      #include <stdint.h>
      typedef struct { int32_t x; size_t len; } point;
      int add(int a, int b);
    EOS
    (testpath/"test.c").write <<~EOS
      #include <clang-c/Index.h>
      #include <stdio.h>
      #include <string.h>

      static enum CXChildVisitResult visit(CXCursor c, CXCursor parent, CXClientData data) {
        if (clang_getCursorKind(c) == CXCursor_FunctionDecl) {
          CXString name = clang_getCursorSpelling(c);
          if (strcmp(clang_getCString(name), "add") == 0) (*(int *)data)++;
          clang_disposeString(name);
        }
        return CXChildVisit_Continue;
      }

      int main(int argc, char **argv) {
        CXString version = clang_getClangVersion();
        printf("%s\\n", clang_getCString(version));
        clang_disposeString(version);
        CXIndex index = clang_createIndex(0, 1);
        CXTranslationUnit tu = clang_parseTranslationUnit(index, argv[1],
          (const char *[]){"-isysroot", argv[2], "-resource-dir", argv[3]}, 4, NULL, 0, CXTranslationUnit_None);
        if (!tu) return 1;
        int errors = 0;
        for (unsigned i = 0; i < clang_getNumDiagnostics(tu); i++) {
          CXDiagnostic d = clang_getDiagnostic(tu, i);
          if (clang_getDiagnosticSeverity(d) >= CXDiagnostic_Error) errors++;
          clang_disposeDiagnostic(d);
        }
        int found = 0;
        clang_visitChildren(clang_getTranslationUnitCursor(tu), visit, &found);
        clang_disposeTranslationUnit(tu);
        clang_disposeIndex(index);
        return errors > 0 || found != 1;
      }
    EOS
    system ENV.cc, "test.c", "-o", "test", "-I#{include}", "#{lib}/libclang.a", "-lc++"
    resource_dir = lib/"clang/#{version.major}"
    assert_match "clang version #{version}", shell_output("./test test.h #{MacOS.sdk_path} #{resource_dir}")

    # Only the libclang C API may be exported, not the llvm C++ symbols
    exported = shell_output("nm -gU #{lib}/libclang.a").lines.grep(/ [TDS] /)
    refute_empty exported
    assert_empty exported.grep_v(/ _clang_/)
  end
end
