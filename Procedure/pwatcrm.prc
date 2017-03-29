DROP PROCEDURE BANINST1.PWATCRM;

CREATE OR REPLACE PROCEDURE BANINST1.PWATCRM IS

/*

    TAREA: * Consulta de admiciones para alimentar la lectura del CRM
             y carga las diferencias.
    FECHA: 20/12/2010
    AUTOR: GEPC
   MODULO: GENERAL

*/

  vsError VARCHAR2(4000) := NULL;

  csEsp      CONSTANT VARCHAR2(1) := ' ';
  cs9999     CONSTANT VARCHAR2(4) := '9999';
  csSIMPLE   CONSTANT VARCHAR2(6) := 'SIMPLE';
  csDDMMYYYY CONSTANT VARCHAR2(8) := 'DDMMYYYY';

  BEGIN
      INSERT INTO SWRTCRM
      (
      SWRTCRM_SEQNC,                SWRTCRM_NAME_SUFFIX,          SWRTCRM_ID,                  SWRTCRM_PROGRAM_CODE,
      SWRTCRM_DATE_BANNER,          SWRTCRM_PSMA,                 SWRTCRM_PSLC,                SWRTCRM_PSCI,
      SWRTCRM_PSHC,                 SWRTCRM_NEM,                  SWRTCRM_PROG_SCORE,          SWRTCRM_PSU_SCORE,
      SWRTCRM_EXP_AUTPSU,           SWRTCRM_EXP_AUTCOL,           SWRTCRM_EXP_ESAR,            SWRTCRM_EXP_ESES,
      SWRTCRM_EXP_CONV,             SWRTCRM_EXP_DESC,             SWRTCRM_EXP_BHER,            SWRTCRM_EXP_BPAR,
      SWRTCRM_EXP_BASI,             SWRTCRM_EXP_BDEP,             SWRTCRM_STS_ADM,             SWRTCRM_DEC_ADM,
      SWRTCRM_DATE_FIN,             SWRTCRM_USER_FIN,             SWRTCRM_TERM_CODE,           SWRTCRM_SARHEAD_CODE,
      SWRTCRM_SARHEAD_APLS_CODE,    SWRTCRM_SARHEAD_ADD_DATE,     SWRTCRM_SARETRY_PRIORITY_NO, SWRTCRM_SARADDR_STREET_LINE1,
      SWRTCRM_SARADDR_STREET_LINE2, SWRTCRM_SARADDR_STREET_LINE3, SWRTCRM_SARADDR_CITY,        SWRTCRM_SARADDR_STAT_CDE,
      SWRTCRM_SARADDR_CNTY_CDE,     SWRTCRM_SARADDR_ZIP,          SWRTCRM_SARADDR_NATN_CDE,    SWRTCRM_SARPHON_PQLF_CDE1,
      SWRTCRM_SARPHON_PHONE1,       SWRTCRM_SARPHON_PQLF_CDE2,    SWRTCRM_SARPHON_PHONE2,      SWRTCRM_SARPHON_PQLF_CDE3,
      SWRTCRM_SARPHON_PHONE3,       SWRTCRM_SARPERS_FIRST_NAME,   SWRTCRM_SARPERS_LAST_NAME,   SWRTCRM_SARPERS_MIDDLE_NAME1,
      SWRTCRM_SARPERS_BIRTH_DTE,    SWRTCRM_SARPERS_GENDER,       SWRTCRM_SARPERS_CITZ_CDE,    SWRTCRM_SARHSCH_IDEN_CDE,
      SWRTCRM_SARHSCH_HSGR_DATE,    SWRTCRM_SARPCOL_IDEN_CDE,     SWRTCRM_SARRQST_ANSR_DESC,   SWRTCRM_SARRQST_ANSR_DESC2,
      SWRTCRM_ACTIVITY_DATE,        SWRTCRM_USER
      )
      SELECT
      FWASEQN,                      GWBTCRM_NAME_SUFFIX,          GWBTCRM_ID,                  GWBTCRM_PROGRAM_CODE,
      GWBTCRM_DATE_BANNER,          GWBTCRM_PSMA,                 GWBTCRM_PSLC,                GWBTCRM_PSCI,
      GWBTCRM_PSHC,                 GWBTCRM_NEM,                  GWBTCRM_PROG_SCORE,          GWBTCRM_PSU_SCORE,
      GWBTCRM_EXP_AUTPSU,           GWBTCRM_EXP_AUTCOL,           GWBTCRM_EXP_ESAR,            GWBTCRM_EXP_ESES,
      GWBTCRM_EXP_CONV,             GWBTCRM_EXP_DESC,             GWBTCRM_EXP_BHER,            GWBTCRM_EXP_BPAR,
      GWBTCRM_EXP_BASI,             GWBTCRM_EXP_BDEP,             GWBTCRM_STS_ADM,             GWBTCRM_DEC_ADM,
      GWBTCRM_DATE_FIN,             GWBTCRM_USER_FIN,             GWBTCRM_TERM_CODE,           GWBTCRM_SARHEAD_CODE,
      GWBTCRM_SARHEAD_APLS_CODE,    GWBTCRM_SARHEAD_ADD_DATE,     GWBTCRM_SARETRY_PRIORITY_NO, GWBTCRM_SARADDR_STREET_LINE1,
      GWBTCRM_SARADDR_STREET_LINE2, GWBTCRM_SARADDR_STREET_LINE3, GWBTCRM_SARADDR_CITY,        GWBTCRM_SARADDR_STAT_CDE,
      GWBTCRM_SARADDR_CNTY_CDE,     GWBTCRM_SARADDR_ZIP,          GWBTCRM_SARADDR_NATN_CDE,    GWBTCRM_SARPHON_PQLF_CDE1,
      GWBTCRM_SARPHON_PHONE1,       GWBTCRM_SARPHON_PQLF_CDE2,    GWBTCRM_SARPHON_PHONE2,      GWBTCRM_SARPHON_PQLF_CDE3,
      GWBTCRM_SARPHON_PHONE3,       GWBTCRM_SARPERS_FIRST_NAME,   GWBTCRM_SARPERS_LAST_NAME,   GWBTCRM_SARPERS_MIDDLE_NAME1,
      GWBTCRM_SARPERS_BIRTH_DTE,    GWBTCRM_SARPERS_GENDER,       GWBTCRM_SARPERS_CITZ_CDE,    GWBTCRM_SARHSCH_IDEN_CDE,
      GWBTCRM_SARHSCH_HSGR_DATE,    GWBTCRM_SARPCOL_IDEN_CDE,     GWBTCRM_SARRQST_ANSR_DESC,   GWBTCRM_SARRQST_ANSR_DESC2,
      GWBTCRM_ACTIVITY_DATE,        GWBTCRM_USER
       FROM GWBTCRM
      WHERE NOT EXISTS (SELECT NULL
                          FROM SWRTCRM
                         WHERE NVL(SWRTCRM_NAME_SUFFIX                          ,csEsp) = NVL(GWBTCRM_NAME_SUFFIX                            ,csEsp)
                           AND NVL(SWRTCRM_ID                                   ,csEsp) = NVL(GWBTCRM_ID                                     ,csEsp)
                           AND NVL(SWRTCRM_PROGRAM_CODE                         ,csEsp) = NVL(GWBTCRM_PROGRAM_CODE                           ,csEsp)
                           AND NVL(TO_CHAR(SWRTCRM_DATE_BANNER,csDDMMYYYY)      ,csEsp) = NVL(TO_CHAR(GWBTCRM_DATE_BANNER,csDDMMYYYY)        ,csEsp)
                           AND NVL(SWRTCRM_PSMA                                 ,csEsp) = NVL(GWBTCRM_PSMA                                   ,csEsp)
                           AND NVL(SWRTCRM_PSLC                                 ,csEsp) = NVL(GWBTCRM_PSLC                                   ,csEsp)
                           AND NVL(SWRTCRM_PSCI                                 ,csEsp) = NVL(GWBTCRM_PSCI                                   ,csEsp)
                           AND NVL(SWRTCRM_PSHC                                 ,csEsp) = NVL(GWBTCRM_PSHC                                   ,csEsp)
                           AND NVL(SWRTCRM_NEM                                  ,csEsp) = NVL(GWBTCRM_NEM                                    ,csEsp)
                           AND NVL(SWRTCRM_PROG_SCORE                           ,csEsp) = NVL(GWBTCRM_PROG_SCORE                             ,csEsp)
                           AND NVL(SWRTCRM_PSU_SCORE                            ,csEsp) = NVL(GWBTCRM_PSU_SCORE                              ,csEsp)
                           AND NVL(SWRTCRM_EXP_AUTPSU                           ,csEsp) = NVL(GWBTCRM_EXP_AUTPSU                             ,csEsp)
                           AND NVL(SWRTCRM_EXP_AUTCOL                           ,csEsp) = NVL(GWBTCRM_EXP_AUTCOL                             ,csEsp)
                           AND NVL(SWRTCRM_EXP_ESAR                             ,csEsp) = NVL(GWBTCRM_EXP_ESAR                               ,csEsp)
                           AND NVL(SWRTCRM_EXP_ESES                             ,csEsp) = NVL(GWBTCRM_EXP_ESES                               ,csEsp)
                           AND NVL(SWRTCRM_EXP_CONV                             ,csEsp) = NVL(GWBTCRM_EXP_CONV                               ,csEsp)
                           AND NVL(SWRTCRM_EXP_DESC                             ,csEsp) = NVL(GWBTCRM_EXP_DESC                               ,csEsp)
                           AND NVL(SWRTCRM_EXP_BHER                             ,csEsp) = NVL(GWBTCRM_EXP_BHER                               ,csEsp)
                           AND NVL(SWRTCRM_EXP_BPAR                             ,csEsp) = NVL(GWBTCRM_EXP_BPAR                               ,csEsp)
                           AND NVL(SWRTCRM_EXP_BASI                             ,csEsp) = NVL(GWBTCRM_EXP_BASI                               ,csEsp)
                           AND NVL(SWRTCRM_EXP_BDEP                             ,csEsp) = NVL(GWBTCRM_EXP_BDEP                               ,csEsp)
                           AND NVL(SWRTCRM_STS_ADM                              ,csEsp) = NVL(GWBTCRM_STS_ADM                                ,csEsp)
                           AND NVL(SWRTCRM_DEC_ADM                              ,csEsp) = NVL(GWBTCRM_DEC_ADM                                ,csEsp)
                           AND NVL(TO_CHAR(SWRTCRM_DATE_FIN,csDDMMYYYY)         ,csEsp) = NVL(TO_CHAR(GWBTCRM_DATE_FIN,csDDMMYYYY)           ,csEsp)
                           AND NVL(SWRTCRM_USER_FIN                             ,csEsp) = NVL(GWBTCRM_USER_FIN                               ,csEsp)
                           AND NVL(SWRTCRM_TERM_CODE                            ,csEsp) = NVL(GWBTCRM_TERM_CODE                              ,csEsp)
                           AND NVL(SWRTCRM_SARHEAD_CODE                         ,csEsp) = NVL(GWBTCRM_SARHEAD_CODE                           ,csEsp)
                           AND NVL(SWRTCRM_SARHEAD_APLS_CODE                    ,csEsp) = NVL(GWBTCRM_SARHEAD_APLS_CODE                      ,csEsp)
                           AND NVL(TO_CHAR(SWRTCRM_SARHEAD_ADD_DATE,csDDMMYYYY) ,csEsp) = NVL(TO_CHAR(GWBTCRM_SARHEAD_ADD_DATE,csDDMMYYYY)   ,csEsp)
                           AND NVL(TO_CHAR(SWRTCRM_SARETRY_PRIORITY_NO,cs9999)  ,csEsp) = NVL(TO_CHAR(GWBTCRM_SARETRY_PRIORITY_NO,cs9999)    ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_STREET_LINE1                 ,csEsp) = NVL(GWBTCRM_SARADDR_STREET_LINE1                   ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_STREET_LINE2                 ,csEsp) = NVL(GWBTCRM_SARADDR_STREET_LINE2                   ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_STREET_LINE3                 ,csEsp) = NVL(GWBTCRM_SARADDR_STREET_LINE3                   ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_CITY                         ,csEsp) = NVL(GWBTCRM_SARADDR_CITY                           ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_STAT_CDE                     ,csEsp) = NVL(GWBTCRM_SARADDR_STAT_CDE                       ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_CNTY_CDE                     ,csEsp) = NVL(GWBTCRM_SARADDR_CNTY_CDE                       ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_ZIP                          ,csEsp) = NVL(GWBTCRM_SARADDR_ZIP                            ,csEsp)
                           AND NVL(SWRTCRM_SARADDR_NATN_CDE                     ,csEsp) = NVL(GWBTCRM_SARADDR_NATN_CDE                       ,csEsp)
                           AND NVL(SWRTCRM_SARPHON_PQLF_CDE1                    ,csEsp) = NVL(GWBTCRM_SARPHON_PQLF_CDE1                      ,csEsp)
                           AND NVL(SWRTCRM_SARPHON_PHONE1                       ,csEsp) = NVL(GWBTCRM_SARPHON_PHONE1                         ,csEsp)
                           AND NVL(SWRTCRM_SARPHON_PQLF_CDE2                    ,csEsp) = NVL(GWBTCRM_SARPHON_PQLF_CDE2                      ,csEsp)
                           AND NVL(SWRTCRM_SARPHON_PHONE2                       ,csEsp) = NVL(GWBTCRM_SARPHON_PHONE2                         ,csEsp)
                           AND NVL(SWRTCRM_SARPHON_PQLF_CDE3                    ,csEsp) = NVL(GWBTCRM_SARPHON_PQLF_CDE3                      ,csEsp)
                           AND NVL(SWRTCRM_SARPHON_PHONE3                       ,csEsp) = NVL(GWBTCRM_SARPHON_PHONE3                         ,csEsp)
                           AND NVL(SWRTCRM_SARPERS_FIRST_NAME                   ,csEsp) = NVL(GWBTCRM_SARPERS_FIRST_NAME                     ,csEsp)
                           AND NVL(SWRTCRM_SARPERS_LAST_NAME                    ,csEsp) = NVL(GWBTCRM_SARPERS_LAST_NAME                      ,csEsp)
                           AND NVL(SWRTCRM_SARPERS_MIDDLE_NAME1                 ,csEsp) = NVL(GWBTCRM_SARPERS_MIDDLE_NAME1                   ,csEsp)
                           AND NVL(TO_CHAR(SWRTCRM_SARPERS_BIRTH_DTE,csDDMMYYYY),csEsp) = NVL(TO_CHAR(GWBTCRM_SARPERS_BIRTH_DTE,csDDMMYYYY)  ,csEsp)
                           AND NVL(SWRTCRM_SARPERS_GENDER                       ,csEsp) = NVL(GWBTCRM_SARPERS_GENDER                         ,csEsp)
                           AND NVL(SWRTCRM_SARPERS_CITZ_CDE                     ,csEsp) = NVL(GWBTCRM_SARPERS_CITZ_CDE                       ,csEsp)
                           AND NVL(SWRTCRM_SARHSCH_IDEN_CDE                     ,csEsp) = NVL(GWBTCRM_SARHSCH_IDEN_CDE                       ,csEsp)
                           AND NVL(SWRTCRM_SARHSCH_HSGR_DATE                    ,csEsp) = NVL(GWBTCRM_SARHSCH_HSGR_DATE                      ,csEsp)
                           AND NVL(SWRTCRM_SARPCOL_IDEN_CDE                     ,csEsp) = NVL(GWBTCRM_SARPCOL_IDEN_CDE                       ,csEsp)
                           AND NVL(SWRTCRM_SARRQST_ANSR_DESC                    ,csEsp) = NVL(GWBTCRM_SARRQST_ANSR_DESC                      ,csEsp)
                           AND NVL(SWRTCRM_SARRQST_ANSR_DESC2                   ,csEsp) = NVL(GWBTCRM_SARRQST_ANSR_DESC2                     ,csEsp)
                       )
      ORDER BY GWBTCRM_NAME_SUFFIX;

  EXCEPTION
      WHEN OTHERS THEN
           vsError := SQLERRM;

           ROLLBACK;

           INSERT INTO GWRERRM(GWRERRM_ERROR,GWRERRM_ORIGIN) VALUES(vsError, csSIMPLE);

           COMMIT;
  END PWATCRM;
/
