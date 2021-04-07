# About

CMake script that downloads and builds conan packages from github.


## How it works

`conan_github_downloader.cmake` includes script provided by `SCRIPT_PATH`.

Use `cmake -P` to run `conan_github_downloader.cmake`:

```bash
cmake \
  -DSCRIPT_PATH="$PWD/my_script.cmake"
  -DEXTRA_CONAN_OPTS="--profile;default" \
  -P tools/conan_github_downloader.cmake
```

## About `SCRIPT_PATH` file contents

Clones git repo and creates conan package:

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

Clones git repo branch "testing/1.90" and creates conan package if `ENABLE_CPPCHECK` is `TRUE`:

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
