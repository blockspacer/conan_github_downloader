# About

CMake script that downloads and builds conan packages from github using provided options.

## Where to store `SCRIPT_PATH` file?

Best practices is to create `get_conan_dependencies.cmake` file near `conanfile.py` (or near `conanfile.txt`).

`get_conan_dependencies.cmake` file must contain cmake code that creates all dependencies i.e. it does not auto-detect dependencies of dependencies.

That will allow to continue working even if `ConanCenter` server goes down.

## Why build from sources

Some people do not like to install binaries.

If you think that it is beneficial to build software from sources - you may prefer `conan_github_downloader`

[Gentoo answer why build from sources](https://wiki.gentoo.org/wiki/Why_build_from_sources)

## How it works

`conan_github_downloader.cmake` includes script provided by `SCRIPT_PATH`.

Use `cmake -P` to run `conan_github_downloader.cmake`:

```bash
cmake \
  -DSCRIPT_PATH="$PWD/my_script.cmake" \
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

Now you can run commands that can clone git repo, remove old conan package and create new package.

Example with best practices:

```cmake
set(ENABLE_CPPCHECK TRUE CACHE BOOL "ENABLE_CPPCHECK")
if(ENABLE_CPPCHECK
  AND NOT EXISTS "${CURRENT_SCRIPT_DIR}/.tmp/conan-cppcheck_installer")
  git_clone("${CURRENT_SCRIPT_DIR}/.tmp/conan-cppcheck_installer"
      "https://github.com/bincrafters/conan-cppcheck_installer.git"
      "-b;testing/1.90")
endif()
#
set(CLEAN_CPPCHECK FALSE CACHE BOOL "CLEAN_CPPCHECK")
if(ENABLE_CPPCHECK AND CLEAN_CPPCHECK)
  conan_remove_target(conan-cppcheck_installer)
endif()
#
conan_build_target_if(
  "conan-cppcheck_installer" # target to clean
  "conan/stable"
  "${CURRENT_SCRIPT_DIR}/.tmp/conan-cppcheck_installer" # target to build
  ENABLE_CPPCHECK
  "")
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

Example below removes conan package if `conan search` succeeded:

```cmake
# Runs `conan search` command i.e.
# conan search cppcheck_installer/master@conan/stable \
#   -q "compiler=clang OR compiler=gcc"
conan_search(
  TARGET "conan-cppcheck_installer/master@conan/stable"
  RESULT_VAR_NAME cppcheck_installer_EXISTS
  VERBOSE TRUE
  QUERY -q "compiler=clang OR compiler=gcc"
)
if(cppcheck_installer_EXISTS)
  conan_remove_target(conan-cppcheck_installer)
endif()
```

## Motivation

Events similar to `Bintray Sunset` may happen any day, see https://blog.conan.io/2021/03/31/Bintray-sunset-timeline.html

## About `CLEAN_BUILD` option

If can pass `-DCLEAN_BUILD=ON` than all conan packages from `SCRIPT_PATH` will be re-created (i.e. will run `conan remove` before `conan create`)

```bash
cmake \
  -DSCRIPT_PATH="$PWD/integration_tests/integration_test.cmake" \
  -DEXTRA_CONAN_OPTS="--profile;clang\
;-s;build_type=Debug\
;--build;missing" \
  -DCLEAN_BUILD=ON \
  -P conan_github_downloader.cmake
```

## Alternatives

See https://stackoverflow.com/q/62261869

## (for contibutors) Integration tests

Run tests before pull requests:

```bash
cmake \
  -DSCRIPT_PATH="$PWD/integration_tests/integration_test.cmake" \
  -DEXTRA_CONAN_OPTS="--profile;clang\
;-s;build_type=Debug\
;--build;missing" \
  -P conan_github_downloader.cmake
```
