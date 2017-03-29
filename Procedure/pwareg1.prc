DROP PROCEDURE BANINST1.PWAREG1;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG1(psLevl VARCHAR2,
                                             psTerm VARCHAR2,
                                             pnSeq  INTEGER,
                                             psUser VARCHAR2,
                                             psStat VARCHAR2) IS

/*
    Tarea: Reglas de repetici?n (Primera etapa)
           Buscar las materias repetidas por los alumnos
    Fecha: 07/07/2011
   Modulo: Historia academica

*/

  vsCodErr VARCHAR2(5000) := NULL;

  CURSOR cuRegla IS
         SELECT SHRTCKN_PIDM      PIDM,
                SHRTCKN_SUBJ_CODE SUBJ,
                SHRTCKN_CRSE_NUMB CRSE,
                COUNT(1)
           FROM SHRTCKN,
                SHRTCKL
          WHERE SHRTCKL_PIDM        = SHRTCKN_PIDM
            AND SHRTCKL_TERM_CODE   = SHRTCKN_TERM_CODE
            AND SHRTCKL_TCKN_SEQ_NO = SHRTCKN_SEQ_NO
            AND SHRTCKL_LEVL_CODE   = psLevl
--            AND SHRTCKN_PIDM = 4450
          GROUP BY SHRTCKN_PIDM,
                   SHRTCKN_SUBJ_CODE,
                   SHRTCKN_CRSE_NUMB
         HAVING COUNT(1) > 1;

  BEGIN
      PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'I');

      FOR regRgl IN cuRegla LOOP

          INSERT INTO SWRTCKN(SWRTCKN_SEQ, SWRTCKN_PIDM, SWRTCKN_SUBJ_CODE, SWRTCKN_CRSE_NUMB, SWRTCKN_LEVL_CODE, SWRTCKN_TERM_CODE, SWRTCKN_USER)
                       VALUES(pnSeq,       regRgl.PIDM,  regRgl.SUBJ,       regRgl.CRSE,       psLevl,            psTerm,            psUser);

      END LOOP;

      COMMIT;

     PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'U');

  EXCEPTION
      WHEN OTHERS THEN
           vsCodErr := SQLCODE;

           ROLLBACK;

           PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'O', vsCodErr);

  END PWAREG1;
/


DROP PUBLIC SYNONYM PWAREG1;

CREATE PUBLIC SYNONYM PWAREG1 FOR BANINST1.PWAREG1;


GRANT EXECUTE ON BANINST1.PWAREG1 TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWAREG1 TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWAREG1 TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWAREG1 TO OAS_PUBLIC;

GRANT EXECUTE ON BANINST1.PWAREG1 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG1 TO WWW2_USER;
