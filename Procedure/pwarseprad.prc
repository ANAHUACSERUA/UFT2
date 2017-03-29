DROP PROCEDURE BANINST1.PWARSEPRAD;

CREATE OR REPLACE PROCEDURE BANINST1.PWARSEPRAD(psTerm  VARCHAR2,
                                                psEncu  VARCHAR2,
                                                psRate  VARCHAR2 DEFAULT NULL
                                               ) IS

/**************************************************************
           tarea:  realiza la seleción de información para el proceso seprad
          módulo:  resultados del sistema de evaluación de la práctica docente (seprad)
           autor:  horacio martínez ramírez - hmr
           fecha:  01/nov/2010
**************************************************************/

  csSIN    CONSTANT VARCHAR2(3) := 'SIN';
  csCOMENT CONSTANT VARCHAR2(6) := 'COMENT';
  csC      CONSTANT VARCHAR2(1) := 'C';

  BEGIN
      INSERT INTO SWRPSPD
      (SWRPSPD_TERM_CODE,SWRPSPD_FACULTY_PIDM,SWRPSPD_PIDM,
       SWRPSPD_TEMP_PIDM,SWRPSPD_CRN
      )
      SELECT
       SVRESAS_TERM_CODE,SVRESAS_FACULTY_PIDM,SVRESAS_PIDM,
       SVRESAS_TEMP_PIDM,SVRESAS_CRN
        FROM SVRESAS INNER JOIN SWRPGAC ON (SVRESAS_CRN = SWRPGAC_CRN AND SVRESAS_TERM_CODE = SWRPGAC_TERM_CODE)
       WHERE (
                 psRate IS NULL
              OR
                 SVRESAS_PIDM IN (SELECT A.SGBSTDN_PIDM
                                    FROM SGBSTDN A
                                   WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                                      FROM SGBSTDN B
                                                                     WHERE B.SGBSTDN_PIDM = A.SGBSTDN_PIDM
                                                                   )
                                     AND NVL(A.SGBSTDN_RATE_CODE,csSIN) = psRate
                                 )
             )
         AND EXISTS (SELECT NULL
                       FROM SVBTESH
                      WHERE SVBTESH_TSSC_CODE       = SVRESAS_TSSC_CODE
                        AND SVBTESH_ESAS_STATUS_IND = csC
                        AND SVBTESH_FACULTY_PIDM    = SVRESAS_FACULTY_PIDM
                        AND SVBTESH_CRN             = SVRESAS_CRN
                        AND SVBTESH_TERM_CODE       = psTerm
                        AND SVBTESH_ESAS_TEMP_PIDM  = SVRESAS_TEMP_PIDM
                    )
         AND SVRESAS_TSSC_CODE                = psEncu
         AND SVRESAS_TERM_CODE                = psTerm;


  END PWARSEPRAD;
/
