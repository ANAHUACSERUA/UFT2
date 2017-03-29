DROP PROCEDURE BANINST1.PWPMODT;

CREATE OR REPLACE PROCEDURE BANINST1.PWPMODT (psPeriodo VARCHAR DEFAULT NULL,
                                              psFecha VARCHAR DEFAULT NULL
                                              ) AS
    /******************************************************************************
    PROCEDIMIENTO:       PWPMODT
    OBJETIVO:            Extrae información de montos de morosidad por Alumno, contrato y documento de un query, insertando en la tabla TAISMGR.TWRMRDT
    REQUIRIMIENTO:       Antes de llamar a ejecutar este procedimiento, validar que se haya ejecutado este insert
    INSERT INTO SOBSEQN (SOBSEQN_FUNCTION,SOBSEQN_SEQNO_PREFIX,SOBSEQN_MAXSEQNO,SOBSEQN_ACTIVITY_DATE) VALUES ('REPORT_SEQ_DT',NULL,0,SYSDATE);
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
    vsReport_Seq   NUMBER := BANINST1.pk_Util.f_NumSec('REPORT_SEQ_DT');

    vnNumErr       NUMBER         :=0;
    vsMsg          VARCHAR2 (9999):= '';
    vdInicial      DATE;
    vdFinal        DATE;
    vsPeriodo      VARCHAR2 (999) := '';
    vsFecha        VARCHAR2 (999) := '';
    vsFechaI       VARCHAR2 (999) := '';
    vsPrograma     VARCHAR2 (14)  := '';
    vsStatusAlum   VARCHAR2 (4)   := '';
    vsPeriodoAd    VARCHAR2 (8)   := '';
    vsCode         VARCHAR2 (8)   := '';
    vsNumContrato  VARCHAR2 (14)  := '';
    vsPeriContrato VARCHAR2 (10)   := '';
    vnPidm         NUMBER(8)      :=0;

    csO        CONSTANT VARCHAR2(3)  := 'O';
    csEsp      CONSTANT VARCHAR2(1)  := ' ';
    csSesp     CONSTANT VARCHAR2(1)  := '';
    csC        CONSTANT VARCHAR2(3)  := 'C';
    csY        CONSTANT VARCHAR2(3)  := 'Y';
    csCAE      CONSTANT VARCHAR2(5)  := 'CAE';
    csBEC      CONSTANT VARCHAR2(5)  := 'BEC';
    csCA       CONSTANT VARCHAR2(4)  := 'CA';
    csRP       CONSTANT VARCHAR2(4)  := 'RP';
    csRV       CONSTANT VARCHAR2(4)  := 'RV';
    cs201399   CONSTANT VARCHAR2(6)  := '201399';
    csPAGADO   CONSTANT VARCHAR2(8)  := 'PAGADO';
    csPWPMODT  CONSTANT VARCHAR2(7)  := 'PWPMODT';
    csVIGENTE  CONSTANT VARCHAR2(9)  := 'VIGENTE';
    csDDMMRRRR CONSTANT VARCHAR2(12) := 'DD/MM/YYYY';
    csHHMISS   CONSTANT VARCHAR2(12)  :='HH24:MI:SS';
    cdHH24MISS CONSTANT VARCHAR2(24)  :='DD/MM/YYYY HH24:MI:SS';


    cn0        CONSTANT NUMBER(1)    := 0;
    cn1        CONSTANT NUMBER(1)    := 1;
    cn30       CONSTANT NUMBER(2)    := 30;
    cn90       CONSTANT NUMBER(2)    := 90;
    cn180      CONSTANT NUMBER(3)    := 180;

    -- CONTRATO
    vsQueryCtr    VARCHAR2(500) :=
               'SELECT TWBCNTR_PIDM,
                       TWBCNTR_NUM,
                       TWBCNTR_TERM_CODE
                  FROM TWBCNTR ';
--                                                 where twbcntr_pidm = 3022';

     vsQueryDoc    VARCHAR2(32765) := '';

     /** Entity record type CTR*/
     TYPE CTR_REC IS RECORD (
      R_PIDM       TWBCNTR.TWBCNTR_PIDM%TYPE,
      R_NUM        TWBCNTR.TWBCNTR_NUM%TYPE,
      R_TERM_CODE  TWBCNTR.TWBCNTR_TERM_CODE%TYPE);

    /** Entity cursor variable type CTR*/
    TYPE CTR_SET IS TABLE OF  CTR_REC;
    CTR_ITEMS CTR_SET;


     /** Entity record type DOC*/
     TYPE DOC_REC IS RECORD (
     MORO_PIDM        TWRMRDT.TWRMRDT_PIDM%TYPE,
     MORO_PERI_CNTR   TWRMRDT.TWRMRDT_CNTR_TERM_CODE%TYPE,
     MORO_PERI_DOCU   TWRMRDT.TWRMRDT_DOCU_TERM_CODE%TYPE,
     DOCU_SEQ         TWRMRDT.TWRMRDT_DOCU_SEQ%TYPE,
     DOCU_NUM         TWRMRDT.TWRMRDT_DOCU_NUM%TYPE,
     MORO_PROG        TWRMRDT.TWRMRDT_PROGRAM_CODE%TYPE,
     MORO_CNTR        TWRMRDT.TWRMRDT_CNTR_NUM%TYPE,
     MORO_AMOUNT      TWRMRDT.TWRMRDT_AMOUNT%TYPE,
     MORO_PAYM        TWRMRDT.TWRMRDT_PAYM_CODE%TYPE,
     MORO_STST        TWRMRDT.TWRMRDT_STST_CODE%TYPE,
     MORO_TERM        TWRMRDT.TWRMRDT_TERM_CODE_ADMIT%TYPE,
     MORO_STU         TWRMRDT.TWRMRDT_STU_RUT%TYPE,
     MORO_MORA_30     TWRMRDT.TWRMRDT_MORA_30%TYPE,
     MORO_MORA_90     TWRMRDT.TWRMRDT_MORA_90%TYPE,
     MORO_MORA_180    TWRMRDT.TWRMRDT_MORA_180%TYPE,
     MORO_MORA_MAYOR  TWRMRDT.TWRMRDT_MORA_MAYOR%TYPE,
     MORO_TOTAL_MORA  TWRMRDT.TWRMRDT_TOTAL_MORA%TYPE,
     MORO_TOTAL_CAE   TWRMRDT.TWRMRDT_TOTAL_CAE%TYPE,
     MORO_TOTAL_BECA  TWRMRDT.TWRMRDT_TOTAL_BECAS%TYPE,
     CODE             TWRMRDT.TWRMRDT_SBGI_CODE%TYPE);


    /** Entity cursor variable type DOC*/
    TYPE DOC_SET IS TABLE OF  DOC_REC;
    regDoc DOC_SET;

    BEGIN

      vdInicial := SYSDATE;

      vsPeriodo := psPeriodo;
      vsFecha   := psFecha;
      --vsFechaI  := vsFecha||' '||TO_CHAR(vsDate, csHHMISS);




      IF vsPeriodo IS NOT NULL THEN
       vsQueryCtr := vsQueryCtr || ' WHERE TWBCNTR_TERM_CODE = '||vsPeriodo;
      END IF;


      EXECUTE IMMEDIATE vsQueryCtr BULK COLLECT INTO CTR_ITEMS;

      IF CTR_ITEMS IS NOT NULL THEN IF CTR_ITEMS.COUNT > 0 THEN
        FOR I IN CTR_ITEMS.FIRST..CTR_ITEMS.LAST LOOP

          vsPrograma     := '';
          vsStatusAlum   := '';
          vsPeriodoAd    := '';
          vsCode         := '';
          vsNumContrato  := '';
          vsPeriContrato := '';
          vnPidm         := 0;

           BEGIN
           -- GASTON,
           --CURSOR cu_gst(vnPidm NUMBER) IS
                  SELECT NVL(a.SGBSTDN_PROGRAM_1,'S_PRG'),
                         NVL(a.SGBSTDN_STST_CODE,'ST'),
                         NVL(SGBSTDN_TERM_CODE_ADMIT,'S_PER')
                    INTO vsPrograma,
                    vsStatusAlum,
                    vsPeriodoAd
                    FROM SGBSTDN a
                   WHERE a.SGBSTDN_TERM_CODE_EFF =
                         (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                            FROM SGBSTDN B
                           WHERE B.SGBSTDN_PIDM = CTR_ITEMS(I).R_PIDM
                             AND B.SGBSTDN_TERM_CODE_EFF <= cs201399)
                     AND A.SGBSTDN_PIDM = CTR_ITEMS(I).R_PIDM;
                                     --and a.sgbstdn_pidm = 3022;

           EXCEPTION
                    WHEN OTHERS
                        THEN
                           vnNumErr     := SQLCODE;
                           vsMsg        := SUBSTR (SQLERRM, 1, 900);
                           vsPrograma   := 'S_PRG';--NULL;
                           vsStatusAlum := 'ST';--NULL;
                           vsPeriodoAd  := 'S_PER';--NULL;
                           INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
                                VALUES (vnNumErr, 'SGBSTDN:'||CTR_ITEMS(I).R_PIDM||':'||SUBSTR (vsMsg, 1, 900), SYSDATE);
           END;

           BEGIN
           -- CODE
           --CURSOR cu_stv(vnPidm NUMBER) IS
                  SELECT NVL(MAX(STVSBGI_CODE),'S_COD') Code
                    INTO vsCode
                    FROM STVSBGI,SORHSCH
                   WHERE STVSBGI_CODE = SORHSCH_SBGI_CODE
                     AND SORHSCH_PIDM= CTR_ITEMS(I).R_PIDM;
                                                  --and sorhsch_pidm = 3022;


           EXCEPTION
                    WHEN OTHERS
                        THEN
                           vnNumErr := SQLCODE;
                           vsMsg    := SUBSTR (SQLERRM, 1, 900);
                           vsCode   := 'S_COD';
                           INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
                                VALUES (vnNumErr, 'STVSBGI,SORHSCH:'||SUBSTR (vsMsg, 1, 950), SYSDATE);

           END;

          vsNumContrato  := CTR_ITEMS(I).R_NUM;
          vsPeriContrato := CTR_ITEMS(I).R_TERM_CODE;
          vnPidm         := CTR_ITEMS(I).R_PIDM;


