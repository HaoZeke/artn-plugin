submodule( m_artn_option )nperp_limitation_r
  use d_artn_params, only: nperp_limitation, nperp, def_nperp_limitation, nperp_step
  implicit none
contains

  !> @author
  !!   Nicolas Salles
  !!   Matic Poberznik
  !!   Miha Gunde

  !> @brief
  !!   Define the nperp value.
  !!   Increment nperp_step that select the nperp value in the array nperp_limitation
  !!   Incrementation is 1, increment = -1 
  !
  !> @param[in]  increment   command {-1,0,1} allows to show what it does
  !
  MODULE SUBROUTINE nperp_limitation_step( increment )
    !
    implicit none

    integer, intent( in ) :: increment

    integer :: n

    !! increment nperp_step
    if( increment == 1 )then
       !! Save the basin nperp
       if( nperp_step == 1 )nperp_limitation(1) = nperp
       !! increment the limitation list
       nperp_step = nperp_step + increment
    endif

    n = size(nperp_limitation)

    !! IF   nperp_step in the range of nperp_limitation
    !! ELSE use the last value nperp_limitation
    if( nperp_step < n )then
       nperp = nperp_limitation( nperp_step )
    else
       nperp = nperp_limitation( n )
    endif

    !! Return to nperp_step = 1
    if( increment == -1 )then
       nperp_step = 1
       nperp = nperp_limitation( nperp_step )
    endif

  end SUBROUTINE nperp_limitation_step



  !...........................................................................................
  !> @authors
  !!   Nicolas Salles
  !!   Matic Poberznik
  !!   Miha Gunde
  !
  !> @brief manage the max perp-relax iteration
  !
  !> @par Purpose
  !!  ============
  !>
  !> @verbatim
  !> the nperp are stored in array nperp_limitation() with in
  !> first element the value of nperp if exist and in last the
  !> nperp_end. The last element is repeated until the end of research
  !> Values:
  !>  -2 nothing
  !>  -1 no limitation
  !>  {0,1,...} nperp limit
  !> @endverbatim
  !
  !> @param[in] flag true/false to use nperp_limitation
  !
  MODULE SUBROUTINE nperp_limitation_init( flag )
    !
    ! use m_artn_error
    implicit none

    logical, intent( in ) :: flag

    logical :: verb
    integer :: n, perp_end !,i

    verb = .true.
    verb = .false.

    write(*,*) "Enter nperp_limitation_init", flag
    write(*,*) "allocated nperp",allocated(nperp_limitation)
    write(*,*) "mperp", nperp, " size ", size(nperp_limitation)
    !! User says use nperp_limitation
    IF( flag )THEN

       !! but no defines the limitation (previously initialized at -2 by default)
       IF( ALL(nperp_limitation == -2) )THEN
          deallocate( nperp_limitation )
          allocate( nperp_limitation, source=def_nperp_limitation )
          if( nperp > -1 )nperp_limitation( 1 ) = nperp
          !write(*,'("NPERP_LIMITATION_INIT> ",*(1x,i0))')nperp_limitation(:)

          !! define just one limitation
       ELSE
          n = count(nperp_limitation > -2)

          !! and also define nperp
          perp_end = -1  !! No limitation for the last perp step
          perp_end = nperp_limitation(n) !! last limit is last value given by user
          write(*,*) "nperp_end", perp_end

          if( nperp /= -1 )then
             nperp_limitation = [ nperp, nperp_limitation(1:n), perp_end ]
          else
             !nperp_limitation = [ def_nperp_limitation(1), nperp_limitation(1:n), perp_end ]
             nperp_limitation = [ nperp_limitation(1:n), perp_end ]
          endif

       ENDIF

       !! User does not use the nperp_limitation
    ELSE
       !! We still define nperp_limitation but at nothing
       nperp_limitation = [ -1, -1 ]

       !! But he still define is own nperp in basin
       if( nperp > -1 )nperp_limitation(1) = nperp
    ENDIF
    !write(*,'(" NPERP_LIMITATION_INIT> ",*(1x,i0))')nperp_limitation(:)

    !! Define nperp
    nperp = nperp_limitation(1)

    if( verb ) write(*,'(5x,"|> NPERP_LIMITATION:: Actual nperp",1x,i0,/5x,"|> NPERP_LIMITATION::List:",*(1x,i0))') &
         nperp, nperp_limitation(:)


  end SUBROUTINE nperp_limitation_init


end submodule nperp_limitation_r
