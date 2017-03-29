DROP PROCEDURE BANINST1.PWAENRL2;

CREATE OR REPLACE PROCEDURE BANINST1.PWAENRL2(psTerm VARCHAR2
                                             ) IS

  /*
     TAREA: Actualizar la cantidad de inscritos en la programaci¿n acad¿mica
     FECHA: 17/03/2009
     AUTOR: GEPC
    MODULO: Programaci¿n academica

             * Etapas de actualizaci¿n
               7. UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS SSBXLST
               8. UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS SSBXLST

  Modificaci¿n: 07/04/2011
                GEPC
                * Se quito la tabla SWRERRP que era de auditoria

  */

  csY CONSTANT VARCHAR2(1) := 'Y';
  cn0 CONSTANT NUMBER(1)   := 0;

  BEGIN
      --UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS SSBXLST
      BEGIN
          UPDATE SSRRESV  Y
             SET Y.SSRRESV_ENRL  =  (SELECT NVL(COUNT(SFRSTCR_CRN),cn0)
                                       FROM SFRSTCR,
                                            STVRSTS,
                                            SGBSTDN
                                      WHERE SFRSTCR_TERM_CODE      = Y.SSRRESV_TERM_CODE
                                        AND SFRSTCR_CRN            = Y.SSRRESV_CRN
                                        AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                                        AND STVRSTS_INCL_SECT_ENRL = csY
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
           WHERE Y.SSRRESV_ENRL      <> (SELECT NVL(COUNT(SFRSTCR_CRN),cn0)
                                           FROM SFRSTCR,
                                                STVRSTS,
                                                SGBSTDN
                                          WHERE SFRSTCR_TERM_CODE      = Y.SSRRESV_TERM_CODE
                                            AND SFRSTCR_CRN            = Y.SSRRESV_CRN
                                            AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                                            AND STVRSTS_INCL_SECT_ENRL = csY
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
                                                                                         AND C.SSRRESV_TERM_CODE  = psTerm
                                                                                     )
                                            AND SFRSTCR_TERM_CODE  = psTerm
                                        )
             AND EXISTS (SELECT NULL
                           FROM SFRSTCR,
                                STVRSTS,
                                SGBSTDN
                          WHERE SFRSTCR_TERM_CODE      = Y.SSRRESV_TERM_CODE
                            AND SFRSTCR_CRN            = Y.SSRRESV_CRN
                            AND SFRSTCR_RSTS_CODE      = STVRSTS_CODE
                            AND STVRSTS_INCL_SECT_ENRL = csY
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
                                                                          AND C.SSRRESV_TERM_CODE = psTerm
                                                                      )
                            AND SFRSTCR_TERM_CODE  = psTerm
                        )
             AND Y.SSRRESV_TERM_CODE  = psTerm;

      EXCEPTION
          WHEN OTHERS THEN
               NULL;
      END;

      COMMIT;

      --UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS SSBXLST
      BEGIN
          UPDATE SSRRESV  Y
             SET Y.SSRRESV_WAIT_COUNT = (SELECT NVL(COUNT(SFRSTCR_CRN),cn0)
                                           FROM SFRSTCR,
                                                STVRSTS,
                                                SGBSTDN
                                          WHERE SFRSTCR_TERM_CODE     = Y.SSRRESV_TERM_CODE
                                            AND SFRSTCR_CRN           = Y.SSRRESV_CRN
                                            AND SFRSTCR_RSTS_CODE     = STVRSTS_CODE
                                            AND STVRSTS_WAIT_IND      = csY
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
           WHERE Y.SSRRESV_WAIT_COUNT <> (SELECT NVL(COUNT(SFRSTCR_CRN),cn0)
                                            FROM SFRSTCR,
                                                 STVRSTS,
                                                 SGBSTDN
                                           WHERE SFRSTCR_TERM_CODE     = Y.SSRRESV_TERM_CODE
                                             AND SFRSTCR_CRN           = Y.SSRRESV_CRN
                                             AND SFRSTCR_RSTS_CODE     = STVRSTS_CODE
                                             AND STVRSTS_WAIT_IND      = csY
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
                                                                                           AND SFRSTCR_TERM_CODE  = psTerm
                                                                                       )
                                             AND SFRSTCR_TERM_CODE  = psTerm
                                         )
             AND EXISTS (SELECT NULL
                           FROM SFRSTCR,
                                STVRSTS,
                                SGBSTDN
                          WHERE SFRSTCR_TERM_CODE     = Y.SSRRESV_TERM_CODE
                            AND SFRSTCR_CRN           = Y.SSRRESV_CRN
                            AND SFRSTCR_RSTS_CODE     = STVRSTS_CODE
                            AND STVRSTS_WAIT_IND      = csY
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
                                                                          AND C.SSRRESV_TERM_CODE  = psTerm
                                                                      )
                           AND SFRSTCR_TERM_CODE  = psTerm
                        )
             AND Y.SSRRESV_TERM_CODE   = psTerm;

       EXCEPTION
          WHEN OTHERS THEN
               NULL;
       END;

      COMMIT;

  END PWAENRL2;
/
