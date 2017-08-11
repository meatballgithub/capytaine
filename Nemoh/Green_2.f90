MODULE Green_2

  USE Green_1, ONLY: COMPUTE_ASYMPTOTIC_S0
  USE Initialize_Green_2

  IMPLICIT NONE

  REAL, PARAMETER :: DPI  = 6.283185307179586 ! 2π
  REAL, PARAMETER :: DPI2 = 19.73920880217871 ! 2π²

CONTAINS

  REAL FUNCTION PL2(U1,U2,U3,XU)
    REAL::U1,U2,U3,XU
    PL2=((XU-U1)*(XU-U2))/((U3-U1)*(U3-U2))
    RETURN
  END FUNCTION

  SUBROUTINE COMPUTE_S2(XI, XJ, depth, wavenumber, FS, VS)

    ! Inputs
    REAL, DIMENSION(3),    INTENT(IN)  :: XI, XJ
    REAL,                  INTENT(IN)  :: depth, wavenumber

    ! Outputs
    COMPLEX,               INTENT(OUT) :: FS
    COMPLEX, DIMENSION(3), INTENT(OUT) :: VS

    ! Local variables
    INTEGER                            :: KI, KJ
    REAL                               :: RRR, AKR, ZZZ, AKZ, DD, PSURR
    REAL                               :: SIK, CSK, SQ, EPZ
    REAL                               :: PD1X, PD2X, PD1Z, PD2Z
    REAL, DIMENSION(3)                 :: XL, ZL

    RRR = NORM2(XI(1:2) - XJ(1:2))
    AKR = wavenumber*RRR

    ZZZ = XI(3) + XJ(3)
    AKZ = wavenumber*ZZZ

    DD  = SQRT(RRR**2 + ZZZ**2)

    IF ((DD > 1e-5) .AND. (wavenumber > 0)) THEN
      PSURR = PI/(wavenumber*DD)**3
    ELSE
      PSURR = 0.0
    ENDIF

    ! IF (AKZ > -1.5e-6) THEN
    !   WRITE(*,*)'AKZ < -1.5 E-6' ! Not a very explicit warning...
    ! END IF

    IF (AKZ > -16) THEN             !   -16 < AKZ < -1.5e-6

      !================================================
      ! Evaluate PDnX and PDnZ depending on AKZ and AKR
      !================================================

      IF (AKR < 99.7) THEN          !     0 < AKR < 99.7

        IF (AKZ < -1e-2) THEN       !   -16 < AKZ < -1e-2
          KJ = INT(8*(ALOG10(-AKZ)+4.5))
        ELSE                        ! -1e-2 < AKZ < -1.5e-6
          KJ = INT(5*(ALOG10(-AKZ)+6))
        ENDIF
        KJ = MAX(MIN(KJ, 45), 2)

        IF (AKR < 1) THEN           !     0 < AKR < 1
          KI = INT(5*(ALOG10(AKR+1e-20)+6)+1)
        ELSE                        !     1 < AKR < 99.7
          KI = INT(3*AKR+28)
        ENDIF
        KI = MAX(MIN(KI, 327), 2)

        XL(1) = PL2(XR(KI),   XR(KI+1), XR(KI-1), AKR)
        XL(2) = PL2(XR(KI+1), XR(KI-1), XR(KI),   AKR)
        XL(3) = PL2(XR(KI-1), XR(KI),   XR(KI+1), AKR)
        ZL(1) = PL2(XZ(KJ),   XZ(KJ+1), XZ(KJ-1), AKZ)
        ZL(2) = PL2(XZ(KJ+1), XZ(KJ-1), XZ(KJ),   AKZ)
        ZL(3) = PL2(XZ(KJ-1), XZ(KJ),   XZ(KJ+1), AKZ)

        PD1Z = DOT_PRODUCT(XL, MATMUL(APD1Z(KI-1:KI+1, KJ-1:KJ+1), ZL))
        PD2Z = DOT_PRODUCT(XL, MATMUL(APD2Z(KI-1:KI+1, KJ-1:KJ+1), ZL))

        IF (RRR > 1e-5) THEN
          PD1X = DOT_PRODUCT(XL, MATMUL(APD1X(KI-1:KI+1, KJ-1:KJ+1), ZL))
          PD2X = DOT_PRODUCT(XL, MATMUL(APD2X(KI-1:KI+1, KJ-1:KJ+1), ZL))
        END IF

      ELSE  ! 99.7 < AKR

        EPZ  = EXP(AKZ)
        SQ   = SQRT(2*PI/AKR)
        CSK  = COS(AKR-PI/4)
        SIK  = SIN(AKR-PI/4)

        PD1Z = PSURR*AKZ - PI*EPZ*SQ*SIK
        PD2Z =                EPZ*SQ*CSK

        IF (RRR > 1e-5) THEN
          ! PD1X=-PSURR*AKR-PI*EPZ*SQ*(CSK-0.5/AKR*SIK) ! correction par GD le 17/09/2010
          PD1X = PI*EPZ*SQ*(CSK - 0.5*SIK/AKR) - PSURR*AKR
          PD2X =    EPZ*SQ*(SIK + 0.5*CSK/AKR)
        END IF

      ENDIF

      !====================================
      ! Deduce FS ans VS from PDnX and PDnZ
      !====================================

      FS    = -CMPLX(PD1Z, PD2Z)
      IF (depth == 0.0) THEN
        VS(3) = -CMPLX(PD1Z-PSURR*AKZ, PD2Z)
      ELSE
        VS(3) = -CMPLX(PD1Z, PD2Z)
      END IF

      IF (RRR > 1e-5) THEN
        IF (depth == 0.0) THEN
          VS(1) = (XI(1) - XJ(1))/RRR * CMPLX(PD1X+PSURR*AKR, PD2X)
          VS(2) = (XI(2) - XJ(2))/RRR * CMPLX(PD1X+PSURR*AKR, PD2X)
        ELSE
          VS(1) = (XI(1) - XJ(1))/RRR * CMPLX(PD1X, PD2X)
          VS(2) = (XI(2) - XJ(2))/RRR * CMPLX(PD1X, PD2X)
        END IF
      ELSE
        VS(1:2) = CMPLX(0.0, 0.0)
      END IF

    ELSE ! AKZ < -16
      FS      = CMPLX(-PSURR*AKZ, 0.0)
      VS(1:3) = CMPLX(0.0, 0.0)
    ENDIF

    RETURN
  END SUBROUTINE COMPUTE_S2

  SUBROUTINE VNSINFD             &
      (wavenumber, X0I, X0J, AJ, &
      SP, SM, VSP, VSM)
    ! Compute the frequency-dependent part of the Green function in the infinite depth case.

    ! Inputs
    REAL,               INTENT(IN)  :: wavenumber, AJ
    REAL, DIMENSION(3), INTENT(IN)  :: X0I   ! Coordinates of the source point
    REAL, DIMENSION(3), INTENT(IN)  :: X0J   ! Coordinates of the center of the integration panel

    ! Outputs
    COMPLEX,               INTENT(OUT) :: SP, SM   ! Integral of the Green function over the panel.
    COMPLEX, DIMENSION(3), INTENT(OUT) :: VSP, VSM ! Gradient of the integral of the Green function with respect to X0I.

    ! Local variables
    REAL                               :: ADPI, ADPI2, AKDPI, AKDPI2
    REAL, DIMENSION(3)       :: XI
    COMPLEX, DIMENSION(1)    :: FS
    COMPLEX, DIMENSION(3, 1) :: VS

    XI(:) = X0I(:)
    ! XI(3) = MIN(X0I(3), -1e-5*Mesh%xy_diameter)
    CALL COMPUTE_S2(XI, X0J, 0.0, wavenumber, FS(1), VS(:, 1))

    ! IF (Mesh%Isym == 0) THEN
    SP       = FS(1)
    VSP(1:3) = VS(1:3, 1)
    SM       = CMPLX(0.0, 0.0)
    VSM      = CMPLX(0.0, 0.0)

    ! ELSE IF (Mesh%Isym == 1) THEN
    !   ! Reflect the source point across the (xOz) plane and compute another coefficient
    !   XI(2) = -X0I(2)
    !   CALL COMPUTE_S2(XI, X0J, wavenumber, FS(2), VS(:, 2))
    !   VS(2, 2) = -VS(2, 2) ! Reflection of the output vector

    !   ! Assemble the two results
    !   SP       = FS(1)      + FS(2)
    !   VSP(1:3) = VS(1:3, 1) + VS(1:3, 2)
    !   SM       = FS(1)      - FS(2)
    !   VSM(1:3) = VS(1:3, 1) - VS(1:3, 2)
    ! END IF

    ADPI2  = wavenumber*AJ/DPI2
    ADPI   = wavenumber*AJ/DPI
    AKDPI2 = wavenumber**2*AJ/DPI2
    AKDPI  = wavenumber**2*AJ/DPI

    SP  = CMPLX(REAL(SP)*ADPI2,   AIMAG(SP)*ADPI)
    VSP = CMPLX(REAL(VSP)*AKDPI2, AIMAG(VSP)*AKDPI)

    ! IF (Mesh%ISym == Y_SYMMETRY) THEN
    !   SM  = CMPLX(REAL(SM)*ADPI2,   AIMAG(SM)*ADPI)
    !   VSM = CMPLX(REAL(VSM)*AKDPI2, AIMAG(VSM)*AKDPI)
    ! END IF

    RETURN
  END SUBROUTINE VNSINFD

  SUBROUTINE VNSFD &
      (wavenumber, X0I, X0J, AJ, depth, &
      SP, SM, VSP, VSM)
    ! Compute the frequency-dependent part of the Green function in the finite depth case.

    ! Inputs
    REAL,               INTENT(IN)  :: wavenumber, AJ, depth
    REAL, DIMENSION(3), INTENT(IN)  :: X0I   ! Coordinates of the source point
    REAL, DIMENSION(3), INTENT(IN)  :: X0J   ! Coordinates of the center of the integration panel

    ! Outputs
    COMPLEX,               INTENT(OUT) :: SP, SM   ! Integral of the Green function over the panel.
    COMPLEX, DIMENSION(3), INTENT(OUT) :: VSP, VSM ! Gradient of the integral of the Green function with respect to X0I.

    ! Local variables
    INTEGER                                :: KE
    REAL                                   :: AMH, AKH, A, COF1, COF2, COF3, COF4
    REAL                                   :: AQT, RRR
    REAL, DIMENSION(3)                     :: XI, XJ
    REAL, DIMENSION(4, 1)       :: FTS, PSR
    REAL, DIMENSION(3, 4, 1)    :: VTS
    COMPLEX, DIMENSION(4, 1)    :: FS
    COMPLEX, DIMENSION(3, 4, 1) :: VS

    !========================================
    ! Part 1: Solve 4 infinite depth problems
    !========================================

    XI(:) = X0I(:)
    ! XI(3) = MIN(X0I(3), -EPS*Mesh%xy_diameter)
    XJ(:) = X0J(:)

    ! Distance in xOy plane
    RRR = NORM2(XI(1:2) - XJ(1:2))

    ! 1.a First infinite depth problem
    CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(1, 1), VS(:, 1, 1))

    PSR(1, 1) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    ! 1.b Shift and reflect XI and compute another value of the Green function
    XI(3) = -X0I(3) - 2*depth
    XJ(3) =  X0J(3)
    CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(2, 1), VS(:, 2, 1))
    VS(3, 2, 1) = -VS(3, 2, 1) ! Reflection of the output vector

    PSR(2, 1) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    ! 1.c Shift and reflect XJ and compute another value of the Green function
    XI(3) =  X0I(3)
    XJ(3) = -X0J(3) - 2*depth
    CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(3, 1), VS(:, 3, 1))

    PSR(3, 1) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    ! 1.d Shift and reflect both XI and XJ and compute another value of the Green function
    XI(3) = -X0I(3) - 2*depth
    XJ(3) = -X0J(3) - 2*depth
    CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(4, 1), VS(:, 4, 1))
    VS(3, 4, 1) = -VS(3, 4, 1) ! Reflection of the output vector

    PSR(4, 1) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    ! IF (Mesh%ISym == NO_Y_SYMMETRY) THEN
      ! Add up the results of the four problems
      SP       = -SUM(FS(1:4, 1)) - SUM(PSR(1:4, 1))
      VSP(1:3) = -SUM(VS(1:3, 1:4, 1), 2)
      SM       = CMPLX(0.0, 0.0)
      VSM      = CMPLX(0.0, 0.0)

    ! ELSE IF (Mesh%ISym == Y_SYMMETRY) THEN
    !   ! If the y-symmetry is used, the four symmetric problems have to be solved
    !   XI(:) = X0I(:)
    !   XI(2) = -XI(2)
    !   ! XI(3) = MIN(X0I(3), -EPS*Mesh%xy_diameter)
    !   XJ(:) = X0J(:)

    !   RRR = NORM2(XI(1:2) - XJ(1:2))

    !   ! 1.a' First infinite depth problem
    !   CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(1, 2), VS(:, 1, 2))

    !   PSR(1, 2) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    !   ! 1.b' Shift and reflect XI and compute another value of the Green function
    !   XI(3) = -X0I(3) - 2*depth
    !   XJ(3) =  X0J(3)
    !   CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(2, 2), VS(:, 2, 2))
    !   VS(3, 2, 2) = -VS(3, 2, 2)

    !   PSR(2, 2) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    !   ! 1.c' Shift and reflect XJ and compute another value of the Green function
    !   XI(3) =  X0I(3)
    !   XJ(3) = -X0J(3) - 2*depth
    !   CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(3, 2), VS(:, 3, 2))

    !   PSR(3, 2) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    !   ! 1.d' Shift and reflect both XI and XJ and compute another value of the Green function
    !   XI(3) = -X0I(3) - 2*depth
    !   XJ(3) = -X0J(3) - 2*depth
    !   CALL COMPUTE_S2(XI(:), XJ(:), depth, wavenumber, FS(4, 2), VS(:, 4, 2))
    !   VS(3, 4, 2) = -VS(3, 4, 2)

    !   PSR(4, 2) = PI/(wavenumber*SQRT(RRR**2+(XI(3)+XJ(3))**2))

    !   ! Reflection of the four output vectors around xOz plane
    !   VS(2, 1:4, 2) = -VS(2, 1:4, 2)

    !   ! Add up the results of the 2×4 problems
    !   SP       = -SUM(FS(1:4, 1)) - SUM(PSR(1:4, 1)) - SUM(FS(1:4, 2)) - SUM(PSR(1:4, 2))
    !   VSP(1:3) = -SUM(VS(1:3, 1:4, 1), 2)            - SUM(VS(1:3, 1:4, 2), 2)
    !   SM       = -SUM(FS(1:4, 1)) - SUM(PSR(1:4, 1)) + SUM(FS(1:4, 2)) + SUM(PSR(1:4, 2))
    !   VSM(1:3) = -SUM(VS(1:3, 1:4, 1), 2)            + SUM(VS(1:3, 1:4, 2), 2)
    ! END IF

    ! Multiply by some coefficients
    AMH  = wavenumber*depth
    AKH  = AMH*TANH(AMH)
    A    = (AMH+AKH)**2/(depth*(AMH**2-AKH**2+AKH))
    COF1 = -A/(8*PI**2)*AJ
    COF2 = -A/(8*PI)   *AJ
    COF3 = wavenumber*COF1
    COF4 = wavenumber*COF2

    SP  = CMPLX(REAL(SP)*COF1,  AIMAG(SP)*COF2)
    VSP = CMPLX(REAL(VSP)*COF3, AIMAG(VSP)*COF4)

    ! IF (Mesh%ISym == Y_SYMMETRY) THEN
    !   SM  = CMPLX(REAL(SM)*COF1,  AIMAG(SM)*COF2)
    !   VSM = CMPLX(REAL(VSM)*COF3, AIMAG(VSM)*COF4)
    ! END IF

    !=====================================================
    ! Part 2: Integrate (NEXP+1)×4 terms of the form 1/MM'
    !=====================================================

    AMBDA(NEXP+1) = 0
    AR(NEXP+1)    = 2

    DO KE = 1, NEXP+1
      XI(:) = X0I(:)

      ! 2.a Shift observation point and compute integral
      XI(3) =  X0I(3) + depth*AMBDA(KE) - 2*depth
      CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(1, 1), VTS(:, 1, 1))

      ! 2.b Shift and reflect observation point and compute integral
      XI(3) = -X0I(3) - depth*AMBDA(KE)
      CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(2, 1), VTS(:, 2, 1))
      VTS(3, 2, 1) = -VTS(3, 2, 1) ! Reflection of the output vector

      ! 2.c Shift and reflect observation point and compute integral
      XI(3) = -X0I(3) + depth*AMBDA(KE) - 4*depth
      CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(3, 1), VTS(:, 3, 1))
      VTS(3, 3, 1) = -VTS(3, 3, 1) ! Reflection of the output vector

      ! 2.d Shift observation point and compute integral
      XI(3) =  X0I(3) - depth*AMBDA(KE) + 2*depth
      CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(4, 1), VTS(:, 4, 1))

      AQT = -AR(KE)/(8*PI)

      ! IF (Mesh%ISym == NO_Y_SYMMETRY) THEN
        ! Add all the contributions
        SP     = SP     + AQT*SUM(FTS(1:4, 1))
        VSP(:) = VSP(:) + AQT*SUM(VTS(1:3, 1:4, 1), 2)

      ! ELSE IF (Mesh%ISym == Y_SYMMETRY) THEN
      !   ! If the y-symmetry is used, the four symmetric problems have to be solved
      !   XI = X0I(:)
      !   XI(2) = -X0I(2)

      !   ! 2.a' Shift observation point and compute integral
      !   XI(3) =  X0I(3) + depth*AMBDA(KE) - 2*depth
      !   CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(1, 2), VTS(:, 1, 2))

      !   ! 2.b' Shift and reflect observation point and compute integral
      !   XI(3) = -X0I(3) - depth*AMBDA(KE)
      !   CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(2, 2), VTS(:, 2, 2))
      !   VTS(3, 2, 2) = -VTS(3, 2, 2) ! Reflection of the output vector

      !   ! 2.c' Shift and reflect observation point and compute integral
      !   XI(3) = -X0I(3) + depth*AMBDA(KE) - 4*depth
      !   CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(3, 2), VTS(:, 3, 2))
      !   VTS(3, 3, 2) = -VTS(3, 3, 2) ! Reflection of the output vector

      !   ! 2.d' Shift observation point and compute integral
      !   XI(3) =  X0I(3) - depth*AMBDA(KE) + 2*depth
      !   CALL COMPUTE_ASYMPTOTIC_S0(XI(:), X0J(:), AJ, FTS(4, 2), VTS(:, 4, 2))

      !   ! Reflection of the output vector around the xOz plane
      !   VTS(2, 1:4, 2) = -VTS(2, 1:4, 2)

      !   ! Add all the contributions
      !   SP     = SP     + AQT*(SUM(FTS(1:4, 1))         + SUM(FTS(1:4, 2)))
      !   VSP(:) = VSP(:) + AQT*(SUM(VTS(1:3, 1:4, 1), 2) + SUM(VTS(1:3, 1:4, 2), 2))
      !   SM     = SM     + AQT*(SUM(FTS(1:4, 1))         - SUM(FTS(1:4, 2)))
      !   VSM(:) = VSM(:) + AQT*(SUM(VTS(1:3, 1:4, 1), 2) - SUM(VTS(1:3, 1:4, 2), 2))

      ! END IF
    END DO

    RETURN
  END SUBROUTINE

END MODULE Green_2