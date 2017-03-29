DROP PROCEDURE BANINST1.PWAREG2;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG2(psLevl VARCHAR2,
                                             psTerm VARCHAR2,
                                             pnSeq  INTEGER,
                                             psUser VARCHAR2,
                                             psStat VARCHAR2) IS

/*
    Tarea: Reglas de repetici?n (Segunda etapa)
             * Obtener los valores iniciales de los campos
               "SHRTCKN_REPEAT_COURSE_IND", "SHRTCKN_ACTIVITY_DATE", "SHRTCKN_REPEAT_SYS_IND",
               antes de actualizarlos y encaso de error restaurarlos.

    Fecha: 07/07/2011
   Modulo: Historia academica

*/

  vsCodErr VARCHAR2(5000) := NULL;

  CURSOR cuValorInicial IS
         SELECT SHRTCKN_PIDM              Pidm,
                SHRTCKN_TERM_CODE         Term,
                SHRTCKN_SEQ_NO            SeqN,
                SHRTCKN_CRN               Crn,
                SHRTCKN_SUBJ_CODE         Subj,
                SHRTCKN_CRSE_NUMB         Crse,
                SHRTCKN_REPEAT_COURSE_IND RepC,
                SHRTCKN_ACTIVITY_DATE     Acty,
                SHRTCKN_REPEAT_SYS_IND    RepS
           FROM SHRTCKN
          WHERE           (SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE, SHRTCKN_CRSE_NUMB)
                IN (SELECT SWRTCKN_PIDM, SWRTCKN_SUBJ_CODE, SWRTCKN_CRSE_NUMB
                      FROM SWRTCKN
                     WHERE SWRTCKN_SEQ       = pnSeq
                       AND SWRTCKN_LEVL_CODE = psLevl
                       AND SWRTCKN_TERM_CODE = psTerm
                   );

  BEGIN
      PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'I');

      FOR regVal IN cuValorInicial LOOP

          INSERT INTO SWNTCKN(SWNTCKN_SEQ,      SWNTCKN_PIDM,           SWNTCKN_TERM_CODE, SWNTCKN_SEQ_NO,
                              SWNTCKN_CRN,      SWNTCKN_SUBJ_CODE,      SWNTCKN_CRSE_NUMB, SWNTCKN_REPEAT_COURSE_IND,
                              SWNTCKN_ACTIVITY, SWNTCKN_REPEAT_SYS_IND, SWNTCKN_TERM,      SWNTCKN_LEVL_CODE,
                              SWNTCKN_USER
                             )
                       VALUES(pnSeq,            regVal.Pidm,            regVal.Term,       regVal.SeqN,
                              regVal.Crn,       regVal.Subj,            regVal.Crse,       regVal.RepC,
                              regVal.Acty,      regVal.RepS,            psTerm,            psLevl,
                              psUser
                             );

      END LOOP;

      COMMIT;

      PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'U');

  EXCEPTION
      WHEN OTHERS THEN
           vsCodErr := SQLCODE;
           ROLLBACK;

           PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'O', vsCodErr);

  END PWAREG2;
/


DROP PUBLIC SYNONYM PWAREG2;

CREATE PUBLIC SYNONYM PWAREG2 FOR BANINST1.PWAREG2;


GRANT EXECUTE ON BANINST1.PWAREG2 TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWAREG2 TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWAREG2 TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWAREG2 TO OAS_PUBLIC;

GRANT EXECUTE ON BANINST1.PWAREG2 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG2 TO WWW2_USER;
