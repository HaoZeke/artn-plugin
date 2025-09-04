##
## the functions have prefix <artn_> just to distinguish they are custom, and not from CMake.
## There is no relation to artn.
##

## find string in file; return whole line with string
function(artn_get_string in_string in_file out_string)
    if(NOT EXISTS "${in_file}")
        message(FATAL_ERROR "pARTn :: file ${in_file} does not exist.")
    endif()

    # # read file into array of strings
    file(STRINGS ${in_file} this_file)

    set(found "")
    # parse file strings
    while(this_file)
        # pop an array element into LINE
        list(POP_FRONT this_file LINE)
        # this is a regex check if `string` matches `LINE`
        if(${LINE} MATCHES ${in_string})
            set(found ${LINE})
            # message(STATUS "found line:: ${LINE}")
            break()
        endif()
    endwhile()

    set(${out_string} ${found} PARENT_SCOPE)
endfunction(artn_get_string)

##
## match version values of the format major.minor.patch
## If any values dont exist, set them to 0, i.e. 7.5 => major=7, minor=5, patch=0
function(artn_version_values version_str major minor patch)
    ## version major value
    string(REGEX MATCH "^([0-9]+)" _match "${version_str}")
    set(${major} ${CMAKE_MATCH_1} PARENT_SCOPE)

    ## version minor value
    string(REGEX MATCH "^[0-9]+\\.([0-9]+)" _match "${version_str}")
    if("${CMAKE_MATCH_1}" STREQUAL "")
        set(mn 0)
    else()
        set(mn ${CMAKE_MATCH_1})
    endif()

    ## version patch value
    string(REGEX MATCH "^[0-9]+\\.[0-9]+\\.([0-9]+)" _match "${version_str}")
    if("${CMAKE_MATCH_1}" STREQUAL "")
        set(pt 0)
    else()
        set(pt ${CMAKE_MATCH_1})
    endif()

    set(${minor} ${mn} PARENT_SCOPE)
    set(${patch} ${pt} PARENT_SCOPE)
endfunction(artn_version_values)
