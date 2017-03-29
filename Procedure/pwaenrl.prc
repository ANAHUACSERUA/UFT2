DROP PROCEDURE BANINST1.PWAENRL;

CREATE OR REPLACE PROCEDURE BANINST1.PWAENRL(psTerm VARCHAR2) IS

  /*
     TAREA: Actualizar la cantidad de inscritos en la programación académica
     FECHA: 17/03/2009
     AUTOR: GEPC
    MODULO: Programación academica

             * Etapas de actualización
               1. UPDATE INCORRECT ENROLLMENT COUNT ON SSBSECT
               2. UPDATE INCORRECT AVAILABLE SEATS COUNT ON SSBSECT
               3. UPDATE INCORRECT WAITING LIST COUNT ON SSBSECT
               4. UPDATE INCORRECT AVAILABLE WAITING LIST SEATS
               5. UPDATE ENROLLMENT COUNT ON XLIST RECORDS SSBXLST
               6. UPDATE INCORRECT AVAILABLE SEATS COUNT ON XLISTS SSBXLST
               7. UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS SSBXLST
               8. UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS SSBXLST
               9. UPDATE INCORRECT AVAILABLE SEATS COUNT ON RESERVED SEATS
  */

  vsErr  VARCHAR2(4000) := NULL;
  vnRows NUMBER        := 0;

  procedure InsertEatapa(psEtapa varchar2) is

  begin
      INSERT INTO SWRERRP(SWRERRP_ETAPA, SWRERRP_ACCION, SWRERRP_TERM_CODE, SWRERRP_CAMP_CODE, SWRERRP_ERROR, SWRERRP_CODE)
                   VALUES('EnrlBanner',  'UPDATE',       psTerm,            'UFT',            psEtapa,       vnRows);
  end InsertEatapa;

  procedure InsertError(psEtapa varchar2,
                        psError varchar2) is

  begin
      INSERT INTO SWRERRP(SWRERRP_ETAPA, SWRERRP_ACCION, SWRERRP_TERM_CODE, SWRERRP_CAMP_CODE, SWRERRP_TSSC_CODE, SWRERRP_ERROR)
                   VALUES('EnrlBanner',  'UPDATE',       psTerm,            'UFT',            psEtapa,           psError);
  end InsertError;

  BEGIN

      --UPDATE INCORRECT ENROLLMENT COUNT ON SSBSECT
      BEGIN
          UPDATE SSBSECT X
             SET (X.SSBSECT_ENRL,
                  X.SSBSECT_TOT_CREDIT_HRS) = (SELECT NVL(COUNT(SFRSTCR_CRN),0),
                                                      NVL(SUM(SFRSTCR_CREDIT_HR),0)
                                                 FROM SFRSTCR,
                                                      STVRSTS
                                                WHERE SFRSTCR_CRN            = X.SSBSECT_CRN
                                                  AND SFRSTCR_TERM_CODE      = X.SSBSECT_TERM_CODE
                                                  AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                                                  AND STVRSTS_INCL_SECT_ENRL = 'Y'
                                              ),
                 X.SSBSECT_CENSUS_ENRL      = (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                                 FROM SFRSTCR,
                                                      STVRSTS
                                                WHERE SFRSTCR_CRN             = X.SSBSECT_CRN
                                                  AND SFRSTCR_TERM_CODE       = X.SSBSECT_TERM_CODE
                                                  AND SFRSTCR_RSTS_CODE       = STVRSTS_CODE
                                                  AND STVRSTS_INCL_SECT_ENRL  = 'Y'
                                                  AND SFRSTCR_RSTS_DATE      <= X.SSBSECT_CENSUS_ENRL_DATE
                                              ),
                 X.SSBSECT_CENSUS_2_ENRL    = (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                                 FROM SFRSTCR,
                                                      STVRSTS
                                                WHERE SFRSTCR_CRN             = X.SSBSECT_CRN
                                                  AND SFRSTCR_TERM_CODE       = X.SSBSECT_TERM_CODE
                                                  AND SFRSTCR_RSTS_CODE       = STVRSTS_CODE
                                                  AND STVRSTS_INCL_SECT_ENRL  = 'Y'
                                                  AND SFRSTCR_RSTS_DATE      <= X.SSBSECT_CENSUS_2_DATE
                                              )
           WHERE X.SSBSECT_TERM_CODE = psTerm
             AND X.SSBSECT_ENRL     <> (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                          FROM SFRSTCR,
                                               STVRSTS
                                         WHERE SFRSTCR_TERM_CODE      = X.SSBSECT_TERM_CODE
                                           AND SFRSTCR_CRN            = X.SSBSECT_CRN
                                           AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                                           AND STVRSTS_INCL_SECT_ENRL = 'Y'
                                       )
             AND EXISTS (SELECT NULL
                           FROM SFRSTCR,
                                STVRSTS
                          WHERE SFRSTCR_TERM_CODE      = X.SSBSECT_TERM_CODE
                            AND SFRSTCR_CRN            = X.SSBSECT_CRN
                            AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                            AND STVRSTS_INCL_SECT_ENRL = 'Y'
                        );

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT ENROLLMENT COUNT ON SSBSECT');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiecoSSBSECT', vsErr);
      END;

      --UPDATE INCORRECT AVAILABLE SEATS COUNT ON SSBSECT
      BEGIN
          UPDATE SSBSECT
             SET SSBSECT_SEATS_AVAIL = (SSBSECT_MAX_ENRL      - SSBSECT_ENRL),
                 SSBSECT_WAIT_AVAIL  = (SSBSECT_WAIT_CAPACITY - SSBSECT_WAIT_COUNT)
           WHERE SSBSECT_TERM_CODE   = psTerm
             AND (   SSBSECT_SEATS_AVAIL <> (SSBSECT_MAX_ENRL      - SSBSECT_ENRL)
                  OR SSBSECT_WAIT_AVAIL  <> (SSBSECT_WAIT_CAPACITY - SSBSECT_WAIT_COUNT)
                 );

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT AVAILABLE SEATS COUNT ON SSBSECT');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiascoSSBSECT', vsErr);
      END;

      COMMIT;

      --UPDATE INCORRECT WAITING LIST COUNT ON SSBSECT
      BEGIN
          UPDATE SSBSECT
             SET SSBSECT_WAIT_COUNT   = (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                           FROM STVRSTS,
                                                SFRSTCR
                                          WHERE SFRSTCR_CRN       = SSBSECT_CRN
                                            AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                            AND SFRSTCR_RSTS_CODE = STVRSTS_CODE
                                            AND STVRSTS_WAIT_IND  = 'Y'
                                        )
            WHERE SSBSECT_TERM_CODE   = psTerm
              AND SSBSECT_WAIT_COUNT <> (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                           FROM STVRSTS,
                                                SFRSTCR
                                          WHERE SFRSTCR_CRN       = SSBSECT_CRN
                                            AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                            AND SFRSTCR_RSTS_CODE = STVRSTS_CODE
                                            AND STVRSTS_WAIT_IND  = 'Y'
                                        )
              AND EXISTS (SELECT NULL
                            FROM STVRSTS,
                                 SFRSTCR
                           WHERE SFRSTCR_CRN       = SSBSECT_CRN
                             AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                             AND SFRSTCR_RSTS_CODE = STVRSTS_CODE
                             AND STVRSTS_WAIT_IND  = 'Y'
                         );

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT WAITING LIST COUNT ON SSBSECT');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiwlcoSSBSECT', vsErr);
      END;

      --UPDATE INCORRECT AVAILABLE WAITING LIST SEATS
      BEGIN
          UPDATE SSBSECT
             SET SSBSECT_WAIT_AVAIL  = (SSBSECT_WAIT_CAPACITY - SSBSECT_WAIT_COUNT)
           WHERE SSBSECT_TERM_CODE   = psTerm
             AND SSBSECT_WAIT_AVAIL <> (SSBSECT_WAIT_CAPACITY - SSBSECT_WAIT_COUNT);

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT AVAILABLE WAITING LIST SEATS');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiawlSEATS', vsErr);
      END;

      COMMIT;

      --UPDATE ENROLLMENT COUNT ON XLIST RECORDS SSBXLST
      BEGIN
          UPDATE SSBXLST
             SET SSBXLST_ENRL  = (SELECT NVL(SUM(SSBSECT_ENRL),0)
                                    FROM SSBSECT,
                                         SSRXLST
                                   WHERE SSBSECT_TERM_CODE  = SSBXLST_TERM_CODE
                                     AND SSRXLST_TERM_CODE  = SSBXLST_TERM_CODE
                                     AND SSRXLST_XLST_GROUP = SSBXLST_XLST_GROUP
                                     AND SSRXLST_CRN        = SSBSECT_CRN
                                 )
           WHERE SSBXLST_ENRL <> (SELECT SUM(SSBSECT_ENRL)
                                    FROM SSBSECT,
                                         SSRXLST
                                   WHERE SSBSECT_TERM_CODE  = SSBXLST_TERM_CODE
                                     AND SSRXLST_TERM_CODE  = SSBXLST_TERM_CODE
                                     AND SSRXLST_XLST_GROUP = SSBXLST_XLST_GROUP
                                     AND SSRXLST_CRN        = SSBSECT_CRN
                                 )
             AND SSBXLST_TERM_CODE = psTerm;

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE ENROLLMENT COUNT ON XLIST RECORDS SSBXLST');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uecoxrSSBXLST', vsErr);
      END;

      --UPDATE INCORRECT AVAILABLE SEATS COUNT ON XLISTS SSBXLST
      BEGIN
          UPDATE SSBXLST
             SET SSBXLST_SEATS_AVAIL  = (SSBXLST_MAX_ENRL - SSBXLST_ENRL)
           WHERE SSBXLST_SEATS_AVAIL <> (SSBXLST_MAX_ENRL - SSBXLST_ENRL)
             AND SSBXLST_TERM_CODE    = psTerm;

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT AVAILABLE SEATS COUNT ON XLISTS SSBXLST');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiascoxSSBXLST', vsErr);
      END;

      COMMIT;

      --UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS SSBXLST
      BEGIN
          UPDATE SSRRESV  Y
             SET Y.SSRRESV_ENRL  =  (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                       FROM SFRSTCR,
                                            STVRSTS,
                                            SGBSTDN
                                      WHERE SFRSTCR_TERM_CODE      = Y.SSRRESV_TERM_CODE
                                        AND SFRSTCR_CRN            = Y.SSRRESV_CRN
                                        AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                                        AND STVRSTS_INCL_SECT_ENRL = 'Y'
                                        AND SFRSTCR_PIDM           = SGBSTDN_PIDM
                                        AND SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(F.SGBSTDN_TERM_CODE_EFF)
                                                                        FROM SGBSTDN F
                                                                       WHERE F.SGBSTDN_PIDM           = SGBSTDN_PIDM
                                                                         AND F.SGBSTDN_TERM_CODE_EFF <= Y.SSRRESV_TERM_CODE
                                                                     )
                                        AND (Y.SSRRESV_LEVL_CODE || Y.SSRRESV_MAJR_CODE ||
                                             Y.SSRRESV_CLAS_CODE || Y.ROWID )  = (SELECT MAX(G.SSRRESV_LEVL_CODE || G.SSRRESV_MAJR_CODE ||
                                                                                             G.SSRRESV_CLAS_CODE || G.ROWID  )
                                                                                    FROM SSRRESV G
                                                                                   WHERE (    G.SSRRESV_CLAS_CODE = F_CLASS_CALC_FNC(SGBSTDN_PIDM, SGBSTDN_LEVL_CODE, Y.SSRRESV_TERM_CODE)
                                                                                          OR  G.SSRRESV_CLAS_CODE IS NULL
                                                                                         )
                                                                                     AND (   G.SSRRESV_MAJR_CODE = SGBSTDN_MAJR_CODE_1
                                                                                          OR G.SSRRESV_MAJR_CODE IS NULL
                                                                                         )
                                                                                     AND (   G.SSRRESV_LEVL_CODE = SGBSTDN_LEVL_CODE
                                                                                          OR G.SSRRESV_LEVL_CODE IS NULL
                                                                                         )
                                                                                     AND G.SSRRESV_CRN       = Y.SSRRESV_CRN
                                                                                     AND G.SSRRESV_TERM_CODE = Y.SSRRESV_TERM_CODE
                                                                                 )
                                    )
           WHERE Y.SSRRESV_TERM_CODE  = psTerm
             AND Y.SSRRESV_ENRL      <> (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                           FROM SFRSTCR,
                                                STVRSTS,
                                                SGBSTDN
                                          WHERE SFRSTCR_TERM_CODE      = Y.SSRRESV_TERM_CODE
                                            AND SFRSTCR_CRN            = Y.SSRRESV_CRN
                                            AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                                            AND STVRSTS_INCL_SECT_ENRL = 'Y'
                                            AND SFRSTCR_PIDM           = SGBSTDN_PIDM
                                            AND SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                                            FROM SGBSTDN B
                                                                           WHERE B.SGBSTDN_PIDM           = SGBSTDN_PIDM
                                                                             AND B.SGBSTDN_TERM_CODE_EFF <= Y.SSRRESV_TERM_CODE
                                                                         )
                                            AND (Y.SSRRESV_LEVL_CODE || Y.SSRRESV_MAJR_CODE ||
                                                 Y.SSRRESV_CLAS_CODE || Y.ROWID )  = (SELECT MAX(C.SSRRESV_LEVL_CODE || C.SSRRESV_MAJR_CODE ||
                                                                                                 C.SSRRESV_CLAS_CODE || C.ROWID)
                                                                                        FROM SSRRESV C
                                                                                       WHERE (   C.SSRRESV_CLAS_CODE = F_CLASS_CALC_FNC(SGBSTDN_PIDM, SGBSTDN_LEVL_CODE, Y.SSRRESV_TERM_CODE )
                                                                                              OR C.SSRRESV_CLAS_CODE IS NULL
                                                                                             )
                                                                                         AND (   C.SSRRESV_MAJR_CODE = SGBSTDN_MAJR_CODE_1
                                                                                              OR C.SSRRESV_MAJR_CODE IS NULL
                                                                                             )
                                                                                         AND (   C.SSRRESV_LEVL_CODE = SGBSTDN_LEVL_CODE
                                                                                              OR C.SSRRESV_LEVL_CODE IS NULL
                                                                                             )
                                                                                         AND C.SSRRESV_CRN       = Y.SSRRESV_CRN
                                                                                         AND C.SSRRESV_TERM_CODE = Y.SSRRESV_TERM_CODE
                                                                                     )
                                        )
             AND EXISTS (SELECT NULL
                           FROM SFRSTCR,
                                STVRSTS,
                                SGBSTDN
                          WHERE SFRSTCR_TERM_CODE      = Y.SSRRESV_TERM_CODE
                            AND SFRSTCR_CRN            = Y.SSRRESV_CRN
                            AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                            AND STVRSTS_INCL_SECT_ENRL = 'Y'
                            AND SFRSTCR_PIDM           = SGBSTDN_PIDM
                            AND SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                            FROM SGBSTDN B
                                                           WHERE B.SGBSTDN_PIDM           = SGBSTDN_PIDM
                                                             AND B.SGBSTDN_TERM_CODE_EFF <= Y.SSRRESV_TERM_CODE
                                                         )
                            AND (Y.SSRRESV_LEVL_CODE || Y.SSRRESV_MAJR_CODE ||
                                 Y.SSRRESV_CLAS_CODE || Y.ROWID )  =  (SELECT MAX(C.SSRRESV_LEVL_CODE || C.SSRRESV_MAJR_CODE ||
                                                                                  C.SSRRESV_CLAS_CODE || C.ROWID)
                                                                         FROM SSRRESV C
                                                                        WHERE (   C.SSRRESV_CLAS_CODE = F_CLASS_CALC_FNC(SGBSTDN_PIDM, SGBSTDN_LEVL_CODE, Y.SSRRESV_TERM_CODE)
                                                                               OR C.SSRRESV_CLAS_CODE IS NULL
                                                                              )
                                                                          AND (   C.SSRRESV_MAJR_CODE = SGBSTDN_MAJR_CODE_1
                                                                               OR C.SSRRESV_MAJR_CODE IS NULL
                                                                              )
                                                                          AND (   C.SSRRESV_LEVL_CODE = SGBSTDN_LEVL_CODE
                                                                               OR C.SSRRESV_LEVL_CODE IS NULL
                                                                              )
                                                                          AND C.SSRRESV_CRN       = Y.SSRRESV_CRN
                                                                          AND C.SSRRESV_TERM_CODE = Y.SSRRESV_TERM_CODE
                                                                      )
                        );

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS SSBXLST');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiecorsSSBXLST', vsErr);
      END;

      COMMIT;

      --UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS SSBXLST
      BEGIN
          UPDATE SSRRESV  Y
             SET Y.SSRRESV_WAIT_COUNT = (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                           FROM SFRSTCR,
                                                STVRSTS,
                                                SGBSTDN
                                          WHERE SFRSTCR_TERM_CODE     = Y.SSRRESV_TERM_CODE
                                            AND SFRSTCR_CRN           = Y.SSRRESV_CRN
                                            AND SFRSTCR_RSTS_CODE     = STVRSTS_CODE
                                            AND STVRSTS_WAIT_IND      = 'Y'
                                            AND SFRSTCR_PIDM          = SGBSTDN_PIDM
                                            AND SGBSTDN_TERM_CODE_EFF = (SELECT MAX(F.SGBSTDN_TERM_CODE_EFF)
                                                                           FROM SGBSTDN F
                                                                          WHERE F.SGBSTDN_PIDM = SGBSTDN_PIDM
                                                                            AND F.SGBSTDN_TERM_CODE_EFF <= Y.SSRRESV_TERM_CODE)
                                                                            AND (Y.SSRRESV_LEVL_CODE || Y.SSRRESV_MAJR_CODE ||
                                                                                 Y.SSRRESV_CLAS_CODE || Y.ROWID )  =  (SELECT MAX(G.SSRRESV_LEVL_CODE || G.SSRRESV_MAJR_CODE ||
                                                                                                                                  G.SSRRESV_CLAS_CODE || G.ROWID)
                                                                                                                         FROM SSRRESV G
                                                                                                                        WHERE (   G.SSRRESV_CLAS_CODE = F_CLASS_CALC_FNC(SGBSTDN_PIDM, SGBSTDN_LEVL_CODE, Y.SSRRESV_TERM_CODE )
                                                                                                                               OR G.SSRRESV_CLAS_CODE IS NULL
                                                                                                                              )
                                                                                                                          AND (   G.SSRRESV_MAJR_CODE = SGBSTDN_MAJR_CODE_1
                                                                                                                               OR G.SSRRESV_MAJR_CODE IS NULL
                                                                                                                              )
                                                                                                                          AND (   G.SSRRESV_LEVL_CODE = SGBSTDN_LEVL_CODE
                                                                                                                               OR G.SSRRESV_LEVL_CODE IS NULL
                                                                                                                              )
                                                                                                                          AND G.SSRRESV_CRN       = Y.SSRRESV_CRN
                                                                                                                          AND G.SSRRESV_TERM_CODE = Y.SSRRESV_TERM_CODE
                                                                                                                      )
                                        )
           WHERE Y.SSRRESV_TERM_CODE   = psTerm
             AND Y.SSRRESV_WAIT_COUNT <> (SELECT NVL(COUNT(SFRSTCR_CRN),0)
                                            FROM SFRSTCR,
                                                 STVRSTS,
                                                 SGBSTDN
                                           WHERE SFRSTCR_TERM_CODE     = Y.SSRRESV_TERM_CODE
                                             AND SFRSTCR_CRN           = Y.SSRRESV_CRN
                                             AND SFRSTCR_RSTS_CODE     = STVRSTS_CODE
                                             AND STVRSTS_WAIT_IND      = 'Y'
                                             AND SFRSTCR_PIDM          = SGBSTDN_PIDM
                                             AND SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                                            FROM SGBSTDN B
                                                                           WHERE B.SGBSTDN_PIDM           = SGBSTDN_PIDM
                                                                             AND B.SGBSTDN_TERM_CODE_EFF <= Y.SSRRESV_TERM_CODE
                                                                         )
                                             AND (Y.SSRRESV_LEVL_CODE || Y.SSRRESV_MAJR_CODE ||
                                                  Y.SSRRESV_CLAS_CODE || Y.ROWID )  =  (SELECT MAX(C.SSRRESV_LEVL_CODE || C.SSRRESV_MAJR_CODE ||
                                                                                                   C.SSRRESV_CLAS_CODE || C.ROWID)
                                                                                          FROM SATURN.SSRRESV C
                                                                                         WHERE (   C.SSRRESV_CLAS_CODE = F_CLASS_CALC_FNC(SGBSTDN_PIDM, SGBSTDN_LEVL_CODE, Y.SSRRESV_TERM_CODE)
                                                                                                OR C.SSRRESV_CLAS_CODE IS NULL
                                                                                               )
                                                                                           AND (   C.SSRRESV_MAJR_CODE = SGBSTDN_MAJR_CODE_1
                                                                                                OR C.SSRRESV_MAJR_CODE IS NULL
                                                                                               )
                                                                                           AND (   C.SSRRESV_LEVL_CODE = SGBSTDN_LEVL_CODE
                                                                                                OR C.SSRRESV_LEVL_CODE IS NULL)
                                                                                           AND C.SSRRESV_CRN       = Y.SSRRESV_CRN
                                                                                           AND C.SSRRESV_TERM_CODE = Y.SSRRESV_TERM_CODE
                                                                                       )
                                         )
             AND EXISTS (SELECT NULL
                           FROM SFRSTCR,
                                STVRSTS,
                                SGBSTDN
                          WHERE SFRSTCR_TERM_CODE     = Y.SSRRESV_TERM_CODE
                            AND SFRSTCR_CRN           = Y.SSRRESV_CRN
                            AND SFRSTCR_RSTS_CODE     = STVRSTS_CODE
                            AND STVRSTS_WAIT_IND      = 'Y'
                            AND SFRSTCR_PIDM          = SGBSTDN_PIDM
                            AND SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                           FROM SGBSTDN B
                                                          WHERE B.SGBSTDN_PIDM           = SGBSTDN_PIDM
                                                            AND B.SGBSTDN_TERM_CODE_EFF <= Y.SSRRESV_TERM_CODE
                                                        )
                            AND (Y.SSRRESV_LEVL_CODE || Y.SSRRESV_MAJR_CODE ||
                                 Y.SSRRESV_CLAS_CODE || Y.ROWID )  =  (SELECT MAX(C.SSRRESV_LEVL_CODE || C.SSRRESV_MAJR_CODE ||
                                                                                  C.SSRRESV_CLAS_CODE || C.ROWID)
                                                                         FROM SSRRESV C
                                                                        WHERE (   C.SSRRESV_CLAS_CODE = F_CLASS_CALC_FNC( SGBSTDN_PIDM, SGBSTDN_LEVL_CODE, Y.SSRRESV_TERM_CODE)
                                                                               OR C.SSRRESV_CLAS_CODE IS NULL
                                                                              )
                                                                          AND (   C.SSRRESV_MAJR_CODE = SGBSTDN_MAJR_CODE_1
                                                                               OR C.SSRRESV_MAJR_CODE IS NULL
                                                                              )
                                                                          AND (   C.SSRRESV_LEVL_CODE = SGBSTDN_LEVL_CODE
                                                                               OR C.SSRRESV_LEVL_CODE IS NULL
                                                                              )
                                                                          AND C.SSRRESV_CRN       = Y.SSRRESV_CRN
                                                                          AND C.SSRRESV_TERM_CODE = Y.SSRRESV_TERM_CODE
                                                                      )
                        );

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS SSBXLST');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiwlcorsSSBXLST', vsErr);
      END;

      --UPDATE INCORRECT  AVAILABLE  SEATS  COUNT ON RESERVED SEATS
      BEGIN
          UPDATE SSRRESV
             SET SSRRESV_SEATS_AVAIL = (SSRRESV_MAX_ENRL - SSRRESV_ENRL) ,
                 SSRRESV_WAIT_AVAIL  = (SSRRESV_WAIT_CAPACITY - SSRRESV_WAIT_COUNT)
           WHERE SSRRESV_TERM_CODE = psTerm
             AND (   SSRRESV_SEATS_AVAIL <> (SSRRESV_MAX_ENRL - SSRRESV_ENRL)
                  OR SSRRESV_WAIT_AVAIL  <> (SSRRESV_WAIT_CAPACITY - SSRRESV_WAIT_COUNT)
                 );

          vnRows := SQL%ROWCOUNT;

          InsertEatapa('UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS SSBXLST');

      EXCEPTION
          WHEN OTHERS THEN
               vsErr := SUBSTR(SQLERRM,1,4000);

               InsertError('uiwlcorsSSBXLST', vsErr);
      END;

      COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
           vsErr := SUBSTR(SQLERRM,1,4000);

           InsertError('JobEnrl', vsErr);

  END PWAENRL;
/
