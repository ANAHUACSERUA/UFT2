CREATE OR REPLACE PACKAGE BODY BANINST1.kwactlg IS

/*
         TAREA: Código AJAX para llenar objetos "SELECT" y el objeto "boxFrame"
                que es creado con el paquete "KWAPRMG1"
        MODULO: Porgramación Académica
    APLICACION: Programas Magisteriales
         FECHA: 10/02/2014
         AUTOR: MAC

--       mod  : md-02
                roman ruiz
                volver a poner el el stvtrac y SSBCRNN
                en base a un respaldo
                roman ruiz
                30/jun/2014

--       mod  : md-03
                roman ruiz
                Permitir que sean todos los periodos (no solo los 10)
                08/Dic/2014				

*/

  global_pidm spriden.spriden_pidm%type;

  TYPE t_Cursor IS REF CURSOR;

  csA         CONSTANT VARCHAR2(1)  := 'A';
  csR         CONSTANT VARCHAR2(1)  := 'R';
  csI         CONSTANT VARCHAR2(1)  := 'I';
  csE         CONSTANT VARCHAR2(1)  := 'E';
  csF         CONSTANT VARCHAR2(1)  := 'F';
  csM         CONSTANT VARCHAR2(1)  := 'M';
  csN         CONSTANT VARCHAR2(1)  := 'N';
  csO         CONSTANT VARCHAR2(1)  := 'O';
  csC         CONSTANT VARCHAR2(1)  := 'C';
  csJ         CONSTANT VARCHAR2(1)  := 'J';
  csH         CONSTANT VARCHAR2(1)  := 'H';
  csSim       CONSTANT VARCHAR2(1)  := 'S';
  csCrhOpen   CONSTANT VARCHAR2(1)  := '[';
  csCrhClos   CONSTANT VARCHAR2(1)  := ']';
  csPrnOpen   CONSTANT VARCHAR2(1)  := '(';
  csPrnClos   CONSTANT VARCHAR2(1)  := ')';
  csComa      CONSTANT VARCHAR2(1)  := ',';
  csComilla   CONSTANT VARCHAR2(1)  := '"';
  csEsp       CONSTANT VARCHAR2(1)  := ' ';
  csAst       CONSTANT VARCHAR2(1)  := '*';
  csGui       CONSTANT VARCHAR2(1)  := '-';
  csY         CONSTANT VARCHAR2(1)  := 'Y';
  csPnt       CONSTANT VARCHAR2(1)  := '.';
  csNull      CONSTANT VARCHAR2(1)  := NULL;
  csCml       CONSTANT VARCHAR2(1)  := '"';
  csTil       CONSTANT VARCHAR2(1)  := '~';
  cs0         CONSTANT VARCHAR2(1)  := '0';
  csAps       CONSTANT VARCHAR2(2)  := '''';
  csShlCml    CONSTANT VARCHAR2(2)  := '\"';
  csShlAps    CONSTANT VARCHAR2(3)  := '\''';
  csShl       CONSTANT VARCHAR2(1)  := '/';
  cs00        CONSTANT VARCHAR2(2)  := '00';
  cs10        CONSTANT VARCHAR2(2)  := '10';
  cs40        CONSTANT VARCHAR2(2)  := '40';
  cs50        CONSTANT VARCHAR2(2)  := '50';
  cs60        CONSTANT VARCHAR2(2)  := '60';
  cs99        CONSTANT VARCHAR2(2)  := '99';
  csLI        CONSTANT VARCHAR2(2)  := 'LI';
  csRE        CONSTANT VARCHAR2(2)  := 'RE';
  csRW        CONSTANT VARCHAR2(2)  := 'RW';
  csPR        CONSTANT VARCHAR2(2)  := 'PR';
  csSP        CONSTANT VARCHAR2(2)  := 'SP';
  csWE        CONSTANT VARCHAR2(2)  := 'WE';
  csLC        CONSTANT VARCHAR2(2)  := 'LC';
  csMA        CONSTANT VARCHAR2(2)  := 'MA';
  csDR        CONSTANT VARCHAR2(2)  := 'DR';
  csJP        CONSTANT VARCHAR2(2)  := 'JP';
  csUAT       CONSTANT VARCHAR2(3)  := 'UAT';
  csISF       CONSTANT VARCHAR2(3)  := 'ISF';
  cs000       CONSTANT VARCHAR2(3)  := '000';
  csLCB       CONSTANT VARCHAR2(3)  := 'LCB';
  csMRE       CONSTANT VARCHAR2(3)  := 'MRE';
  csMEX       CONSTANT VARCHAR2(3)  := 'MEX';
  csPRE       CONSTANT VARCHAR2(3)  := 'PRE';
  csYear      CONSTANT VARCHAR2(4)  := TO_CHAR(SYSDATE,'YYYY');
  csSICC      CONSTANT VARCHAR2(4)  := 'SICC';
  csCODO      CONSTANT VARCHAR2(4)  := 'CODO'; -- JMSM 23/10/2013
  csIngles    CONSTANT VARCHAR2(6)  := 'Inglés';
  cs999999    CONSTANT VARCHAR2(6)  := '999999';
  cs999998    CONSTANT VARCHAR2(6)  := '999998';
  cs999997    CONSTANT VARCHAR2(6)  := '999997';
  cs999996    CONSTANT VARCHAR2(6)  := '999996';
  cs000000    CONSTANT VARCHAR2(6)  := '000000';
  cs299999    CONSTANT VARCHAR2(6)  := '299999';
  cs201010    CONSTANT VARCHAR2(6)  := '201010';
  cs201040    CONSTANT VARCHAR2(6)  := '201040';
  cszzzzzz    CONSTANT VARCHAR2(6)  := 'zzzzzz';
  csCampCode  CONSTANT VARCHAR2(6)  := F_CONTEXTO();
  cs_Camp     CONSTANT VARCHAR2(6)  := '%_'||csCampCode;
  csABIERTA   CONSTANT VARCHAR2(7)  := 'ABIERTA';
  csCERRADA   CONSTANT VARCHAR2(7)  := 'CERRADA';
  csPMEXP     CONSTANT VARCHAR2(7)  := '%(MEX)%';
  csEspanol   CONSTANT VARCHAR2(7)  := 'Español';
  csOtro      CONSTANT VARCHAR2(7)  := 'Otro';
  csStvColl   CONSTANT VARCHAR2(7)  := 'STVCOLL';
  csStvLevl   CONSTANT VARCHAR2(7)  := 'STVLEVL';
  csStvRdef   CONSTANT VARCHAR2(7)  := 'STVRDEF';
  csGtvInsm   CONSTANT VARCHAR2(7)  := 'GTVINSM';
  csIdiomas   CONSTANT VARCHAR2(7)  := 'IDIOMAS';
  csSirNist   CONSTANT VARCHAR2(7)  := 'SIRNIST';
  csSwrPltm   CONSTANT VARCHAR2(7)  := 'SWRPLTM';
  csSwvComp   CONSTANT VARCHAR2(7)  := 'SWVCOMP';
  csGwbAutr   CONSTANT VARCHAR2(7)  := 'GWBAUTR';
  csGwbInst   CONSTANT VARCHAR2(7)  := 'GWBINST';
  csGwbModl   CONSTANT VARCHAR2(7)  := 'GWBMODL';
  csStvTerm   CONSTANT VARCHAR2(7)  := 'STVTERM';
  csCurLevl   CONSTANT VARCHAR2(7)  := 'CURLEVL';
  csStvLend   CONSTANT VARCHAR2(7)  := 'STVLEND';
  csSwvSbgi   CONSTANT VARCHAR2(7)  := 'SWVSBGI';
  csSwvMajr   CONSTANT VARCHAR2(7)  := 'SWVMAJR';
  csStvCamp   CONSTANT VARCHAR2(7)  := 'STVCAMP';
  csStvStat   CONSTANT VARCHAR2(7)  := 'STVSTAT';
  csGtvZipc   CONSTANT VARCHAR2(7)  := 'GTVZIPC';
  csSmrPrle   CONSTANT VARCHAR2(7)  := 'SMRPRLE';
  csStvCnty   CONSTANT VARCHAR2(7)  := 'STVCNTY';
  csStvSbgi   CONSTANT VARCHAR2(7)  := 'STVSBGI';
  csSvvTssc   CONSTANT VARCHAR2(7)  := 'SVVTSSC';
  csStvCnt2   CONSTANT VARCHAR2(7)  := 'STVCNT2';
  csStvSta2   CONSTANT VARCHAR2(7)  := 'STVSTA2';
  csSsbSect   CONSTANT VARCHAR2(7)  := 'SSBSECT';
  csSsbSec2   CONSTANT VARCHAR2(7)  := 'SSBSEC2';
  csSwvCom2   CONSTANT VARCHAR2(7)  := 'SWVCOM2';
  csGvvGsrc   CONSTANT VARCHAR2(7)  := 'GVVGSRC';
  csStvCty2   CONSTANT VARCHAR2(7)  := 'STVCTY2';
  csSWBSUBJ   CONSTANT VARCHAR2(7)  := 'SWBSUBJ';
  csEXECUTE   CONSTANT VARCHAR2(7)  := 'EXECUTE';
  csSTVPTRM   CONSTANT VARCHAR2(7)  := 'STVPTRM';
  csSWBFOHO   CONSTANT VARCHAR2(7)  := 'SWBFOHO';
  csSWBFOH2   CONSTANT VARCHAR2(7)  := 'SWBFOH2';
  csSTVEDLV   CONSTANT VARCHAR2(7)  := 'STVEDLV';
  csACTAGRD   CONSTANT VARCHAR2(7)  := 'ACTAGRD';
  csGtvZip2   CONSTANT VARCHAR2(7)  := 'GTVZIP2';
  csSWBPHON   CONSTANT VARCHAR2(7)  := 'SWBPHON';
  csSWAPHON   CONSTANT VARCHAR2(7)  := 'SWAPHON';
  csSWAPAGO   CONSTANT VARCHAR2(7)  := 'SWAPAGO'; --GEPC 24/10/2013
  --csSWAPAGO   CONSTANT VARCHAR2(7)  := 'SWAPAGO'; --GEPC 24/10/2013
  csSWBPHO1   CONSTANT VARCHAR2(7)  := 'SWBPHO1';
  csSWBPHO2   CONSTANT VARCHAR2(7)  := 'SWBPHO2';
  csSWBVUEL   CONSTANT VARCHAR2(7)  := 'SWBVUEL';
  csGURUSRI   CONSTANT VARCHAR2(7)  := 'GURUSRI';
  csUSRYEXE   CONSTANT VARCHAR2(7)  := 'USRYEXE';
  csUSRNEXE   CONSTANT VARCHAR2(7)  := 'USRNEXE';
  csSTVHLDD   CONSTANT VARCHAR2(7)  := 'STVHLDD'; -- JMSM 07/06/2013
  csTOPSUSR   CONSTANT VARCHAR2(7)  := 'TOPSUSR'; -- JMSM 23/10/2013
  csSGBUSER   CONSTANT VARCHAR2(7)  := 'SGBUSER'; -- IELQ 26/06/2013
  csSWBEGRE   CONSTANT VARCHAR2(7)  := 'SWBEGRE';
  csSWBVUELo  CONSTANT VARCHAR2(8)  := 'SWBVUELo';
  csSWBVUELc  CONSTANT VARCHAR2(8)  := 'SWBVUELc';
  csCITAESTA  CONSTANT VARCHAR2(8)  := 'CITAESTA';
  csBLOQUEOS  CONSTANT VARCHAR2(8)  := 'BLOQUEOS';
  csDELETEPM  CONSTANT VARCHAR2(8)  := 'DELETEPM';
  csGURIDEN   CONSTANT VARCHAR2(8)  := 'GURIDEN';
  csSWBMODL   CONSTANT VARCHAR2(8)  := 'SWBMODL';
  csSWAPRIN   CONSTANT VARCHAR2(8)  := 'SWAPRIN';
  csSWAVUEL   CONSTANT VARCHAR2(8)  := 'SWAVUEL';
  csSWADOML   CONSTANT VARCHAR2(8)  := 'SWADOML';
  csSWACORR   CONSTANT VARCHAR2(8)  := 'SWACORR';
  csSWASPMX   CONSTANT VARCHAR2(8)  := 'SWASPMX';
  csASTDACA   CONSTANT VARCHAR2(8)  := 'ASTDACA';
  csKWABACPL  CONSTANT VARCHAR2(8)  := 'KWABACPL';
  csPromocion CONSTANT VARCHAR2(9)  := 'PROMOCION';
  csPromocio2 CONSTANT VARCHAR2(9)  := 'PROMOCIO2';
  csINCONSITC CONSTANT VARCHAR2(9)  := 'INCONSITC';
  csCRITERIOS CONSTANT VARCHAR2(9)  := 'CRITERIOS';
  csCRITERIOM CONSTANT VARCHAR2(9)  := 'CRITERIOM';
  csCUPOMAXIM CONSTANT VARCHAR2(9)  := 'CUPOMAXIM';
  csKWARLLEte CONSTANT VARCHAR2(9)  := 'KWARLLEte';
  csKWABAINGL CONSTANT VARCHAR2(9)  := 'KWABAINGL';
  csRolarStan CONSTANT VARCHAR2(9)  := 'RolarStan';
  csTWRSCRR   CONSTANT VARCHAR2(7)  := 'TWRSCRR';
  csSWBCIUD   CONSTANT VARCHAR2(7)  := 'SWBCIUD'; -- IELQ 23/10/2013
  csSWBESTA   CONSTANT VARCHAR2(7)  := 'SWBESTA'; -- IELQ 23/10/2013

  csPIDM      CONSTANT VARCHAR2(4)  := 'PIDM';        --- JCCR 04 MZO 2011
  csSsbSectR  CONSTANT VARCHAR2(10) := 'CSSSBSECTR';  --- JCCR 04 MZO 2011
  csTWRTAIN   CONSTANT VARCHAR2(7)  := 'TWRTAIN';     --- JCCR 10 MZO 2011
  csCITAINSC  CONSTANT VARCHAR2(8)  := 'CITAINSC';    --- JCCR 18 MAY 2011
  csEGRESADOS CONSTANT VARCHAR2(11) := '%EGRESADOS%';
  csLeCordon  CONSTANT VARCHAR2(14) := 'Le Cordon Blue';
  csNoAsigna  CONSTANT VARCHAR2(19) := 'Sin usuario';
  csNoAsigna2 CONSTANT VARCHAR2(32) := 'Usuario actualizador no asignado'; --gepc 22/10/2013
  csModaPar   CONSTANT VARCHAR2(21) := '(modalidad parcial=M)';
  csModaFin   CONSTANT VARCHAR2(21) := '(modalidad final=F)';
  csAllTerms  CONSTANT VARCHAR2(21) := 'Todos los periodos';
  csBAN_DEFAULT_M CONSTANT VARCHAR2(13) := 'BAN_DEFAULT_M'; --gepc 14/10/2013
  --md-02 start
  csStvTrac   CONSTANT VARCHAR2(7) := 'STVTRAC';
  csSsbCrnn   CONSTANT VARCHAR2(7) := 'SSBCRNN';
  csShlCll    CONSTANT VARCHAR2(2) := '\"';
  csShlApos   CONSTANT VARCHAR2(3) := '\''';
  csApos      CONSTANT VARCHAR2(2) := '''';
  --md-02  end
  cn0         CONSTANT NUMBER(1)   := 0;
  cn1         CONSTANT NUMBER(1)   := 1;
  cn2         CONSTANT NUMBER(1)   := 2;
  cn3         CONSTANT NUMBER(1)   := 3;
  cn4         CONSTANT NUMBER(1)   := 4;
  cn5         CONSTANT NUMBER(1)   := 5;
  cn6         CONSTANT NUMBER(1)   := 6;
  cn10        CONSTANT NUMBER(2)   := 10;
  cn13        CONSTANT NUMBER(2)   := 13;
  cn20        CONSTANT NUMBER(2)   := 20;
  cn22        CONSTANT NUMBER(2)   := 22;
  cn24        CONSTANT NUMBER(2)   := 24;
  cn40        CONSTANT NUMBER(2)   := 40;
  cn65        CONSTANT NUMBER(2)   := 65;
  cn90        CONSTANT NUMBER(2)   := 90;
  cn193       CONSTANT NUMBER(3)   := 193;
  cn201       CONSTANT NUMBER(3)   := 201;
  cn205       CONSTANT NUMBER(3)   := 205;
  cn209       CONSTANT NUMBER(3)   := 209;
  cn211       CONSTANT NUMBER(3)   := 211;
  cn218       CONSTANT NUMBER(3)   := 218;

  cdSysDate   CONSTANT DATE        := SYSDATE;
  cdTysDate   CONSTANT DATE        := TRUNC(SYSDATE);

  -- IELQ 09/10/2013
  csSin       CONSTANT VARCHAR2(3)  := 'SIN';


  -- LA FUNCION RETORNA EL CURSOR SELECCIONADO
  FUNCTION consulta(psCatalogo VARCHAR2,
                    psFiltro1  VARCHAR2 DEFAULT NULL,
                    psFiltro2  VARCHAR2 DEFAULT NULL,
                    psFiltro3  VARCHAR2 DEFAULT NULL,
                    psFiltro4  VARCHAR2 DEFAULT NULL,
                    psFiltro5  VARCHAR2 DEFAULT NULL
                   ) RETURN t_Cursor;

  --SALTA LA SEGURIDAD
  PROCEDURE saltaSeguridad;

  -- * CREA UN ARRAY PARA MANEJARLO CON AJAX
  --   ARRAY DE LA FORMA: [ ["",""], ["",""], ["",""]]
  PROCEDURE arreglo(psCatalogo VARCHAR2,
                    psFiltro1  VARCHAR2 DEFAULT NULL,
                    psFiltro2  VARCHAR2 DEFAULT NULL,
                    psFiltro3  VARCHAR2 DEFAULT NULL,
                    psFiltro4  VARCHAR2 DEFAULT NULL,
                    psFiltro5  VARCHAR2 DEFAULT NULL
                   );

  --RETORNA UNA PAGINA HTML
  PROCEDURE pagina(psCatalogo VARCHAR2,
                   psFiltro1  VARCHAR2 DEFAULT NULL,
                   psFiltro2  VARCHAR2 DEFAULT NULL,
                   psFiltro3  VARCHAR2 DEFAULT NULL,
                   psFiltro4  VARCHAR2 DEFAULT NULL,
                   psFiltro5  VARCHAR2 DEFAULT NULL
                  );

  --SALTA LA SEGURIDAD
  PROCEDURE saltaSeguridad IS

  BEGIN
      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;
  END saltaSeguridad;

  -- LA FUNCION RETORNA EL CURSOR SELECCIONADO
  FUNCTION consulta(psCatalogo VARCHAR2,
                    psFiltro1  VARCHAR2 DEFAULT NULL,
                    psFiltro2  VARCHAR2 DEFAULT NULL,
                    psFiltro3  VARCHAR2 DEFAULT NULL,
                    psFiltro4  VARCHAR2 DEFAULT NULL,
                    psFiltro5  VARCHAR2 DEFAULT NULL
                   ) RETURN t_Cursor IS

  cuQry  t_Cursor;

  BEGIN

      IF    psCatalogo = csStvColl THEN
            OPEN cuQry FOR
                 SELECT STVCOLL_CODE AS dataCode,
                        DECODE(psFiltro1,csSWAPRIN,
                                         STVCOLL_CODE||csEsp||STVCOLL_DESC,
                                         STVCOLL_DESC
                              ) AS dataDesc
                   FROM STVCOLL
                  WHERE STVCOLL_CODE <> cs00
                    AND STVCOLL_CODE <> cs99
                    AND (
                             psFiltro1 IS NULL
                          OR
                             (
                                   psFiltro1 = csCUPOMAXIM
                               AND STVCOLL_CODE IN (SELECT SWRUSCO_COLL_CODE
                                                      FROM SWRUSCO
                                                     WHERE SWRUSCO_USER_CODE = psFiltro2
                                                   )
                             )
                          OR (
                              psFiltro1 = csSWAPRIN
                             )
                       )
                  ORDER BY STVCOLL_DESC;

      ELSIF psCatalogo = csStvLevl THEN
            OPEN cuQry FOR
                 SELECT STVLEVL_CODE AS dataCode,
                        STVLEVL_DESC AS dataDesc
                   FROM STVLEVL
                  WHERE STVLEVL_CODE <> cs00
                    AND STVLEVL_CODE <> csLI
                  ORDER BY STVLEVL_DESC;

      ELSIF psCatalogo = csGURUSRI THEN
            OPEN cuQry FOR
                 SELECT csNoAsigna                               AS dataCode,
                        RPAD(csNoAsigna,cn20,csPnt)||csNoAsigna2 AS dataDesc
                   FROM DUAL
                  WHERE psFiltro2 IS NULL
                  UNION ALL
                 SELECT GURUSRI_VPDI_USER_ID                                AS dataCode,
                        RPAD(GURUSRI_VPDI_USER_ID,cn20,csPnt)||GURIDEN_DESC AS dataDesc
                   FROM GURUSRI,
                        GURIDEN
                  WHERE                        EXISTS (SELECT NULL
                                                         FROM GURUOBJ
                                                        WHERE GURUOBJ_USERID = GURIDEN_USER_ID
                                                          AND (
                                                                 (    psFiltro1      = csSWAPHON
                                                                  AND GURUOBJ_OBJECT = csSWAPHON
                                                                  AND GURUOBJ_ROLE   = csBAN_DEFAULT_M
                                                                 )
                                                               OR
                                                                 (
                                                                      psFiltro1      = csSWAPRIN
                                                                  AND GURUOBJ_OBJECT = csSWAPRIN
                                                                  AND GURUOBJ_ROLE   = csBAN_DEFAULT_M
                                                                 )
                                                              )
                                                      )
                    AND cn24                        = (SELECT COUNT(cn1)
                                                         FROM GORFBPR
                                                        WHERE GORFBPR_FBPR_CODE    LIKE csEGRESADOS
                                                          AND GORFBPR_FGAC_USER_ID    = GURUSRI_VPDI_USER_ID
                                                      )
                    AND GURUSRI_VPDI_USER_ID        = GURIDEN_USER_ID
                    AND GURUSRI_VPDI_CODE           = csCampCode
                  ORDER BY dataCode;

      ELSIF psCatalogo = csUSRYEXE THEN
            OPEN cuQry FOR
                 SELECT GURUSRI_VPDI_USER_ID                                  AS dataCode,
                        RPAD(GURUSRI_VPDI_USER_ID,cn20,cspnt)||A.GURIDEN_DESC AS dataDesc
                   FROM GURUSRI,
                        GURIDEN A
                  WHERE                        EXISTS (SELECT NULL
                                                         FROM GORFBPR
                                                        WHERE GORFBPR_FBPR_CODE IN (SELECT GTVFBPR_CODE
                                                                                      FROM GTVFBPR
                                                                                     WHERE GTVFBPR_CODE LIKE csEGRESADOS
                                                                                     )
                                                          AND GORFBPR_FGAC_USER_ID = A.GURIDEN_USER_ID
                                                      )
                    AND A.GURIDEN_ACTIVITY_DATE     = (SELECT MAX(B.GURIDEN_ACTIVITY_DATE)
                                                         FROM GURIDEN B
                                                        WHERE B.GURIDEN_USER_ID = A.GURIDEN_USER_ID
                                                      )
                    AND GURUSRI_VPDI_USER_ID        = A.GURIDEN_USER_ID
                    AND GURUSRI_VPDI_CODE           = csCampCode
                  ORDER BY GURUSRI_VPDI_USER_ID;

      ELSIF psCatalogo = csUSRNEXE THEN
            OPEN cuQry FOR
                 SELECT GURUSRI_VPDI_USER_ID                                  AS dataCode,
                        RPAD(GURUSRI_VPDI_USER_ID,cn20,cspnt)||A.GURIDEN_DESC AS dataDesc
                   FROM GURUSRI,
                        GURIDEN A
                  WHERE                    NOT EXISTS (SELECT NULL
                                                         FROM GORFBPR
                                                        WHERE GORFBPR_FBPR_CODE IN (SELECT GTVFBPR_CODE
                                                                                      FROM GTVFBPR
                                                                                     WHERE GTVFBPR_CODE LIKE csEGRESADOS
                                                                                     )
                                                          AND GORFBPR_FGAC_USER_ID = A.GURIDEN_USER_ID
                                                      )
                    AND                        EXISTS (SELECT NULL
                                                         FROM GURUOBJ
                                                        WHERE GURUOBJ_USERID  =  A.GURIDEN_USER_ID
                                                          AND GURUOBJ_OBJECT IN (csSWASPMX,csSWACORR,csSWAPHON,csSWAPRIN,csSWAPAGO,csSWAVUEL,csSWADOML)
                                                      )
                    AND A.GURIDEN_ACTIVITY_DATE     = (SELECT MAX(B.GURIDEN_ACTIVITY_DATE)
                                                         FROM GURIDEN B
                                                        WHERE B.GURIDEN_USER_ID = A.GURIDEN_USER_ID
                                                      )
                    AND GURUSRI_VPDI_USER_ID        = A.GURIDEN_USER_ID
                    AND GURUSRI_VPDI_CODE           = csCampCode
                  ORDER BY GURUSRI_VPDI_USER_ID;


      ELSIF psCatalogo = csGtvZipc THEN
            OPEN cuQry FOR
                 SELECT GTVZIPC_CITY AS dataCode,
                        GTVZIPC_CITY AS dataDesc
                   FROM GTVZIPC
                  WHERE GTVZIPC_CODE = psFiltro1
                  ORDER BY dataDesc DESC;

      ELSIF psCatalogo = csGtvZip2 THEN
            OPEN cuQry FOR
                 SELECT DISTINCT GTVZIPC_NATN_CODE                   AS dataCode,
                                 pk_catalogo.pais(GTVZIPC_NATN_CODE) AS dataDesc
                   FROM GTVZIPC
                  WHERE (UPPER(GTVZIPC_CITY) = UPPER(psFiltro4) OR psFiltro4 IS NULL)
                    AND GTVZIPC_CNTY_CODE = psFiltro3
                    AND GTVZIPC_STAT_CODE = psFiltro2
                    AND GTVZIPC_CODE      = psFiltro1
                  ORDER BY dataDesc DESC;

      ELSIF psCatalogo = csStvRdef THEN
            OPEN cuQry FOR
                 SELECT STVRDEF_CODE AS dataCode,
                        STVRDEF_DESC AS dataDesc
                   FROM STVRDEF
                  ORDER BY STVRDEF_DESC;

      ELSIF psCatalogo = csGtvInsm THEN
            OPEN cuQry FOR
                 SELECT GTVINSM_CODE AS dataCode,
                        GTVINSM_DESC AS dataDesc
                   FROM GTVINSM
                  ORDER BY DECODE(GTVINSM_CODE,csPR,cn1,csSP,cn2,csWE,cn3,cn4);

      ELSIF psCatalogo = csGtvInsm THEN
            OPEN cuQry FOR
                 SELECT GTVINSM_CODE AS dataCode,
                        GTVINSM_DESC AS dataDesc
                   FROM GTVINSM
                  ORDER BY GTVINSM_DESC;

      ELSIF psCatalogo = csSTVHLDD THEN                                 -- JMSM 07/06/2013
            OPEN cuQry FOR
                 SELECT STVHLDD_CODE                                    AS dataCode,
                        STVHLDD_CODE||csEsp||csGui||csEsp||STVHLDD_DESC AS dataDesc
                   FROM STVHLDD
                  ORDER BY STVHLDD_CODE;


      ELSIF psCatalogo = csIdiomas THEN
            OPEN cuQry FOR
                 SELECT csI       AS dataCode,
                        csIngles  AS dataDesc
                   FROM DUAL
                  UNION ALL
                 SELECT csE       AS dataCode,
                        csEspanol AS dataDesc
                   FROM DUAL
                  UNION ALL
                 SELECT csO       AS dataCode,
                        csOtro    AS dataDesc
                   FROM DUAL
                  ORDER BY dataDesc;

      ELSIF psCatalogo = csSirNist THEN
            OPEN cuQry FOR
                 SELECT SIRNIST_PIDM AS dataCode,
                        (SELECT REPLACE(SPRIDEN_LAST_NAME,csAst,csEsp)||csEsp||
                                SPRIDEN_FIRST_NAME
                           FROM SPRIDEN
                          WHERE SPRIDEN_CHANGE_IND IS NULL
                            AND SPRIDEN_PIDM = SIRNIST_PIDM
                        ) AS dataDesc
                   FROM SIRNIST
                  WHERE SIRNIST_NIST_CODE = csSICC
                    AND SIRNIST_TERM_CODE = psFiltro1
                    AND SIRNIST_COLL_CODE = psFiltro2
                  GROUP BY SIRNIST_PIDM
                  ORDER BY dataDesc;

      ELSIF psCatalogo = csSwrPltm THEN
            OPEN cuQry FOR
                 SELECT SWRPLTM_SEQN_CODE  AS dataCode,
                        NVL(
                        (SELECT SWVESTR_DESC
                           FROM SWVESTR
                          WHERE SWVESTR_CODE = SWRPLTM_ESTRATEGIA
                        ),
                        SWRPLTM_ESTRATEGIA) AS dataDesc
                   FROM SWRPLTM
                  WHERE SWRPLTM_SELECCION = csY
                    AND SWRPLTM_CRN       = psFiltro2
                    AND SWRPLTM_TERM_CODE = psFiltro1;

      ELSIF psCatalogo = csSwvComp THEN
            OPEN cuQry FOR
                 SELECT SWVCOMP_CODE AS dataCode,
                        SWVCOMP_DESC AS dataDesc
                   FROM SWVCOMP
                  WHERE SWVCOMP_TIPO = csM
                  ORDER BY SWVCOMP_ORDEN ;

      ELSIF psCatalogo = csGwbAutr THEN
            OPEN cuQry FOR
                 SELECT GWBAUTR_CODE AS dataCode,
                        GWBAUTR_DESC AS dataDesc
                   FROM GWBAUTR
                  ORDER BY GWBAUTR_DESC;

      ELSIF psCatalogo = csGwbInst THEN
            OPEN cuQry FOR
                 SELECT GWBINST_CODE AS dataCode,
                        GWBINST_DESC AS dataDesc
                   FROM GWBINST
                  ORDER BY GWBINST_DESC;

      ELSIF psCatalogo = csGwbModl THEN
            OPEN cuQry FOR
                 SELECT GWBMODL_CODE AS dataCode,
                        GWBMODL_DESC AS dataDesc
                   FROM GWBMODL
                  ORDER BY GWBMODL_DESC;

      ELSIF psCatalogo = csCurLevl THEN
            OPEN cuQry FOR
                 SELECT STVLEVL_CODE AS dataCode,
                        STVLEVL_DESC AS dataDesc
                   FROM STVLEVL
                  WHERE STVLEVL_CODE IN (SELECT SOBCURR_LEVL_CODE
                                           FROM SOBCURR
                                          WHERE EXISTS (SELECT csNull
                                                          FROM SMRPRLE
                                                         WHERE SMRPRLE_PROGRAM    = SOBCURR_PROGRAM
                                                           AND SMRPRLE_LOCKED_IND = csN
                                                       )
                                        )
                  ORDER BY dataCode DESC;

      ELSIF psCatalogo = csStvTerm THEN
            OPEN cuQry FOR
                 SELECT STVTERM_CODE AS dataCode,
                        DECODE(psFiltro1,csINCONSITC, STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csBLOQUEOS,  STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csCRITERIOS, STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csCRITERIOM, STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csCITAINSC,  STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csDELETEPM,  STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csEXECUTE,   STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csCUPOMAXIM, STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csPromocio2, STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csACTAGRD,   STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csKWARLLEte, STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csKWABAINGL, STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csKWABACPL,  STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csASTDACA,   STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         csSTVTERM,   STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC,
                                         STVTERM_DESC
                              ) AS dataDesc
                   FROM STVTERM
                  WHERE (
                            psFiltro1 IS NULL
                         OR
                            psFiltro1 = csEXECUTE
                         OR
                            (
                                 psFiltro1          = csPromocion
                             AND cdSysDate         <= ADD_MONTHS(STVTERM_START_DATE, cn6)
                             AND STVTERM_CODE      <> cs999999
                             AND STVTERM_TRMT_CODE <> csR
                            )
                         OR
                            (
                                 psFiltro1                     = csPromocio2
                             AND (
                                     SUBSTR(STVTERM_DESC,cn1,cn2)        = psFiltro2
                                  OR
                                     SUBSTR(UPPER(STVTERM_DESC),cn1,cn3) = psFiltro2
                                  OR
                                     (    csPRE                          = psFiltro2
                                      AND SUBSTR(STVTERM_CODE,cn5,cn2)   = cs50
                                     )
                                 )
                             AND (   SUBSTR(STVTERM_CODE,cn1,cn4) = csYear
                                  OR SUBSTR(STVTERM_CODE,cn1,cn4) = csYear + cn1
                                  OR SUBSTR(STVTERM_CODE,cn1,cn4) = csYear + cn2
                                  OR SUBSTR(STVTERM_CODE,cn1,cn4) = csYear + cn3
                                 )
                            )
                         OR
                            (
                                 psFiltro1     = csINCONSITC
                             AND STVTERM_CODE IN (SELECT encuesta.TERM
                                                    FROM (SELECT SSBSECT_TERM_CODE            AS TERM,
                                                                 MIN(SVRESAF_DTES_BEGIN_DATE) AS MIND,
                                                                 MAX(SVRESAF_DTES_END_DATE)   AS MAXD
                                                            FROM SSBSECT INNER JOIN SVRESAF ON (SSBSECT_TERM_CODE = SVRESAF_TERM_CODE AND SSBSECT_CRN = SVRESAF_CRN)
                                                           WHERE (SSBSECT_CAMP_CODE = psFiltro2 OR psFiltro2 IS NULL)
                                                           GROUP BY SSBSECT_TERM_CODE
                                                         ) encuesta
                                                   WHERE (
                                                             TRUNC(encuesta.MIND-cn20) <= cdTysDate
                                                          OR
                                                             TRUNC(encuesta.MIND+cn20) > cdTysDate
                                                         )
                                                     AND TRUNC(encuesta.MAXD+cn90) >= cdTysDate
                                                 )
                            )
                          OR
                            (
                                 psFiltro1     = csBLOQUEOS
                             AND STVTERM_CODE IN (SELECT SFRRACL_TERM_CODE
                                                    FROM SFRRACL
                                                   WHERE SFRRACL_PIDM = f_get_pidm(psFiltro2)
                                                     AND SFRRACL_LAST_ACTIVITY_DATE IS NOT NULL
                                                     AND SFRRACL_REG_ACCESS_ID      IS NOT NULL
                                                     AND SFRRACL_SOURCE_CDE         IS NOT NULL
                                                 )
                            )
                          OR
                            (
                                 psFiltro1     = csCRITERIOS
                             AND STVTERM_CODE IN (SELECT SIRASGN_TERM_CODE
                                                    FROM SIRASGN
                                                   WHERE EXISTS (SELECT NULL
                                                                   FROM SOBTERM
                                                                  WHERE SOBTERM_TERM_CODE              = SIRASGN_TERM_CODE
                                                                    AND SOBTERM_DYNAMIC_SCHED_TERM_IND = csY
                                                                )
                                                     AND SIRASGN_PRIMARY_IND = csY
                                                     AND SIRASGN_PIDM        = psFiltro2
                                                 )
                            )
                         OR
                            (
                                 psFiltro1     = csCRITERIOM
                             AND STVTERM_CODE IN (SELECT SIRNIST_TERM_CODE
                                                    FROM SIRNIST
                                                   WHERE EXISTS (SELECT NULL
                                                                   FROM SOBTERM
                                                                  WHERE SOBTERM_TERM_CODE              = SIRNIST_TERM_CODE
                                                                    AND SOBTERM_DYNAMIC_SCHED_TERM_IND = csY
                                                                )
                                                     AND SIRNIST_NIST_CODE = csSICC
                                                              AND SIRNIST_ASTY_CODE = csMRE
                                                     AND SIRNIST_PIDM      = psFiltro2
                                                 )
                            )
                         OR
                            (
                                 psFiltro1     = csPIDM
                             AND STVTERM_CODE IN (SELECT DISTINCT SIRASGN_TERM_CODE termCode
                                                        FROM SIRASGN, STVTERM
                                                        WHERE SIRASGN_PIDM        = psFiltro2
                                                        AND SIRASGN_PRIMARY_IND = csY
                                                        AND STVTERM_CODE        = SIRASGN_TERM_CODE
                                                        AND EXISTS (SELECT NULL
                                                        FROM SOBTERM
                                                        WHERE SOBTERM_TERM_CODE              = SIRASGN_TERM_CODE
                                                        AND SOBTERM_DYNAMIC_SCHED_TERM_IND = csY)
                                                 )
                            )
                         OR
                           (
                                 psFiltro1                     = csCITAINSC
                             AND STVTERM_CODE                 IN (SELECT SFRCTRL_TERM_CODE_HOST
                                                                    FROM SFRCTRL
                                                                   WHERE SUBSTR(SFRCTRL_TERM_CODE_HOST,cn1,cn4) >= csYear
                                                                     AND (
                                                                           (
                                                                                TRUNC(SFRCTRL_BEGIN_DATE) >= cdTysDate
                                                                            AND cdTysDate NOT BETWEEN TRUNC(SFRCTRL_BEGIN_DATE) AND TRUNC(SFRCTRL_END_DATE)
                                                                           )
                                                                        OR
                                                                           (
                                                                                    cdTysDate BETWEEN TRUNC(SFRCTRL_BEGIN_DATE)     AND TRUNC(SFRCTRL_END_DATE)

                                                                           )
                                                                        )
                                                                 )
                             --AND SUBSTR(STVTERM_CODE,cn6,cn1)  = cs0         --md-03
                             AND TRUNC(STVTERM_END_DATE)       > cdTysDate
                             AND STVTERM_CODE                 <> cs999999
                             AND STVTERM_CODE                 <> cs999998
                             AND STVTERM_CODE                 <> cs999997
                             AND STVTERM_CODE                 <> cs999996
                           )
                         OR
                           (
                                 psFiltro1     = csCITAESTA
                             AND STVTERM_CODE IN (SELECT SFRCTRL_TERM_CODE_HOST
                                                    FROM SFRCTRL
                                                   WHERE csCampCode IN  (SFRCTRL_CMPS_1,
                                                                         SFRCTRL_CMPS_2,
                                                                         SFRCTRL_CMPS_3,
                                                                         SFRCTRL_CMPS_4,
                                                                         SFRCTRL_CMPS_5
                                                                        )
                                                 )
                             AND (   STVTERM_CODE = cs999998
                                  OR STVTERM_CODE = cs999997
                                  OR STVTERM_CODE = cs999996
                                 )
                           )
                         OR
                           (
                                psFiltro1     = csDELETEPM
                            AND STVTERM_CODE IN (SELECT SWBSUBJ_TERM_CODE
                                                   FROM SWBSUBJ
                                                  WHERE NOT EXISTS (SELECT NULL
                                                                      FROM FWRPBLC
                                                                     WHERE FWRPBLC_CRN       = SWBSUBJ_CRN
                                                                       AND FWRPBLC_TERM_CODE = SWBSUBJ_TERM_CODE
                                                                   )
                                                )

                           )
                         OR
                           (
                                psFiltro1     = csCUPOMAXIM
                            AND STVTERM_CODE <> cs000000
                            AND STVTERM_CODE <> cs999999
                            AND STVTERM_CODE <> cs299999
                           )
                         OR
                           (
                                psFiltro1     = csACTAGRD
                            AND          EXISTS (SELECT NULL
                                                   FROM SOBTERM
                                                  WHERE SOBTERM_TERM_CODE              = STVTERM_CODE
                                                    AND SOBTERM_DYNAMIC_SCHED_TERM_IND = csY
                                                )
                            AND STVTERM_CODE IN (SELECT SIRASGN_TERM_CODE
                                                   FROM SIRASGN
                                                  WHERE SIRASGN_PRIMARY_IND = csY
                                                    AND SIRASGN_PIDM        = psFiltro2
                                                )
                           )
                         OR
                           (
                                psFiltro1     = csSTVTERM
                            AND          EXISTS (SELECT NULL
                                                   FROM SOBTERM
                                                  WHERE SOBTERM_TERM_CODE              = STVTERM_CODE
                                                    AND SOBTERM_DYNAMIC_SCHED_TERM_IND = csY
                                                )
                            AND STVTERM_CODE                 <> cs999999
                            AND STVTERM_CODE                 <> cs999998
                            AND STVTERM_CODE                 <> cs999997
                            AND STVTERM_CODE                 <> cs999996
                            AND STVTERM_CODE                 <> cs000000
                            AND STVTERM_CODE                 <> cs299999
                            AND TRUNC(STVTERM_END_DATE)       > cdTysDate -200
                           )
                         OR
                           (    psFiltro1                     = csKWARLLEte
                            AND SUBSTR(STVTERM_CODE,cn5,cn2)  = cs10
                            AND STVTERM_CODE                 >= cs201010
                           )
                         OR
                           (    psFiltro1                     = csKWABAINGL
                            AND SUBSTR(STVTERM_CODE,cn5,cn2)  = cs40
                            AND STVTERM_CODE                 >= cs201040
                           )
                         OR
                           (    psFiltro1                     = csKWABACPL
                            AND SUBSTR(STVTERM_CODE,cn5,cn2) IN (cs40, cs10, cs60)
                            AND STVTERM_CODE                 >= cs201010
                           )
                         OR
                           (    psFiltro1                     = csASTDACA
                            AND          EXISTS (SELECT NULL
                                                   FROM SHRTTRM
                                                  WHERE SHRTTRM_TERM_CODE = STVTERM_CODE
                                                    AND SHRTTRM_PIDM      = f_get_pidm(psFiltro2)
                                                )
                           )
                        )
                  UNION ALL
                 SELECT cszzzzzz   AS dataCode,
                        csAllTerms AS dataDesc
                   FROM DUAL
                  WHERE psFiltro1 = csCUPOMAXIM
                  ORDER BY dataCode DESC;

      ELSIF psCatalogo = csStvLend THEN
            OPEN cuQry FOR
                 SELECT STVLEND_CODE AS dataCode,
                        STVLEND_DESC AS dataDesc
                   FROM STVLEND
                  ORDER BY dataCode DESC;

      ELSIF psCatalogo = csSwvSbgi THEN
            OPEN cuQry FOR
                 SELECT SWVSBGI_CODE AS dataCode,
                        SWVSBGI_DESC AS dataDesc
                   FROM SWVSBGI
                  ORDER BY dataCode DESC;

      ELSIF psCatalogo = csSwvMajr THEN
            OPEN cuQry FOR
                 SELECT SWVMAJR_CODE AS dataCode,
                        SWVMAJR_DESC AS dataDesc
                   FROM SWVMAJR
                  WHERE (
                             (
                                  psFiltro1 IS NULL
                              AND
                                  SWVMAJR_INDICATOR = csY
                             )
                         OR
                             (
                                  psFiltro1          = csPromocion
                              AND
                                  SWVMAJR_INDICATOR = csN
                             )
                        )
                  ORDER BY dataCode DESC;

      ELSIF psCatalogo = csStvCamp THEN
            OPEN cuQry FOR
                 SELECT csLCB      AS dataCode,
                        DECODE(psFiltro1,csINCONSITC,csLCB||csEsp||csGui||csEsp||csLeCordon,
                                         csEXECUTE,  csLCB||csEsp||csGui||csEsp||csLeCordon,
                               csLeCordon
                        ) AS dataDesc
                   FROM DUAL
                  WHERE psFiltro1 IS NULL
                  UNION ALL
                 SELECT STVCAMP_CODE AS dataCode,
                        DECODE(psFiltro1,csINCONSITC,STVCAMP_CODE||csEsp||csGui||csEsp||STVCAMP_DESC,STVCAMP_DESC) AS dataDesc
                   FROM STVCAMP
                  WHERE (
                             (
                                  psFiltro1 IS NULL
                             )
                         OR
                               psFiltro1 = csEXECUTE
                         OR
                             (
                                  psFiltro1     = csPromocion
                              AND STVCAMP_CODE <> csUAT
                              AND STVCAMP_CODE <> csA
                              AND STVCAMP_CODE <> cs000
                             )
                         OR
                             (
                                 psFiltro1     = csINCONSITC
                             AND STVCAMP_CODE IN (SELECT encuesta.CAMP
                                                   FROM (SELECT SSBSECT_CAMP_CODE            AS CAMP,
                                                                MIN(SVRESAF_DTES_BEGIN_DATE) AS MIND,
                                                                MAX(SVRESAF_DTES_END_DATE)   AS MAXD
                                                           FROM SSBSECT INNER JOIN SVRESAF ON (SSBSECT_TERM_CODE = SVRESAF_TERM_CODE AND SSBSECT_CRN = SVRESAF_CRN)
                                                          GROUP BY SSBSECT_CAMP_CODE
                                                        ) encuesta
                                                  WHERE (
                                                            TRUNC(encuesta.MIND-cn20) <= cdTysDate
                                                         OR
                                                            TRUNC(encuesta.MIND+cn20) > cdTysDate
                                                        )
                                                    AND TRUNC(encuesta.MAXD+cn90) >= cdTysDate
                                                )
                            )
                        )
                  ORDER BY dataCode;

      ELSIF psCatalogo = csStvPtrm THEN
            OPEN cuQry FOR
                 SELECT STVPTRM_CODE AS dataCode,
                        DECODE(psFiltro1,csINCONSITC,STVPTRM_CODE||csEsp||csGui||csEsp||STVPTRM_DESC,
                                         csEXECUTE,  STVPTRM_CODE||csEsp||csGui||csEsp||STVPTRM_DESC,
                        STVPTRM_DESC) AS dataDesc
                   FROM STVPTRM
                  WHERE (
                             (
                                  psFiltro1 IS NULL
                             )
                         OR
                               psFiltro1 = csEXECUTE
                         OR
                             (
                                 psFiltro1     = csINCONSITC
                             AND STVPTRM_CODE IN (SELECT encuesta.PTRM
                                                   FROM (SELECT SSBSECT_PTRM_CODE            AS PTRM,
                                                                MIN(SVRESAF_DTES_BEGIN_DATE) AS MIND,
                                                                MAX(SVRESAF_DTES_END_DATE)   AS MAXD
                                                           FROM SSBSECT INNER JOIN SVRESAF ON (SSBSECT_TERM_CODE = SVRESAF_TERM_CODE AND SSBSECT_CRN = SVRESAF_CRN)
                                                          WHERE (SSBSECT_CAMP_CODE = psFiltro2 OR psFiltro2 IS NULL)
                                                            AND (SSBSECT_TERM_CODE = psFiltro3 OR psFiltro3 IS NULL)
                                                          GROUP BY SSBSECT_PTRM_CODE
                                                        ) encuesta
                                                  WHERE (
                                                            TRUNC(encuesta.MIND-cn20) <= cdTysDate
                                                         OR
                                                            TRUNC(encuesta.MIND+cn20) > cdTysDate
                                                        )
                                                    AND TRUNC(encuesta.MAXD+cn90) >= cdTysDate
                                                )
                            )
                        )
                  ORDER BY dataCode;

      ELSIF psCatalogo = csStvStat THEN
            OPEN cuQry FOR
                 SELECT STVSTAT_CODE          AS dataCode,
                        INITCAP(STVSTAT_DESC) AS dataDesc
                   FROM STVSTAT
                  WHERE (
                             (
                                  psFiltro1 IS NULL
                             )
                         OR
                             (
                                  psFiltro1     = csPromocion
                              AND STVSTAT_CODE <> cs000
                              AND (   ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) = cn193
                                   OR ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) = cn201
                                   OR ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) = cn205
                                   OR ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) = cn209
                                   OR ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) = cn211
                                   OR ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) = cn218
                                   OR (    ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) >= cn65
                                       AND ASCII(SUBSTR(STVSTAT_DESC, cn3, cn1)) <= cn90
                                      )
                                   OR STVSTAT_DESC LIKE csPMEXP
                                  )
                             )
                        )
                  ORDER BY dataDesc;

      ELSIF psCatalogo = csGtvZipc THEN
            OPEN cuQry FOR
                 SELECT GTVZIPC_CITY AS dataCode,
                        GTVZIPC_CITY AS dataDesc
                   FROM GTVZIPC
                  WHERE GTVZIPC_CODE = psFiltro1
                  ORDER BY dataDesc DESC;

      ELSIF psCatalogo = csSmrPrle THEN
            OPEN cuQry FOR
                 SELECT SMRPRLE_PROGRAM      AS dataCode,
                        -- IELQ 09/10/2013
                        DECODE (psFiltro5, csSin, SMRPRLE_PROGRAM_DESC,
                                                  SMRPRLE_PROGRAM||csEsp||csGui||csEsp||SMRPRLE_PROGRAM_DESC) AS dataDesc
                        --SMRPRLE_PROGRAM||csEsp||csGui||csEsp||SMRPRLE_PROGRAM_DESC AS dataDesc
                   FROM SMRPRLE
                  WHERE SMRPRLE_PROGRAM IN (SELECT C.SOBCURR_PROGRAM
                                              FROM SORMCRL S,
                                                   SOBCURR C
                                             WHERE S.SORMCRL_TERM_CODE_EFF  = (SELECT MAX(S2.SORMCRL_TERM_CODE_EFF)
                                                                                 FROM SORMCRL S2
                                                                                WHERE S2.SORMCRL_CURR_RULE      = S.SORMCRL_CURR_RULE
                                                                              )
                                               AND S.SORMCRL_CURR_RULE      = C.SOBCURR_CURR_RULE
                                               AND S.SORMCRL_TERM_CODE_EFF <= psFiltro3
                                               AND (
                                                       (    psFiltro4         IS NULL
                                                        AND S.SORMCRL_REC_IND  = csY
                                                       )
                                                    OR
                                                       (
                                                        csRolarStan = psFiltro4
                                                       )
                                                   )
                                               AND C.SOBCURR_LEVL_CODE      = psFiltro2
                                               AND (
                                                      (     psFiltro1           = csISF
                                                        and SOBCURR_COLL_CODE   = csJP
                                                      )
                                                   OR
                                                      (     psFiltro1           <> csISF
                                                        AND (
                                                                C.SOBCURR_CAMP_CODE  = psFiltro1
                                                             OR
                                                                C.SOBCURR_CAMP_CODE IS NULL
                                                            )
                                                      )
                                                   )
                                           )
               ORDER BY SMRPRLE_PROGRAM;

      ELSIF psCatalogo = csStvCnty THEN
            OPEN cuQry FOR
                 SELECT STVCNTY_CODE AS dataCode,
                        STVCNTY_DESC AS dataDesc
                   FROM STVCNTY
                  WHERE (
                             (
                               psFiltro1 IS NULL
                             )
                          OR
                             (
                                   psFiltro1     = csPromocion
                               AND
                                   STVCNTY_CODE IN (SELECT SOBSBGI_CNTY_CODE
                                                      FROM SOBSBGI
                                                     WHERE SOBSBGI_STAT_CODE = psFiltro2
                                                   )
                             )
                        )
               ORDER BY dataDesc;

      ELSIF psCatalogo = csStvSbgi THEN
            OPEN cuQry FOR
                 SELECT STVSBGI_CODE AS dataCode,
                        STVSBGI_DESC AS dataDesc
                   FROM STVSBGI
                  WHERE (
                             (
                               psFiltro1 IS NULL
                             )
                          OR
                             (
                                   psFiltro1     = csPromocion
                               AND (
                                       (    psFiltro2        = csLC
                                        AND STVSBGI_TYPE_IND = csH
                                       )
                                    OR
                                       (    psFiltro2        IN (csMA,csDR)
                                        AND STVSBGI_TYPE_IND  = csC
                                       )
                                   )
                             )
                        )
               ORDER BY dataDesc;

      ELSIF psCatalogo = csSvvTssc THEN
            OPEN cuQry FOR
                 SELECT SVVTSSC_CODE                                    AS dataCode,
                        SVVTSSC_CODE||csEsp||csGui||csEsp||SVVTSSC_DESC AS dataDesc
                   FROM SVVTSSC
                  ORDER BY dataCode;
      --md-02 start
      -- term
      ELSIF psCatalogo = csStvTrac THEN
            OPEN cuQry FOR
                 SELECT STVTERM_CODE AS dataCode,
                        STVTERM_CODE||csGui||STVTERM_DESC AS dataDesc
                   FROM STVTERM
                  WHERE EXISTS (SELECT NULL
                                  FROM SIRASGN
                                 WHERE SIRASGN_TERM_CODE   = STVTERM_CODE
                                   AND SIRASGN_PRIMARY_IND = csY
                                   AND SIRASGN_PIDM        = psFiltro1
                               )
                    AND EXISTS (SELECT NULL
                                  FROM SOBTERM
                                 WHERE SOBTERM_TERM_CODE              = STVTERM_CODE
                                   AND SOBTERM_DYNAMIC_SCHED_TERM_IND = csY
                               )
                  ORDER BY STVTERM_CODE DESC;
        -- crn
      ELSIF psCatalogo = csSsbCrnn THEN
            OPEN cuQry FOR
                 SELECT SSBSECT_CRN AS dataCode,
                        SSBSECT_CRN      ||csGui||
                        SSBSECT_SUBJ_CODE||csGui||
                        SSBSECT_CRSE_NUMB||csGui||
                        INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,csApos,csShlApos),csComilla,csShlCll)) AS dataDesc
                   FROM SCBCRSE A,
                        SSBSECT SS
                  WHERE SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                    AND SCBCRSE_EFF_TERM  = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                               FROM SCBCRSE SC
                                              WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                            )
                    AND EXISTS (SELECT NULL
                                  FROM SIRASGN
                                 WHERE SIRASGN_TERM_CODE   = psFiltro1
                                   AND SIRASGN_CRN         = SSBSECT_CRN
                                   AND SIRASGN_PIDM        = psFiltro2
                                   AND SIRASGN_PRIMARY_IND = csY
                               )
                    AND EXISTS (SELECT NULL
                                  FROM SFRSTCR
                                 WHERE SFRSTCR_TERM_CODE  = psFiltro1
                                   AND SFRSTCR_RSTS_CODE IN (SELECT STVRSTS_CODE FROM STVRSTS WHERE STVRSTS_GRADABLE_IND = csY)
                                   AND SFRSTCR_CRN        = SSBSECT_CRN
                               )
                    AND SSBSECT_TERM_CODE = psFiltro1
                  ORDER BY SSBSECT_SUBJ_CODE,SSBSECT_CRSE_NUMB;

      --md-02 end
      ELSIF psCatalogo = csStvCnt2 THEN
            OPEN cuQry FOR
                 SELECT STVCNTY_CODE                                    AS dataCode,
                        STVCNTY_CODE||csEsp||csGui||csEsp||STVCNTY_DESC AS dataDesc
                   FROM STVCNTY
                  WHERE STVCNTY_CODE IN (SELECT GTVZIPC_CNTY_CODE
                                           FROM GTVZIPC
                                          WHERE GTVZIPC_CODE = psFiltro1
                                        )
                  ORDER BY dataDesc;

      ELSIF psCatalogo = csStvSta2 THEN
            OPEN cuQry FOR
                 SELECT STVSTAT_CODE                                    AS dataCode,
                        STVSTAT_CODE||csEsp||csGui||csEsp||STVSTAT_DESC AS dataDesc
                   FROM STVSTAT
                  WHERE STVSTAT_CODE IN (SELECT GTVZIPC_STAT_CODE
                                           FROM GTVZIPC
                                          WHERE GTVZIPC_CODE = psFiltro1
                                        )
                  ORDER BY dataDesc;

      ELSIF psCatalogo = csSsbSect THEN
            OPEN cuQry FOR
                 SELECT SSBSECT_CRN                                                            AS dataCode,
                        SSBSECT_CRN||csEsp||SSBSECT_SUBJ_CODE||csEsp||SSBSECT_CRSE_NUMB||csEsp||
                        INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,csAps,csShlAps),csCml,csShlCml)) AS dataDesc
                   FROM SCBCRSE A,
                        SSBSECT SS
                  WHERE SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                    AND SCBCRSE_EFF_TERM  = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                               FROM SCBCRSE SC
                                              WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                            )
                    AND EXISTS (SELECT NULL
                                  FROM SIRASGN
                                 WHERE SIRASGN_CRN         = SSBSECT_CRN
                                   AND SIRASGN_PRIMARY_IND = csY
                                   AND SIRASGN_PIDM        = psFiltro2
                                   AND SIRASGN_TERM_CODE   = psFiltro1
                               )
                    AND SSBSECT_TERM_CODE = psFiltro1
                  ORDER BY SSBSECT_SUBJ_CODE,
                           SSBSECT_CRSE_NUMB;

      ELSIF psCatalogo = csSwvCom2 THEN
            OPEN cuQry FOR
                 SELECT swvcom.compCode                        AS dataCode,
                        swvcom.compCode||csEsp||csGui||csEsp||
                        swvcom.compDesc||csEsp||csGui||csEsp||
                        swvcom.TipoDesc                        AS dataDesc
                   FROM (SELECT SWVCOMP_CODE                                     AS compCode,
                                SWVCOMP_DESC                                     AS compDesc,
                                DECODE(SWVCOMP_TIPO,csM,csModaPar,csF,csModaFin) AS TipoDesc,
                                DECODE(SWVCOMP_TIPO,csM,cn1,csF,cn2)             AS ordnTipo,
                                SWVCOMP_ORDEN                                    AS compOrdn
                           FROM SWVCOMP
                        ) swvcom
                  ORDER BY swvcom.ordnTipo,
                           swvcom.compOrdn;

      ELSIF psCatalogo = csTWRTAIN  THEN
            OPEN cuQry FOR
             SELECT TWRTAIN_TERM_CODE  AS dataCode,
                    TWRTAIN_TERM_CODE||csEsp||(SELECT STVTERM_DESC
                                               FROM STVTERM
                                              WHERE STVTERM_CODE = TWRTAIN_TERM_CODE) AS dataDesc
               FROM TWRTAIN
              WHERE NVL(TWRTAIN_TERM_ACTIVE,csN) = csY
              ORDER BY TWRTAIN_TERM_CODE;

      ELSIF psCatalogo = csSsbSectR  THEN
            OPEN cuQry FOR
                 SELECT SSBSECT_CRN                                                  AS dataCode,
                        SSBSECT_CRN||csEsp||SSBSECT_SUBJ_CODE||csEsp||SSBSECT_CRSE_NUMB||csEsp||
                        INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,'''','\'''),'"','\"')) AS dataDesc
                   FROM SCBCRSE A,
                        SSBSECT SS
                  WHERE SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                    --AND SSBSECT_CAMP_CODE = csCampCode
                    AND SCBCRSE_EFF_TERM  = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                FROM SCBCRSE SC
                                               WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                 AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                 AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                            )
                    AND EXISTS              (SELECT NULL
                                               FROM SIRASGN
                                              WHERE SIRASGN_TERM_CODE   = psFiltro1
                                                AND SIRASGN_CRN         = SSBSECT_CRN
                                                AND SIRASGN_PIDM        = psFiltro2
                                                AND SIRASGN_PRIMARY_IND = csY
                                            )
                    AND EXISTS              (SELECT NULL
                                               FROM SFRSTCR
                                              WHERE SFRSTCR_RSTS_CODE IN (csRW, csRE)
                                                AND SFRSTCR_CRN        = SSBSECT_CRN
                                                AND SFRSTCR_TERM_CODE  = SSBSECT_TERM_CODE
                                                AND SFRSTCR_TERM_CODE  = psFiltro1
                                            )
                    AND SSBSECT_TERM_CODE = psFiltro1
                  ORDER BY SSBSECT_SUBJ_CODE,
                           SSBSECT_CRSE_NUMB;

      ELSIF psCatalogo = csSsbSec2 THEN
            OPEN cuQry FOR
                 SELECT SSBSECT_CRN                                                            AS dataCode,
                        SSBSECT_CRN||csEsp||SSBSECT_SUBJ_CODE||csEsp||SSBSECT_CRSE_NUMB||csEsp||
                        INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,csAps,csShlAps),csCml,csShlCml)) AS dataDesc
                   FROM SCBCRSE A,
                        SSBSECT SS,
                        SIRASGN,
                        (SELECT SSBOVRR_TERM_CODE AS TERM,
                                SSBOVRR_CRN       AS CRN
                           FROM SIRNIST,SSBOVRR
                          WHERE SIRNIST_TOPS_CODE = SSBOVRR_TOPS_CODE
                            AND SIRNIST_NIST_CODE = csSICC
                            AND SIRNIST_ASTY_CODE = csMRE
                            AND SIRNIST_TERM_CODE = psFiltro1
                            AND SIRNIST_PIDM      = psFiltro2
                        ) SUPP
                  WHERE csY               = SIRASGN_PRIMARY_IND(+)
                    AND SSBSECT_TERM_CODE = SIRASGN_TERM_CODE(+)
                    AND SSBSECT_CRN       = SIRASGN_CRN(+)
                    AND SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                    AND SCBCRSE_EFF_TERM  = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                 FROM SCBCRSE SC
                                                WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                  AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                  AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                              )
                    AND SSBSECT_TERM_CODE = SUPP.TERM
                    AND SSBSECT_CRN       = SUPP.CRN
                    AND SSBSECT_CAMP_CODE = csCampCode
                    AND SSBSECT_SSTS_CODE = csA
                    AND SSBSECT_TERM_CODE = psFiltro1
                  UNION ALL
                 SELECT SSBSECT_CRN                                                            AS dataCode,
                        SSBSECT_CRN||csEsp||SSBSECT_SUBJ_CODE||csEsp||SSBSECT_CRSE_NUMB||csEsp||
                        INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,csAps,csShlAps),csCml,csShlCml)) AS dataDesc
                   FROM SCBCRSE A,
                        SSBSECT SS,
                        SIRASGN
                  WHERE csY                 = SIRASGN_PRIMARY_IND(+)
                    AND SSBSECT_TERM_CODE   = SIRASGN_TERM_CODE(+)
                    AND SSBSECT_CRN         = SIRASGN_CRN(+)
                    AND SSBSECT_SUBJ_CODE   = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB   = SCBCRSE_CRSE_NUMB
                    AND SCBCRSE_EFF_TERM    = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                 FROM SCBCRSE SC
                                                WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                  AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                  AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                              )
                    AND (SSBSECT_SUBJ_CODE,SSBSECT_CRSE_NUMB) IN (SELECT SCBSUPP_SUBJ_CODE,SCBSUPP_CRSE_NUMB
                                                                    FROM SIRNIST,SCBSUPP A
                                                                   WHERE A.SCBSUPP_TOPS_CODE = SIRNIST_TOPS_CODE
                                                                     AND A.SCBSUPP_EFF_TERM  = (SELECT MAX(B.SCBSUPP_EFF_TERM)
                                                                                                  FROM SCBSUPP B
                                                                                                 WHERE B.SCBSUPP_SUBJ_CODE  = A.SCBSUPP_SUBJ_CODE
                                                                                                   AND B.SCBSUPP_CRSE_NUMB  = A.SCBSUPP_CRSE_NUMB
                                                                                                   AND B.SCBSUPP_EFF_TERM  <= SIRNIST_TERM_CODE
                                                                                               )
                                                                     AND SIRNIST_ASTY_CODE   = csMRE
                                                                     AND SIRNIST_NIST_CODE   = csSICC
                                                                     AND SIRNIST_PIDM        = psFiltro2
                                                                     AND SIRNIST_TERM_CODE   = psFiltro1
                                                                 )
                    AND NOT EXISTS (SELECT NULL
                                      FROM SSBOVRR
                                     WHERE SSBOVRR_TERM_CODE = SSBSECT_TERM_CODE
                                       AND SSBOVRR_CRN       = SSBSECT_CRN
                                   )
                    AND SSBSECT_SSTS_CODE   = csA
                    AND SSBSECT_CAMP_CODE   = csCampCode
                    AND SSBSECT_TERM_CODE   = psFiltro1
                  UNION ALL
                 SELECT SSBSECT_CRN                                                            AS dataCode,
                        SSBSECT_CRN||csEsp||SSBSECT_SUBJ_CODE||csEsp||SSBSECT_CRSE_NUMB||csEsp||
                        INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,csAps,csShlAps),csCml,csShlCml)) AS dataDesc
                   FROM SCBCRSE A,
                        SSBSECT SS,
                        SIRASGN
                  WHERE csY                = SIRASGN_PRIMARY_IND(+)
                    AND SSBSECT_TERM_CODE  = SIRASGN_TERM_CODE(+)
                    AND SSBSECT_CRN        = SIRASGN_CRN(+)
                    AND SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB  = SCBCRSE_CRSE_NUMB
                    AND SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                FROM SCBCRSE SC
                                               WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                 AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                 AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                             )
                    AND SCBCRSE_COLL_CODE IN (SELECT SIRNIST_COLL_CODE
                                                FROM SIRNIST
                                               WHERE SIRNIST_NIST_CODE  = csSICC
                                                 AND SIRNIST_ASTY_CODE  = csMRE
                                                 AND SIRNIST_TOPS_CODE IS NULL
                                                 AND SIRNIST_PIDM       = psFiltro2
                                                 AND SIRNIST_TERM_CODE  = psFiltro1
                                             )
                    AND SSBSECT_SSTS_CODE  = csA
                    AND SSBSECT_CAMP_CODE  = csCampCode
                    AND SSBSECT_TERM_CODE  = psFiltro1
                  ORDER BY dataDesc;

      ELSIF psCatalogo = csGvvGsrc THEN
            OPEN cuQry FOR
                 SELECT GVVGSRC_CODE                                    AS dataCode,
                        GVVGSRC_CODE||csEsp||csGui||csEsp||GVVGSRC_DESC AS dataDesc
                   FROM GVVGSRC
                  ORDER BY GVVGSRC_CODE;

      ELSIF psCatalogo = csStvCty2 THEN
            OPEN cuQry FOR
                 SELECT STVCTYP_CODE AS dataCode,
                        STVCTYP_DESC AS dataDesc
                   FROM STVCTYP
                  WHERE (
                            (
                              psFiltro1 IS NULL
                            )
                         OR
                            (
                                  psFiltro1                    = csPromocion
                              AND SUBSTR(STVCTYP_CODE,cn1,cn1) = csJ
                            )
                        )
                  ORDER BY STVCTYP_DESC;

      ELSIF psCatalogo = csSWBSUBJ THEN
            OPEN cuQry FOR
                 SELECT SWBSUBJ_CRN                                                               AS dataCode,
                        SWBSUBJ_CRN||csEsp||csGui||csEsp||
                        BANINST1.FWATITL(SWBSUBJ_SUBJ_CODE, SWBSUBJ_CRSE_NUMB, SWBSUBJ_TERM_CODE) AS dataDesc
                   FROM SWBSUBJ
                  WHERE NOT EXISTS (SELECT NULL
                                      FROM FWRPBLC
                                     WHERE FWRPBLC_CRN       = SWBSUBJ_CRN
                                       AND FWRPBLC_TERM_CODE = SWBSUBJ_TERM_CODE
                                   )
                    AND SWBSUBJ_TERM_CODE = psFiltro1
                  ORDER BY SWBSUBJ_CRN;

    ELSIF psCatalogo = csGURIDEN THEN
            OPEN cuQry FOR
                 SELECT GURIDEN_USER_ID                                    AS dataCode,
                        GURIDEN_USER_ID||csEsp||csGui||csEsp||GURIDEN_DESC AS dataDesc
                   FROM GURIDEN
                  ORDER BY GURIDEN_USER_ID ;


      ELSIF psCatalogo = csSWBMODL THEN
             OPEN cuQry FOR
                  SELECT SWBMODL_CODE       AS datacode,
                         SWBMODL_DESC_SHORT AS dataDesc
                    FROM SWBMODL
                    ORDER BY SWBMODL_CODE;

      ELSIF psCatalogo = csSWBFOHO THEN
            OPEN cuQry FOR
                  SELECT DISTINCT SWBFOHO_PROGRAM                                                             AS datacode,
                                  SWBFOHO_PROGRAM||csEsp||csGui||csEsp||PK_CATALOGO.PROGRAMA(SWBFOHO_PROGRAM) AS dataDesc
                    FROM SWBFOHO
                   WHERE SWBFOHO_MOTIVO_BAJA IS NULL
                     AND SWBFOHO_TIPO_CERT    = psFiltro1
                   ORDER BY datacode;

      ELSIF psCatalogo = csSWBFOH2 THEN
            OPEN cuQry FOR
                 SELECT DISTINCT SWBFOHO_PIDM||cstil||SWBFOHO_FOLIO_CERT                                     AS datacode,
                                 pk_catalogo.nombre(SWBFOHO_PIDM)||csPrnOpen||SWBFOHO_FOLIO_CERT||csPrnClos AS dataDesc
                   FROM SWBFOHO
                  WHERE SWBFOHO_MOTIVO_BAJA IS NULL
                    AND SWBFOHO_TIPO_CERT    = psFiltro1
                    AND SWBFOHO_PROGRAM      = psFiltro2
                  ORDER BY dataDesc;



      ELSIF psCatalogo = csSTVEDLV THEN
            OPEN cuQry FOR
                 SELECT STVEDLV_CODE AS dataCode,
                        STVEDLV_DESC AS dataDesc
                   FROM STVEDLV
                  WHERE (
                            (    psFiltro1     = csLC
                             AND STVEDLV_CODE IN ('BAC', 'BA4', 'BA5', 'BA6')
                            )
                         OR
                            (    psFiltro1    = csMA
                             AND STVEDLV_CODE = 'LIC'
                            )
                         OR
                            (    psFiltro1    = csDR
                             AND STVEDLV_CODE = 'MAE'
                            )
                        );

      ELSIF psCatalogo = csACTAGRD THEN
            OPEN cuQry FOR
                 SELECT SSBSECT_CRN            AS dataCode,
                        SSBSECT_CRN      ||csEsp||
                        SSBSECT_SUBJ_CODE||csEsp||
                        SSBSECT_CRSE_NUMB||csEsp||
                        INITCAP(SCBCRSE_TITLE) AS dataDesc
                   FROM SCBCRSE A,
                        SSBSECT SS
                  WHERE SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB  = SCBCRSE_CRSE_NUMB
                    AND SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                FROM SCBCRSE SC
                                               WHERE SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                                 AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                 AND SC.SCBCRSE_EFF_TERM <= psFiltro1
                                             )
                    AND SSBSECT_CRN       IN (SELECT SIRASGN_CRN
                                                FROM SIRASGN
                                               WHERE SIRASGN_PRIMARY_IND = csY
                                                 AND SIRASGN_PIDM        = psFiltro2
                                                 AND SIRASGN_TERM_CODE   = psFiltro1
                                             )
                    AND               EXISTS (SELECT NULL
                                                FROM SFRSTCR
                                               WHERE SFRSTCR_RSTS_CODE IN (csRE,csRW)
                                                 AND SFRSTCR_CRN        = SSBSECT_CRN
                                                 AND SFRSTCR_TERM_CODE  = psFiltro1
                                             )
                    AND SSBSECT_CAMP_CODE  = csCampCode
                    AND SSBSECT_TERM_CODE  = psFiltro1
                  ORDER BY SSBSECT_SUBJ_CODE,
                           SSBSECT_CRSE_NUMB;

      -- IELQ 26/06/2013
      ELSIF psCatalogo = csSGBUSER THEN
            OPEN cuQry FOR
                 SELECT SGBUSER_TERM_CODE AS dataCode,
                        STVTERM_CODE||csEsp||csGui||csEsp||STVTERM_DESC AS dataDesc
                   FROM SGBUSER US, STVTERM TR
                  WHERE US.SGBUSER_PIDM      = psFiltro1
                    AND US.SGBUSER_TERM_CODE = TR.STVTERM_CODE
               ORDER BY STVTERM_CODE DESC;

      --JMSM 23/10/2013
      ELSIF psCatalogo = csTOPSUSR THEN
            OPEN cuQry FOR
                 SELECT SPRIDEN_ID                                     AS dataCode,
                        RPAD(SPRIDEN_ID,                cn22,csPnt)||
                        SPRIDEN_LAST_NAME||csEsp||SPRIDEN_FIRST_NAME   AS dataDesc
                   FROM SPRIDEN
                  WHERE SPRIDEN_CHANGE_IND IS NULL
                    AND EXISTS (SELECT NULL
                                  FROM SIRNIST
                                 WHERE SIRNIST_NIST_CODE <> csCODO
                                   AND SIRNIST_PIDM = SPRIDEN_PIDM
                                )
                  ORDER BY SPRIDEN_ID;



      -- IELQ 23/10/2013


      ELSE
            OPEN cuQry FOR
                 SELECT csEsp AS dataCode,
                        csEsp AS dataDesc
                   FROM DUAL;
      END IF;

      RETURN cuQry;

  END consulta;

  -- * CREA UN ARRAY PARA MANEJARLO CON AJAX
  --   ARRAY DE LA FORMA: [ ["",""], ["",""], ["",""]]
  PROCEDURE arreglo(psCatalogo VARCHAR2,
                    psFiltro1  VARCHAR2 DEFAULT NULL,
                    psFiltro2  VARCHAR2 DEFAULT NULL,
                    psFiltro3  VARCHAR2 DEFAULT NULL,
                    psFiltro4  VARCHAR2 DEFAULT NULL,
                    psFiltro5  VARCHAR2 DEFAULT NULL
                   ) IS

  TYPE t_Record IS RECORD (rCode VARCHAR2(90),
                           rDesc VARCHAR2(1600)
                          );

  TYPE t_Table IS TABLE OF t_Record INDEX BY BINARY_INTEGER;

  tabDatos t_Table;
  cuCursor t_Cursor;
  vnRow    INTEGER := 1;

  BEGIN
      cuCursor := consulta(psCatalogo, psFiltro1, psFiltro2, psFiltro3, psFiltro4, psFiltro5);

      LOOP
           EXIT WHEN cuCursor%NOTFOUND;
           FETCH cuCursor INTO tabDatos(vnRow).rCode,
                               tabDatos(vnRow).rDesc;
           EXIT WHEN cuCursor%NOTFOUND;

           vnRow := vnRow + cn1;

      END LOOP;
      CLOSE cuCursor;

      --corchete inicial "["
      htp.prn(csCrhOpen);

      FOR vnI IN cn1..(vnRow-cn1) LOOP
          --registro como un arreglo bidimensional
          htp.prn(csCrhOpen||csComilla||tabDatos(vnI).rCode||csComilla||csComa||
                             csComilla||tabDatos(vnI).rDesc||csComilla||
                  csCrhClos||csComa
                 );
      END LOOP;

      --corchete final "]"
      htp.prn(csCrhOpen||csComilla||csComilla||csComa||
                         csComilla||csComilla||
              csCrhClos||csCrhClos
             );
  END arreglo;

  --RETORNA UNA PAGINA HTML
  PROCEDURE pagina(psCatalogo VARCHAR2,
                   psFiltro1  VARCHAR2 DEFAULT NULL,
                   psFiltro2  VARCHAR2 DEFAULT NULL,
                   psFiltro3  VARCHAR2 DEFAULT NULL,
                   psFiltro4  VARCHAR2 DEFAULT NULL,
                   psFiltro5  VARCHAR2 DEFAULT NULL
                  ) IS

  TYPE t_Record IS RECORD (rCode VARCHAR2(500),
                           rDesc VARCHAR2(4000)
                          );

  TYPE t_Table IS TABLE OF t_Record INDEX BY BINARY_INTEGER;

  tabDatos t_Table;
  cuCursor t_Cursor;
  vnRow    INTEGER := 1;
  vnExists INTEGER := 0;

  cgsRenglon CONSTANT VARCHAR2(100) := 'onMouseOver=this.style.background='''||PK_ObjRuaHTML.vgsColorCursor||'''; onMouseOut=this.style.background=''#efefef'';';

  BEGIN

      cuCursor := consulta(psCatalogo, psFiltro1, psFiltro2, psFiltro3, psFiltro4, psFiltro5);

      LOOP
           EXIT WHEN cuCursor%NOTFOUND;
           FETCH cuCursor INTO tabDatos(vnRow).rCode,
                               tabDatos(vnRow).rDesc;
           EXIT WHEN cuCursor%NOTFOUND;

           vnRow := vnRow + cn1;

      END LOOP;
      CLOSE cuCursor;

--      <script type="text/javascript">
--      <!--
--      setTimeout("asignarEventos()",1000);
--      -->
--      </script>


      htp.p(
      '<html><head><title>&nbsp;</title>'||
      '<META http-equiv="Content-Type" content="text/html; charset=ISO-8859-15">'||
      '<META HTTP-EQUIV="Pragma" NAME="Cache-Control" CONTENT="no-cache">'||
      '<META HTTP-EQUIV="Cache-Control" NAME="Cache-Control" CONTENT="no-cache">
      <link rel="stylesheet" href="kwactlg.css" type="text/css">
      '
      );

      IF psCatalogo IN ('SWBPHON','SWBPHO1','SWBPHO2','SWBEGRE') THEN
          htp.p(
          '
          <style type="text/css">
          <!--
          td.selcCour {font-size:10.0pt;  font-family:Courier New, Courier;}
          -->
          </style>
          ');
      END IF;

      htp.p(
      '</head><body bgcolor="#efefef">'||
      '<form name="frmDatos">'||
      '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
      );

      FOR vnI IN cn1..(vnRow-cn1) LOOP
          vnExists := 1;

          htp.p(
          '<tr bgcolor="#efefef" '||cgsRenglon||'>'||
              '<td align="center" width="5%">'
          );

          IF psCatalogo IN ('SWBPHON','SWBPHO1','SWBPHO2','SWBEGRE') THEN
             htp.p('<input type="checkbox" style="width:17pt; height:17pt;" name="psObjec'||vnI||'" value="'||tabDatos(vnI).rCode||'"  onClick="parent.procesoeEnd();" />');
          ELSE
             htp.p('<input type="checkbox" style="width:17pt; height:17pt;" name="psObjec'||vnI||'" value="'||tabDatos(vnI).rCode||'" />');
          END IF;

          htp.p(
          '</td>'||
          '<td width="95%" class="selcCour">'||tabDatos(vnI).rDesc||'</td></tr>'
          );
      END LOOP;

      htp.p(
      '</table>
      </form>

      <script type="text/javascript">
      <!--
      ');

      kwactlg.js();

      htp.p(
      '
      -->
      </script>
      ');


      IF    psCatalogo IN ('SWBPHON','SWBEGRE') AND vnExists = 0 AND psFiltro3 IS NULL THEN
             htp.p('<center><font color="#ff0000" face="Verdana" size="4">');

            IF    psCatalogo = 'SWBPHON' THEN
                  htp.p('Los egresados ya tienen recaudador asigando.');

            ELSIF psCatalogo = 'SWBEGRE' THEN
                  htp.p('Los egresados ya tienen usuario asignado.');

            END IF;

            htp.p('</font></center>');

      ELSIF psCatalogo IN ('SWBPHON','SWBEGRE') AND vnExists = 0 AND psFiltro3 IS NOT NULL THEN
            htp.p(
            '<center><font color="#ff0000" face="Verdana" size="4">No se encontraron datos.</font></center>
            ');
      ELSIF psCatalogo IN ('SWBPHON','SWBEGRE') AND vnExists > 0  THEN
            htp.p(
            '<script type="text/javascript">
            <!--

            parent.objUser.disabled = false;
            -->
            </script>
            ');
      END IF;

      IF    psCatalogo IN ('SWBPHON','SWBPHO1','SWBPHO2','SWBEGRE') THEN
            htp.p(
            '<script type="text/javascript">
            <!--
            parent.procesoTerminado();
            parent.procesoeEnd();
            parent.vgbSelectALL = false;
            -->
            </script>
            ');

      END IF;

      htp.p(
      '
      </body></html>
      '
      );


  EXCEPTION
      WHEN OTHERS THEN
           htp.p(sqlerrm);
  END pagina;

  --LLENA UN OBJETO "SELECT" DE HTML
  PROCEDURE catalogo(psCatalogo VARCHAR2,
                     psFiltro1  VARCHAR2 DEFAULT NULL,
                     psFiltro2  VARCHAR2 DEFAULT NULL,
                     psFiltro3  VARCHAR2 DEFAULT NULL,
                     psFiltro4  VARCHAR2 DEFAULT NULL,
                     psFiltro5  VARCHAR2 DEFAULT NULL
                    ) IS

  BEGIN
      arreglo(psCatalogo, psFiltro1, psFiltro2, psFiltro3, psFiltro4, psFiltro5);
  END catalogo;

  --CREA UN PÁGINA PARA LA SELECCIÓN DE CHECKBOX
  PROCEDURE paginaHTML(psPagina  VARCHAR2,
                       psFiltro1 VARCHAR2 DEFAULT NULL,
                       psFiltro2 VARCHAR2 DEFAULT NULL,
                       psFiltro3 VARCHAR2 DEFAULT NULL,
                       psFiltro4 VARCHAR2 DEFAULT NULL,
                       psFiltro5 VARCHAR2 DEFAULT NULL,
                       psCambio   VARCHAR2 DEFAULT NULL
                      ) IS

  BEGIN
      pagina(psPagina, psFiltro1, psFiltro2, psFiltro3, psFiltro4, psFiltro5);

  END paginaHTML;

  --HOJAS DE ESTILOS PARA EL PROCEDIMINETO "paginaHTML"
  PROCEDURE css IS

  BEGIN
      htp.p('
      body  {margin-left: 0pt; margin-right: 0pt; margin-top: 0pt;margin-bottom: 0pt;}
      table {border-collapse:collapse;border:none;}

      td {color: black;
          font-family: Verdana, Arial Narrow, helvetica, sans-serif;
         }
      th {color: black;
          font-family: Verdana, Arial Narrow, helvetica, sans-serif;
         }

      input.check1 {width:17pt; height:17pt;}
      ');
      --vertical-align: top;
  END css;

  --CÓDIGO JavaScript PARA EL PROCEDIMINETO "paginaHTML"
  PROCEDURE js IS

  BEGIN
      htp.p(
      '
      var objFrmDatos = document.frmDatos;
      var vgnLimite   = 0;

      ');
      --htp.p('var objFrmDatos = document.getElementsByTagName("frmDatos");');

      --getUsuarios
      htp.p(
      'function getUsuarios()
      {
        var vnLength = objFrmDatos.elements.length;
        var vnSelect = 0;

        for(var vnI = 0; vnI < vnLength; vnI++)
        {

               if(objFrmDatos.elements[vnI].checked == true)
               {
                  vnSelect = vnSelect+ 1;
               }

        }

        return (vnLength + " Egresados.&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Seleccionados " + vnSelect + ".");

      } //getUsuarios
      '
      );

       --getEgresados
      htp.p(
      'function getEgresados()
      {
        var vnLength = objFrmDatos.elements.length;

        return vnLength;

      } //getEgresados
      '
      );

      --getSelect
      htp.p(
      'function getSelect() {
         var vsSelect    = "";

         for(var vnI=0; vnI<objFrmDatos.elements.length; vnI++) {
                if(objFrmDatos.elements[vnI].checked == true) {
                vsSelect = vsSelect + objFrmDatos.elements[vnI].value + ",";
             }
            }

         return vsSelect;
      } //getSelect
      '
      );

      --seleccionaALL
      htp.p(
      'function seleccionaALL(psValue) {

         for(var vnI=0; vnI<objFrmDatos.elements.length; vnI++)
         {
           objFrmDatos.elements[vnI].checked = psValue;

         }

          parent.procesoeEnd();

      } //seleccionaALL
      '
      );

      --concatenaEgresados
      htp.p(
      'function concatenaEgresados(pnLimite)
      {
        var vsEgresados = "";
        var vbCiclo     = true;
        var vnI         = 0;

        for(vnI = pnLimite; vnI < objFrmDatos.elements.length; vnI++)
        {
            if(vbCiclo)
            {
               if(objFrmDatos.elements[vnI].checked == true)
               {
                  vsEgresados = vsEgresados + objFrmDatos.elements[vnI].value + "/";

                  if(vsEgresados.length >= 32000)
                  {
                     vgnLimite = vnI + 1;
                     vbCiclo   = false;
                  }
               }
            } //if(vbCiclo)
        }

        if(vbCiclo) {
           vgnLimite = vnI + 1;
        }

        return vsEgresados;

      } //concatenaEgresados'
      );

      --valoresRegistrados
      htp.p(
      'function valoresRegistrados(psValores) {
         var arrValores = new Array();

         eval("arrValores=" + psValores);

         for(var vnI=0; vnI<objFrmDatos.elements.length; vnI++) {
             for(var vnJ=0; vnJ<arrValores.length; vnJ++) {
                 if(objFrmDatos.elements[vnI].value == arrValores[vnJ]) {
                    objFrmDatos.elements[vnI].checked = true;

                    objFrmDatos.elements[vnI].focus();
                 }
             }
            }

         return;
      } //valoresRegistrados
      '
      );

      --disabledObjects
      htp.p(
      'function disabledObjects(pbDisabled) {
         for(var vnI=0; vnI<objFrmDatos.elements.length; vnI++) {
             objFrmDatos.elements[vnI].disabled = pbDisabled;
            }
         return;
      } //disabledObjects
      '
      );

  END js;

END KWACTLG;
/