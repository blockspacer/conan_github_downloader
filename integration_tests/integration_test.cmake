conan_search(
  TARGET "dfsfdsdf/dsffsdfsdf@conan/stable"
  RESULT_VAR_NAME dummy_EXISTS
  VERBOSE TRUE
  QUERY -q "compiler=clang OR compiler=gcc"
)
if(dummy_EXISTS)
  message(FATAL_ERROR "dummy EXISTS")
endif()
