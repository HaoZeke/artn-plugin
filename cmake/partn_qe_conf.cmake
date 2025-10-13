## this is executed when QE_PATH is passed to cmake

##  find the root dir realtive to passed QE_PATH, by locating the 'cmake' directory
if(IS_DIRECTORY "${QE_PATH}/../cmake")
    set(qeroot ${QE_PATH}/../)
elseif(IS_DIRECTORY "${QE_PATH}/cmake")
    set(qeroot ${QE_PATH})
else()
    ## not make and not cmake ... error
    message(
        FATAL_ERROR
        "QE_PATH incorrect, or QE not configured neither by `make` nor `cmake`."
    )
endif()
message(STATUS "qeroot ${qeroot}")

##  find if qe is configured with make or cmake
set(qe_make False)
set(qe_cmake False)
if(EXISTS "${qeroot}/make.inc")
    set(qe_make True)
elseif(EXISTS "${QE_PATH}/CMakeCache.txt")
    set(qe_cmake True)
else()
    message(FATAL_ERROR "QE at given path not configured.")
endif()
message(STATUS "qe_make:${qe_make} qe_cmake:${qe_cmake}")

message(STATUS "Checking QE version")

## get hard-coded version line from qe/include/qe_version.h
artn_get_string("version_number" ${qeroot}/include/qe_version.h line)

## extract the version number which is inside ' ' or " "
string(REGEX REPLACE "^.*['\"](.*)['\"]" "\\1" qe_version "${line}")
message(STATUS "QE version is: ${qe_version}")

artn_version_values(${qe_version} qe_major qe_minor qe_patch)
message(STATUS "major:${qe_major} minor:${qe_minor} patch:${qe_patch}")

## qe versions < 7.3 not supported through cmake
if("${qe_major}" LESS 7)
    message(
        FATAL_ERROR
        "pARTn :: QE versions < 7.3 not supported through CMake."
    )
endif()
if("${qe_major}" EQUAL 7)
    if("${qe_minor}" LESS 3)
        message(
            FATAL_ERROR
            "pARTn :: QE versions < 7.3 not supported through CMake."
        )
    endif()
endif()

## copy the plugin_ext_forces file with call to artn_QE to QE/PW/src
## NOTE: the COPY_FILE command requires cmake>=3.21
file(
    COPY_FILE
    ${CMAKE_CURRENT_SOURCE_DIR}/ENGINES/QE/plugin_ext_forces.f90
    ${qeroot}/PW/src/plugin_ext_forces.f90
)

## check for "legacy plugin" configuration
if(qe_make)
    artn_get_string("-D__LEGACY_PLUGINS" ${qeroot}/make.inc found_str)
    if("${found_str}" STREQUAL "")
        message(
            FATAL_ERROR
            "QE needs to be configured with the flag: --enable-legacy-plugins"
        )
    endif()
elseif(qe_cmake)
    artn_get_string("QE_ENABLE_PLUGINS:STRING=legacy" ${QE_PATH}/CMakeCache.txt found_str)
    if("${found_str}" STREQUAL "")
        message(
            FATAL_ERROR
            "QE needs to be configured with the flag: -DQE_ENABLE_PLUGINS=legacy"
        )
    endif()
endif()

## add artn lib dependency
if(qe_make) # for make
    ## whats the name of qelibs? LIBOBJS or QELIBS
    set(qelibs "LIBOBJS")
    artn_get_string("LIBOBJS" ${qeroot}/make.inc found_str)
    if( "${found_str}" STREQUAL "")
      set(qelibs "QELIBS")
    endif()
    # message( STATUS "qelibs is: ${qelibs}")

    ## add libartn.so into make.inc, if its not there already
    artn_get_string(
      "${qelibs} \\+= ${artn_libpath}/libartn\.so"
      ${qeroot}/make.inc
      found_str
    )
    if("${found_str}" STREQUAL "")
        file(
            APPEND
            ${qeroot}/make.inc
            "\n## ======= lines added by pARTn \n"
            "${qelibs} += ${artn_libpath}/libartn.so\n"
            "## ============================ \n"
            )
        endif()

    ## after building target artn, execute make pw from qe root
    add_custom_command(
        TARGET artn
        POST_BUILD
        COMMAND make pw -j
        WORKING_DIRECTORY ${qeroot}
        COMMENT "       Building/Rebuild target pw..."
    )
elseif(qe_cmake) # for cmake
    ## add dependency libartn.so into PW/CMakeLists.txt, if not there
    artn_get_string("target_link_libraries\\(qe_pw PRIVATE ${artn_libpath}/libartn\.so\\)"
      ${qeroot}/PW/CMakeLists.txt found_str
    )
    if("${found_str}" STREQUAL "")
        file(
            APPEND
            ${qeroot}/PW/CMakeLists.txt
            "\n## ======= lines added by pARTn \n"
            "target_link_libraries(qe_pw PRIVATE ${artn_libpath}/libartn.so)\n"
            "## ============================ \n"
        )
    endif()

    ## after making target artn, launch `cmake --build . --target pw` in QE_PATH dir
    add_custom_command(
        TARGET artn
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} --build . --target pw --parallel
        WORKING_DIRECTORY ${QE_PATH}
        COMMENT "       Building/Rebuild target pw..."
    )
endif()
