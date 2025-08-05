message("SIESTA_PATH : ${SIESTA_PATH}")

## need mpi info
find_package(MPI REQUIRED Fortran)
if(NOT MPI_FOUND)
  message(FATAL_ERROR "MPI not found")
endif()

## need lua lib
find_package(Lua REQUIRED)
if(NOT LUA_FOUND)
  message(FATAL_ERROR "pARTn :: Lua library (liblua) needed for Siesta, not found.")
endif()


## locate CMakeCache
if( NOT EXISTS "${SIESTA_PATH}/CMakeCache.txt" )
  message(FATAL_ERROR "pARTn :: Incorrect Siesta build path (SIESTA_PATH): ${SIESTA_PATH}.")
endif()


## check if FLOOK is turned on
artn_get_string("SIESTA_WITH_FLOOK:BOOL" ${SIESTA_PATH}/CMakeCache.txt line )
string(REGEX MATCH ".+=(.+)" _match "${line}")
if( NOT "${CMAKE_MATCH_1}" STREQUAL "ON" )
  message(FATAL_ERROR "pARTn :: Siesta needs to be configured with -DSIESTA_WITH_FLOOK=ON")
endif()

## libpartn_lua.so library
add_library(partn_lua SHARED)
target_sources(partn_lua PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/Files_Siesta/partn_lua.f90
  ${CMAKE_CURRENT_SOURCE_DIR}/Files_Siesta/lua.f90 )

## need the mpi fortran libraries
target_link_libraries(partn_lua PUBLIC MPI::MPI_Fortran)
## link to artn lib
target_link_libraries( partn_lua PUBLIC artn )
## link lua lib
target_link_libraries(partn_lua PRIVATE ${LUA_LIBRARIES})


##
set_target_properties(partn_lua
  PROPERTIES CXX_STANDARD 11 CXX_STANDARD_REQUIRED ON
  Fortran_PREPROCESS ON Fortran_FORMAT FREE
  POSITION_INDEPENDENT_CODE ON LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

## copy libpartn_lua.so to Files_Siesta
## <TARGET_FILE:project> is full path name of target; and <TARGET_FILE_NAME:project> is just filename
add_custom_command(TARGET partn_lua POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy
  "$<TARGET_FILE:partn_lua>" "${CMAKE_CURRENT_SOURCE_DIR}/Files_Siesta/$<TARGET_FILE_NAME:partn_lua>")

