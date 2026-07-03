#! /bin/bash

OS=$1
ESY_LIBJPEG_TURBO_PREFIX=$2

if [[ "$(python3 -V 2>&1)" =~ "Python 3" ]]
then
    PYTHON_BINARY="python3"
elif [[ "$(python -V 2>&1)" =~ "Python 3" ]]
then
    PYTHON_BINARY="python"
elif [[ "$(python -V 2>&1)" =~ "Python 2" ]]
then
    PYTHON_BINARY="python"
elif [[ "$(python2 -V 2>&1)" =~ "Python 2" ]]
then
    PYTHON_BINARY="python2"
else
    echo "esy-skia requires Python to be available in your PATH."
    exit -1
fi

# Define cache directory
if [[ $OS == "windows" ]]; then
    CACHE_DIR="${TEMP:-/tmp}/esy-skia-build-cache/$OS"
else
    CACHE_DIR="/tmp/esy-skia-build-cache-$(whoami)/$OS"
fi

# Check if cache exists and we are not forcing a rebuild
if [ -z "$ESY_SKIA_REBUILD" ] && [ -z "$ESY_SKIA_SCRATCH" ]; then
    FOUND_CACHE=""
    if [ "$OS" = "windows" ]; then
        # Check candidate locations on Windows
        for dir in "$CACHE_DIR" "/tmp/esy-skia-build-cache/$OS" "/tmp/esy-skia" "/tmp"; do
            if [ -f "$dir/skia.dll" ] && [ -f "$dir/libskia.a" ]; then
                echo "esy-skia: Using cached build from $dir"
                mkdir -p "$cur__target_dir/out/Shared"
                cp "$dir/skia.dll" "$cur__target_dir/out/Shared/skia.dll"
                cp "$dir/skia.def" "$cur__target_dir/out/Shared/skia.def" 2>/dev/null || true
                cp "$dir/libskia.a" "$cur__target_dir/out/Shared/libskia.a"
                FOUND_CACHE="true"
                break
            fi
        done
        if [ "$FOUND_CACHE" = "true" ]; then
            exit 0
        fi
    else
        # Check candidate locations on Darwin / Linux
        for dir in "$CACHE_DIR" "/tmp/esy-skia-build-cache/$OS" "/tmp/esy-skia" "/tmp"; do
            if [ -f "$dir/libskia.a" ]; then
                echo "esy-skia: Using cached build from $dir"
                mkdir -p "$cur__target_dir/out/Static"
                cp "$dir/libskia.a" "$cur__target_dir/out/Static/libskia.a"
                FOUND_CACHE="true"
                break
            fi
        done
        if [ "$FOUND_CACHE" = "true" ]; then
            exit 0
        fi
    fi
fi

if [[ $OS == "windows" ]]
then
    # If we are told to build from scratch, do so.
    if [[ -n "$ESY_SKIA_SCRATCH" ]]
    then
        $PYTHON_BINARY tools/git-sync-deps
        ln -s third_party/externals/gyp tools/gyp
        WINDOWS_PYTHON_PATH="$(cygpath -w $(which $PYTHON_BINARY))"
        bin/gn gen $cur__target_dir/out/Shared --script-executable="$WINDOWS_PYTHON_PATH" --args='is_debug=false is_component_build=true esy_skia_enable_svg=true skia_use_partition_alloc=false skia_use_icu=false skia_use_perfetto=false' || exit -1
        ninja.exe -C $cur__target_dir/out/Shared skia
        mv $cur__target_dir/out/Shared/libskia.dll $cur__target_dir/out/Shared/skia.dll
    else
        mkdir -p $cur__target_dir/out/Shared/ 
        cp prebuilt/windows/skia.dll $cur__target_dir/out/Shared/skia.dll
    fi
    esy/gendef.exe - $cur__target_dir/out/Shared/skia.dll > $cur__target_dir/out/Shared/skia.def
    x86_64-W64-mingw32-dlltool.exe -D $cur__target_dir/out/Shared/skia.dll -d $cur__target_dir/out/Shared/skia.def -A -l $cur__target_dir/out/Shared/libskia.a

    # Cache the outputs
    mkdir -p "$CACHE_DIR"
    cp "$cur__target_dir/out/Shared/skia.dll" "$CACHE_DIR/skia.dll"
    cp "$cur__target_dir/out/Shared/skia.def" "$CACHE_DIR/skia.def"
    cp "$cur__target_dir/out/Shared/libskia.a" "$CACHE_DIR/libskia.a"
else
    # Only use prebuilt if we are on darwin
    if [ "$OS" = "darwin" ] && [ -n "$ESY_SKIA_PREBUILT" ] && [ -f "$ESY_SKIA_PREBUILT" ]; then
        echo "esy-skia: Using prebuilt libskia.a at $ESY_SKIA_PREBUILT, skipping compilation."
        mkdir -p "$cur__target_dir/out/Static"
        cp "$ESY_SKIA_PREBUILT" "$cur__target_dir/out/Static/libskia.a"
    else
        $PYTHON_BINARY tools/git-sync-deps
        if [ ! -L tools/gyp ] && [ ! -d tools/gyp ]; then
            ln -s third_party/externals/gyp tools/gyp
        fi

        CC=clang
        CXX=clang++
        if ! [ -x "$(command -v clang++)" ]; then
            echo "Manually activating llvm toolset 7.0..."
            source /opt/rh/llvm-toolset-7.0/enable
            CC="clang --gcc-toolchain=/usr/lib/gcc/x86_64-redhat-linux/4.8.5 -stdlib=libstdc++"
            CXX="clang++ --gcc-toolchain=/usr/lib/gcc/x86_64-redhat-linux/4.8.5 -I/usr/include/c++/4.8.5 -I/usr/include/c++/4.8.5/x86_64-redhat-linux -std=c++11 -stdlib=libstdc++"
            echo "-- clang version:"
            $CC -v
            echo "-- clang++ version:"
            $CXX -v
        else
            echo "llvm toolset-7.0 does not need to be manually activated"
        fi

        bin/gn gen $cur__target_dir/out/Static --script-executable="$PYTHON_BINARY" "--args=cc=\"$CC\" cxx=\"$CXX\" skia_use_system_libjpeg_turbo=true esy_skia_enable_svg=true is_debug=false skia_use_partition_alloc=false skia_use_icu=false skia_use_perfetto=false extra_cflags=[\"-I${ESY_LIBJPEG_TURBO_PREFIX}/include\"] extra_ldflags=[\"-L${ESY_LIBJPEG_TURBO_PREFIX}/lib\", \"-ljpeg\" ]" || exit -1
        ninja.exe -C $cur__target_dir/out/Static skia || exit -1
    fi

    # Cache the outputs
    mkdir -p "$CACHE_DIR"
    cp "$cur__target_dir/out/Static/libskia.a" "$CACHE_DIR/libskia.a"
fi
