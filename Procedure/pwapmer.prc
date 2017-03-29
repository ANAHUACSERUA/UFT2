DROP PROCEDURE BANINST1.PWAPMER;

CREATE OR REPLACE PROCEDURE BANINST1.PWAPMER (psTerm    VARCHAR2,
                            psCrnn    VARCHAR2,
                            psSecc    VARCHAR2,
                            psErro    VARCHAR2,
                            psSubb    VARCHAR2 DEFAULT 'A',
                            psAccn    VARCHAR2 DEFAULT 'I')
IS
   vnSecuencia    NUMBER (3) := 0;

   csA   CONSTANT VARCHAR2 (1) := 'A';
   csI   CONSTANT VARCHAR2 (1) := 'I';
   csD   CONSTANT VARCHAR2 (1) := 'D';
BEGIN
   SELECT NVL (MAX (SWRPMER_SEQN), 0) + 1
     INTO vnSecuencia
     FROM SWRPMER
    WHERE     SWRPMER_TERM_CODE = psTerm
          AND SWRPMER_CRN = psCrnn
          AND SWRPMER_SECC_CODE = psSecc
          AND NVL (SWRPMER_SUBB_SECC, csA) = psSubb;

   IF psAccn = csI
   THEN
      INSERT INTO SWRPMER (SWRPMER_TERM_CODE,
                           SWRPMER_CRN,
                           SWRPMER_SEQN,
                           SWRPMER_SECC_CODE,
                           SWRPMER_SUBB_SECC,
                           SWRPMER_ERROR)
           VALUES (psTerm,
                   psCrnn,
                   vnSecuencia,
                   psSecc,
                   psSubb,
                   SUBSTR (psErro, 1, 4000));
   ELSIF psAccn = csD
   THEN
      DELETE SWRPMER
       WHERE     SWRPMER_TERM_CODE = psTerm
             AND SWRPMER_CRN = psCrnn
             AND SWRPMER_SECC_CODE = psSecc
             AND NVL (SWRPMER_SUBB_SECC, csA) = NVL (psSubb, csA);
   END IF;

   COMMIT;
END PWAPMER;
/


DROP PUBLIC SYNONYM PWAPMER;

CREATE PUBLIC SYNONYM PWAPMER FOR BANINST1.PWAPMER;


GRANT EXECUTE ON BANINST1.PWAPMER TO WWW_USER;
