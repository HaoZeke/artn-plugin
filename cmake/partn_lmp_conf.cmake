message(STATUS "LAMMPS PATH : ${LAMMPS_PATH}")

# include_directories(${LAMMPS_PATH}/src)

## find lmproot dir: search for cmake dir
if(IS_DIRECTORY "${LAMMPS_PATH}/cmake")
    set(lmproot ${LAMMPS_PATH})
elseif(IS_DIRECTORY "${LAMMPS_PATH}/../cmake")
    set(lmproot ${LAMMPS_PATH}/../)
else()
    message(
        FATAL_ERROR
        "pARTn :: LAMMPS_PATH does not seem to be correct: ${LAMMPS_PATH}."
    )
endif()
message(STATUS "lmproot: ${lmproot}")

## find if cmake or make was used for lammps
set(lmp_cmake False)
set(lmp_make False)
## if cmake, then LAMMPS_PATH should point to bulddir, and there should be CMakeCache file
## if make, there should be src/iblammps.so symlink
if(EXISTS "${LAMMPS_PATH}/CMakeCache.txt")
    set(lmp_cmake True)
elseif(IS_SYMLINK "${LAMMPS_PATH}/src/liblammps.so")
    set(lmp_make True)
endif()
message(STATUS "lmp_make:${lmp_make} lmp_cmake:${lmp_cmake}")

## find lammps version
artn_get_string("LAMMPS_VERSION" ${lmproot}/src/version.h vstr)
string(REGEX MATCH "^.+\"(.+)\"" _match "${vstr}")
set(lmp_version ${CMAKE_MATCH_1})
artn_get_string("LAMMPS_UPDATE" ${lmproot}/src/version.h ustr)
if(NOT "${ustr}" STREQUAL "")
    string(REGEX MATCH "^.+\"(.+)\"" _match "${ustr}")
    string(JOIN "-" lmp_version ${lmp_version} ${CMAKE_MATCH_1})
endif()
message(STATUS "LAMMPS version:: ${lmp_version}")

## find <machine>
if(lmp_make)
    # resolve the symlink liblammps.so
    file(READ_SYMLINK "${lmproot}/src/liblammps.so" line)
    string(REGEX MATCH "liblammps_([^\.]+)" _match "${line}")
    set(lmp_machine ${CMAKE_MATCH_1})
elseif(lmp_cmake)
    # read it from CMakeCache
    artn_get_string("LAMMPS_MACHINE:STRING" ${LAMMPS_PATH}/CMakeCache.txt line)
    string(REGEX MATCH "^.+=(.+)" _match "${line}")
    set(lmp_machine ${CMAKE_MATCH_1})
else()
    message(
        FATAL_ERROR
        "LAMMPS_PATH incorrect, or Lammps not compiled by neither 'cmake' nor 'make'."
    )
endif()

## see if package plugin is set
if(lmp_make)
    artn_get_string("PLUGIN" ${lmproot}/src/lmpinstalledpkgs.h pkg_plugin)
elseif(lmp_cmake)
    artn_get_string("PLUGIN" ${LAMMPS_PATH}/styles/lmpinstalledpkgs.h pkg_plugin)
endif()
if("${pkg_plugin}" STREQUAL "")
    message(
        FATAL_ERROR
        "pARTn :: package PLUGIN is needed, but not found in LAMMPS."
    )
endif()

## set the dir for included files from lammps
set(lmpinclude "${lmproot}/src")

## find liblammps_<machine>.so
set(liblammps "lammps")
## if lammps is built with cmake, even the symlink has <machine> in name..
if(lmp_cmake)
    if(NOT "${lmp_machine}" STREQUAL "")
        set(liblammps "lammps_${lmp_machine}")
    endif()
endif()
find_library(
    LAMMPS_LIB
    NAMES ${liblammps}
    PATHS ${LAMMPS_PATH} ${lmproot}/build ${lmproot}/src
    DOC "Path to the external liblammps file"
)
message(STATUS "LAMMPS libary is found : ${LAMMPS_LIB}")

## add -I paths
target_include_directories(artn-lmp PUBLIC "${lmpinclude}")

## link artn to liblammps
target_link_libraries(artn-lmp ${LAMMPS_LIB})
