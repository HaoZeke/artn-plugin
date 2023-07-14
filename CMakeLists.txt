cmake_minimum_required(VERSION 3.18)

# Define main project
project(pARTn LANGUAGES CXX C Fortran)

# set(CMAKE_VERBOSE_MAKEFILE ON)
# set(VERBOSE ON)

# cmake Project authors
set(AUTHOR "Eugene Sanscartier")
set(AUTHOR_DETAILS "")
set(DESCRIPTION "This is a cmake project that aim to ease compilation. pARTn is a library for transition state finding using activation and relaxation technique. ")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CXX_FLAGS)
    message(STATUS "Setting the build type to \"RelWithDebInfo\" as none was specified.")
    set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "Set the build type in this build tree." FORCE)

    # Possible values of build type in MLIP for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "RelWithDebInfo" "MinSizeRel")
endif(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CXX_FLAGS)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")
include(PreventInSourceBuilds)

# #####################################################################################################################
find_package(LAPACK REQUIRED)

if(LAPACK_FOUND)
    message(STATUS "Found LAPACK: TRUE")
endif(LAPACK_FOUND)

# #####################################################################################################################
option(BUILD_SHARED_LIBS "Build BUILD_SHARED_LIBS" ON)

option(WITH_LAMMPS "Build with/for LAMMPS" OFF)

option(WITH_QE "Build with/for QE" OFF)
set(qe_patch git apply --3way ${CMAKE_CURRENT_SOURCE_DIR}/Files_QE/qe.patch.git) # be carefull

# #####################################################################################################################
include(FetchContent)
set(FETCHCONTENT_QUIET FALSE)

# Here we get LAMMPS from git and add it to the project, default option/package are also set
FetchContent_Declare(LAMMPS_GIT
    GIT_REPOSITORY https://github.com/lammps/lammps.git
    GIT_TAG develop
    SOURCE_SUBDIR cmake
    GIT_PROGRESS ON
)
FetchContent_Declare(QE_GIT
    GIT_REPOSITORY https://gitlab.com/QEF/q-e.git
    GIT_TAG develop
    GIT_PROGRESS ON
    PATCH_COMMAND ${qe_patch}
)

if(WITH_LAMMPS AND NOT LAMMPS_ROOT)
    option(PKG_MANYBODY "Build LAMMPS PKG_MANYBODY" ON)
    option(PKG_PLUGIN "Build LAMMPS PKG_PLUGIN" ON)
    FetchContent_MakeAvailable(LAMMPS_GIT)
endif()

if(WITH_QE AND NOT QE_ROOT)
    set(QE_ENABLE_PLUGINS "legacy" CACHE INTERNAL "")
    FetchContent_MakeAvailable(QE_GIT)
endif()

# #####################################################################################################################
# Variour compilation options
string(TOUPPER ${CMAKE_BUILD_TYPE} type)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${type}}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${type}}")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${CMAKE_Fortran_FLAGS_${type}}")

# We can set here additional default Fortran_FLAGS here, its alwas possible to add flags by setting -D CMAKE_Fortran_FLAGS=... in terminal :):
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-0 -std=legacy") # -x f95-cpp-input

# #######################################################################################################################
add_library(partn SHARED)
target_link_libraries(partn ${LAPACK_LIBRARIES})

# #######################################################################################################################
set_target_properties(partn
    PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED ON
    Fortran_PREPROCESS ON
    Fortran_FORMAT FREE
    POSITION_INDEPENDENT_CODE ON
)

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/partn_modules)
set_target_properties(partn PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

add_subdirectory(src)

# #######################################################################################################################
# #######################################################################################################################
if(WITH_LAMMPS)
    add_subdirectory(Files_LAMMPS)

    if(LAMMPS_ROOT)
        include_directories(${LAMMPS_ROOT}/src)
        include_directories(${LAMMPS_ROOT})
    else()
        include_directories(${lammps_git_SOURCE_DIR}/src)
        include_directories(${lammps_git_SOURCE_DIR})
        target_link_libraries(lammps PRIVATE partn)
        set_target_properties(lammps PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

        install(TARGETS partn EXPORT LAMMPS_Targets)
    endif()
endif()

if(WITH_QE)
    target_link_libraries(qe_pw PRIVATE partn)
    set_target_properties(qe_pw_exe PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

    install(TARGETS partn EXPORT qeTargets)
endif()

# #######################################################################################################################
# #######################################################################################################################
