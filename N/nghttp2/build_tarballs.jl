# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nghttp2"
version = v"1.48.0"

# Collection of sources required to build LibCURL
sources = [
    ArchiveSource("https://github.com/nghttp2/nghttp2/releases/download/v$(version)/nghttp2-$(version).tar.xz",
                  "47d8f30ee4f1bc621566d10362ca1b3ac83a335c63da7144947c806772d016e4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nghttp2-*

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --enable-lib-only
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libnghttp2", :libnghttp2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
