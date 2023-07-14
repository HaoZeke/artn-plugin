set(SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/plugin_ext_forces.f90
)
target_sources(qe_pw PRIVATE ${SOURCES} )
