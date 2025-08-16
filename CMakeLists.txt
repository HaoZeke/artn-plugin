cmake_minimum_required(VERSION 3.20)

# Define main project
project(pARTn LANGUAGES CXX C Fortran)

# set(CMAKE_VERBOSE_MAKEFILE ON)
# set(VERBOSE ON)

# cmake Project authors
set(AUTHOR "Eugene Sanscartier")
set(AUTHOR_DETAILS "")
set(DESCRIPTION
    "This is a cmake project that aim to ease compilation. pARTn is a library for transition state finding using activation and relaxation technique. "
)

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CXX_FLAGS)
    set(CMAKE_BUILD_TYPE
        RelWithDebInfo
        CACHE STRING
        "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
        FORCE
    )
endif(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CXX_FLAGS)
string(TOUPPER "${CMAKE_BUILD_TYPE}" BTYPE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
include(PreventInSourceBuilds)
include(partnHelpers)

## directory artn_root/lib
set(artn_libpath "${CMAKE_CURRENT_SOURCE_DIR}/lib")

# ##################################################################################################################

# This is needed only when using AppleClang with gfortran compilers, since Apple forget to add some path
if(
    APPLE
    AND NOT IOS
    AND (
        CMAKE_C_COMPILER_ID STREQUAL "AppleClang"
        OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
    )
    AND CMAKE_Fortran_COMPILER_ID STREQUAL "GNU"
)
    # message(STATUS "This is macOS")
    # For some reason these are not automaticaly appened to the link directory
    execute_process(
        COMMAND gfortran --print-search-dirs
        OUTPUT_VARIABLE GFORTRAN_SEARCH_DIRS
    )
    string(REGEX MATCH "libraries: *=([^\r\n]+)" _ "${GFORTRAN_SEARCH_DIRS}")
    set(GFORTRAN_LIB_DIRS "${CMAKE_MATCH_1}")
    string(REPLACE ":" ";" GFORTRAN_LIB_DIRS "${GFORTRAN_LIB_DIRS}")

    message(STATUS "GFORTRAN_LIB_DIRS ${GFORTRAN_LIB_DIRS}")

    foreach(GFORTRAN_LIB_DIR ${GFORTRAN_LIB_DIRS})
        if(EXISTS "${GFORTRAN_LIB_DIR}") # There is a little bit of junck in GFORTRAN_SEARCH_DIRS
            link_directories("${GFORTRAN_LIB_DIR}")
        endif()
    endforeach()
endif()

# #################################################################################################################
find_package(LAPACK REQUIRED)
if(LAPACK_FOUND)
    message(STATUS "Found LAPACK: TRUE")
endif(LAPACK_FOUND)

# ###################################################################################################################
option(BUILD_SHARED_LIBS "Build BUILD_SHARED_LIBS" ON)

option(WITH_LAMMPS "Build with/for LAMMPS" OFF)
option(WITH_QE "Build with/for QE" OFF)
option(WITH_SIESTA "Build with/for SIESTA" OFF)

# ##################################################################################################################
include(FetchContent)
set(FETCHCONTENT_QUIET FALSE)

# #################################################################################################################
if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    add_compile_options($<$<COMPILE_LANGUAGE:Fortran>:-ffree-line-length-0>)
    add_compile_options($<$<COMPILE_LANGUAGE:Fortran>:-std=legacy>)
elseif(
    CMAKE_Fortran_COMPILER_ID STREQUAL "Intel"
    OR CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM"
)
    add_compile_options($<$<COMPILE_LANGUAGE:Fortran>:-free>)
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-Wno-deprecated-non-prototype>)
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-Wno-parentheses>)
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-Wno-dangling-else>)
endif()
message(STATUS "CMAKE_Fortran_COMPILER_ID ${CMAKE_Fortran_COMPILER_ID}")
message(STATUS "CMAKE_Fortran_FLAGS ${CMAKE_Fortran_FLAGS}")

## specify directory for module files, and cache it into CMakeCache for reference
set(CMAKE_Fortran_MODULE_DIRECTORY
    ${CMAKE_BINARY_DIR}/artn_modules
    CACHE STRING
    "Directory for Fortran modules"
)

