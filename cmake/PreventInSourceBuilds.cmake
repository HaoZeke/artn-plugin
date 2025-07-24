# - Prevent in-source builds.
# https://stackoverflow.com/questions/1208681/with-cmake-how-would-you-disable-in-source-builds/

function(prevent_in_source_builds)
  get_filename_component(srcdir "${CMAKE_SOURCE_DIR}" REALPATH)
  get_filename_component(bindir "${CMAKE_BINARY_DIR}" REALPATH)

  if("${srcdir}" STREQUAL "${bindir}")
    message(FATAL_ERROR
      "\nIn-source builds are not allowed!\n"
      "Please create a separate build directory, e.g.:\n"
      "  mkdir build && cd build && cmake ..\n"
      "To clean up after this aborted in-place compilation:\n"
      "  rm -rf CMakeCache.txt CMakeFiles\n"
    )
  endif()
endfunction()

prevent_in_source_builds()