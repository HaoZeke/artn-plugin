## SPDX-License-Identifier: GPL-3.0-or-later
## Native meson build for artn-plugin (pARTn library).
## Exposes artn_dep for downstream meson consumers.
## No -cpp flag: h_artn_info.f90 is generated via configure_file
## to avoid breaking meson's Fortran submodule dependency scanner.

project('artn-plugin', ['c', 'fortran'],
  version: '0.1.0',
  meson_version: '>= 0.60.0',
  default_options: [
    'fortran_std=none',
    'buildtype=release',
  ],
)

fc = meson.get_compiler('fortran')

lapack_dep = dependency('lapack', required: false)
if not lapack_dep.found()
  lapack_dep = dependency('lapack', method: 'cmake', required: false)
endif
if not lapack_dep.found()
  lapack_dep = fc.find_library('lapack', required: true)
endif

fortran_args = []
if fc.get_id() == 'gcc'
  fortran_args += ['-ffree-line-length-0', '-cpp']
elif fc.get_id() == 'intel' or fc.get_id() == 'intel-llvm'
  fortran_args += ['-free', '-fpp']
endif

## Generate h_artn_info.f90 from template (avoids #include needing -cpp)
artn_info_conf = configuration_data()
artn_info_conf.set('ARTN_VERSION', '1.0.0')
artn_info_conf.set('ARTN_GIT_BRANCH', '(meson)')
artn_info_conf.set('ARTN_GIT_COMMIT', '(meson)')
h_artn_info_f90 = configure_file(
  input: 'src/h_artn_info.f90.in',
  output: 'h_artn_info.f90',
  configuration: artn_info_conf,
)

artn_sources = files(
  'src/h_artn_precision.f90',
  'src/m_artn_error.f90',
  'src/h_artn_units.f90',
  'src/d_artn_data.f90',
  'src/d_artn_params.f90',
  'src/d_datainfo.f90',
  'src/m_artn_tools.f90',
  'src/m_artn_fire.f90',
  'src/m_artn_option.f90',
  'src/m_artn_report.f90',
  'src/m_block_lanczos.f90',
  'src/diag.f90',
  'src/string_tools.f90',
  'src/split_field.f90',
  'src/pbc.f90',
  'src/center.f90',
  'src/permute.f90',
  'src/random.f90',
  'src/constrained_draw.f90',
  'src/convert_units.f90',
  'src/compute_delr.f90',
  'src/check_artn_params.f90',
  'src/check_force_convergence.f90',
  'src/dump_routines.f90',
  'src/fill_param_step.f90',
  'src/get_data.f90',
  'src/get_params.f90',
  'src/get_runparam.f90',
  'src/set_data.f90',
  'src/set_params.f90',
  'src/set_runparam.f90',
  'src/lanczos.f90',
  'src/block_lanczos.f90',
  'src/block_perprelax.f90',
  'src/block_pusheigen.f90',
  'src/block_pushinit.f90',
  'src/block_pushover.f90',
  'src/block_finalize.f90',
  'src/push_init.f90',
  'src/push_over_procedure.f90',
  'src/move_mode.f90',
  'src/move_nextmin.f90',
  'src/nperp_limitation.f90',
  'src/smooth_interpol.f90',
  'src/sum_force.f90',
  'src/save_step_data.f90',
  'src/make_filename.f90',
  'src/write_report.f90',
  'src/write_struct.f90',
  'src/start_guess.f90',
  'src/restart.f90',
  'src/clean_artn.f90',
  'src/m_setup_artn.f90',
  'src/artn.f90',
  'src/artn_step.f90',
  'src/artn_debug.f90',
  'src/artn_api.f90',
  'src/artn_c_wrappers.f90',
  'src/artn_QE.f90',
)

artn_inc = include_directories('interface')
artn_src_inc = include_directories('src')

artn_lib = library('artn',
  artn_sources + [h_artn_info_f90],
  fortran_args: fortran_args,
  dependencies: lapack_dep,
  include_directories: [artn_inc, artn_src_inc],
  install: true,
  pic: true,
)

install_headers('interface/artn.h')

artn_dep = declare_dependency(
  link_with: artn_lib,
  include_directories: artn_inc,
)

meson.override_dependency('artn', artn_dep)
