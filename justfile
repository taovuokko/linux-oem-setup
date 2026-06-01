set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

build_dir := "build"

default:
    just --list

configure:
    cmake -S . -B {{build_dir}} -G Ninja -DCMAKE_BUILD_TYPE=Debug

build: configure
    cmake --build {{build_dir}}

run: build
    ./{{build_dir}}/src/gui/oem-setup-gui --mock

helper-check: build
    printf '{"displayName":"Matti Meikäläinen","username":"matti","locale":"fi_FI.UTF-8"}\n' | ./{{build_dir}}/src/helper/oem-setup-helper --validate-only

test: build
    ctest --test-dir {{build_dir}} --output-on-failure

check: build helper-check test

clean:
    cmake -E rm -rf {{build_dir}}
