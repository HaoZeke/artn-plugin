##
## thefunctions have prefix <artn_> just to distinguish they are custom, not from CMake
##

## find a string in file; return logical T/F
function(artn_find_string in_string in_file found_str)
  # message(STATUS "in_string: ${in_string}")
  # message(STATUS "in_file: ${in_file}")

  # # read file into array of strings
  file(STRINGS ${in_file} this_file )

  set(found False)

  # parse file strings
  while(this_file)
    # pop an array element into LINE
    list(POP_FRONT this_file LINE)
    # this is a regex check if `string` matches `LINE`
    if(${LINE} MATCHES ${in_string})
      set(found True)
      # message(STATUS "found line:: ${LINE}")
      break()
    endif()
  endwhile()

  set(found_str ${found} PARENT_SCOPE)

endfunction(artn_find_string)


## find string in file; return whole line with string
function(artn_get_string in_string in_file out_string)
  # # read file into array of strings
  file(STRINGS ${in_file} this_file )

  set(found "")
  # parse file strings
  while(this_file)
    # pop an array element into LINE
    list(POP_FRONT this_file LINE)
    # this is a regex check if `string` matches `LINE`
    if(${LINE} MATCHES ${in_string})
      set(found ${LINE})
      message(STATUS "found line:: ${LINE}")
      break()
    endif()
  endwhile()

  set(${out_string} ${found} PARENT_SCOPE)

endfunction(artn_get_string)
