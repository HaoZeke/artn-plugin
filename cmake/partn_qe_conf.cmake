## this is executed when QE_PATH is passed to cmake

##  find the root dir realtive to passed QE_PATH, by locating the 'cmake' directory
if(IS_DIRECTORY "${QE_PATH}/../cmake")
    set(qeroot ${QE_PATH}/../)
elseif(IS_DIRECTORY "${QE_PATH}/cmake")
    set(qeroot ${QE_PATH})
else()
    message(FATAL_ERROR "pARTn :: QE_PATH incorrect: ${QE_PATH}")
endif()
message(STATUS "qeroot ${qeroot}")

##  find if qe is configured with make or cmake
set(qe_make False)
set(qe_cmake False)
if(EXISTS "${qeroot}/make.inc")
    set(qe_make True)
elseif(EXISTS "${QE_PATH}/CMakeCache.txt")
    set(qe_cmake True)
endif()
message(STATUS "qe_make:${qe_make} qe_cmake:${qe_cmake}")

message(STATUS "Checking QE version")

## get hard-coded version line from qe/include/qe_version.h
artn_get_string("version_number" ${qeroot}/include/qe_version.h line)

## extract the version number which is inside ' ' or " "
string(REGEX REPLACE "^.*['\"](.*)['\"]" "\\1" qe_version "${line}")
message(STATUS "QE version is: ${qe_version}")

artn_version_values(${qe_version} qe_major qe_minor qe_patch)
# message(STATUS "major:${qe_major} minor:${qe_minor} patch:${qe_patch}")

## qe versions < 7.3 not supported through cmake
if("${qe_major}" LESS_EQUAL 7)
    if("${qe_minor}" LESS 3)
        message(
            FATAL_ERROR
            "pARTn :: QE versions < 7.3 not supported through CMake."
        )
    endif()
endif()

## copy the plugin_ext_forces file with call to artn_QE to QE/PW/src
file(
    COPY_FILE
    ${CMAKE_CURRENT_SOURCE_DIR}/ENGINES/QE/plugin_ext_forces.f90
    ${qeroot}/PW/src/plugin_ext_forces.f90
)

## add artn lib dependency
if(qe_make) # for make
    ## add libartn.so into make.inc, if its not there already
    artn_get_string("LIBOBJS \\+= ${CMAKE_BINARY_DIR}/libartn\.so" ${qeroot}/make.inc found_str)
    if("${found_str}" STREQUAL "")
        file(
            APPEND
            ${qeroot}/make.inc
            "LIBOBJS += ${CMAKE_BINARY_DIR}/libartn.so\n"
        )
    endif()

    artn_get_string("QELIBS \\+= ${CMAKE_BINARY_DIR}/libartn\.so" ${qeroot}/make.inc found_str)
    if("${found_str}" STREQUAL "")
        file(
            APPEND
            ${qeroot}/make.inc
            "QELIBS += ${CMAKE_BINARY_DIR}/libartn.so\n"
        )
    endif()

    ## after building target artn, execute make pw from qe root
    add_custom_command(
        TARGET artn
        POST_BUILD
        COMMAND make pw
        WORKING_DIRECTORY ${qeroot}
        COMMENT "       Building/Rebuild target pw..."
    )
elseif(qe_cmake) # for cmake
    ## add dependency libartn.so into PW/CMakeLists.txt, if not there
    artn_get_string("target_link_libraries\\(qe_pw PRIVATE ${CMAKE_BINARY_DIR}/libartn\.so\\)"
      ${QE_PATH}/PW/CMakeLists.txt found_str
    )
    if("${found_str}" STREQUAL "")
        file(
            APPEND
            ${QE_PATH}/PW/CMakeLists.txt
            "target_link_libraries(qe_pw PRIVATE ${CMAKE_BINARY_DIR}/libartn.so)\n"
        )
    endif()

    ## after making target artn, launch `cmake --build . --target pw` in QE_PATH dir
    add_custom_command(
        TARGET artn
        POST_BUILD
        COMMAND cmake --build . --target pw
        WORKING_DIRECTORY ${QE_PATH}
        COMMENT "       Building/Rebuild target pw..."
    )
else()
    ## not make and not cmake ... error
    message(
        FATAL_ERROR
        "QE_PATH incorrect, or QE not configured neither by `make` nor `cmake`."
    )
endif()
