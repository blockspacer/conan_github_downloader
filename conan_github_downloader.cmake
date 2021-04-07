#
# portable build script based on "cmake -P"
#
# example:
# cmake \
#   -DSCRIPT_PATH="$PWD/my_script.cmake"
#   -DEXTRA_CONAN_OPTS="--profile;default" \
#   -P tools/conan_github_downloader.cmake
#
# USAGE (Example contents of file -DSCRIPT_PATH="$PWD/my_script.cmake")
#
# if(NOT EXISTS "${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers")
#   git_clone("${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers"
#       "https://github.com/blockspacer/flex_support_headers.git"
#       "")
# endif()
# conan_build_target_if(
#   "flex_support_headers" # target to clean
#   "conan/stable"
#   "${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers" # target to build
#   ALWAYS_BUILD
#   "")
#
#
cmake_minimum_required(VERSION 3.5)

option(CLEAN_BUILD "CLEAN_BUILD" ON)
if(CLEAN_BUILD)
  message(WARNING "(conan_github_downloader)
    clean rebuild of all conan deps may take a lot of time.
    Use `CLEAN_BUILD=OFF` with `--build=missing` in `EXTRA_CONAN_OPTS`")
endif(CLEAN_BUILD)

# TODO: make local, not global
# allows to run `execute_process` without printing to console
option(PRINT_TO_STDOUT "PRINT_TO_STDOUT" ON)
if(PRINT_TO_STDOUT)
  set(OUTPUT_VARS ) # undefined
else()
  set(OUTPUT_VARS OUTPUT_VARIABLE stdout)
endif(PRINT_TO_STDOUT)

# --- includes ---
# WHY CMAKE_CURRENT_LIST_DIR? see https://stackoverflow.com/a/12854575/10904212
set(CURRENT_SCRIPT_DIR ${CMAKE_CURRENT_LIST_DIR})

#
# Colored print to terminal, uses "cmake_echo_color"
#
# WHY? see https://stackoverflow.com/a/36233927/10904212
# NOTE: if you print to file - disable "HAS_COLORED_OUTPUT"
#
# SUPPORTED COLORS: see https://github.com/Kitware/CMake/blob/master/Source/cmcmd.cxx#L1408
#
# options (only ON/OFF):
# * DISABLE_COLORED_OUTPUT
# * HAS_COLORED_OUTPUT
# vars:
# * TOGGLE_COLORED_OUTPUT ("true"/"false")
# * SHOW_ICONS (TRUE/FALSE)
# macros:
# * colored_print
# * colored_fatal
# * colored_ok
# * colored_warn
# * colored_notify

cmake_minimum_required(VERSION 3.5)

# switches to cmake message() system (preferred)
option(HAS_COLORED_OUTPUT "is running from terminal" ON)

if(HAS_COLORED_OUTPUT)
  # WHY CLICOLOR_FORCE? see https://stackoverflow.com/a/36233927/10904212
  set(COLORED_OUTPUT_ENABLER "${CMAKE_COMMAND}" "-E" "env" "CLICOLOR_FORCE=1")
else(HAS_COLORED_OUTPUT)
  set(COLORED_OUTPUT_ENABLER "")
endif(HAS_COLORED_OUTPUT)

# NOTE: not recommended, see HAS_COLORED_OUTPUT
option(DISABLE_COLORED_OUTPUT "full disable of output" OFF)

option(LOG_ALL_COLORED_OUTPUT "only for debug in-dev purposes" OFF)

# see "--switch=" at https://github.com/Kitware/CMake/blob/master/Source/cmcmd.cxx#L1395
set(TOGGLE_COLORED_OUTPUT "true")

set(SHOW_ICONS TRUE)
set(CROSS_ICON "✘")
set(OK_ICON "✔")
set(NOTIFY_ICON "(!)")
set(WARN_ICON "(!!!)")

# As of CMake 3.5, cmake_parse_arguments becomes a builtin command (written in C++ instead of CMake)
# include(CMakeParseArguments) is no longer required but, for now, the file CMakeParseArguments.cmake is kept empty for compatibility.
include(CMakeParseArguments)

# NOTE: not public implementation
#
# Function
#   colored_print_implementation(MESSAGE <...> (PARAMS <...>))
#
# Example:
#   colored_print_implementation(MESSAGE "hello world;13.,fga")
#   colored_print_implementation(MESSAGE "hello world;13.,fga" PARAMS --red --bold)
function(colored_print_implementation)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  #set(options ) # empty
  #set(oneValueArgs ) # empty
  set(multiValueArgs PARAMS MESSAGE )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(MESSAGE ${ARGUMENTS_MESSAGE})
  #
  set(PARAMS ${ARGUMENTS_PARAMS})
  #
  set(dependencies "")
  if(ARGUMENTS_DEPENDENCIES)
    set(dependencies ${ARGUMENTS_UNPARSED_ARGUMENTS})
  endif()
  #
  if(LOG_ALL_COLORED_OUTPUT)
    message(STATUS "Provided ARGN are:")
    foreach(src ${ARGN})
        message(STATUS "- ${src}")
    endforeach(src)
    message(STATUS "dependencies=${dependencies}")
    message(STATUS "MESSAGE=${MESSAGE}")
    message(STATUS "PARAMS=${PARAMS}")
  endif(LOG_ALL_COLORED_OUTPUT)
  #
  if(NOT DISABLE_COLORED_OUTPUT)
    if(HAS_COLORED_OUTPUT)
      execute_process(COMMAND
        ${COLORED_OUTPUT_ENABLER}
          # see https://github.com/Kitware/CMake/blob/master/Source/cmcmd.cxx#L1408
          ${CMAKE_COMMAND} -E cmake_echo_color ${PARAMS} --switch=${TOGGLE_COLORED_OUTPUT} "${MESSAGE}"
      )
    else(HAS_COLORED_OUTPUT)
      message(STATUS ${MESSAGE})
    endif(HAS_COLORED_OUTPUT)
  endif(NOT DISABLE_COLORED_OUTPUT)
endfunction()

# deprecated: can`t handle complex lists, see colored_print_implementation
# example: colored_print("hello world" --red --bold)
#macro(colored_print MESSAGE)
#  if(NOT DISABLE_COLORED_OUTPUT)
#    if(HAS_COLORED_OUTPUT)
#      execute_process(COMMAND
#        ${COLORED_OUTPUT_ENABLER}
#          # see https://github.com/Kitware/CMake/blob/master/Source/cmcmd.cxx#L1408
#          ${CMAKE_COMMAND} -E cmake_echo_color ${ARGN} --switch=${TOGGLE_COLORED_OUTPUT} ${MESSAGE}
#      )
#    else(HAS_COLORED_OUTPUT)
#      message(STATUS ${MESSAGE})
#    endif(HAS_COLORED_OUTPUT)
#  endif(NOT DISABLE_COLORED_OUTPUT)
#endmacro(colored_print)

# example: colored_print("hello world" --red --bold)
macro(colored_print MESSAGE)
  if(NOT DISABLE_COLORED_OUTPUT)
    colored_print_implementation(MESSAGE ${MESSAGE} PARAMS ${ARGN})
  endif(NOT DISABLE_COLORED_OUTPUT)
endmacro(colored_print)

# example: colored_fatal("hello world" --red --bold)
macro(colored_fatal MESSAGE)
  if(NOT DISABLE_COLORED_OUTPUT)
    if(SHOW_ICONS)
      colored_print_implementation(MESSAGE "${CROSS_ICON} " PARAMS --red --bold --no-newline)
    endif(SHOW_ICONS)
    colored_print_implementation(MESSAGE ${MESSAGE} PARAMS ${ARGN})
    message(FATAL_ERROR ${MESSAGE})
  endif(NOT DISABLE_COLORED_OUTPUT)
endmacro(colored_fatal)

# example: colored_ok("hello world" --green --bold)
macro(colored_ok MESSAGE)
  if(NOT DISABLE_COLORED_OUTPUT)
    if(SHOW_ICONS)
      colored_print_implementation(MESSAGE "${OK_ICON} " PARAMS --green --bold --no-newline)
    endif(SHOW_ICONS)
    colored_print_implementation(MESSAGE ${MESSAGE} PARAMS ${ARGN})
  endif(NOT DISABLE_COLORED_OUTPUT)
endmacro(colored_ok)

# example: colored_warn("hello world" --yellow --bold)
macro(colored_warn MESSAGE)
  if(NOT DISABLE_COLORED_OUTPUT)
    if(SHOW_ICONS)
      colored_print_implementation(MESSAGE "${WARN_ICON} " PARAMS --yellow --bold --no-newline)
    endif(SHOW_ICONS)
    colored_print_implementation(MESSAGE ${MESSAGE} PARAMS ${ARGN})
    message(WARNING ${MESSAGE})
  endif(NOT DISABLE_COLORED_OUTPUT)
endmacro(colored_warn)

# example: colored_notify("hello world" --yellow --bold)
macro(colored_notify MESSAGE)
  if(NOT DISABLE_COLORED_OUTPUT)
    if(SHOW_ICONS)
      colored_print_implementation(MESSAGE "${NOTIFY_ICON} " PARAMS --yellow --bold --no-newline)
    endif(SHOW_ICONS)
    colored_print_implementation(MESSAGE ${MESSAGE} PARAMS ${ARGN})
  endif(NOT DISABLE_COLORED_OUTPUT)
endmacro(colored_notify)

set(EXTRA_CONAN_OPTS "" CACHE STRING "conan arguments")
if(EXTRA_CONAN_OPTS STREQUAL "")
  message(FATAL_ERROR "(conan_github_downloader)
    provide EXTRA_CONAN_OPTS, see comments in .cmake file")
endif()

find_program(CONAN_PATH conan
             HINTS ${CONAN_DIR}
                   /usr/bin
                   /usr/local/bin
                   $ENV{PATH}
                   CMAKE_SYSTEM_PROGRAM_PATH)

if(NOT CONAN_PATH)
  message(FATAL_ERROR "conan not found! Aborting...")
endif() # NOT CONAN_PATH

macro(cmake_remove_directory DIR_PATH)
    message(STATUS "running `cmake_remove_directory` for ${PATH_URI}")
    execute_process(
      COMMAND
        ${COLORED_OUTPUT_ENABLER}
          ${CMAKE_COMMAND} "-E" "time" "cmake" "-E" "remove_directory" "${DIR_PATH}"
      WORKING_DIRECTORY ${CURRENT_SCRIPT_DIR}
      TIMEOUT 7200 # sec
      RESULT_VARIABLE retcode
      ERROR_VARIABLE stderr
      ${OUTPUT_VARS} # may create `stdout` variable
    )
    if(NOT "${retcode}" STREQUAL "0")
      message( FATAL_ERROR "(cmake_remove_directory ${DIR_PATH})
        Bad exit status ${retcode} ${stdout} ${stderr}")
    endif()
endmacro(cmake_remove_directory)

macro(cmake_make_dir DIR_PATH)
    message(STATUS "running `git clone` for ${PATH_URI}")
    execute_process(
      COMMAND
        ${COLORED_OUTPUT_ENABLER}
          ${CMAKE_COMMAND} "-E" "time" "cmake" "-E" "make_directory" "${DIR_PATH}"
      WORKING_DIRECTORY ${CURRENT_SCRIPT_DIR}
      TIMEOUT 7200 # sec
      RESULT_VARIABLE retcode
      ERROR_VARIABLE stderr
      ${OUTPUT_VARS} # may create `stdout` variable
    )
    if(NOT "${retcode}" STREQUAL "0")
      message( FATAL_ERROR "(cmake_make_dir)
        Bad exit status ${retcode} ${stdout} ${stderr}")
    endif()
endmacro(cmake_make_dir)

# NOTE: specify OPTIONS with ';' like "-b;v0.2.1"
macro(git_clone WORKING_DIRECTORY PATH_URI OPTIONS)
    message(STATUS "running `git clone` for ${PATH_URI}")
    execute_process(
      COMMAND
        ${COLORED_OUTPUT_ENABLER}
          ${CMAKE_COMMAND} "-E" "time" "git" "clone" ${PATH_URI} "${WORKING_DIRECTORY}" "--recursive" ${OPTIONS}
      WORKING_DIRECTORY ${CURRENT_SCRIPT_DIR}
      TIMEOUT 7200 # sec
      RESULT_VARIABLE retcode
      ERROR_VARIABLE stderr
      ${OUTPUT_VARS} # may create `stdout` variable
    )
    if(NOT "${retcode}" STREQUAL "0")
      message( FATAL_ERROR "(git_clone)
        Bad exit status ${retcode} ${stdout} ${stderr}")
    endif()
endmacro(git_clone)

macro(conan_remove_target TARGET_NAME)
  #
  message(STATUS "running `conan remove -f` for ${TARGET_NAME}")
  set(ENV{CONAN_REVISIONS_ENABLED} 1)
  set(ENV{CONAN_VERBOSE_TRACEBACK} 1)
  set(ENV{CONAN_PRINT_RUN_COMMANDS} 1)
  set(ENV{CONAN_LOGGING_LEVEL} 1)
  set(ENV{GIT_SSL_NO_VERIFY} 1)
  execute_process(
    COMMAND
      ${COLORED_OUTPUT_ENABLER}
        ${CMAKE_COMMAND} "-E" "time" "${CONAN_PATH}" "remove" ${TARGET_NAME} "-f"
    WORKING_DIRECTORY ${CURRENT_SCRIPT_DIR}
    TIMEOUT 7200 # sec
    RESULT_VARIABLE retcode
    ERROR_VARIABLE stderr
    ${OUTPUT_VARS} # may create `stdout` variable
  )
  if(NOT "${retcode}" STREQUAL "0")
    message( WARNING "(conan_remove_target)
      Bad exit status ${retcode} ${stdout} ${stderr}")
  endif()
endmacro(conan_remove_target)

macro(conan_install_target TARGET_PATH EXTRA_TARGET_OPTS)
  #
  if(NOT EXISTS "${TARGET_PATH}/conanfile.py" AND NOT EXISTS "${TARGET_PATH}/conanfile.txt")
    message(FATAL_ERROR "(conan_install_target)
      path not found: ${TARGET_PATH}/conanfile.py
      AND ${TARGET_PATH}/conanfile.txt")
  endif()
  #
  message(STATUS "running `conan install` for ${TARGET_PATH}")
  set(ENV{CONAN_REVISIONS_ENABLED} 1)
  set(ENV{CONAN_VERBOSE_TRACEBACK} 1)
  set(ENV{CONAN_PRINT_RUN_COMMANDS} 1)
  set(ENV{CONAN_LOGGING_LEVEL} 1)
  set(ENV{GIT_SSL_NO_VERIFY} 1)
  execute_process(
    COMMAND
      ${COLORED_OUTPUT_ENABLER}
        ${CMAKE_COMMAND} "-E" "time"
          "${CONAN_PATH}" "install" "." ${EXTRA_CONAN_OPTS} ${EXTRA_TARGET_OPTS}
    WORKING_DIRECTORY ${TARGET_PATH}
    TIMEOUT 7200 # sec
    RESULT_VARIABLE retcode
    ERROR_VARIABLE stderr
    ${OUTPUT_VARS} # may create `stdout` variable
  )
  if(NOT "${retcode}" STREQUAL "0")
    message( FATAL_ERROR "(conan_install_target)
      Bad exit status ${retcode} ${stdout} ${stderr}")
  endif()
endmacro(conan_install_target)

macro(conan_create_target TARGET_PATH TARGET_CHANNEL EXTRA_TARGET_OPTS)
  #
  if(NOT EXISTS "${TARGET_PATH}/conanfile.py" AND NOT EXISTS "${TARGET_PATH}/conanfile.txt")
    message(FATAL_ERROR "(conan_create_target)
      path not found: ${TARGET_PATH}/conanfile.py
      AND ${TARGET_PATH}/conanfile.txt")
  endif()
  #
  message(STATUS "running `conan create` for ${TARGET_PATH}")
  set(ENV{CONAN_REVISIONS_ENABLED} 1)
  set(ENV{CONAN_VERBOSE_TRACEBACK} 1)
  set(ENV{CONAN_PRINT_RUN_COMMANDS} 1)
  set(ENV{CONAN_LOGGING_LEVEL} 1)
  set(ENV{GIT_SSL_NO_VERIFY} 1)
  execute_process(
    COMMAND
      ${COLORED_OUTPUT_ENABLER}
        ${CMAKE_COMMAND} "-E" "time"
          "${CONAN_PATH}" "create" "." "${TARGET_CHANNEL}" ${EXTRA_CONAN_OPTS} ${EXTRA_TARGET_OPTS}
    WORKING_DIRECTORY ${TARGET_PATH}
    TIMEOUT 7200 # sec
    RESULT_VARIABLE retcode
    ERROR_VARIABLE stderr
    ${OUTPUT_VARS} # may create `stdout` variable
  )
  if(NOT "${retcode}" STREQUAL "0")
    message( FATAL_ERROR "(conan_create_target)
      Bad exit status ${retcode} ${stdout} ${stderr}")
  endif()
endmacro(conan_create_target)

macro(conan_build_target_if TARGET_NAME TARGET_CHANNEL TARGET_PATH OPTION_NAME EXTRA_TARGET_OPTS)
  if(NOT ${OPTION_NAME})
    message(STATUS "(conan_build_target_if)
      DISABLED: ${OPTION_NAME}")
  endif()

  if(${OPTION_NAME})
    if(CLEAN_BUILD)
      conan_remove_target(${TARGET_NAME})
    endif(CLEAN_BUILD)
    conan_install_target(${TARGET_PATH} "${EXTRA_TARGET_OPTS}")
    conan_create_target(${TARGET_PATH} ${TARGET_CHANNEL} "${EXTRA_TARGET_OPTS}")
  endif(${OPTION_NAME})
endmacro(conan_build_target_if)

# USAGE
#
# conan_build_target_if(
#   "flex_support_headers" # target to clean
#   "conan/stable"
#   "${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers" # target to build
#   ALWAYS_BUILD
#   "")
#
set(ALWAYS_BUILD TRUE CACHE BOOL "ALWAYS_BUILD")

# USAGE
#
# conan_build_target_if(
#   "flex_support_headers" # target to clean
#   "conan/stable"
#   "${CURRENT_SCRIPT_DIR}/.tmp/flex_support_headers" # target to build
#   NEVER_BUILD
#   "")
#
set(NEVER_BUILD FALSE CACHE BOOL "NEVER_BUILD")

# --- run `conan create` command ---

set(SCRIPT_PATH "" CACHE STRING "cmake script to run")
if(SCRIPT_PATH STREQUAL "")
  message(FATAL_ERROR "(conan_github_downloader)
    provide EXTRA_CONAN_OPTS, see comments in .cmake file")
endif()

include(${SCRIPT_PATH})
