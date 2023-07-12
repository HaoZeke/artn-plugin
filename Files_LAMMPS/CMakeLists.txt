set(SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/artn.h
    ${CMAKE_CURRENT_SOURCE_DIR}/fix_artn.h
    ${CMAKE_CURRENT_SOURCE_DIR}/artnplugin.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/fix_artn.cpp
)
target_sources(partn PRIVATE ${SOURCES} )
