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

find_package(BLAS)

# #####################################################################################################################
option(BUILD_SHARED_LIBS "Build BUILD_SHARED_LIBS" ON)

option(WITH_LAMMPS "Build with/for LAMMPS" OFF)
option(WITH_QE "Build with/for QE" OFF)
option(WITH_SIESTA "Build with/for SIESTA" OFF)

# #####################################################################################################################
include(FetchContent)
set(FETCHCONTENT_QUIET FALSE)

# Here we get LAMMPS from git and add it to the project, default option/package are also set
FetchContent_Declare(QE_GIT GIT_REPOSITORY https://gitlab.com/QEF/q-e.git GIT_TAG develop GIT_SHALLOW 1 GIT_PROGRESS ON)

# #####################################################################################################################
# Variour compilation options
string(TOUPPER ${CMAKE_BUILD_TYPE} type)

# We can set here additional FLAGS here, its alwas possible to add flags by setting -D CMAKE_Fortran_FLAGS=... in terminal :):
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${type}}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${type}}")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${CMAKE_Fortran_FLAGS_${type}}")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-0 -std=legacy") # -x f95-cpp-input

# #######################################################################################################################
add_library(artn SHARED)
target_link_libraries(artn ${LAPACK_LIBRARIES})

# #######################################################################################################################
set_target_properties(artn PROPERTIES CXX_STANDARD 17 Fortran_PREPROCESS ON Fortran_FORMAT FREE POSITION_INDEPENDENT_CODE ON)

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/artn_modules)
set_target_properties(artn PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

add_subdirectory(src)

# #######################################################################################################################
# #######################################################################################################################
# # execute_process(COMMAND git rev-parse --abbrev-ref HEAD OUTPUT_VARIABLE git_branch)
# execute_process(COMMAND echo "#define ARTN_INFO_GIT_BRANCH \"${git_branch}\"" COMMAND tee ${CMAKE_CURRENT_SOURCE_DIR}/src/artn_gitinfo.h)
# # execute_process(COMMAND git rev-parse --short=7 HEAD OUTPUT_VARIABLE git_commit)
# execute_process(COMMAND echo "#define ARTN_INFO_GIT_COMMIT \"${git_commit}\"" COMMAND tee --append ${CMAKE_CURRENT_SOURCE_DIR}/src/artn_gitinfo.h)
execute_process(COMMAND echo "#define ARTN_INFO_GIT_BRANCH \"(unknown)\"" COMMAND tee ${CMAKE_CURRENT_SOURCE_DIR}/src/artn_gitinfo.h)
execute_process(COMMAND echo "#define ARTN_INFO_GIT_COMMIT \"(unknown)\"" COMMAND tee --append ${CMAKE_CURRENT_SOURCE_DIR}/src/artn_gitinfo.h)

# execute_process(COMMAND sed "{:q;N;s/\\n//g;t q}" ${CMAKE_CURRENT_SOURCE_DIR}/src/artn_gitinfo.h)
if(WITH_LAMMPS)
    add_subdirectory(Files_LAMMPS)

    if(LAMMPS_ROOT)
        include_directories(${LAMMPS_ROOT}/src)
        include_directories(${LAMMPS_ROOT})
    else()
        FetchContent_Declare(LAMMPS_GIT GIT_REPOSITORY https://github.com/lammps/lammps.git GIT_TAG develop GIT_SHALLOW 1 SOURCE_SUBDIR cmake GIT_PROGRESS ON)
        option(PKG_MANYBODY "Build LAMMPS PKG_MANYBODY" ON)
        option(PKG_PLUGIN "Build LAMMPS PKG_PLUGIN" ON)
        FetchContent_MakeAvailable(LAMMPS_GIT)
        include_directories(${lammps_git_SOURCE_DIR}/src)
        include_directories(${lammps_git_SOURCE_DIR})
        target_link_libraries(lammps PRIVATE artn)
        set_target_properties(lammps PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

        install(TARGETS artn EXPORT LAMMPS_Targets)
    endif()
endif()

if(WITH_QE)
    if(QE_ROOT)
        if(QE_MAKE) # for make
            execute_process(COMMAND echo "LIBOBJS += ${CMAKE_BINARY_DIR}/libartn.so" COMMAND tee --append ${QE_ROOT}/make.inc) # you must run config of qe with make
            execute_process(COMMAND echo "QELIBS += ${CMAKE_BINARY_DIR}/libartn.so" COMMAND tee --append ${QE_ROOT}/make.inc) # you must run config of qe with make

            add_custom_command(TARGET artn POST_BUILD COMMAND make pw WORKING_DIRECTORY ${QE_ROOT} COMMENT "       Building/Rebuild target pw...")
        else() # for cmake
            execute_process(COMMAND echo "target_link_libraries(qe_pw PRIVATE ${CMAKE_BINARY_DIR}/libartn.so)" COMMAND tee --append ${QE_ROOT}/PW/CMakeLists.txt) # nothing to do here
        endif()

        # cp ${QE_PATH}/PW/src/plugin_ext_forces.f90 $(ART_PATH)/Files_QE
        # execute_process(COMMAND cp ${QE_ROOT}/PW/src/plugin_ext_forces.f90 ${CMAKE_CURRENT_SOURCE_DIR}/Files_QE/plugin_ext_forces.f90)

        # cat $(ART_PATH)/Files_QE/PW-src-modified/plugin_ext_forces.f90 > ${QE_PATH}/PW/src/plugin_ext_forces.f90
        execute_process(COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/Files_QE/PW-src-modified/plugin_ext_forces.f90 ${QE_ROOT}/PW/src/plugin_ext_forces.f90)

        if(QE_CMAKE)
            add_custom_command(TARGET artn POST_BUILD COMMAND cmake --build . --target pw WORKING_DIRECTORY ${QE_ROOT}/${QE_CMAKE} COMMENT "       Building/Rebuild target pw...")
        elseif(NOT QE_MAKE)
            message(WARNING "Eider set QE_CMAKE path to the cmake build directory inside QE_ROOT (e.g. -DQE_CMAKE=build) or rebuild QE manualy after building this project")
        endif()

    # message("Build pARTn library, then build pw. If you want to build QE with make run QE configuration command before this cmake configuration (or run again afterwards this cmake configuration)")
    else()
        set(QE_ENABLE_PLUGINS "legacy" CACHE INTERNAL "")
        FetchContent_MakeAvailable(QE_GIT)

        execute_process(COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/Files_QE/plugin_ext_forces.f90 ${qe_git_SOURCE_DIR}/PW/src/plugin_ext_forces.f90)
        target_link_libraries(qe_pw PRIVATE artn)
        set_target_properties(qe_pw_exe PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

        install(TARGETS artn EXPORT qeTargets)
    endif()
endif()

# if(WITH_SIESTA)
# add_library(partn_lua SHARED)
# target_sources(partn_lua PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Files_Siesta/partn_lua.f90 ${CMAKE_CURRENT_SOURCE_DIR}/Files_Siesta/lua.f90)
# set_target_properties(partn_lua PROPERTIES CXX_STANDARD 11 CXX_STANDARD_REQUIRED ON Fortran_PREPROCESS ON Fortran_FORMAT FREE POSITION_INDEPENDENT_CODE ON)

# if(SIESTA_ROOT)
# else()
# FetchContent_Declare(SIESTA_GIT GIT_REPOSITORY https://gitlab.com/siesta-project/siesta.git GIT_TAG dev GIT_SHALLOW 1 GIT_PROGRESS ON)
# # add_subdirectory(Files_SIESTA)

# target_link_libraries(qe_pw PRIVATE artn)
# endif()
# endif()

# #######################################################################################################################
# #######################################################################################################################