--          INSERT INTO UNO VALUES('vsPrograma:'||vsPrograma||':vsStatusAlum:'||vsStatusAlum,
--                                 'vsPeriodoAd:'||vsPeriodoAd||':vsCode:'||vsCode,
--                                 'vsNumContrato:'||vsNumContrato||':vsPeriContrato:'||vsPeriContrato||':vnPidm:'||vnPidm); COMMIT;

                    for regDoc in (
                    SELECT q2.TWBDOCU_PIDM         MORO_PIDM,
                           vsPeriContrato          MORO_PERI_CNTR,
                           q2.TWBDOCU_TERM_CODE    MORO_PERI_DOCU,
                           q2.TWBDOCU_SEQ_NUM      DOCU_SEQ,
                           q2.TWBDOCU_DOCU_NUM     DOCU_NUM,
                           vsPrograma              MORO_PROG,
                           vsNumContrato           MORO_CNTR,
                           SUM( (SELECT SUM(twbdocu_amount)
                                   FROM twbdocu, twrdotr
                                  WHERE TWBDOCU_CNTR_NUM = vsNumContrato
                                    AND twrdotr_docu_Seq_num = twbdocu_Seq_num
                                    AND twrdotr_orig_ind = csO)
                           )                       MORO_AMOUNT,
                           q2.TWBDOCU_PAYM_CODE    MORO_PAYM,
                           vsStatusAlum            MORO_STST,
                           vsPeriodoAd             MORO_TERM,
                           SPBPERS_NAME_SUFFIX     MORO_STU,
                           SUM(q2.menores30)       MORO_MORA_30,
                           SUM(q2.menores3090)     MORO_MORA_90,
                           SUM(q2.menores90180)    MORO_MORA_180,
                           SUM(q2.mas180)          MORO_MORA_MAYOR,
                           SUM(NVL(q2.menores30,cn0)+
                           NVL(q2.menores3090,cn0)+
                           NVL(q2.menores90180,cn0)+
                           NVL(q2.mas180,cn0))     MORO_TOTAL_MORA,
                           MontoCae.TotalCae       MORO_TOTAL_CAE,
                           Beca.TotalBeca          MORO_TOTAL_BECA,
                           vsCode                  CODE
                      FROM SPRIDEN, SPBPERS,
                           (SELECT SUM(TWBDOCU_AMOUNT)  TotalCae,
                                   TWBDOCU_PIDM         Pidm,
                                   TWBDOCU_TERM_CODE    Periodo
                              FROM TWBDOCU
                             WHERE TWBDOCU_PAYM_CODE = csCAE
                               AND TWBDOCU_STATUS_IND NOT IN (csCA,csRP,csRV)
                               AND TWBDOCU_PIDM = vnPidm
                               AND TWBDOCU_CNTR_NUM  = vsNumContrato
                               AND TWBDOCU_TERM_CODE = vsPeriContrato
                             GROUP BY  TWBDOCU_PIDM, TWBDOCU_TERM_CODE                              ) MontoCae,
                           (SELECT TWBDOCU_PIDM         Pidm,
                                   TWBDOCU_TERM_CODE    Periodo,
                                   SUM(TWBDOCU_AMOUNT)  TotalBeca
                              FROM twbdocu
                             WHERE EXISTS( SELECT cn1
                                             FROM TWBCNTR
                                            WHERE TWBCNTR_NUM = TWBDOCU_CNTR_NUM
                                              AND TWBCNTR_PIDM = vnPidm
                                              AND TWBDOCU_STATUS_IND <> csC)
                                              AND EXISTS( SELECT cn1
                                                            FROM twrbast
                                                           WHERE twrbast_status_ind = twbdocu_status_ind
                                                             AND twrbast_code = csPAGADO)
                                                             AND ( twbdocu_paym_code = csBEC
                                                                   OR EXISTS( SELECT cn1
                                                                                FROM TWRDOBE
                                                                               WHERE twrdobe_paym_code = twbdocu_paym_code
                                                                             ))
                                                             AND NOT EXISTS( SELECT cn1
                                                                               FROM TWBRETR
                                                                              WHERE TWBRETR_CNTR_NUM = TWBDOCU_CNTR_NUM
                                                                           )
                                                           GROUP BY  TWBDOCU_PIDM, TWBDOCU_TERM_CODE) Beca,
                           (SELECT q1.TWBDOCU_PIDM,
                                   q1.TWBDOCU_TERM_CODE,
                                   q1.TWBDOCU_SEQ_NUM,
                                   q1.TWBDOCU_DOCU_NUM,
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
                                   FROM (
                                   SELECT TWBDOCU_PIDM,
                                          TWBDOCU_TERM_CODE,
                                          TWBDOCU_SEQ_NUM,
                                          TWBDOCU_DOCU_NUM,
                                          TWBDOCU_CNTR_NUM,
                                          TWBDOCU_PAYM_CODE,
                                          TWBDOCU_AMOUNT,
                                          TO_DATE(vsFecha,csDDMMRRRR)-TRUNC(TWBDOCU_EXPIRATION_DATE) dias
                                     FROM TWBDOCU
                                    WHERE EXISTS (SELECT cn1
                                                    FROM TWRBAST
                                                   WHERE TWRBAST_CODE = csVIGENTE
                                                     AND TWRBAST_STATUS_IND = TWBDOCU_STATUS_IND
                                                 )
                                      AND TRUNC(TWBDOCU_EXPIRATION_DATE) <= TO_DATE(vsFecha,csDDMMRRRR)
                                      AND TWBDOCU_PIDM = vnPidm
                                      AND TWBDOCU_CNTR_NUM  = vsNumContrato
                                      AND TWBDOCU_TERM_CODE = vsPeriContrato
                                       --                                                                     and twbdocu_pidm = 3022
                                   ) q1
                           ) q2
                     WHERE SPRIDEN_CHANGE_IND IS NULL
                       AND SPRIDEN_PIDM    = q2.TWBDOCU_PIDM
                       AND SPBPERS_PIDM(+) = q2.TWBDOCU_PIDM
                       AND q2.TWBDOCU_PIDM = MontoCae.Pidm(+)
                       AND q2.TWBDOCU_TERM_CODE = MontoCae.Periodo(+)
                       AND q2.TWBDOCU_PIDM = Beca.Pidm(+)
                       AND q2.TWBDOCU_TERM_CODE = Beca.Periodo(+)
                    HAVING SUM(NVL(q2.menores30   ,cn0)+
                           NVL(q2.menores3090 ,cn0)+
                           NVL(q2.menores90180,cn0)+
                           NVL(q2.mas180, cn0)) > cn0
                     GROUP BY q2.TWBDOCU_PIDM,
                     vsPeriContrato,
                     q2.TWBDOCU_TERM_CODE,
                     q2.TWBDOCU_SEQ_NUM,
                     q2.TWBDOCU_DOCU_NUM,
                     vsPrograma,
                     vsNumContrato,
                     q2.TWBDOCU_PAYM_CODE,
                     vsStatusAlum,
                     vsPeriodoAd,
                     SPBPERS_NAME_SUFFIX,
                     MontoCae.TotalCae,
                     Beca.TotalBeca,
                     vsCode ) LOOP

                   BEGIN


                    vnMorosos := vnMorosos + 1;
                    INSERT INTO TAISMGR.TWRMRDT
                               (TWRMRDT_REPORT_SEQ,
                                TWRMRDT_SEQ_NO,
                                TWRMRDT_PIDM,
                                TWRMRDT_CNTR_TERM_CODE,
                                TWRMRDT_DOCU_TERM_CODE,
                                TWRMRDT_DOCU_SEQ,
                                TWRMRDT_DOCU_NUM,
                                TWRMRDT_PROGRAM_CODE,
                                TWRMRDT_CNTR_NUM,
                                TWRMRDT_AMOUNT,
                                TWRMRDT_PAYM_CODE,
                                TWRMRDT_STST_CODE,
                                TWRMRDT_TERM_CODE_ADMIT,
                                TWRMRDT_STU_RUT,
                                TWRMRDT_MORA_30,
                                TWRMRDT_MORA_90,
                                TWRMRDT_MORA_180,
                                TWRMRDT_MORA_MAYOR,
                                TWRMRDT_TOTAL_MORA,
                                TWRMRDT_TOTAL_CAE,
                                TWRMRDT_TOTAL_BECAS,
                                TWRMRDT_SBGI_CODE,
                                TWRMRDT_ACTIVITY_DATE,
                                TWRMRDT_USER_ID,
                                TWRMRDT_CUT_DATE,
                                TWRMRDT_RANK_DATE)
                    VALUES(vsReport_Seq,
                           vnMorosos,
                           regDoc.MORO_PIDM,
                           regDoc.MORO_PERI_CNTR,
                           regDoc.MORO_PERI_DOCU,
                           regDoc.DOCU_SEQ,
                           regDoc.DOCU_NUM,
                           regDoc.MORO_PROG,
                           regDoc.MORO_CNTR,
                           regDoc.MORO_AMOUNT,
                           regDoc.MORO_PAYM,
                           regDoc.MORO_STST,
                           regDoc.MORO_TERM,
                           regDoc.MORO_STU,
                           regDoc.MORO_MORA_30,
                           regDoc.MORO_MORA_90,
                           regDoc.MORO_MORA_180,
                           regDoc.MORO_MORA_MAYOR,
                           regDoc.MORO_TOTAL_MORA,
                           regDoc.MORO_TOTAL_CAE,
                           regDoc.MORO_TOTAL_BECA,
                           regDoc.CODE,
                           vsDate,
                           USER,
                           TO_CHAR(vsDate,  csDDMMRRRR),
                           TO_DATE(psFECHA||TO_CHAR(SYSDATE, csHHMISS),cdHH24MISS)
                           );

                   EXCEPTION
                      WHEN OTHERS
                          THEN
                             vnNumErr := SQLCODE;
                             vsMsg    := SUBSTR (SQLERRM, 1, 900);

                             INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
                                  VALUES (vnNumErr, 'insert'||'vsPrograma:'||vsPrograma||':vsStatusAlum:'||
                                  vsStatusAlum||'vsPeriodoAd:'||vsPeriodoAd||':vsCode:'||vsCode||'vsNumContrato:'||
                                  vsNumContrato||':vsPeriContrato:'||vsPeriContrato||':vnPidm:'||
                                  vnPidm||'-'||SUBSTR (vsMsg, 1, 850), SYSDATE);



                   END;
                  END LOOP;

      END LOOP;
      END IF; END IF;
    vdFinal := SYSDATE;
    INSERT INTO GWBTMRA VALUES (vsReport_Seq,vdInicial, vdFinal,
                                  vnMorosos, vsPeriodo ,vsFecha,
                                  csPWPMODT, vsDate);

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
         vsMsg    := 'OTRO' ||SQLERRM;

         INSERT INTO GWBEMRA (GWBEMRA_NUM, GWBEMRA_MSG, GWBEMRA_FECHA)
              VALUES (vnNumErr, SUBSTR (vsMsg, 1, 950), SYSDATE);

         COMMIT;
         HTP.P(SQLERRM);
         RAISE;
END;
/
