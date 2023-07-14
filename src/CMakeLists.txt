set(SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/artn.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/artn_params_mod.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/artn_QE.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/center.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/check_force_convergence.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/setup_artn.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/clean_artn.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/diag.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/displacement_validation.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/fperp_min_alignment.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/get_functions.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/invmat3x3.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/lanczos.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/make_filename.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/move_mode.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/nextmin.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/nperp_limitation.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/pbc.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/perpforce.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/push_init.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/push_over_procedure.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/read_guess.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/restart.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/smooth_interpol.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/start_guess.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/sum_force.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/units.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/write_report.f90
        ${CMAKE_CURRENT_SOURCE_DIR}/write_struct.f90
)
target_sources(partn PRIVATE ${SOURCES} )