# ###################################################################################################################
## define libartn
add_library(artn SHARED)
## link with lapack
target_link_libraries(artn ${LAPACK_LIBRARIES})
## set properties of libartn
set_target_properties(
    artn
    PROPERTIES
        Fortran_PREPROCESS ON
        Fortran_FORMAT FREE
        POSITION_INDEPENDENT_CODE ON
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

## make the directory `artn_root/lib` and copy the targer libartn after it has been built
add_custom_command(
    TARGET artn
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${artn_libpath}"
    COMMAND
        ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:artn>"
        "${artn_libpath}/$<TARGET_FILE_NAME:artn>"
)

# ###################################################################################################################
add_subdirectory(src)

# ###################################################################################################################
# ###################################################################################################################
execute_process(
    COMMAND git rev-parse --abbrev-ref HEAD
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE ARTN_GIT_BRANCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
    COMMAND git rev-parse --short=7 HEAD
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE ARTN_GIT_COMMIT
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
file(
    WRITE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/artn_gitinfo.h
    "#define ARTN_INFO_GIT_BRANCH \"${ARTN_GIT_BRANCH}\"\n"
)
file(
    APPEND
    ${CMAKE_CURRENT_SOURCE_DIR}/src/artn_gitinfo.h
    "#define ARTN_INFO_GIT_COMMIT \"${ARTN_GIT_COMMIT}\"\n"
)

if(WITH_LAMMPS)
    ################################################################################################################
    # Find MPI, could be better and detect MPISTUBS instead of MPI

    find_package(MPI REQUIRED COMPONENTS CXX Fortran)
    include_directories(SYSTEM ${MPI_INCLUDE_PATH})

    if(MPI_FOUND)
        message(STATUS "MPI Found: YES")
        message(STATUS "MPI CXX compiler: ${MPI_CXX_COMPILER}")
        message(STATUS "MPI CXX libraries: ${MPI_CXX_LIBRARIES}")
        message(STATUS "MPI CXX include path: ${MPI_CXX_INCLUDE_DIRS}")
        message(STATUS "MPI FORTRAN compiler: ${MPI_FORTRAN_COMPILER}")
    else()
        message(FATAL_ERROR "MPI Not Found")
    endif()

    add_library(artn-lmp SHARED)
    target_link_libraries(artn-lmp artn ${MPI_CXX_LIBRARIES})
    target_include_directories(artn-lmp PRIVATE ${MPI_CXX_INCLUDE_DIRS})
    add_subdirectory(ENGINES/LAMMPS)

    ## after building artn-lmp, copy to libpath
    add_custom_command(
        TARGET artn-lmp
        POST_BUILD
        COMMAND
            ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:artn-lmp>"
            "${artn_libpath}/$<TARGET_FILE_NAME:artn-lmp>"
    )

    if(LAMMPS_PATH)
        ## LAMMPS_PATH is passed
        include(partn_lmp_conf)
    else()
        ## LAMMPS_PATH is not passed
        ## command: cmake .. -DWITH_LAMMPS  --> will pull lammps from git

        FetchContent_Declare(
            LAMMPS_GIT
            GIT_REPOSITORY https://github.com/lammps/lammps.git
            GIT_TAG release
            GIT_SHALLOW 1
            SOURCE_SUBDIR
            cmake
            GIT_PROGRESS ON
        )
        option(PKG_MANYBODY "Build LAMMPS PKG_MANYBODY" ON)
        option(PKG_PLUGIN "Build LAMMPS PKG_PLUGIN" ON)
        FetchContent_MakeAvailable(LAMMPS_GIT)
        include_directories(${lammps_git_SOURCE_DIR}/src)

        target_link_libraries(artn-lmp lammps)
    endif()
endif()

if(WITH_QE)
    if(QE_PATH)
        ## QE_PATH is passed.
        include(partn_qe_conf)
    else()
        ## QE_PATH is not passed.
        ## command: cmake .. -DWITH_QE  --> will pull qe from git

        FetchContent_Declare(
            QE_GIT
            GIT_REPOSITORY https://gitlab.com/QEF/q-e.git
            GIT_TAG master
            GIT_SHALLOW 1
            GIT_PROGRESS ON
        )
        set(QE_ENABLE_PLUGINS "legacy" CACHE INTERNAL "")
        FetchContent_MakeAvailable(QE_GIT)

        file(
            COPY_FILE
            ${CMAKE_CURRENT_SOURCE_DIR}/ENGINES/QE/plugin_ext_forces.f90
            ${qe_git_SOURCE_DIR}/PW/src/plugin_ext_forces.f90
        )
        target_link_libraries(qe_pw PRIVATE artn)
        set_target_properties(
            qe_pw_exe
            PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        )

        install(TARGETS artn EXPORT qeTargets)
    endif()
endif()

if(WITH_SIESTA)
    if(SIESTA_PATH)
        ## SIESTA_PATH is passed
        include(partn_siesta_conf)
    else()
        ## SIESTA_PATH is not passed
        message(FATAL_ERROR "pARTn :: need SIESTA_PATH.")

        # FetchContent_Declare(SIESTA_GIT GIT_REPOSITORY https://gitlab.com/siesta-project/siesta.git GIT_TAG dev GIT_SHALLOW 1 GIT_PROGRESS ON)
        # # add_subdirectory(ENGINES/Siesta)
    endif()
endif()

#### print the configuration
message(STATUS "----------------------------")
message(STATUS "    CMake configuration:    ")
message(STATUS "----------------------------")
message(STATUS " WITH_LAMMPS: ${WITH_LAMMPS}")
if(WITH_LAMMPS)
    message(
        "        LAMMPS_PATH : ${LAMMPS_PATH}
        version     : ${lmp_version}
        <machine>   : ${lmp_machine}
        LAMMPS_LIB  : ${LAMMPS_LIB} "
    )
endif()
message(STATUS "----------------------------")
message(STATUS " WITH_QE: ${WITH_QE}")
if(WITH_QE)
    message(
        "        QE_PATH : ${QE_PATH}
        version : ${qe_version} "
    )
endif()
message(STATUS "----------------------------")
message(STATUS " WITH_SIESTA: ${WITH_SIESTA}")
if(WITH_SIESTA)
    message("       SIESTA_PATH : ${SIESTA_PATH} ")
endif()
message(STATUS "----------------------------")

# ################################################################################################################
# ################################################################################################################
