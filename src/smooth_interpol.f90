submodule( m_option ) smooth_interpol_r
  implicit none
contains

  !> @author
  !!  Matic Poberznik
  !!  Miha Gunde
  !!  Nicolas Salles
  !
  !> @brief Smooth Interpolation
  !
  !> @par Purpose
  !  ============ 
  !>   Return a smooth interpolation v2 betwwen 2 field v1 and v2:
  !>   - v2 is a linear combination between v1 and v2
  !>   - v2= v1 when ismooth = 0       -> done in init
  !>   - v2= V2 when ismooth = nsmooth -> done in eigen 
  !
  !> @param[in,out]  ismooth  actual smooth step 
  !> @param[in]      nsmooth  max smooth step 
  !> @param[in]      nat      number of atom
  !> @param[in]      v0       the actual orientation
  !> @param[in,out]  v1       the direction we come
  !> @param[in]      v2       the direction we go
  !!
  !> @ingroup Control
  !!
  !> @snippet smooth_interpol.f90 smooth
  MODULE SUBROUTINE smooth_interpol( ismooth, nsmooth, nat, v0, v1, v2 )
    !
    !> [smooth]
    USE artn_params, ONLY : filout, verbose
    use m_artn_tools, only: ddot
    IMPLICIT NONE
    !
    INTEGER,  INTENT( INOUT ) :: ismooth   ! degree of interpolation
    INTEGER,  INTENT( IN )    :: nsmooth   ! number of degree of interpolation
    INTEGER,  INTENT( IN )    :: nat       ! number of points in 3D field
    REAL(DP), INTENT( IN )    :: v0(3,nat) ! Actuel field
    REAL(DP), INTENT( INOUT ) :: v1(3,nat) ! Orientation field 1
    REAL(DP), INTENT( IN )    :: v2(3,nat) ! Orientation field 2
    !
    ! Local variables
    REAL(DP)                  :: smoothing_factor, f_orient
    ! REAL(DP), external        :: ddot
    integer                   :: ios, u0
    logical                   :: ALLOC
    character(len=128)        :: msg

    ! save variable
    REAL(DP), allocatable, save :: Vi(:,:), Vf(:,:)

    !
    ! ...At the first step we save the last push and the direction
    !      we want to go smoothly
    ALLOC = ( allocated(Vi).AND.allocated(Vf) )
    if( ismooth == 1.OR..NOT.ALLOC )then
       Vi = v1
       Vf = v2
    endif

    smoothing_factor = 1.0_DP*real(ismooth,DP) / real(nsmooth+1,DP)

    !
    ! ...Define the actual oriention from the final direction
    f_orient = ddot( 3*nat, v0, 1, vf, 1 )

    !
    ! ...Interpolation between Vi (initial) and Vf (final)
    v1 = (1.0_DP - smoothing_factor) * Vi    &
         - SIGN(1.0_DP,f_orient) * smoothing_factor * Vf

    !
    ! ...Info Output
    IF( verbose > 2 ) THEN
       open(NEWUNIT=u0, FILE=filout, FORM='formatted', STATUS='unknown', POSITION='append', IOSTAT=ios, IOMSG=msg)
       if( ios /= 0 ) then
          write(*,*) "ERROR with file:",trim(filout)
          write(*,*) trim(msg)
       end if
       WRITE (u0,'(5x,a23,1x,i2,a1,i2,1x,a7,1x,f15.9)')&
            "|> Smooth interpolation", ismooth,"/",nsmooth, "factor=",smoothing_factor
       close(u0, status="keep")
    ENDIF

    !
    ! deallocate vi and vf on last ismooth step
    if( ismooth==nsmooth) then
       if( allocated(vi))deallocate(vi)
       if( allocated(vf))deallocate(vf)
    end if
    !> [smooth]
    !
  END SUBROUTINE smooth_interpol


end submodule smooth_interpol_r
