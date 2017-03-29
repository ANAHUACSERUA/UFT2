DROP PROCEDURE BANINST1.PWPMORA;

CREATE OR REPLACE PROCEDURE BANINST1.PWPMORA (psPeriodo VARCHAR,
                                              psFecha VARCHAR
                                              ) AS




    /******************************************************************************
    PROCEDIMIENTO:       PWPMORA
    OBJETIVO:            Extrae información de montos de morosidad de un query, insertando en la tabla TAISMGR.TWRMORO
    REQUIRIMIENTO:       Antes de llamar a ejecutar este procedimiento, validar que se haya ejecutado este insert
    INSERT INTO SOBSEQN (SOBSEQN_FUNCTION,SOBSEQN_SEQNO_PREFIX,SOBSEQN_MAXSEQNO,SOBSEQN_ACTIVITY_DATE) VALUES ('REPORT_SEQ',NULL,0,SYSDATE);
    COMMIT;

    PARAMETROS:
    psPeriodo:           Periodo lectivo del documento
    psFECHA:             Fecha expirada del documento

    AUTOR:               José Juan Ochoa
    FECHA:               20130613
    ******************************************************************************/
    -- Variable que almacena numero de sequencia
    vnMorosos    NUMBER :=0;

    -- Variable que almecena fecha de ejecución del reporte
    vsDate       DATE   := sysdate;

    -- Variable que almacena numero de reporte
    vsReport_Seq NUMBER := BANINST1.pk_Util.f_NumSec('REPORT_SEQ');

    vnNumErr     NUMBER;
    vsMsg        VARCHAR2 (9999);
    vdInicial    DATE;
    vdFinal      DATE;
    vsPeriodo    VARCHAR2 (999);
    vsFecha      VARCHAR2 (999);


    csO        CONSTANT VARCHAR2(1)  := 'O';
    csEsp      CONSTANT VARCHAR2(1)  := ' ';
    csSesp     CONSTANT VARCHAR2(1)  := '';
    csC        CONSTANT VARCHAR2(1)  := 'C';
    csY        CONSTANT VARCHAR2(1)  := 'Y';
    csCAE      CONSTANT VARCHAR2(3)  := 'CAE';
    csBEC      CONSTANT VARCHAR2(3)  := 'BEC';
    csCA       CONSTANT VARCHAR2(2)  := 'CA';
    csRP       CONSTANT VARCHAR2(2)  := 'RP';
    csRV       CONSTANT VARCHAR2(2)  := 'RV';
    cs201399   CONSTANT VARCHAR2(6)  := '201399';
    csPAGADO   CONSTANT VARCHAR2(6)  := 'PAGADO';
    csVIGENTE  CONSTANT VARCHAR2(7)  := 'VIGENTE';
    csDDMMRRRR CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
    csHHMISS   CONSTANT VARCHAR2(10)  := 'HH24:MI:SS';
    cdHH24MISS CONSTANT VARCHAR2(22)  := 'DD/MM/YYYY HH24:MI:SS';


    cn0        CONSTANT NUMBER(1)    := 0;
    cn1        CONSTANT NUMBER(1)    := 1;
    cn30       CONSTANT NUMBER(2)    := 30;
    cn90       CONSTANT NUMBER(2)    := 90;
    cn180      CONSTANT NUMBER(3)    := 180;

      CURSOR cu_moro(psPer VARCHAR,
                     psFec VARCHAR) IS
           SELECT PIDM        MORO_PIDM, PERICONTRATO MORO_PERI_CNTR, DOCU_TERM_CODE MORO_DOCU,
                  PROGR       MORO_PROG, NUMCONT      MORO_CNTR, AMOUNT         MORO_AMOUNT,
                  PAYM_CODE   MORO_PAYM, STATUSALUM   MORO_STST, PERIODOAD      MORO_TERM,
                  NAME_SUFFIX MORO_STU,
                 SUM(MENORES30)    MORO_MORA_30,  SUM(MENORES3090) MORO_MORA_90,
                 SUM(MENORES90180) MORO_MORA_180, SUM(MAS180)  MORO_MORA_MAYOR, SUM(MAS1802)     MORO_TOTAL_MORA,
                 TOTALCAE   MORO_TOTAL_CAE,
                 TOTALBECA  MORO_TOTAL_BECA,
                 CODE       MORO_SBGI_CODE
            FROM(
             SELECT q2.TWBDOCU_PIDM                                      PIDM,
                    Contrato.PeriContrato                                PERICONTRATO,
                    q2.TWBDOCU_TERM_CODE                                 DOCU_TERM_CODE,
                    gaston.programa                                      PROGR,
                    Contrato.NumContrato                                 NUMCONT,
                    (SELECT SUM(twbdocu_amount)
                       FROM twbdocu, twrdotr
                      WHERE TWBDOCU_CNTR_NUM = Contrato.NumContrato
                        AND twrdotr_docu_Seq_num = twbdocu_Seq_num
                        AND twrdotr_orig_ind = csO)                      AMOUNT,
                    q2.TWBDOCU_PAYM_CODE                                 PAYM_CODE,
                    gaston.StatusAlum                                    STATUSALUM,
                    gaston.PeriodoAd                                     PERIODOAD,
                    SPBPERS_NAME_SUFFIX                                  NAME_SUFFIX,
                    SUM(q2.menores30)                                    MENORES30,
                    SUM(q2.menores3090)                                  MENORES3090,
                    SUM(q2.menores90180)                                 MENORES90180,
                    SUM(q2.mas180)                                       MAS180,
                    SUM(NVL(q2.menores30,cn0)+
                        NVL(q2.menores3090,cn0)+
                        NVL(q2.menores90180,cn0)+
                        NVL(q2.mas180,cn0))                              MAS1802,
                    MontoCae.TotalCae                                    TOTALCAE,
                    Beca.TotalBeca                                       TOTALBECA,
                    (SELECT DISTINCT STVSBGI_CODE
                       FROM STVSBGI,SORHSCH
                      WHERE STVSBGI_CODE = SORHSCH_SBGI_CODE
                        AND SORHSCH_PIDM=q2.TWBDOCU_PIDM
                        AND ROWNUM = cn1 )                               CODE
             FROM SPRIDEN, SPBPERS,
                  (SELECT TWBCNTR_PIDM       Pidm,
                          TWBCNTR_NUM        NumContrato,
                          TWBCNTR_TERM_CODE  PeriContrato
                     FROM TWBCNTR                                                        ) CONTRATO,
                  (SELECT a.SGBSTDN_PROGRAM_1    Programa,
                          a.SGBSTDN_PIDM         PIDM,
                          a.SGBSTDN_COLL_CODE_1  Escuela,
                          a.SGBSTDN_STST_CODE    StatusAlum,
                          SGBSTDN_TERM_CODE_ADMIT PeriodoAd
                     FROM SGBSTDN a
                    WHERE a.SGBSTDN_TERM_CODE_EFF =
                          (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                             FROM SGBSTDN B
                            WHERE B.SGBSTDN_PIDM = a.SGBSTDN_PIDM
                              AND B.SGBSTDN_TERM_CODE_EFF <= cs201399)                    ) GASTON,
                  (SELECT SUM(TWBDOCU_AMOUNT)  TotalCae,
                          TWBDOCU_PIDM         Pidm,
                          TWBDOCU_TERM_CODE    Periodo
                     FROM TWBDOCU
                    WHERE TWBDOCU_PAYM_CODE = csCAE
                      AND TWBDOCU_STATUS_IND NOT IN (csCA,csRP,csRV)
                    GROUP BY  TWBDOCU_PIDM, TWBDOCU_TERM_CODE                             ) MontoCae,
                  (SELECT  TWBDOCU_PIDM         Pidm,
                           TWBDOCU_TERM_CODE    Periodo,
                           SUM(TWBDOCU_AMOUNT)  TotalBeca
                      FROM twbdocu
                     WHERE EXISTS( SELECT cn1  --eL CONTRATO DEBE SER VALIDO
                                     FROM TWBCNTR
                                    WHERE TWBCNTR_NUM = TWBDOCU_CNTR_NUM
                                      AND TWBDOCU_STATUS_IND <> csC)
                       AND EXISTS( SELECT cn1  --el estado del documento debe ser pagado, descarta basura tambien
                                     FROM twrbast
                                    WHERE twrbast_status_ind = twbdocu_status_ind
                                      AND twrbast_code = csPAGADO)
                      --Clausula para detectar si es beca
                      AND ( twbdocu_paym_code = csBEC
                           OR EXISTS( SELECT cn1
                                        FROM TWRDOBE
                                       WHERE twrdobe_paym_code = twbdocu_paym_code
                                    )
                          )
                      --Clausula para detectar un retracto
                      AND NOT EXISTS( SELECT cn1
                                        FROM TWBRETR
                                       WHERE TWBRETR_CNTR_NUM = TWBDOCU_CNTR_NUM
                      )
                  GROUP BY  TWBDOCU_PIDM, TWBDOCU_TERM_CODE                               ) Beca,
                  (SELECT q1.TWBDOCU_PIDM,
                          q1.TWBDOCU_TERM_CODE,
                          q1.TWBDOCU_CNTR_NUM,
                          q1.TWBDOCU_PAYM_CODE,
                          CASE
                              WHEN q1.dias <=cn30
                               AND q1.dias >cn0
                              THEN twbdocu_amount
                          END menores30,
                          CASE
                              WHEN q1.dias >cn30
                               AND q1.dias<=cn90
                              THEN twbdocu_amount
                          END menores3090,
                          CASE
                              WHEN q1.dias >cn90
                               AND q1.dias <=cn180
                              THEN twbdocu_amount
                          END menores90180,
                          CASE
                              WHEN q1.dias >cn180
                              THEN twbdocu_amount
                          END mas180
                     FROM
--                           (SELECT TWBDOCU_PIDM,
--                                   TWBDOCU_TERM_CODE,
--                                   TWBDOCU_SEQ_NUM,
--                                   twbdocu_amount,
--                                   TO_DATE(psFECHA,csDDMMRRRR)-TRUNC(TWBDOCU_EXPIRATION_DATE) dias,
--                                   TWBDOCU_CNTR_NUM,
--                                   TWBDOCU_PAYM_CODE
--                              FROM twbdocu
--                             WHERE pk_Matricula.f_GetBanStQ(csVIGENTE,TWBDOCU_STATUS_IND) = csY -- solo vigentes
--                               AND TRUNC(TWBDOCU_EXPIRATION_DATE) <= TO_DATE(psFECHA,csDDMMRRRR)
--                           ) q1
                            (SELECT TWBDOCU_PIDM,
                                    TWBDOCU_TERM_CODE,
                                    TWBDOCU_CNTR_NUM,
                                    TWBDOCU_PAYM_CODE,
                                    twbdocu_amount,
                                    TO_DATE(psFECHA,csDDMMRRRR)-TRUNC(TWBDOCU_EXPIRATION_DATE) dias
                               FROM twbdocu
                              WHERE  EXISTS (SELECT 1
                                               FROM TWRBAST
                                              WHERE TWRBAST_CODE = csVIGENTE
                                                AND TWRBAST_STATUS_IND = TWBDOCU_STATUS_IND
                                            )
                                AND TRUNC(TWBDOCU_EXPIRATION_DATE) <= TO_DATE(psFECHA,csDDMMRRRR)
                            ) q1
                  ) q2
            WHERE SPRIDEN_CHANGE_IND IS NULL
              AND SPRIDEN_PIDM    = q2.TWBDOCU_PIDM
              AND SPBPERS_PIDM(+) = q2.TWBDOCU_PIDM
              AND q2.TWBDOCU_PIDM = Contrato.Pidm(+)
              AND q2.TWBDOCU_CNTR_NUM  = Contrato.NumContrato(+)
              AND q2.TWBDOCU_TERM_CODE = Contrato.PeriContrato(+)
              AND q2.TWBDOCU_PIDM = GASTON.PIDM(+)
              AND q2.TWBDOCU_PIDM = MontoCae.Pidm(+)
              AND q2.TWBDOCU_TERM_CODE = MontoCae.Periodo(+)
              AND q2.TWBDOCU_PIDM = Beca.Pidm(+)
              AND q2.TWBDOCU_TERM_CODE = Beca.Periodo(+)
              AND(CONTRATO.PeriContrato = psPeriodo OR psPeriodo IS NULL OR psPeriodo = csSesp)
           HAVING SUM(NVL(q2.menores30   ,cn0)+
                      NVL(q2.menores3090 ,cn0)+
                      NVL(q2.menores90180,cn0)+
                      NVL(q2.mas180,      cn0)) > cn0
           GROUP BY q2.TWBDOCU_PIDM,
                  q2.TWBDOCU_TERM_CODE,
                  q2.TWBDOCU_PAYM_CODE,
                  SPBPERS_NAME_SUFFIX,
                  SPRIDEN_ID,
                  SPRIDEN_FIRST_NAME||csEsp||SPRIDEN_MI,
                  SPRIDEN_LAST_NAME,
                  gaston.programa,
                  gaston.StatusAlum,
                  gaston.PeriodoAd,
                  MontoCae.TotalCae,
                  Beca.TotalBeca,
                  Contrato.NumContrato,
                  Contrato.PeriContrato
           ) A
         GROUP BY PIDM,      PERICONTRATO,  DOCU_TERM_CODE,
                  PROGR,     NUMCONT,       AMOUNT,PAYM_CODE,
                  STATUSALUM,PERIODOAD,     NAME_SUFFIX,
                  TOTALCAE,  TOTALBECA,     CODE;
    BEGIN
      vsPeriodo :=psPeriodo;
      vsFecha   := psFecha;

      vdInicial := SYSDATE;

      FOR regMoro IN cu_moro(vsPeriodo, vsFecha) LOOP

          BEGIN

             vnMorosos := vnMorosos + 1;
             INSERT INTO TAISMGR.TWRMORO
                        (TWRMORO_REPORT_SEQ,
                         TWRMORO_SEQ_NO,
                         TWRMORO_PIDM,
                         TWRMORO_CNTR_TERM_CODE,
                         TWRMORO_DOCU_TERM_CODE,
                         TWRMORO_PROGRAM_CODE,
                         TWRMORO_CNTR_NUM,
                         TWRMORO_AMOUNT,
                         TWRMORO_PAYM_CODE,
                         TWRMORO_STST_CODE,
                         TWRMORO_TERM_CODE_ADMIT,
                         TWRMORO_STU_RUT,
                         TWRMORO_MORA_30,
                         TWRMORO_MORA_90,
                         TWRMORO_MORA_180,
                         TWRMORO_MORA_MAYOR,
                         TWRMORO_TOTAL_MORA,
                         TWRMORO_TOTAL_CAE,
                         TWRMORO_TOTAL_BECAS,
                         TWRMORO_SBGI_CODE,
                         TWRMORO_ACTIVITY_DATE,
                         TWRMORO_USER_ID ,
                         TWRMORO_CUT_DATE,
                         TWRMORO_RANK_DATE)
             VALUES(vsReport_Seq,
                    vnMorosos,
                    regMoro.MORO_PIDM,
                    regMoro.MORO_PERI_CNTR,
                    regMoro.MORO_DOCU,
                    regMoro.MORO_PROG,
                    regMoro.MORO_CNTR,
                    regMoro.MORO_AMOUNT,
                    regMoro.MORO_PAYM,
                    regMoro.MORO_STST,
                    regMoro.MORO_TERM,
                    regMoro.MORO_STU,
                    regMoro.MORO_MORA_30,
                    regMoro.MORO_MORA_90,
                    regMoro.MORO_MORA_180,
                    regMoro.MORO_MORA_MAYOR,
                    regMoro.MORO_TOTAL_MORA,
                    regMoro.MORO_TOTAL_CAE,
                    regMoro.MORO_TOTAL_BECA,
                    regMoro.MORO_SBGI_CODE,
                    vsDate,
                    USER,
                    TO_CHAR(vsDate,csDDMMRRRR ),
                    TO_DATE(psFECHA||TO_CHAR(vsDate, csHHMISS),cdHH24MISS)
                    );
          EXCEPTION
           WHEN OTHERS
               THEN
                  vnNumErr := SQLCODE;
                  vsMsg    := SQLERRM;

                  INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
                       VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

                  COMMIT;
                  HTP.P(SQLERRM);
                  RAISE;
          END;
      END LOOP;

      vdFinal := SYSDATE;
      INSERT INTO GWBTMRA VALUES (vsReport_Seq,vdInicial, vdFinal,  --zzz
                                  vnMorosos, vsPeriodo ,vsFecha,
                                  'PWPMORA',vsDate);

      COMMIT;

    EXCEPTION
      WHEN NO_DATA_FOUND  THEN
         vnNumErr := SQLCODE;
         vsMsg    := 'SIN DATOS ' || SQLERRM;

         INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
              VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

         COMMIT;
         HTP.P(SQLERRM);
      WHEN TOO_MANY_ROWS  THEN
         vnNumErr := SQLCODE;
         vsMsg    := 'MAS DE 1 REGISTRO ' || SQLERRM;

         INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
              VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

         COMMIT;
      WHEN TIMEOUT_ON_RESOURCE
      THEN
         vnNumErr := SQLCODE;
         vsMsg    := 'TIEMPO DE ESPERA TERMINADO ' || SQLERRM;

         INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
              VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

         COMMIT;

      WHEN ROWTYPE_MISMATCH
      THEN
         vnNumErr := SQLCODE;
         vsMsg    := 'TIPOS DE DATOS INCOMPATIBLES ' || SQLERRM;

         INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
              VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

         COMMIT;
         HTP.P(SQLERRM);
      WHEN DUP_VAL_ON_INDEX
      THEN
         vnNumErr := SQLCODE;
         vsMsg    := 'PK REPETIDA' || SQLERRM;

         INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
              VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

         COMMIT;
         HTP.P(SQLERRM);
      WHEN OTHERS
      THEN
         vnNumErr := SQLCODE;
         vsMsg    := SQLERRM;

         INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
              VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

         COMMIT;
         HTP.P(SQLERRM);
         RAISE;
END;
/
