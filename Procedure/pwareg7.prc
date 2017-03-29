DROP PROCEDURE BANINST1.PWAREG7;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG7(psLevl   VARCHAR2,
                                             psTerm   VARCHAR2,
                                             pnSeq    INTEGER,
                                             psUser   VARCHAR2,
                                             psStat   VARCHAR2,
                                             psAccion VARCHAR2,
                                             psCodErr VARCHAR2 DEFAULT NULL) IS

/*
    Tarea: Ejecutar las Reglas de repetici?n (Primera etapa)
    Fecha: 07/07/2011
   Modulo: Historia academica



*/

vsCodErr Varchar2(5000);
  BEGIN


            IF    psAccion = 'I' THEN
            INSERT INTO SWNTCKA(SWNTCKA_SEQ, SWNTCKA_TERM_CODE, SWNTCKA_LEVL_CODE, SWNTCKA_PROCEDURE, SWNTCKA_USER)
                         VALUES(pnSeq,       psTerm,            psLevl,            'PWAREG'||psStat,  psUser);

      ELSIF psAccion = 'U' THEN
            UPDATE SWNTCKA
               SET SWNTCKA_END       = SYSDATE
             WHERE SWNTCKA_SEQ       = pnSeq
               AND SWNTCKA_TERM_CODE = psTerm
               AND SWNTCKA_LEVL_CODE = psLevl
               AND SWNTCKA_PROCEDURE = 'PWAREG'||psStat
               AND SWNTCKA_USER      = psUser;

      ELSIF psAccion = 'O' THEN
            UPDATE SWNTCKA
               SET SWNTCKA_ERROR     = SWNTCKA_ERROR||' '||psCodErr,
                   SWNTCKA_END       = SYSDATE
             WHERE SWNTCKA_SEQ       = pnSeq
               AND SWNTCKA_TERM_CODE = psTerm
               AND SWNTCKA_LEVL_CODE = psLevl
               AND SWNTCKA_PROCEDURE = 'PWAREG'||psStat
               AND SWNTCKA_USER      = psUser;

      END IF;


        EXCEPTION WHEN OTHERS then
        vsCodErr := SQLCODE;
COMMIT;
  END PWAREG7;
/


DROP PUBLIC SYNONYM PWAREG7;

CREATE PUBLIC SYNONYM PWAREG7 FOR BANINST1.PWAREG7;


GRANT EXECUTE ON BANINST1.PWAREG7 TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWAREG7 TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWAREG7 TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWAREG7 TO OAS_PUBLIC;

GRANT EXECUTE ON BANINST1.PWAREG7 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG7 TO WWW2_USER;
