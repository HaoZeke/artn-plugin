submodule(m_block_lanczos)lanczos_routine


  use h_artn_precision, only: DP
  USE m_artn_tools, only: diag
  implicit none


  !! interface to blas/lapack
  interface
     pure subroutine dgemm(transa, transb, m, n, k, alpha, a, lda, b, ldb, beta, c, ldc)
       use, intrinsic :: iso_fortran_env, only : ddp=>real64
       integer,   intent(in) :: ldc
       integer,   intent(in) :: ldb
       integer,   intent(in) :: lda
       character, intent(in) :: transa
       character, intent(in) :: transb
       integer,   intent(in) :: m
       integer,   intent(in) :: n
       integer,   intent(in) :: k
       real(ddp),  intent(in) :: alpha
       real(ddp),  intent(in) :: a(lda, *)
       real(ddp),  intent(in) :: b(ldb, *)
       real(ddp),  intent(in) :: beta
       real(ddp),  intent(inout) :: c(ldc, *)
     end subroutine dgemm
  end interface


contains

  !> @author
  !!  Matic Poberznik
  !!  Miha Gunde
  !!  Nicolas Salles

  !
  !> @brief
  !!   Lanczos subroutine for the ARTn algorithm
  !!
  !> @par Purpose
  !  ============
  !> The idea is to overwrite the 'force' with the vector of desired move,
  !! according to Lanczos diagonalisation algorithm. \n The array 'force' (input)
  !! contains the real forces on structure.
  !
  !> @param [in]      nat              number of atoms
  !> @param [in]      v_in            Input lanczos vector: only used in first step of each lanczos call
  !> @param [in]      pushdir         List of Direction of push on atoms
  !> @param [in]      force            array of Forces on the atoms
  !> @param [in,out]   ilanc           current step of lanczos
  !> @param [in,out]   nlanc        maximal number of Lanczos steps, at convergence gets overwritten with ilanc value
  !> @param [in,out]   lowest_eigval   Lowest eigenvalue obtained by lanczos algo
  !> @param [in,out]   lowest_eigvec   Lowest eigenvector obtained by lanczos algo
  !> @param [out]     displ_vec       The displacement to perform for next step
  !!
  !> @ingroup Control Block
  !!
  !> @snippet lanczos.f90 lanczos
  !!
  MODULE SUBROUTINE lanczos( nat, v_in, pushdir, force, &
       ilanc, nlanc, lowest_eigval, lowest_eigvec, displ_vec )
    !
    !> [lanczos]
    USE d_artn_params, ONLY: lanczos_disp, lanczos_eval_conv_thr, lanczos_min_size
    USE h_artn_units, ONLY: unconvert_param
    use m_artn_tools, only: ddot, dnrm2
    IMPLICIT NONE
    !
    ! -- ARGUMENTS
    INTEGER,                    INTENT(IN)    :: nat
    REAL(DP), DIMENSION(3,nat), INTENT(IN)    :: v_in
    REAL(DP), DIMENSION(3,nat), INTENT(IN)    :: pushdir
    REAL(DP), DIMENSION(3,nat), INTENT(IN)    :: force
    INTEGER,                    INTENT(INOUT) :: ilanc
    INTEGER,                    INTENT(INOUT) :: nlanc
    REAL(DP),                   INTENT(INOUT) :: lowest_eigval
    REAL(DP), DIMENSION(3,nat), INTENT(INOUT) :: lowest_eigvec
    REAL(DP), DIMENSION(3,nat), INTENT(OUT)   :: displ_vec
    !
    ! -- LOCAL VARIABLES
    INTEGER                                   :: i, j, id_min
    REAL(DP), ALLOCATABLE                     :: v1(:,:), q(:,:), eigvals(:)
    REAL(DP)                                  :: dir
    REAL(DP)                                  :: alpha, beta, lowest_eigval_old, eigval_diff
    !
    ! Use allocatable to avoid stack overflow and size mismatch
    REAL(DP), ALLOCATABLE                     :: Htmp(:,:), Hstep(:,:)
    !
    ! allocate vectors and put to zero
    ALLOCATE( q(3,nat),  source=0.0_DP )
    ALLOCATE( v1(3,nat), source=0.0_DP )
    !
    ! store the eigenvalue of the previous iteration
    IF( ilanc > 0 )THEN
       lowest_eigval_old = lowest_eigval
    ELSE
       lowest_eigval_old = 0.0_DP
    ENDIF
    !
    !
    ! decide what to do based on which step ilanc we are in
    IF ( ilanc  == 0 ) THEN
       !
       ! initialization of the lanczos: save the original force, and
       ! the initial lanczos vector
       !
       ! write(785,*) 'entering lanc with size:',nlanc, unconvert_param( "lanczos_disp", lanczos_disp), lanczos_disp
       !
       ! store the force of the initial position
       !
       force_old = force(:,:)
       !
       ! normalize initial vector
       !
       ! write(*,*) "v_in",v_in(1,1)
       v1(:,:) = v_in(:,:) / dnrm2( 3*nat, v_in, 1 )
       !
       ! store this vector in matrix of Lanczos vectors
       !
       Vmat(:,:,1) = v1(:,:)
       !
    ELSEIF (ilanc == 1 ) THEN
       !
       ! First step of the lanczos algorithm:
       !
       ! Generate lanczos vector, v = q - alpha*v0
       !
       ! q(:,:) now represents {Force} = -[Hessian]{R_1}, where {R_1} = {R} + {dR} = {R} + {v0}*d_lanc,
       ! and {v0} is the Lanczos vector v0(:). We need q(:) to represent [Hessian]{v0}, thus
       ! first do q(:) = -[Hessian]( {R_1} - {R} ) = -[Hessian]{dR}
       q(:,:) = force(:,:) - force_old(:,:)
       !! now do q(:) = [Hessian]{dR}/d_lanc = [Hessian]{v0}
       q(:,:) = -q(:,:) / lanczos_disp
       !
       alpha = ddot(3*nat,Vmat(:,:,1),1,q(:,:),1)
       !
       v1(:,:) = q(:,:) - alpha*Vmat(:,:,1)
       !
       ! beta is the norm of v1, used for next ilanc step
       !
       beta = dnrm2(3*nat,v1,1)
       v1(:,:) = v1(:,:) / beta
       !
       ! store the vector for future cycles
       !
       Vmat(:,:,2) = v1(:,:)
       H(1,1) = alpha
       H(2,1) = beta
       H(1,2) = beta
       !
       ! there is only one possible eigval in this step: alpha
       ! the corresponding eigvec is unchanged
       !
       lowest_eigval = alpha
       !
       ! check for convergence in this step
       !
       eigval_diff = (lowest_eigval - lowest_eigval_old)/lowest_eigval_old
       ! write(785,*) 1, lowest_eigval_old, lowest_eigval, abs(eigval_diff)
       !
       IF ( abs(lowest_eigval_old) > 0.0_DP ) THEN
          IF ( ilanc .ge. lanczos_min_size .and. ABS(eigval_diff) <= lanczos_eval_conv_thr ) THEN
             !
             ! lanczos has converged
             ! set max number of iternations to current iteration
             !
             !write(785,*) 'converged step1'
             nlanc = ilanc
             ! increase lanczos counter for last step
             ! lowest_eigvec(:,:) = v_in(:,:)
             !
             ! the displ_vec going out should be: -Vmat(:,:,1), so
             ! put v1 to 0.0, then subtract Vmat(:,:,ilanc) few lines later
             v1(:,:) = 0.0_DP
          ENDIF
       ENDIF
       !
       ! correct v1 so that the move is made from the initial position
       v1(:,:) = v1(:,:) - Vmat(:,:,ilanc)
       !
    ELSEIF (ilanc > 1 .and. ilanc <= nlanc ) THEN
       !
       ! first generate current alpha
       !
       q(:,:) = force(:,:) - force_old(:,:)
       q(:,:) = -q(:,:)/lanczos_disp
       !
       ! alpha = dot( v1, q )
       !
       alpha = ddot(3*nat,vmat(:,:,ilanc),1,q(:,:),1)
       H(ilanc,ilanc) = alpha
       !
       ! then check convergence of the H matrix up to this step
       !
       ALLOCATE( eigvals(ilanc) )
       ! Hstep must mirror H's leading dimension so the dgemm LDB below
       ! (size(Hstep,1)) matches the storage layout; nlanc is clamped to DOF
       ! upstream and can be strictly less than size(H,1) = lanczos_max_size.
       ALLOCATE( Hstep(size(H,1), size(H,2)) )
       ALLOCATE( Htmp(ilanc,ilanc) )
       ! store the H matrix, because its overwritten by eigvecs on diagonalization
       Hstep(:,:) = H(:,:)
       Htmp = H(1:ilanc,1:ilanc)  !%! NS: add this step to remove a warning

       CALL diag(ilanc, Htmp, eigvals, 1 )
       Hstep(1:ilanc,1:ilanc) = Htmp
       !
       ! find the lowest eigenvalue in the vector
       !
       lowest_eigval = eigvals(1)
       id_min = 1
       DO i = 1, ilanc
          IF (eigvals(i) < lowest_eigval ) THEN
             lowest_eigval = eigvals(i)
             id_min = i
          ENDIF
       ENDDO
       !write (*,*) "Debug eigval", lowest_eigval
       !
       ! generate eigenvector in real space, corresponding to lowest eigenvalue
       !
       ! Hstep now stores eigvecs of H (in Lanczos basis).  The eigvec in
       ! coordinate space is  V * Hstep(:, id_min)  -- equivalent to
       !     lowest_eigvec(:) = matmul( Vmat(:,:,1:ilanc), Hstep(1:ilanc, id_min) )
       ! We call dgemm directly instead of matmul.  At these sizes (ilanc
       ! is O(lanczos_max_size), typically <= tens) the perf win is
       ! marginal; matmul would be a clean drop-in replacement if we ever
       ! want to ditch the BLAS stride contract below.
       !
       ! dgemm contract:  C = alpha * op(A) * op(B) + beta * C
       !
       !   CALL dgemm( transA, transB,  M,     N, K,
       !               alpha,  A, LDA,  B, LDB,
       !               beta,   C, LDC )
       !
       !   op(A) is M x K,  op(B) is K x N,  C is M x N.
       !
       !   Key subtlety: LDA / LDB / LDC are the *leading dimensions of the
       !   storage* (Fortran column-major column stride), NOT the operating
       !   dimensions M, K, N.  BLAS declares the formals as assumed-size
       !   (e.g. B(LDB, *)) so there is no shape or bounds check; the caller
       !   must pass the actual first dimension of the allocation that the
       !   slice was taken from.
       !
       ! This call:
       !   'N','N'             no transposes
       !   M = 3*nat           rows of Vmat(1:3, 1:nat) flattened
       !   N = 1               we take a single column Hstep(:, id_min)
       !   K = ilanc           columns of Vmat used / rows of Hstep used
       !   alpha = 1.0, beta = 0.0
       !   A = Vmat(:,:,1:ilanc),  LDA = 3*nat            (first dim of Vmat)
       !   B = Hstep(:, id_min),   LDB = size(Hstep,1)    (first dim of Hstep
       !                                                   as allocated)
       !   C = lowest_eigvec,      LDC = 3*nat
       !
       ! History note: LDB was previously passed as `ilanc` (the K
       ! dimension).  That compiles and -- with N = 1 -- silently returns
       ! correct numerics because dgemm never advances to a "next column"
       ! of B, so the stride is unused.  It would be a real bug the
       ! instant anyone extended the call to N > 1.  And it was not the
       ! heap-overflow cause either: the real overflow was the
       ! Hstep(:,:) = H(:,:) assignment above, when Hstep was allocated
       ! (nlanc, nlanc) but H is (lanczos_max_size, lanczos_max_size) and
       ! the DOF clamp drove nlanc below lanczos_max_size.  We now
       ! allocate Hstep to H's shape, so size(Hstep,1) = lanczos_max_size
       ! and LDB is the correct storage stride regardless of clamping.
       !
       CALL dgemm('N','N', 3*nat, 1, ilanc, 1.0_DP, &
                  Vmat(:,:,1:ilanc), 3*nat, &
                  Hstep(:, id_min),  size(Hstep,1), &
                  0.0_DP, lowest_eigvec, 3*nat)
       !
       ! The direction of the obtained eigenvector is random at this point, since both +/- directions
       ! are valid solutions.
       ! Check if the eigenvec points in the same direction as the pushing direction,
       ! if not, flip it. This is to coherently keep the same direction throughout the research.
       !
       dir = ddot(3*nat,lowest_eigvec,1, pushdir, 1)
       !write (*,*) "Lanczos::Debug dir:", dir
       IF ( dir < 0.D0 ) THEN
          lowest_eigvec(:,:) = -1.D0*lowest_eigvec(:,:)
       ENDIF
       !
       DEALLOCATE( eigvals, Hstep, Htmp )
       !
       ! Check for the convergence of the lanczos eigenvalue
       !
       eigval_diff = (lowest_eigval - lowest_eigval_old)/lowest_eigval_old
       !write (*,*) "Debug eigval:", ilanc, lowest_eigval_old, lowest_eigval, abs(eigval_diff)
       ! write(785,*) ilanc, lowest_eigval_old, lowest_eigval, abs(eigval_diff)
       !
       !IF ( ABS(eigval_diff) <= lanczos_eval_conv_thr ) THEN
       !IF ( ilanc.ge.lanczos_min_size .and. ABS(eigval_diff) <= lanczos_eval_conv_thr ) THEN
       IF ( (ilanc.ge.lanczos_min_size - 1) .and. ABS(eigval_diff) <= lanczos_eval_conv_thr ) THEN
          ! write(*,*) 'converged! in:',ilanc
          !write(785,*) 'converged! in:',ilanc
          !
          ! lanczos has converged
          ! set max number of iternations to current iteration
          nlanc = ilanc
          !
       ENDIF
       !
       ! if lanczos is not yet converged generate new lanczos vector
       !
       IF ( ilanc < nlanc ) THEN
          beta = H(ilanc,ilanc-1)
          !
          ! Generate lanczos vector, v = q - alpha*v1 - beta*v0
          v1(:,:) = q(:,:) - alpha*vmat(:,:,ilanc) - beta*vmat(:,:,ilanc-1)
          !
          ! orthogonalize vectors in accordance with previous ones ...
          DO j = 1, ilanc - 1
             v1(:,:) = v1(:,:) - ddot(3*nat, v1 ,1, Vmat(:,:,j),1)*Vmat(:,:,j)
          ENDDO
          !
          !  do stuff with the new vector
          !
          IF ( dnrm2(3*nat, v1(:,:), 1) < 1.0D-15 ) THEN
             !
             ! new lanczos vector very small, stop (converge)
             !
             ! In theory, this should happen only when ilanc exceeds the dimensionality of the problem (~3N)
             !
             ! write(785,*) 'new vector small!'
             !
          ELSE
             !
             ! normalize the new vector
             !
             v1(:,:) = v1(:,:)/dnrm2(3*nat,v1(:,:),1)
             !
             ! save it into Vmat
             Vmat(:,:,ilanc+1) = v1(:,:)
             !
             ! generate new beta
             beta = ddot(3*nat, q, 1, v1, 1)
             !
             ! store value to H
             H(ilanc+1,ilanc ) = beta
             H(ilanc, ilanc+1) = beta
             !
          ENDIF
          !
       END IF
       !
       ! correct v1 so that the move is made from the initial position
       v1(:,:) = v1(:,:) - Vmat(:,:,ilanc)
       !
    ENDIF
    !
    ! write data for next lanczos step
    !
    ! IF( ilanc > nlanc ) THEN
    !    write(785,*) 'moving back'
    !    ! final move back to initial position
    !    v1(:,:) = 0.D0
    !    v1(:,:) = v1(:,:) - Vmat(:,:,nlanc)
    ! ENDIF
    !
    ! Overwrite displ_vec by the next vector displacement, scaled to lanczos_disp
    !
    ! displ_vec(:,:) = v1(:,:)
    ! write(*,"(3(f9.4,1x))")v1
    ! write(*,*) "lanczos_disp",lanczos_disp
    displ_vec(:,:) = v1(:,:)*lanczos_disp
    !
    DEALLOCATE( q, v1 )
    !> [lanczos]
    !
  END SUBROUTINE lanczos


end submodule lanczos_routine
