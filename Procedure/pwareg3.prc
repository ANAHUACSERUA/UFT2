DROP PROCEDURE BANINST1.PWAREG3;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG3(psLevl VARCHAR2,
                                             psTerm VARCHAR2,
                                             pnSeq  INTEGER,
                                             psUser VARCHAR2,
                                             psStat VARCHAR2) IS

/*
    Tarea: Reglas de repetici?n (Tercera etapa)
             * Actualizar los campos
               "SHRTCKN_REPEAT_COURSE_IND", "SHRTCKN_ACTIVITY_DATE", "SHRTCKN_REPEAT_SYS_IND",
               de las materias repetidas por los alumnos encontrados en la "etapa 1"

    Fecha: 07/07/2011

   Modulo: Historia academica

*/

  vsCodErr   VARCHAR2(50) := NULL;
  vnRowCount NUMBER       := 0;

  BEGIN
      PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'I');

      BEGIN
          UPDATE SHRTCKN
             SET SHRTCKN_REPEAT_COURSE_IND = NULL,
                 SHRTCKN_ACTIVITY_DATE     = SYSDATE,
                 SHRTCKN_REPEAT_SYS_IND    = NULL
           WHERE SHRTCKN_TERM_CODE        <= psTerm
             AND EXISTS (SELECT NULL
                           FROM SHRTCKL
                          WHERE SHRTCKL_PIDM        = SHRTCKN_PIDM
                            AND SHRTCKL_TERM_CODE   = SHRTCKN_TERM_CODE
                            AND SHRTCKL_TCKN_SEQ_NO = SHRTCKN_SEQ_NO
                            AND SHRTCKL_LEVL_CODE   = psLevl
                        )
              AND           (SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE, SHRTCKN_CRSE_NUMB)
                  IN (SELECT SWRTCKN_PIDM, SWRTCKN_SUBJ_CODE, SWRTCKN_CRSE_NUMB
                        FROM SWRTCKN
                       WHERE SWRTCKN_SEQ       = pnSeq
                         AND SWRTCKN_LEVL_CODE = psLevl
                         AND SWRTCKN_TERM_CODE = psTerm
                     );

          vnRowCount := SQL%ROWCOUNT;

      END;

      COMMIT;

      PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'U');

  EXCEPTION
      WHEN OTHERS THEN
           vsCodErr := SQLCODE;

           ROLLBACK;

           PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'O', vsCodErr);

  END PWAREG3;
/


DROP PUBLIC SYNONYM PWAREG3;

CREATE PUBLIC SYNONYM PWAREG3 FOR BANINST1.PWAREG3;


GRANT EXECUTE ON BANINST1.PWAREG3 TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWAREG3 TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWAREG3 TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWAREG3 TO OAS_PUBLIC;

GRANT EXECUTE ON BANINST1.PWAREG3 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG3 TO WWW2_USER;
