# About

CMake script that downloads and builds conan packages from github using provided options.

## How it works

`conan_github_downloader.cmake` includes script provided by `SCRIPT_PATH`.

Use `cmake -P` to run `conan_github_downloader.cmake`:

```bash
cmake \
  -DSCRIPT_PATH="$PWD/my_script.cmake"
  -DEXTRA_CONAN_OPTS="--profile;default" \
  -P tools/conan_github_downloader.cmake
```

You can provide multiple conan options:

```bash
cmake \
  -DSCRIPT_PATH="$PWD/get_conan_dependencies.cmake"\
  -DEXTRA_CONAN_OPTS="--profile;clang\
;-s;build_type=Debug\
;-s;cling_conan:build_type=Release\
;-s;llvm_tools:build_type=Release\
;--build;missing" \
  -P ~/conan_github_downloader/conan_github_downloader.cmake
```

## About `SCRIPT_PATH` file contents

First, create directory where `git` repos must be cloned:

```cmake
if(EXISTS "${CURRENT_SCRIPT_DIR}/.tmp")
  cmake_remove_directory("${CURRENT_SCRIPT_DIR}/.tmp")
endif()

cmake_make_dir("${CURRENT_SCRIPT_DIR}/.tmp")
```

Example below clones git repo and creates conan package:

```cmake
if(NOT EXISTS "${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers")
  git_clone("${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers"
      "https://github.com/blockspacer/flex_support_headers.git"
      "")
endif()
conan_build_target_if(
  "flex_support_headers" # target to clean
  "conan/stable"
  "${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers" # target to build
  ALWAYS_BUILD
  "")
```

Example below clones git repo branch "testing/1.90" and creates conan package if `ENABLE_CPPCHECK` is `TRUE`:

```cmake
set(ENABLE_CPPCHECK TRUE CACHE BOOL "ENABLE_CPPCHECK")
if(ENABLE_CPPCHECK
  AND NOT EXISTS "${CURRENT_SCRIPT_DIR}/.tmp/conan-cppcheck_installer")
  git_clone("${CURRENT_SCRIPT_DIR}/.tmp/conan-cppcheck_installer"
      "https://github.com/bincrafters/conan-cppcheck_installer.git"
      "-b;testing/1.90")
endif()
conan_build_target_if(
  "conan-cppcheck_installer" # target to clean
  "conan/stable"
  "${CURRENT_SCRIPT_DIR}/.tmp/conan-cppcheck_installer" # target to build
  ENABLE_CPPCHECK
  "")
```

## Motivation

Events similar to `Bintray Sunset` may happen any day, see https://blog.conan.io/2021/03/31/Bintray-sunset-timeline.html

## Alternatives

See https://stackoverflow.com/q/62261869
