CREATE OR REPLACE PROCEDURE BANINST1.PWRASAG (
   psReclDesc    VARCHAR2,
   psCRN         VARCHAR2 DEFAULT NULL,
   psTerm        VARCHAR2 DEFAULT NULL,
   psClave       VARCHAR2 DEFAULT NULL,
   psTitulo      VARCHAR2 DEFAULT NULL,
   psSiu         VARCHAR2 DEFAULT NULL,
   psAccion      VARCHAR2 DEFAULT NULL,
   psSubjCode    VARCHAR2 DEFAULT NULL,
   psCrseNumb    VARCHAR2 DEFAULT NULL)
IS
   /*
    Tarea: Reportar la situación académica general del estudiante
    Modulo: Historia Académica
    Fecha: 31/05/2013.
    Autor: AMC
    
    *************************************************
    cambio :  md-01
    descripcion :   el sql de la función de nousados esta mandando mas de 2 registros.. 
                    se cambia la funcionalidad y se incorpora a un cursor
    autor :   Roman Ruiz
    fecha :   18/jul/2014
    *************************************************
    cambio :  md-02
    descripcion : se quita codigo duro  y se toma max(term_code)
                 -- ver si tambien no es necesaria esta senctencia y dejar libre.   
    autor :   Roman Ruiz
    fecha :   31/jul/2014 
    *******************************  
    cambio :  md-03
    descripcion : SE Elimina la modificacion md-02 para tomar todos los periodos.   
    autor :   Roman Ruiz
    fecha :   31/jul/2014 
    *******************************  
    cambio :  md-04
    descripcion : actualizar materias sin valor   
    autor :   Roman Ruiz
    fecha :   11/ago/2014       
    *******************************
    cambio :  md-05
    descripcion : promedio academico   
                  es la suma de la calificacion de la materias cursadas  entre
                  la cantidad de materias cursadas.
                  y solo tomar las materias donde el ind gpa sea Y
    autor :   Roman Ruiz
    fecha :   21/ago/2014       
    *******************************   
    cambio :  md-06
    descripcion : icono del area
                  dejar en x si las materias estan siendo cursadas..
    autor :   Roman Ruiz
    fecha :   21/ago/2014       
    *******************************  
    cambio :  md-07
    descripcion : hacer corte por area
    autor :   Roman Ruiz
    fecha :   22/ago/2014       
    *******************************       
    ************************************************+
   */

   global_Pidm                SPRIDEN.SPRIDEN_PIDM%TYPE;

   tabColumna                 Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vnExists                   NUMBER (4) := 0;
   vnColumnas                 NUMBER (1) := 8;
   vnElectivo                 NUMBER (1) := 0;
   vnRequest                  NUMBER (4) := NULL;
   vsPidm                     NUMBER (9) := NULL;
   vnMED_POND                 NUMBER (23, 9) := NULL;
   vnCOMPLETOX                NUMBER (23, 9) := NULL;
   vnPromedioArit             NUMBER (6, 4) := NULL;
   vsLevlCode                 VARCHAR2 (2) := NULL;
   vsTermCode                 VARCHAR2 (6) := NULL;
   vsID                       VARCHAR2 (9) := NULL;
   vgsInicoPag                VARCHAR2 (10) := NULL; -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de pagina para impresion
   vgCalificacion             VARCHAR2 (15) := NULL;
   vsCamp                     VARCHAR2 (10) := NULL;
   vsTermCodeNoUsado          VARCHAR2 (10) := NULL;
   vsGradCodeNoUsado          VARCHAR2 (10) := NULL;
   vsGmodCodeNoUsado          VARCHAR2 (10) := NULL;
   vsInd01                    VARCHAR2 (15) := NULL;
   vsInd02                    VARCHAR2 (15) := NULL;
   vsProg                     VARCHAR2 (20) := NULL;
   vsMajor                    VARCHAR2 (40) := NULL;
   vsCREDI_REQ                VARCHAR2 (50) := NULL;
   vsCREDI_OBT                VARCHAR2 (50) := NULL;
   vsPrograma                 VARCHAR2 (70) := NULL;
   vsMajorDesc                VARCHAR2 (70) := NULL;
   vsArea                     VARCHAR2 (100) := NULL;
   vsAreaDesc                 VARCHAR2 (400) := NULL;
   vsCDL                      VARCHAR2 (100) := NULL;
   vsIndirizzo                VARCHAR2 (100) := NULL;
   vsImgCorrecto              VARCHAR2 (100) := NULL;
   vsStstDesc                 VARCHAR2 (100) := NULL;
   vsNombre                   VARCHAR2 (120) := NULL;
   vsMateria2                 VARCHAR2 (500) := NULL;
   vsSudbDesc                 STVSUDB.STVSUDB_DESC%TYPE := NULL;
   vsSudeDesc                 STVSUDE.STVSUDE_DESC%TYPE := NULL;
   vsAstdDesc                 STVASTD.STVASTD_DESC%TYPE := NULL;
   vsCredObtTot               number(9);               --md-04

   csN               CONSTANT VARCHAR2 (1) := 'N';
   csY               CONSTANT VARCHAR2 (1) := 'Y';
   csH               CONSTANT VARCHAR2 (1) := 'H';
   csR               CONSTANT VARCHAR2 (1) := 'R';
   cs0               CONSTANT VARCHAR2 (1) := '0';
   csPunto           CONSTANT VARCHAR2 (1) := '.';
   csEsp             CONSTANT VARCHAR2 (1) := ' ';
   csAst             CONSTANT VARCHAR2 (1) := '*';
   csINGL            CONSTANT VARCHAR2 (4) := 'INGL';
   csAING            CONSTANT VARCHAR2 (4) := 'AING';
   csALIN            CONSTANT VARCHAR2 (4) := 'ALIN';
   csIDIT            CONSTANT VARCHAR2 (4) := 'IDIT';
   csIDIO            CONSTANT VARCHAR2 (4) := 'IDIO';
   csASEM            CONSTANT VARCHAR2 (4) := 'ASEM';
   csSSOSC           CONSTANT VARCHAR2 (4) := 'SSOC';
   csCampCode        CONSTANT VARCHAR2 (6) := f_contexto ();
   csWEBUSER         CONSTANT VARCHAR2 (7) := 'WEBUSER';
   csCursando        CONSTANT VARCHAR2 (8) := 'cursando';
   csSincursar       CONSTANT VARCHAR2 (9) := 'sincursar';
   csAcred           CONSTANT VARCHAR2 (10) := 'acreditado';
   csAcreditado      CONSTANT VARCHAR2 (100)
      := '<img width="13" height="13" border="0" src="/imagenes/acreditado.jpg"/>' ;
   csDesacreditado   CONSTANT VARCHAR2 (100)
      := '<img width="13" height="13" border="0" src="/imagenes/sincursar.jpg"/>' ;
   cn0               CONSTANT INTEGER := 0;
   cn1               CONSTANT INTEGER := 1;
   cn2               CONSTANT INTEGER := 2;
   cn10              CONSTANT INTEGER := 10;
   cn20              CONSTANT INTEGER := 20;
   cn30              CONSTANT INTEGER := 30;
   cn40              CONSTANT INTEGER := 40;
   cn50              CONSTANT INTEGER := 50;
   cn60              CONSTANT INTEGER := 60;
   cn100             CONSTANT INTEGER := 100;
   csCrnInv          constant varchar2(15) := 'FORM_GEN';    --md-04

   --cuDetalle
   CURSOR cuDetalle
   IS
        SELECT NVL((SELECT smrpaap_area_priority
                    FROM  smrpaap a
                    WHERE a.smrpaap_term_code_eff = (SELECT MAX (b.smrpaap_term_code_eff)
                                                     FROM  smrpaap b
                                                     WHERE b.smrpaap_program = vsProg)
                      AND a.smrpaap_area = smrdorq_area
                      AND a.smrpaap_program = vsProg), cn100) AS orden,
               SMRDORQ_AREA AS area,
               DECODE ( SMRDOUS_CRSE_SOURCE,
                                        csR, SMRDOUS_CREDIT_HOURS,
                       DECODE (SMRDORQ_MET_IND, csY, SMRDOUS_CREDIT_HOURS,
                        NVL (
--                        (SELECT a.scbcrse_credit_hr_low
--                           FROM scbcrse a
--                          WHERE a.scbcrse_eff_term =
--                                   (SELECT MAX (b.scbcrse_eff_term)
--                                      FROM scbcrse b
--                                     WHERE b.scbcrse_crse_numb        = a.scbcrse_crse_numb
--                                           AND b.scbcrse_subj_code    = a.scbcrse_subj_code
--                                           AND b.scbcrse_eff_term     <= NVL (SMRDORQ_TERM_CODE_EFF, SMRDOUS_TERM_CODE))
--                                AND a.scbcrse_crse_numb = NVL (SMRDORQ_CRSE_NUMB_LOW, SMRDOUS_CRSE_NUMB)
--                                AND a.scbcrse_subj_code = NVL (SMRDORQ_SUBJ_CODE, SMRDOUS_SUBJ_CODE))
--                                ,
                        (SELECT a.scbcrse_credit_hr_low
                           FROM scbcrse a
                          WHERE a.scbcrse_eff_term = (SELECT MAX (b.scbcrse_eff_term)
                                                      FROM  scbcrse b
                                                      WHERE b.scbcrse_crse_numb        = a.scbcrse_crse_numb
                                                      AND   b.scbcrse_subj_code    = a.scbcrse_subj_code)
                           AND a.scbcrse_crse_numb = NVL (SMRDORQ_CRSE_NUMB_LOW, SMRDOUS_CRSE_NUMB)
                           AND a.scbcrse_subj_code = NVL (SMRDORQ_SUBJ_CODE,SMRDOUS_SUBJ_CODE)
                         ),
                        (SELECT MAX(SCBCRSE_CREDIT_HR_LOW)
                           FROM SCBCRSE
                          WHERE SCBCRSE_SUBJ_CODE||' '||SCBCRSE_CRSE_NUMB IN (SELECT smbarul_key_rule
                                                                              FROM smbarul
                                                                              WHERE smbarul_key_rule = SMRDORQ_RULE
                                                                              AND smbarul_area = SMRDORQ_AREA
                                                                              AND smbarul_term_code_eff = (SELECT MAX (x.smbarul_term_code_eff)
                                                                                                           FROM  smbarul x
                                                                                                           WHERE x.smbarul_key_rule = SMRDORQ_RULE
                                                                                                           AND   x.smbarul_area = SMRDORQ_AREA
                                                                                                           AND   x.smbarul_term_code_eff <= NVL(SMRDORQ_TERM_CODE_EFF, SMRDOUS_TERM_CODE))
                        )
                        )
                        )
                        )
                      ) AS cred,
                 NVL((SELECT MAX (SMRDOUS_GRDE_CODE)
                      FROM  SMRDOUS-- SMRDOCN_GRDE_CODE
                      WHERE SMRDOUS_PIDM = F_GETPIDM(vsID)
                      AND   SMRDOUS_REQUEST_NO = vnRequest
                      --AND SMRDOUS_SUBJ_CODE = SWRSEMF.SMRDORQ_SUBJ_CODE
                      AND   SMRDOUS.SMRDOUS_CRSE_NUMB = SWRSEMF.SMRDOUS_CRSE_NUMB
                      AND   SMRDOUS.SMRDOUS_CRN = SWRSEMF.SMRDOUS_CRN
                      AND   SMRDOUS_PROGRAM = vsProg),
                             (SELECT MAX (SMRDOCN_GRDE_CODE)
                              FROM   SMRDOCN
                              WHERE  SMRDOCN_PIDM = F_GETPIDM(vsID)
                              AND    SMRDOCN_REQUEST_NO = vnRequest
                              --AND SMRDOCN_SUBJ_CODE = SWRSEMF.SMRDORQ_SUBJ_CODE
                              AND   SMRDOCN_CRSE_NUMB = SWRSEMF.SMRDOUS_CRSE_NUMB
                              AND   SMRDOCN_CRN = SWRSEMF.SMRDOUS_CRN
                              AND   SMRDOCN_PROGRAM = vsProg)
                     )  AS grde,
               SMRDOUS_TERM_CODE AS term,
               DECODE (SMRDOUS_CRSE_SOURCE,
                       csR, csCursando,
                       DECODE (SMRDORQ_MET_IND, csY, csAcred, csSincursar)) AS stat,
               SMRDOUS_CRN AS crnn,
               DECODE (SMRDOUS_CRSE_SOURCE, csR, NULL, SMRDOUS_GMOD_CODE)  AS gmod,
               NVL ((SELECT a.scrsyln_long_course_title
                     FROM  scrsyln a
                     WHERE a.scrsyln_term_code_eff = (SELECT MAX (b.scrsyln_term_code_eff)
                                                       FROM  scrsyln b
                                                       WHERE b.scrsyln_term_code_eff <= NVL(SMRDORQ_TERM_CODE_EFF, SMRDOUS_TERM_CODE)
                                                       AND   b.scrsyln_crse_numb = a.scrsyln_crse_numb
                                                       AND   b.scrsyln_subj_code = a.scrsyln_subj_code)
                     AND   a.scrsyln_crse_numb = NVL(SMRDORQ_CRSE_NUMB_LOW, SMRDOUS_CRSE_NUMB)
                     AND   a.scrsyln_subj_code = NVL(SMRDORQ_SUBJ_CODE, SMRDOUS_SUBJ_CODE)),
                  UPPER(NVL(smrdous_title,(SELECT MAX(smbarul_desc)
                                         FROM  smbarul
                                         WHERE smbarul_key_rule = SMRDORQ_RULE
                                         AND   smbarul_area = SMRDORQ_AREA
                                         AND   smbarul_term_code_eff = (SELECT MAX (x.smbarul_term_code_eff)
                                                                        FROM  smbarul x
                                                                        WHERE x.smbarul_key_rule = SMRDORQ_RULE
                                                                        AND   x.smbarul_area = SMRDORQ_AREA
                                                                        AND   x.smbarul_term_code_eff <= NVL(SMRDORQ_TERM_CODE_EFF,SMRDOUS_TERM_CODE)))
                        )))
                  AS titl,
                  (SELECT MAX (REPLACE(SMBARUL_KEY_RULE,' ',''))
                   FROM  smbarul
                   WHERE smbarul_key_rule = SMRDORQ_RULE
                   AND   smbarul_area = SMRDORQ_AREA
                   AND   smbarul_term_code_eff = (SELECT MAX (x.smbarul_term_code_eff)
                                                  FROM smbarul x
                                                  WHERE x.smbarul_key_rule = SMRDORQ_RULE
                                                  AND x.smbarul_area = SMRDORQ_AREA
                                                  AND x.smbarul_term_code_eff <= NVL(SMRDORQ_TERM_CODE_EFF, SMRDOUS_TERM_CODE))) clave,
               (SELECT DECODE (COUNT (cn1), cn0, NULL, csAst)
                FROM  scrrtst a
                WHERE a.scrrtst_term_code_eff = (SELECT MAX (b.scrrtst_term_code_eff)
                                                  FROM  scrrtst b
                                                  WHERE b.scrrtst_crse_numb = a.scrrtst_crse_numb
                                                  AND   b.scrrtst_subj_code = a.scrrtst_subj_code
                                                  AND   b.scrrtst_term_code_eff <= NVL (SMRDORQ_TERM_CODE_EFF, SMRDOUS_TERM_CODE))
                 AND  a.SCRRTST_SEQNO = (SELECT MAX (c.scrrtst_seqno)
                                         FROM  scrrtst c
                                         WHERE c.SCRRTST_CRSE_NUMB_PREQ = a.SCRRTST_CRSE_NUMB_PREQ
                                         AND   c.SCRRTST_SUBJ_CODE_PREQ = a.SCRRTST_SUBJ_CODE_PREQ
                                         AND   c.scrrtst_term_code_eff <= NVL(SMRDORQ_TERM_CODE_EFF, SMRDOUS_TERM_CODE))
                 AND a.scrrtst_crse_numb =  NVL(SMRDORQ_CRSE_NUMB_LOW, SMRDOUS_CRSE_NUMB)
                 AND a.scrrtst_subj_code =  NVL(SMRDORQ_SUBJ_CODE, SMRDOUS_SUBJ_CODE))  AS serc,
               SMRDORQ_RULE AS Regla,
               SMRDOUS_ATTR_CODE AS Atrt,
               NVL (SMRDORQ_TERM_CODE_EFF, SMRDOUS_TERM_CODE) AS termCode,
               NVL (SMRDORQ_CRSE_NUMB_LOW, SMRDOUS_CRSE_NUMB) AS crseCode,
               NVL (SMRDORQ_SUBJ_CODE, SMRDOUS_SUBJ_CODE)     AS subjCode,
               (SELECT LTRIM (RTRIM (SMRACMT_TEXT))
                  FROM SMRACMT
                 WHERE SMRACMT_TERM_CODE_EFF = (SELECT MAX (B.SMRACMT_TERM_CODE_EFF)
                                                FROM  SMRACMT B
                                                WHERE B.SMRACMT_AREA = SMRDORQ_AREA)
                   AND SMRACMT_AREA = SMRDORQ_AREA
                   AND ROWNUM = cn1) AS areaDesc
      FROM SWRSEMF
/*    --   WHERE   SMRDORQ_TERM_CODE_EFF = '201025'    --md-02 START     --md-03 start
      WHERE   SMRDORQ_TERM_CODE_EFF = (SELECT MAX(MF.SMRDORQ_TERM_CODE_EFF)
                                       FROM SWRSEMF MF)       --md-02 end -- md-03 end */
      ORDER BY orden,
               term,
               subjCode,
               crseCode;

   --cuNoCapp
   CURSOR cuNoCapp
   IS
      SELECT (SELECT STVNCRQ_DESC
                FROM STVNCRQ
               WHERE STVNCRQ_CODE = SHRNCRS_NCRQ_CODE)   AS ncrqCode,
             (SELECT STVNCST_DESC
                FROM STVNCST
               WHERE STVNCST_CODE = SHRNCRS_NCST_CODE)   AS ncstCode,
             SHRNCRS_NCST_DATE                           AS ncstDate
        FROM SHRNCRS
       WHERE --(  SHRNCRS_NCRQ_CODE IN (csINGL,csSSOSC,csAING,csALIN,csIDIT,csIDIO,csASEM)
             -- SHRNCRS_NCRQ_CODE IN (NULL, csSSOSC, csAING, csALIN, csIDIT, csIDIO, csASEM)
              --OR SHRNCRS_NCST_CODE IN (NULL, csSSOSC, csAING, csALIN, csIDIT, csIDIO, csASEM))
             --AND
             SHRNCRS_PIDM = vsPidm;

   --cabeceroDet
   FUNCTION cabeceroDet (psArea VARCHAR2, psAreaDesc VARCHAR2)
      RETURN VARCHAR2
   IS
   
     vsIMG          VARCHAR2 (100) := NULL;
     vsColumna      VARCHAR2 (100) := '<th width="8%" bgcolor="#efefef" style="border-left:none;"></th>';
     vsBorderRig    VARCHAR2 (100) := 'style="border-right:none;"';
     vnReqCredits   smbaogn.smbaogn_req_credits_overall%TYPE := NULL;
     vnCredits      smbaogn.smbaogn_req_credits_overall%TYPE := NULL;
   
    -- PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      
     --md-06 start
      update swrsemf set SMRDORQ_MET_IND = csN
      WHERE   smrdorq_area =  psArea
      and SMRDOUS_CREDIT_HOURS >= 0
      and SMRDOUS_GRDE_CODE is null ;
     --md-06 end
   
      
      SELECT CASE
                WHEN COUNT (cn1) > cn0 THEN csDesacreditado
                ELSE csAcreditado
             END
        INTO vsIMG
        FROM swrsemf
       WHERE smrdorq_met_ind <> csY 
       AND smrdorq_area = psArea;

      -- creditos a cumplir
      SELECT smbaogn_req_credits_overall
        INTO vnReqCredits
        FROM smbaogn
       WHERE smbaogn_pidm = vsPidm
         AND smbaogn_request_no = vnRequest
         AND smbaogn_program = vsProg
         AND smbaogn_area = psArea;

      --creditos cumplidos
      SELECT SUM ( DECODE (smrdorq_met_ind,
                           csY, NVL (smrdous_credit_hours, cn0),
                           cn0))
        INTO vnCredits
        FROM swrsemf
       WHERE smrdorq_area = psArea;

      IF vnCredits = 0   THEN
      
         SELECT SUM (NVL (smrdous_credit_hours, cn0))
           INTO vnCredits
           FROM swrsemf
          WHERE smrdorq_area = psArea;
      
      END IF;

      IF psAreaDesc LIKE '%ELECTIVO%' THEN
      
         vnElectivo := 1;
         vsBorderRig := NULL;
         vsColumna := '<th width="8%" bgcolor="#efefef">Atributos </th>';
 
     END IF;

      --||'::'||psArea||'::'
      RETURN    '<tr><th bgcolor="#efefef" align="left" colspan="6">'
             || psAreaDesc
             || '('  || psArea || ')'
             || ' '  || vnCredits || ' de ' || vnReqCredits  || '</th>'
             || '<th bgcolor="#efefef" align="right" >Completo</th>'
             || '<td align="center">'  || vsIMG   || '</td>'
             || '</tr>'
             || '<tr>'
             || '<th width="47%" bgcolor="#efefef" ' || vsBorderRig || '>Requerimientos</th>'
             || vsColumna
             || '<th width="7%" bgcolor="#efefef">Seriaci&oacuten</th>'
             || '<th width="7%" bgcolor="#efefef">Cr&eacuteditos</th>'
             || '<th width="8%" bgcolor="#efefef">Periodo</th>'
             || '<th width="8%" bgcolor="#efefef">Calificaci&oacuten</th>'
             || '<th width="10%" bgcolor="#efefef">Modo de calificaci&oacuten</th>'
             || '<th width="5%" bgcolor="#efefef">Completo</th>'
             || '</tr>';
             
   END cabeceroDet;

   --cabeceroGral
   FUNCTION cabeceroGral
      RETURN VARCHAR2
   IS
   BEGIN
      -- md-04 se intercambia lugres entre vsCREDI_REQ y vsCREDI_OBT
      RETURN    '<tr><td colspan="'
             || vnColumnas
             || '" style="border:solid #ffffff 1.0pt;">'
             || '<table border="0" cellpadding="2" cellspacing="0" bordercolor="#dddddd" bgcolor="#ffffff" width="100%"><tr><td width="90%" valign="top">'
             || '<table border="1" bordercolor="#dddddd" bgcolor="#ffffff" width="100%">'
             || '<tr>'
             || '<th width="15%" align="left" valign="bottom" bgcolor="#efefef">'
             || '      ID:'   || '    </th>'
             || '    <td width="17%">'  ||   vsID  || '    </td>'
             || '<th width="17%" align="left" valign="bottom" bgcolor="#efefef">'
             || '      Status alumno:'  || '    </th>'
             || '    <td width="17%">'  ||   vsStstDesc || '    </td>'
             || '<th width="18%" align="left" valign="bottom" bgcolor="#efefef">'
             || '      Completo:'       || '    </th>'
             || '    <td width="16%" align="center" >'  || vsImgCorrecto || '    </td>'
             || '</tr>'
             || '<tr>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      Rut:' || '    </th>'
             || '    <td>'   || F_GET_RUT(vsID)         || '    </td>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      Carrera:'          || '    </th>'
             || '    <td>'  || vsIndirizzo || '    </td>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      Cr&eacute;ditos Requeridos:'  || '    </th>'
             || '    <td >' ||  vsCREDI_REQ          || '    </td>'
             || '</tr>'
             || '<tr>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      Nombre:' || '    </th>'
             || '    <td>'      ||  vsNombre  || '    </td>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      Promedio ponderado:' || '    </th>'
             || '    <td lign="center" >'   ||  vnMED_POND  || '    </td>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      % de Avance:' || '    </th>'
             || '    <td lign="center" >'  ||  TO_NUMBER(vsSudeDesc, '999') || '   %</td> '
             || '</tr>'
             || '<tr>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      Programa:'  || '    </th>'
             || '    <td >'  ||  vsCDL  || '    </td>'
             || '<th align="left" valign="bottom" bgcolor="#efefef"> '
             || '      Promedio aritmético:' || '    </th>'
             || '    <td lign="center" >' ||   vnPromedioArit  || '    </td>'
             || '<th align="left" valign="bottom" bgcolor="#efefef">'
             || '      Cr&eacute;ditos Obtenidos:'  || '    </th>'
             || '    <td >'  ||  vsCREDI_OBT  || '    </td>'
             || '</tr>'
             || '</table>'
             || '</td><td width="10%">'
             || '<table border="0" cellpadding="0" cellspacing="0" bgcolor="#ffffff" width="5%">'
             || '<tr>'
             || '<td width="20%" align="center" ><img src="ARCHIVO.jpg?pnPidm='
             || vsPidm
             || '" width="100" height="130"></td>'
             || '</tr>'
             || '</table>'
             || '</td></tr></table>'
             || '</td></tr>'
             || '<tr><td colspan="'
             || vnColumnas
             || '" style="border:solid #ffffff 1.0pt;">'
             || '</td></tr>';
   END cabeceroGral;

   --obtiene el maximo valor de ejecución del CAPP
   --getMaxRequest
   PROCEDURE getMaxRequest (pnPidm NUMBER, psPrograma VARCHAR2) IS
   BEGIN
   
      SELECT MAX (smrrqcm_request_no)     
        INTO vnRequest
        FROM smrrqcm
       WHERE smrrqcm_orig_curr_source <> csWEBUSER
         AND smrrqcm_process_ind = csN
         AND smrrqcm_program = psPrograma
         AND smrrqcm_pidm = pnPidm;

      SELECT smrrqcm_term_code_eval    
        INTO vsTermCode
        FROM smrrqcm
       WHERE smrrqcm_request_no = vnRequest
         AND smrrqcm_orig_curr_source <> csWEBUSER
         AND smrrqcm_process_ind = csN
         AND smrrqcm_program = psPrograma
         AND smrrqcm_pidm = pnPidm;
             
   END getMaxRequest;

   --getNombre
   FUNCTION getNombre (psId VARCHAR2)
      RETURN VARCHAR2
   IS
      vsPaso   VARCHAR2 (110) := NULL;
   BEGIN
      
      SELECT REPLACE (spriden_last_name || ' ' || spriden_first_name, '*', ' ')
        INTO vsPaso
        FROM spriden
       WHERE spriden_id = psId 
         AND spriden_change_ind IS NULL;

      RETURN vsPaso;
      
   EXCEPTION
      WHEN NO_DATA_FOUND       THEN
         RETURN NULL;
   END getNombre;

   --getSGBSTDN
   PROCEDURE getSGBSTDN
   IS
      --cuTbl1
       /* md-04 start
      CURSOR cuTbl1
      IS      
         SELECT smbpogn_pidm pidm,
                DECODE (smbpogn_met_ind, 'Y', csAcred, csSincursar)         terminado,
                DECODE (smbpogn_connector_overall,
                        'A', smbpogn_req_credits_overall || ' Créditos ',
                        'O', smbpogn_req_credits_overall || ' Créditos ',
                        'N', smbpogn_req_credits_overall || ' Créditos ')   credi_req,
                DECODE (smbpogn_connector_overall,  
                        'A', smbpogn_act_credits_overall || ' Créditos ',
                        'O', smbpogn_act_credits_overall || ' Créditos ',
                        'N', smbpogn_act_credits_overall || ' Créditos')    credi_obt,
                smbpogn_act_gpa        media_ponderata,
                smbpogn_req_credits_overall - smbpogn_act_credits_overall   completox
               , smbpogn_act_credits_overall CredObtT                        --md-04
           FROM smbpogn, smrrqcm
          WHERE smbpogn_pidm = smrrqcm_pidm
            AND smbpogn_request_no = smrrqcm_request_no
            AND smbpogn_program = vsprog
            AND smbpogn_request_no = vnrequest
            AND smbpogn_pidm = vsPidm;
            */
        
      CURSOR cuTbl1 IS  
             SELECT smbpogn_pidm pidm,
                DECODE (smbpogn_met_ind, 'Y', csAcred, csSincursar)         terminado,
                DECODE (smbpogn_connector_overall,
                        'A', smbpogn_req_credits_overall || ' Créditos ',
                        'O', smbpogn_req_credits_overall || ' Créditos ',
                        'N', smbpogn_req_credits_overall || ' Créditos ')   credi_req,
                DECODE (smbpogn_connector_overall,  
                        'A', SMBPOGN_ACT_CREDITS_I_TRAD || ' Créditos ',
                        'O', SMBPOGN_ACT_CREDITS_I_TRAD || ' Créditos ',
                        'N', SMBPOGN_ACT_CREDITS_I_TRAD || ' Créditos ')   credi_obt,
                smbpogn_act_gpa        media_ponderata,
                smbpogn_req_credits_overall - SMBPOGN_ACT_CREDITS_I_TRAD   completox
               , smbpogn_act_credits_overall CredObtT                        --md-04
           FROM smbpogn, smrrqcm
          WHERE smbpogn_pidm = smrrqcm_pidm
            AND smbpogn_request_no = smrrqcm_request_no
            AND smbpogn_program = vsprog
            AND smbpogn_request_no = vnrequest
            AND smbpogn_pidm = vsPidm;
            
       --md-04 end
            
   BEGIN
      BEGIN
         -- Obtiene los Datos
         SELECT Majr,
                NVL ( (SELECT stvmajr_desc
                         FROM stvmajr
                        WHERE stvmajr_code = Majr), csEsp),
                Prog,
                SUBSTR (Prog, cn1, cn2),
                SUBSTR (Prog, LENGTH (Prog) - cn1, cn2),
                --Prog
                NVL ( (SELECT smrprle_program_desc
                         FROM smrprle
                        WHERE smrprle_program = Prog), csEsp),
                (SELECT stvstst_desc
                   FROM stvstst
                  WHERE stvstst_code = ststCode),
                levlCode
           INTO vsMajor,
                vsMajorDesc,
                vsPrograma,
                vsInd01,
                vsInd02,
                vsCDL,
                vsStstDesc,
                vsLevlCode
           FROM (SELECT MIN (sgbstdn_term_code_eff) AS fecMin,
                        MAX (sgbstdn_term_code_eff) AS fecMax,
                        MAX (sgbstdn_majr_code_1) AS Majr,
                        MAX (sgbstdn_program_1) AS Prog,
                        MAX (sgbstdn_stst_code) AS ststCode,
                        MAX (sgbstdn_levl_code) AS levlCode
                   FROM sgbstdn
                  WHERE sgbstdn_pidm = vsPidm 
                    AND sgbstdn_program_1 = vsProg);
      
      EXCEPTION
         WHEN OTHERS  THEN
            NULL;
      END;

      vsIndirizzo := vsMajorDesc;

      -- Obtiene los datos de la tabla General
      
      vsCredObtTot := 0;     --md-04

      FOR regTbl1 IN cuTbl1  LOOP
      --md-04 start
      --   vsCREDI_REQ := regTbl1.credi_obt;
      --   vsCREDI_OBT := regTbl1.credi_req;
         vsCREDI_REQ := regTbl1.credi_req;
         vsCREDI_OBT := regTbl1.credi_obt;
      --md-04 end
         vnMED_POND  := regTbl1.media_ponderata;
         vnCOMPLETOX := regTbl1.completox;
         vsCredObtTot := vsCredObtTot + regTbl1.CredObtT;     --md-04
      END LOOP;

      -- Asigna el Status del Reporte General
      IF vnCOMPLETOX = 0  THEN
         vsImgCorrecto := csAcreditado;
      ELSE
         vsImgCorrecto := csDesacreditado;
      END IF;

      BEGIN
      
         SELECT NVL ( (SELECT stvsudb_desc
                         FROM stvsudb
                        WHERE stvsudb_code = sgbuser_sudb_code),
                       csEsp),                                -- Nivel de Inglés
                NVL (sgbuser_sude_code, NULL)                    --% de Avance
           INTO vsSudbDesc, vsSudeDesc
           FROM sgbuser
          WHERE sgbuser_term_code = (SELECT MAX (sgbuser_term_code)
                                     FROM  sgbuser
                                     WHERE sgbuser_pidm = vsPidm)
            AND sgbuser_pidm = vsPidm;
                
      EXCEPTION
         WHEN OTHERS   THEN
            NULL;
      END;

      BEGIN
         SELECT (SELECT stvastd_desc
                   FROM stvastd
                  WHERE stvastd_code = shrttrm_astd_code_end_of_term)
           INTO vsAstdDesc
           FROM shrttrm
          WHERE shrttrm_term_code = (SELECT MAX (shrttrm_term_code)
                                     FROM  shrttrm
                                     WHERE shrttrm_astd_code_end_of_term IS NOT NULL
                                     AND   shrttrm_pidm = vsPidm)
            AND shrttrm_pidm = vsPidm;
                
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END getSGBSTDN;

   --getprofesor
   FUNCTION getprofesor
      RETURN VARCHAR2
   IS
      vsNombre   VARCHAR2 (200) := NULL;
   BEGIN
   
      SELECT spriden_id
             || csEsp || spriden_first_name
             || csEsp || spriden_last_name  nombre
        INTO vsNombre
        FROM (SELECT sirasgn_pidm AS pidm
                FROM sirasgn
               WHERE sirasgn_crn = psCrn
                 AND sirasgn_term_code = psTerm
                 AND ROWNUM = cn1) sirasg, spriden
       WHERE sirasg.pidm = spriden_pidm 
       AND spriden_change_ind IS NULL;

      RETURN vsNombre;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END getprofesor;


   --datos del curso
   --muestra la información del curso en la misma pagina del reporte
   --datosCurso
   PROCEDURE datosCurso
   IS
   BEGIN         --UTL_URL.UNESCAPE(,'UTF-8' se cambia el color a azul #0A75A3
      HTP.
       p (
         '
          <table border="0" cellpadding="0" bordercolor="#651612" bgcolor="#B0B0FF" cellspacing="0" width="100%" align="center">
            <tr>
              <td>
               <br/>
               <table border="0" width="100%" cellpadding="2" cellspacing="1" bgcolor="#B0B0FF" bordercolor="#0A75A3" align="center">
                 <tr>
                   <th align="right" colspan="2">
                     <a href="#"; onClick="javascript:CerrarInformacion();">Cerrar</a>
                   </th>
                 </tr>
                 <tr>
                   <th colspan="2">'
                     || psTitulo|| '
                   </th>
                 </tr>
                 <tr>
                   <th width="30%" align="right"><b>NRC:</b></th>
                   <td width="70%" >'|| NVL (psCRN, '')|| '</td>
                 </tr>
                 <tr>
                   <th align="right"><b>Profesor:</b></th>
                   <td>'|| NVL (getprofesor (), '')|| '</td>
                </tr>
                <tr>
                  <th align="right"><b>Clave:</b></th>
                  <td>'|| NVL (psClave, '')|| '</td>
                </tr>
              </table>
              <br/>
            </td>
          </tr>
        </table>');
   END datosCurso;

   --pre requicitos
   --seriacion
   PROCEDURE seriacion
   IS
      --cuSeriacion
      CURSOR cuSeriacion IS
         SELECT (SELECT c.scbcrse_title
                   FROM scbcrse c
                  WHERE c.scbcrse_eff_term = (SELECT MAX (d.scbcrse_eff_term)
                                              FROM  scbcrse d
                                              WHERE d.scbcrse_crse_numb = a.scrrtst_crse_numb_preq
                                              AND   d.scbcrse_subj_code = a.scrrtst_subj_code_preq
                                              AND   d.scbcrse_eff_term <= psTerm)
                    AND c.scbcrse_crse_numb = a.scrrtst_crse_numb_preq
                    AND c.scbcrse_subj_code = a.scrrtst_subj_code_preq) AS crseTitl,
                scrrtst_subj_code_preq AS crseSubj,
                scrrtst_crse_numb_preq AS crseNumb
          FROM scrrtst a
          WHERE a.scrrtst_term_code_eff = (SELECT MAX (b.scrrtst_term_code_eff)
                                           FROM  scrrtst b
                                           WHERE b.scrrtst_crse_numb = psCrseNumb
                                           AND   b.scrrtst_subj_code = psSubjCode
                                           AND   b.scrrtst_term_code_eff <= psTerm)
           AND a.SCRRTST_SEQNO = (SELECT MAX (c.SCRRTST_SEQNO)
                                  FROM scrrtst c
                                  WHERE c.SCRRTST_CRSE_NUMB_PREQ = a.SCRRTST_CRSE_NUMB_PREQ
                                  AND c.SCRRTST_SUBJ_CODE_PREQ = a.SCRRTST_SUBJ_CODE_PREQ
                                  AND c.scrrtst_term_code_eff <= psTerm)
           AND a.scrrtst_crse_numb = psCrseNumb
           AND a.scrrtst_subj_code = psSubjCode;
   
   BEGIN
   null;
      HTP.p ('<table border="0" width="100%" cellpadding="2" cellspacing="1" bgcolor="#B0B0FF" bordercolor="#0A75A3" align="center">
                 <tr>
                   <th align="right">
                     <a href="#"; onClick="javascript:CerrarInformacion();">Cerrar</a>
                   </th>
                 </tr>
                 <tr>
                   <th align="center" colspan="2">'
                     || psTitulo|| '
                   </th>
                 </tr> ');

      FOR regSer IN cuSeriacion
      LOOP
         HTP.P (
             '<tr><td align="center">'|| regSer.crseSubj|| regSer.crseNumb||' &nbsp;&nbsp; &nbsp;&nbsp; '|| regSer.crseTitl|| '</td>
             </tr>');
      END LOOP;

      HTP.p ('</table><br/>');
   END seriacion;

   --código java script
   --js
   PROCEDURE js
   IS
   BEGIN
      HTP.P ('
         <script language="javascript" src="kwaslct.js"></script>
         <script type="text/javascript">
          <!--
            var y1 = 10; // change the # on the left to adjuct the Y co-ordinate
            var vbgActiv = false;

          (document.getElementById) ? dom = true : dom = false;
          ');

      --CerrarInformacion
      HTP.P ('
         function CerrarInformacion() {
           document.all.divDatoMateria.style.visibility="hidden";
          } //CerrarInformacion');

      --procesoTerminado
      HTP.p ('
         function procesoTerminado() {
           parent.closeWindowTime();
         } //procesoTerminado
      ');

      --preRequisitos
      HTP.P ('
         function preRequisitos(psTitulo,psTerm, psSubj, psCrse) {
           //parent.iniciaVentana();

           var vsParametros = "psReclDesc=A" +
                              "&psCRN="      + psTerm    +
                              "&psTerm="     + psTerm   +
                              "&psClave="    + psTerm  +
                              "&psTitulo="   + encodeURIComponent(psTitulo) +
                              "&psSiu="      + "'|| psSiu || '" +
                              "&psAccion=S"+
                              "&psSubjCode="    + psSubj  +
                              "&psCrseNumb="    + psCrse;


           getMensaje("PWRASAG",vsParametros,"divDatoMateria");
           document.all.divDatoMateria.style.visibility="visible";

           if(!vbgActiv) {
             cambiaPosicion();
           }

           vbgActiv = true;

         } //preRequisitos
      ');

      --abrirInformacion
      HTP.
       p ('
        function fLovMate(psCRN, psTerm, psClave, psTitulo) {
           //parent.iniciaVentana()

           var vsParametros = "psReclDesc=A" +
                              "&psCRN="      + psCRN    +
                              "&psTerm="     + psTerm   +
                              "&psClave="    + psClave  +
                              "&psTitulo="   + encodeURIComponent(psTitulo) +
                              "&psSiu="      + "'|| psSiu || '" +"&psAccion=D";



           getMensaje("PWRASAG",vsParametros,"divDatoMateria");
           document.all.divDatoMateria.style.visibility="visible";

           if(!vbgActiv) {
             cambiaPosicion();
           }

           vbgActiv = true;
         } //fLovMate

       //cambiaPosicion
        function cambiaPosicion() {

         if (dom) {
           document.getElementById("divDatoMateria").style.visibility=''visible'';
         }

         if (document.layers) {
           document.layers["divDatoMateria"].visibility=''show'';
         }

         document.getElementById("divDatoMateria").style.left = (document.body.clientWidth/2) -400;

         moverVentana();
       } //cambiaPosicion

       //moverVentana
       function moverVentana() {

         if (dom && !document.all) {
           document.getElementById("divDatoMateria").style.top = window.pageYOffset + (window.innerHeight - (window.innerHeight-y1))
         }

 if (document.layers) {
 document.layers["divDatoMateria"].top = window.pageYOffset + (window.innerHeight - (window.innerHeight-y1))
 }

 if (document.all) {
 document.all["divDatoMateria"].style.top = document.body.scrollTop + (document.body.clientHeight - (document.body.clientHeight-y1));
 }

 window.setTimeout("moverVentana()", 10);
 }

 --></script>
 ');
   END js;

   --Son registrados los cursos usados
   PROCEDURE cursosUsados
   IS
   BEGIN
      INSERT INTO sWrdous (smrdous_pidm,
                           smrdous_request_no,
                           smrdous_compliance_order,
                           smrdous_area,
                           smrdous_caa_seqno,
                           smrdous_group,
                           smrdous_key_rule,
                           smrdous_term_code_eff,
                           smrdous_rul_seqno,
                           smrdous_rule,
                           smrdous_rul_seqno_2,
                           smrdous_program,
                           smrdous_area_priority,
                           smrdous_cnt_in_program_ind,
                           smrdous_cnt_in_area_ind,
                           smrdous_cnt_in_group_ind,
                           smrdous_cnt_in_gpa_ind,
                           smrdous_split_ind,
                           smrdous_crse_source,
                           smrdous_applied_ind,
                           smrdous_activity_date,
                           smrdous_a_crse_reuse_ind,
                           smrdous_a_attr_reuse_ind,
                           smrdous_g_crse_reuse_ind,
                           smrdous_g_attr_reuse_ind,
                           smrdous_potential_used_ind,
                           smrdous_equivalent_ind,
                           smrdous_catalog_ind,
                           smrdous_agam_set,
                           smrdous_agam_subset,
                           smrdous_crn,
                           smrdous_title,
                           smrdous_term_code,
                           smrdous_levl_code,
                           smrdous_subj_code,
                           smrdous_crse_numb,
                           smrdous_grde_code,
                           smrdous_gmod_code,
                           smrdous_credit_hours,
                           smrdous_credit_hours_used,
                           smrdous_camp_code,
                           smrdous_coll_code,
                           smrdous_dept_code,
                           smrdous_attr_code,
                           smrdous_atts_code,
                           smrdous_repeat_course_ind,
                           smrdous_trad_ind,
                           smrdous_tckn_seq_no,
                           smrdous_trit_seq_no,
                           smrdous_tram_seq_no,
                           smrdous_trcr_seq_no,
                           smrdous_trce_seq_no,
                           smrdous_dgmr_seq_no,
                           smrdous_earned_ind,
                           smrdous_cnt_in_area_gpa_ind,
                           smrdous_cnt_in_prog_gpa_ind,
                           smrdous_grde_quality_points,
                           smrdous_compl_credits,
                           smrdous_compl_courses,
                           smrdous_actn_code,
                           smrdous_adj_credits,
                           smrdous_adj_courses,
                           smrdous_adj_source_ind,
                           smrdous_agrl_key_rule,
                           smrdous_agrl_rul_seqno,
                           smrdous_agrl_rule,
                           smrdous_agrl_rul_seqno_2,
                           smrdous_tesc_code,
                           smrdous_test_score,
                           smrdous_concurrency_ind)
         SELECT smrdous_pidm,
                smrdous_request_no,
                smrdous_compliance_order,
                smrdous_area,
                smrdous_caa_seqno,
                smrdous_group,
                smrdous_key_rule,
                smrdous_term_code_eff,
                smrdous_rul_seqno,
                smrdous_rule,
                smrdous_rul_seqno_2,
                smrdous_program,
                smrdous_area_priority,
                smrdous_cnt_in_program_ind,
                smrdous_cnt_in_area_ind,
                smrdous_cnt_in_group_ind,
                smrdous_cnt_in_gpa_ind,
                smrdous_split_ind,
                smrdous_crse_source,
                smrdous_applied_ind,
                smrdous_activity_date,
                smrdous_a_crse_reuse_ind,
                smrdous_a_attr_reuse_ind,
                smrdous_g_crse_reuse_ind,
                smrdous_g_attr_reuse_ind,
                smrdous_potential_used_ind,
                smrdous_equivalent_ind,
                smrdous_catalog_ind,
                smrdous_agam_set,
                smrdous_agam_subset,
                smrdous_crn,
                smrdous_title,
                smrdous_term_code,
                smrdous_levl_code,
                smrdous_subj_code,
                smrdous_crse_numb,
                smrdous_grde_code,
                smrdous_gmod_code,
                smrdous_credit_hours,
                smrdous_credit_hours_used,
                smrdous_camp_code,
                smrdous_coll_code,
                smrdous_dept_code,
                smrdous_attr_code,
                smrdous_atts_code,
                smrdous_repeat_course_ind,
                smrdous_trad_ind,
                smrdous_tckn_seq_no,
                smrdous_trit_seq_no,
                smrdous_tram_seq_no,
                smrdous_trcr_seq_no,
                smrdous_trce_seq_no,
                smrdous_dgmr_seq_no,
                smrdous_earned_ind,
                smrdous_cnt_in_area_gpa_ind,
                smrdous_cnt_in_prog_gpa_ind,
                smrdous_grde_quality_points,
                smrdous_compl_credits,
                smrdous_compl_courses,
                smrdous_actn_code,
                smrdous_adj_credits,
                smrdous_adj_courses,
                smrdous_adj_source_ind,
                smrdous_agrl_key_rule,
                smrdous_agrl_rul_seqno,
                smrdous_agrl_rule,
                smrdous_agrl_rul_seqno_2,
                smrdous_tesc_code,
                smrdous_test_score,
                smrdous_concurrency_ind
           FROM smrdous a
          WHERE smrdous_request_no = vnRequest
            AND smrdous_pidm = vsPidm
            AND smrdous_program = vsProg;

      INSERT INTO sWrdorq (smrdorq_pidm,
                           smrdorq_request_no,
                           smrdorq_area,
                           smrdorq_caa_seqno,
                           smrdorq_group,
                           smrdorq_program,
                           smrdorq_term_code_eff,
                           smrdorq_met_ind,
                           smrdorq_source_ind,
                           smrdorq_addl_level_ind,
                           smrdorq_excl_level_ind,
                           smrdorq_exclusions_ind,
                           smrdorq_transfer_ind,
                           smrdorq_split_course_ind,
                           smrdorq_cnt_in_gpa_ind,
                           smrdorq_activity_date,
                           smrdorq_set,
                           smrdorq_subset,
                           smrdorq_rule,
                           smrdorq_subj_code,
                           smrdorq_crse_numb_low,
                           smrdorq_crse_numb_high,
                           smrdorq_attr_code,
                           smrdorq_atts_code,
                           smrdorq_camp_code,
                           smrdorq_coll_code,
                           smrdorq_dept_code,
                           smrdorq_year_rule,
                           smrdorq_term_code_start,
                           smrdorq_term_code_end,
                           smrdorq_req_credits,
                           smrdorq_connector_req,
                           smrdorq_req_courses,
                           smrdorq_max_credits,
                           smrdorq_connector_max,
                           smrdorq_max_courses,
                           smrdorq_min_cred_crse,
                           smrdorq_max_cred_crse,
                           smrdorq_compl_credits,
                           smrdorq_compl_courses,
                           smrdorq_grde_code_min,
                           smrdorq_max_credits_transfer,
                           smrdorq_connector_transfer,
                           smrdorq_max_courses_transfer,
                           smrdorq_act_credits,
                           smrdorq_act_courses,
                           smrdorq_act_credits_transfer,
                           smrdorq_act_courses_transfer,
                           smrdorq_catalog_ind,
                           smrdorq_actn_code,
                           smrdorq_adj_credits,
                           smrdorq_adj_courses,
                           smrdorq_tesc_code,
                           smrdorq_min_value,
                           smrdorq_max_value,
                           smrdorq_concurrency_ind)
         SELECT smrdorq_pidm,
                smrdorq_request_no,
                smrdorq_area,
                smrdorq_caa_seqno,
                smrdorq_group,
                smrdorq_program,
                smrdorq_term_code_eff,
                smrdorq_met_ind,
                smrdorq_source_ind,
                smrdorq_addl_level_ind,
                smrdorq_excl_level_ind,
                smrdorq_exclusions_ind,
                smrdorq_transfer_ind,
                smrdorq_split_course_ind,
                smrdorq_cnt_in_gpa_ind,
                smrdorq_activity_date,
                smrdorq_set,
                smrdorq_subset,
                smrdorq_rule,
                smrdorq_subj_code,
                smrdorq_crse_numb_low,
                smrdorq_crse_numb_high,
                smrdorq_attr_code,
                smrdorq_atts_code,
                smrdorq_camp_code,
                smrdorq_coll_code,
                smrdorq_dept_code,
                smrdorq_year_rule,
                smrdorq_term_code_start,
                smrdorq_term_code_end,
                smrdorq_req_credits,
                smrdorq_connector_req,
                smrdorq_req_courses,
                smrdorq_max_credits,
                smrdorq_connector_max,
                smrdorq_max_courses,
                smrdorq_min_cred_crse,
                smrdorq_max_cred_crse,
                smrdorq_compl_credits,
                smrdorq_compl_courses,
                smrdorq_grde_code_min,
                smrdorq_max_credits_transfer,
                smrdorq_connector_transfer,
                smrdorq_max_courses_transfer,
                smrdorq_act_credits,
                smrdorq_act_courses,
                smrdorq_act_credits_transfer,
                smrdorq_act_courses_transfer,
                smrdorq_catalog_ind,
                smrdorq_actn_code,
                smrdorq_adj_credits,
                smrdorq_adj_courses,
                smrdorq_tesc_code,
                smrdorq_min_value,
                smrdorq_max_value,
                smrdorq_concurrency_ind
           FROM smrdorq a
          WHERE smrdorq_request_no = vnRequest
            AND smrdorq_pidm = vsPidm
            AND smrdorq_program = vsProg;

      INSERT INTO swrsemf (smrdorq_area,
                           smrdorq_subj_code,
                           smrdorq_crse_numb_low,
                           smrdous_credit_hours,
                           smrdous_grde_code,
                           smrdorq_rule,
                           smrdous_term_code,
                           smrdorq_met_ind,
                           smrdous_crse_source,
                           smrdous_crn,
                           smrdous_gmod_code,
                           smrdous_crse_numb,
                           smrdous_subj_code,
                           smrdorq_term_code_eff,
                           smrdous_attr_code,
                           smrdous_title)
         SELECT smrdorq_area,
                smrdorq_subj_code,
                smrdorq_crse_numb_low,
                smrdous_credit_hours,
                smrdous_grde_code,
                smrdorq_rule,
                smrdous_term_code,
                smrdorq_met_ind,
                smrdous_crse_source,
                smrdous_crn,
                smrdous_gmod_code,
                smrdous_crse_numb,
                smrdous_subj_code,
                smrdorq_term_code_eff,
                smrdous_attr_code,
                smrdous_title
           FROM sWrdorq a, sWrdous
          WHERE smrdorq_request_no = smrdous_request_no(+)
            AND smrdorq_pidm = smrdous_pidm(+)
            AND smrdorq_area = smrdous_area(+)
            AND smrdorq_RULE = smrdous_KEY_RULE(+)
            AND smrdorq_program = vsProg
            AND smrdorq_request_no = vnRequest
            AND smrdorq_pidm = vsPidm
            AND SMRDORQ_ACT_CREDITS = 0
         UNION ALL
         SELECT smrdorq_area,
                smrdorq_subj_code,
                smrdorq_crse_numb_low,
                smrdous_credit_hours,
                smrdous_grde_code,
                smrdorq_rule,
                smrdous_term_code,
                smrdorq_met_ind,
                smrdous_crse_source,
                smrdous_crn,
                smrdous_gmod_code,
                smrdous_crse_numb,
                smrdous_subj_code,
                smrdorq_term_code_eff,
                smrdous_attr_code,
                smrdous_title
           FROM sWrdorq, sWrdous
          WHERE smrdorq_request_no = smrdous_request_no
            AND smrdorq_pidm = smrdous_pidm
            AND smrdorq_area = smrdous_area
            AND smrdorq_program = vsProg
            AND smrdorq_RULE = smrdous_KEY_RULE
            AND smrdorq_request_no = vnRequest
            AND smrdorq_pidm = vsPidm
            AND smrdorq_RULE IS NOT NULL;

      COMMIT;
      
   END cursosUsados;

   -- Cursos no usados
   PROCEDURE cursosNoUsados
   IS
   
     vcSub_Code varchar2(10);
     vcCrse_num varchar2(10);
     vcRegla    varchar2(15);
     
     --md-04 start     
     vcCredObtenidos varchar2(75);
     --viPosicion      number(5);      
     --md-04 end
     vcAprueba       varchar2(1);
     
      CURSOR cuLCnull
      IS
         SELECT l.shrtckl_levl_code AS levlCode,
                g.shrtckg_gmod_code AS gmodCode,
                g.shrtckg_credit_hours AS credHour,
                g.shrtckg_grde_code_final AS grdeCode,
                n.shrtckn_seq_no AS tcknSeqn,
                n.shrtckn_crn AS tcknCrnn,
                n.shrtckn_term_code AS termCode,
                n.shrtckn_pidm AS tcknPidm
           FROM shrtckn n, shrtckg g, shrtckl l
          WHERE g.shrtckg_pidm = n.shrtckn_pidm
            AND g.shrtckg_term_code = n.shrtckn_term_code
            AND g.shrtckg_tckn_seq_no = n.shrtckn_seq_no
            AND g.shrtckg_seq_no = (SELECT MAX (g1.shrtckg_seq_no)
                                    FROM shrtckg g1
                                    WHERE g1.shrtckg_pidm = g.shrtckg_pidm
                                    AND   g1.shrtckg_term_code = g.shrtckg_term_code
                                    AND   g1.shrtckg_tckn_seq_no = g.shrtckg_tckn_seq_no)
            AND l.shrtckl_pidm = n.shrtckn_pidm
            AND l.shrtckl_term_code = n.shrtckn_term_code
            AND l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
            AND n.shrtckn_pidm = vsPidm
            AND ( (n.shrtckn_seq_no, n.shrtckn_crn, n.shrtckn_term_code, n.shrtckn_pidm) IN
                     (SELECT smrdocn_tckn_seq_no, smrdocn_crn, smrdocn_term_code, smrdocn_pidm
                        FROM swrdocn
                       WHERE (smrdocn_levl_code IS NULL
                              OR smrdocn_gmod_code IS NULL
                              OR smrdocn_grde_code IS NULL
                              OR smrdocn_credit_hours IS NULL))
                       OR (EXISTS (SELECT NULL
                                 FROM  swrdocn
                                 WHERE smrdocn_tckn_seq_no = shrtckn_seq_no
                                   AND smrdocn_crn = n.shrtckn_crn
                                   AND smrdocn_term_code = n.shrtckn_term_code
                                   AND smrdocn_pidm = n.shrtckn_pidm
                                   AND smrdocn_grde_code <> g.shrtckg_grde_code_final)));
     -- md-04 start                              
      cursor cur_CursoNull is 
       select * 
       from swrsemf
       where (SMRDOUS_CREDIT_HOURS is null or SMRDOUS_GRDE_CODE is null or SMRDOUS_TERM_CODE is null)
        and SMRDORQ_RULE not in (csCrnInv) ; 
        
       cursor cur_MissGde is
         select b.*  --SMRDOCN_CREDIT_HOURS , SMRDOCN_GRDE_CODE, SMRDOCN_TERM_CODE  , SMRDOUS_CRSE_SOURCE , SMRDOCN_CRN, SMRDOCN_CRSE_TITLE
           FROM smrdocn b
          WHERE b.smrdocn_request_no = vnRequest
            AND b.smrdocn_program = vsProg
            AND b.smrdocn_pidm = vsPidm
            and b.SMRDOCN_SUBJ_CODE =  vcSub_Code
            and b.SMRDOCN_CRSE_NUMB  = vcCrse_num;        
        
     --md-04 end
                                           
     
   BEGIN
      INSERT INTO swrdocn (smrdocn_pidm,
                           smrdocn_request_no,
                           smrdocn_term_code,
                           smrdocn_crn,
                           smrdocn_subj_code,
                           smrdocn_crse_numb,
                           smrdocn_program,
                           smrdocn_activity_date,
                           smrdocn_crse_title,
                           smrdocn_crse_source,
                           smrdocn_levl_code,
                           smrdocn_grde_code,
                           smrdocn_gmod_code,
                           smrdocn_credit_hours,
                           smrdocn_credit_hours_avail,
                           smrdocn_camp_code,
                           smrdocn_coll_code,
                           smrdocn_dept_code,
                           smrdocn_trad_ind,
                           smrdocn_repeat_course_ind,
                           smrdocn_tckn_seq_no,
                           smrdocn_trit_seq_no,
                           smrdocn_tram_seq_no,
                           smrdocn_trcr_seq_no,
                           smrdocn_trce_seq_no,
                           smrdocn_dgmr_seq_no,
                           smrdocn_concurrency_ind)
         SELECT smrdocn_pidm,
                smrdocn_request_no,
                smrdocn_term_code,
                smrdocn_crn,
                smrdocn_subj_code,
                smrdocn_crse_numb,
                smrdocn_program,
                smrdocn_activity_date,
                smrdocn_crse_title,
                smrdocn_crse_source,
                smrdocn_levl_code,
                smrdocn_grde_code,
                smrdocn_gmod_code,
                smrdocn_credit_hours,
                smrdocn_credit_hours_avail,
                smrdocn_camp_code,
                smrdocn_coll_code,
                smrdocn_dept_code,
                smrdocn_trad_ind,
                smrdocn_repeat_course_ind,
                smrdocn_tckn_seq_no,
                smrdocn_trit_seq_no,
                smrdocn_tram_seq_no,
                smrdocn_trcr_seq_no,
                smrdocn_trce_seq_no,
                smrdocn_dgmr_seq_no,
                smrdocn_concurrency_ind
           FROM smrdocn b
          WHERE b.smrdocn_request_no = vnRequest
            AND EXISTS (SELECT NULL
                        FROM   shrtckn
                        WHERE shrtckn_pidm = b.smrdocn_pidm
                        AND   shrtckn_subj_code = b.smrdocn_subj_code
                        AND   shrtckn_crse_numb = b.smrdocn_crse_numb)
                AND NOT EXISTS (SELECT NULL
                                FROM sWrdous
                                WHERE smrdous_subj_code = b.smrdocn_subj_code
                                AND   smrdous_crse_numb = b.smrdocn_crse_numb
                                AND   smrdous_camp_code <> b.smrdocn_camp_code)
                AND b.smrdocn_program = vsProg
                AND b.smrdocn_pidm = vsPidm;

      --actualizando valores nulos
      FOR regLcn IN cuLCnull  LOOP
         UPDATE sWrdocn 
                    SET smrdocn_levl_code = regLcn.levlCode,
                        smrdocn_gmod_code = regLcn.gmodCode,
                        smrdocn_grde_code = regLcn.grdeCode,
                        smrdocn_credit_hours = regLcn.credHour,
                        smrdocn_credit_hours_avail = regLcn.credHour
          WHERE smrdocn_tckn_seq_no = regLcn.tcknSeqn
            AND smrdocn_crn = regLcn.tcknCrnn
            AND smrdocn_term_code = regLcn.termCode
            AND smrdocn_pidm = regLcn.tcknPidm;
         

      END LOOP;
      
      
      -- md-04 start
      --cursos sin calif
      for cursoNulo in cur_CursoNull loop
      
            --  cursoNulo.SMRDORQ_AREA; 
            --  cursoNulo.SMRDORQ_TERM_CODE_EFF;
         vcRegla := cursoNulo.SMRDORQ_RULE;              
         vcSub_Code := substr(vcRegla, 1, instr(vcRegla,' ')-1) ; 
         vcCrse_num := substr(vcRegla, instr(vcRegla,' ')+1) ;
         vcAprueba := csN; 
       
         ---actuliza calificaciones
         for missGrade in cur_MissGde loop  
         
            if (( cursoNulo.SMRDORQ_AREA is null) or (missGrade.SMRDOCN_TRAD_IND is null) ) then  
            
              null;
                        
            else 
                 /*
                  select b.*  --SMRDOCN_CREDIT_HOURS , SMRDOCN_GRDE_CODE, SMRDOCN_TERM_CODE  , SMRDOUS_CRSE_SOURCE , SMRDOCN_CRN, SMRDOCN_CRSE_TITLE
                FROM smrdocn b
               WHERE b.smrdocn_request_no = vnRequest
                 AND b.smrdocn_program = vsProg
                 AND b.smrdocn_pidm = vsPidm
                 and b.SMRDOCN_SUBJ_CODE =  vcSub_Code
                 and b.SMRSHRGRDESHRGRDEDOCN_CRSE_NUMB  = vcCrse_num;  
                 
                  SELECT SHRGRDE_PASSED_IND into vcAprueba
                   from shrtckg, SHRGRDE
                   where shrtckg_PIDM = vsPidm
                   AND shrtckg_TERM_CODE =  missGrade.SMRDOCN_TERM_CODE 
                   and SHRTCKG_TCKN_SEQ_NO = missGrade.SMRDOCN_TCKN_SEQ_NO
                   and SHRGRDE_CODE = SHRTCKG_GRDE_CODE_FINAL
                   and shrgrde_levl_code = 'LI'
                   AND ROWNUM = 1;
                   */
                   
                    SELECT SHRGRDE_PASSED_IND into vcAprueba
                   from shrtckg sh, SHRGRDE
                   where sh.shrtckg_PIDM = vsPidm
                   AND sh.shrtckg_TERM_CODE  =  missGrade.SMRDOCN_TERM_CODE 
                   and sh.SHRTCKG_TCKN_SEQ_NO  = missGrade.SMRDOCN_TCKN_SEQ_NO
                   AND sh.SHRTCKG_SEQ_NO = (select max(shh.SHRTCKG_SEQ_NO)
                                            from shrtckg shh
                                            where shh.shrtckg_PIDM = sh.shrtckg_PIDM
                                            AND shh.shrtckg_TERM_CODE = sh.shrtckg_TERM_CODE
                                            and shh.SHRTCKG_TCKN_SEQ_NO = sh.SHRTCKG_TCKN_SEQ_NO)
                   and SHRGRDE_CODE = SHRTCKG_GRDE_CODE_FINAL
                   and shrgrde_levl_code = 'LI'
                   AND ROWNUM = 1;      
                                     
            
               update swrsemf set SMRDOUS_CREDIT_HOURS =  missGrade.SMRDOCN_CREDIT_HOURS
                      , SMRDOUS_GRDE_CODE     =  missGrade.SMRDOCN_GRDE_CODE
                      , SMRDOUS_TERM_CODE     =  missGrade.SMRDOCN_TERM_CODE 
                      , SMRDORQ_MET_IND       = vcAprueba
                      , SMRDOUS_CRSE_SOURCE   = missGrade.SMRDOCN_CRSE_SOURCE
                      , SMRDOUS_CRN           = missGrade.SMRDOCN_CRN
                      , SMRDOUS_GMOD_CODE     = missGrade.SMRDOCN_GMOD_CODE
                      , SMRDOUS_CRSE_NUMB     = missGrade.SMRDOCN_CRSE_NUMB
                      , SMRDOUS_SUBJ_CODE     = missGrade.SMRDOCN_SUBJ_CODE
                      , SMRDOUS_TITLE         = missGrade.SMRDOCN_CRSE_TITLE
               where SMRDORQ_AREA   = cursoNulo.SMRDORQ_AREA
               and SMRDORQ_TERM_CODE_EFF  = cursoNulo.SMRDORQ_TERM_CODE_EFF
               and SMRDORQ_RULE = vcRegla;
               
               if vcAprueba  = csY then
                               
                   --adicionando el numero de horas de la materia faltante.
                   vsCredObtTot := vsCredObtTot + TO_NUMBER(missGrade.SMRDOCN_CREDIT_HOURS);
                   vcCredObtenidos :=  trim(substr(vsCREDI_OBT, instr(vsCREDI_OBT,csEsp))); 
                   vcCredObtenidos := vsCredObtTot || csEsp || vcCredObtenidos; 
                   vsCREDI_OBT := vcCredObtenidos; 
               
               end If; 
                
             end if; 
                  
         end loop;       
      
      end loop;
           
      -- md-04 end
      
   END cursosNoUsados;

/*   md-01 start
   --información de cursos no usados
   PROCEDURE datosNoUsados (psSubj     VARCHAR2 DEFAULT NULL,
                            psCrse     VARCHAR2 DEFAULT NULL,
                            psRegla    VARCHAR2 DEFAULT NULL,
                            psArea     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN

--    if psArea = 'EN1004' then
--htp.p('psSubj='||psSubj||'<br>');
--htp.p('psCrse='||psCrse||'<br>');
--htp.p('psRegla='||psRegla||'<br>');
--htp.p('psArea='||psArea||'<br>');
--htp.p('vsGradCodeNoUsado='||vsGradCodeNoUsado||'<br>');
--htp.p('vsGmodCodeNoUsado='||vsGmodCodeNoUsado||'<br>');
--htp.p('vsTermCodeNoUsado='||vsTermCodeNoUsado||'<br><br>');
--end if;
      select smrdocn_grde_code, smrdocn_gmod_code, smrdocn_term_code
        into vsGradCodeNoUsado, vsGmodCodeNoUsado, vsTermCodeNoUsado
        from swrdocn
       where (
                 (
                      psSubj||psCrse    is not null
                  and smrdocn_crse_numb  = psCrse
                  and smrdocn_subj_code  = psSubj
                 )
              or (
                      psSubj||psCrse is null
                  and exists (select null
                                from smrarul a
                               where a.smrarul_term_code_eff = (select max (b.smrarul_term_code_eff)
                                                                  from smrarul b
                                                                 where b.smrarul_area     = a.smrarul_area
                                                                   and b.smrarul_key_rule = a.smrarul_key_rule
                                                               )
                                 and smrarul_crse_numb_low   = substr(smrdocn_crse_numb,1,4)
                                 and smrarul_subj_code       = smrdocn_subj_code
                                 and a.smrarul_area          = psArea
                                 and a.smrarul_key_rule      = psRegla
                             )
                 )
             );

   exception
      when no_data_found
      then
         null;
   end datosNoUsados;
*/
           
 PROCEDURE datosNoUsados (psSubj     VARCHAR2 DEFAULT NULL,
                            psCrse     VARCHAR2 DEFAULT NULL,
                            psRegla    VARCHAR2 DEFAULT NULL,
                            psArea     VARCHAR2 DEFAULT NULL)
   IS
   
  CURSOR cuCurNoUsado  IS
  select smrdocn_grde_code, smrdocn_gmod_code, smrdocn_term_code
    from swrdocn
   where ( ( psSubj||psCrse    is not null
             and smrdocn_crse_numb  = psCrse
             and smrdocn_subj_code  = psSubj  )
          or ( psSubj||psCrse is null
               and exists (select null
                           from smrarul a
                           where a.smrarul_term_code_eff = (select max (b.smrarul_term_code_eff)
                                                            from smrarul b
                                                            where b.smrarul_area     = a.smrarul_area
                                                            and b.smrarul_key_rule = a.smrarul_key_rule  )
                           and smrarul_crse_numb_low   = substr(smrdocn_crse_numb,1,4)
                           and smrarul_subj_code       = smrdocn_subj_code
                           and a.smrarul_area          = psArea
                           and a.smrarul_key_rule      = psRegla )
                 )
             )  order by smrdocn_term_code desc;
   
   BEGIN

        vsGradCodeNoUsado := null;
        vsGmodCodeNoUsado := null;
        vsTermCodeNoUsado := null; 
        
        for cur_NoUsado in cuCurNoUsado loop
           vsGradCodeNoUsado := cur_NoUsado.smrdocn_grde_code;
           vsGmodCodeNoUsado := cur_NoUsado.smrdocn_gmod_code;
           vsTermCodeNoUsado := cur_NoUsado.smrdocn_term_code;
           exit; --solo tomando el primer valor segun odenación del prog. 
        END LOOP; 
    
   exception
      when no_data_found   then   null;
   end datosNoUsados;

   --md-01 end
  
   --inserta historia
   --insertHistoria
   PROCEDURE insertHistoria (pnPidm NUMBER, psLevl VARCHAR2)
   IS
   BEGIN
                  
      INSERT INTO swrhiac (swrhiac_pidm,
                           swrhiac_term_code,
                           swrhiac_levl_code,
                           swrhiac_subj,
                           swrhiac_crse,
                           swrhiac_crse_title,
                           swrhiac_grade_mod,
                           swrhiac_calif,
                           swrhiac_quality_points,
                           swrhiac_credit_hours,
                           swrhiac_passed_ind,
                           swrhiac_gpa_ind)
         SELECT swvhiac_pidm,
                swvhiac_term_code,
                swvhiac_levl_code,
                swvhiac_subj,
                swvhiac_crse,
                swvhiac_crse_title,
                swvhiac_grade_mod,
                swvhiac_calif,
                swvhiac_quality_points,
                swvhiac_credit_hours,
                swvhiac_passed_ind,
                swvhiac_gpa_ind
           FROM swvhiac
          WHERE swvhiac_levl_code = psLevl 
            AND swvhiac_pidm = pnPidm;

      COMMIT;

      SELECT TRUNC (SUM (swrhiac_quality_points) / COUNT (cn1), cn2)
        INTO vnPromedioArit
        FROM swrhiac
       WHERE swrhiac_credit_hours > cn0
        -- AND swrhiac_passed_ind = csY       --md-05 para el prom se toman todas las materias cursadas 
         AND swrhiac_pidm = pnPidm
         AND SWRHIAC_GPA_IND = csY ;          --md-05
         
         
   END insertHistoria;

-- ***************************************************************
-- BEGIN PRINCIPAL DEL PROCEDIMIENTO PWRASAG   p_main

BEGIN
   IF psSiu IS NULL THEN
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN 
         RETURN; 
      END IF;
   ELSE
      IF NOT twbkwbis.f_validuser (global_Pidm)   THEN
         RETURN;
      END IF;
   END IF;

   --muestra la información del curso en la misma pagina del reporte
   IF psAccion = 'D'  THEN
      datosCurso;
      RETURN;
   ELSIF psAccion = 'S' THEN
      seriacion;
      RETURN;
   END IF;

   --son buscadas los valores de las cookies para asignar los valores del filtro del query.
   vsCamp := PK_OBJHTML.getValueCookie ('psUnive');
   vsProg := PK_OBJHTML.getValueCookie ('psProg');
   vsID := PK_OBJHTML.getValueCookie ('psExped');
   vsPidm := f_get_pidm (vsID);
   vsNombre := getNombre (vsID);

   IF psSiu IS NOT NULL THEN
      vsCamp := csCampCode;
   END IF;

   --obtiene el maximo valor de ejecución del CAPP
   getMaxRequest (vsPidm, vsProg);

   getSGBSTDN ();

   --Son registrados los cursos usados
   cursosUsados ();

   --Son registrados los cursos NO usados
   cursosNoUsados ();
   
   insertHistoria (vsPidm, vsLevlCode);

   --RETURN;

   FOR regDetalle IN cuDetalle
   LOOP
      IF vnExists = 0  THEN
         PK_sisRepImp.
         P_EncabezadoDeReporte (
                              psReclDesc,
                              vnColumnas,
                              tabColumna,
                              vgsInicoPag,
                              psSubtitulo     =>  vsTermCode || ' ' || pk_catalogo.periodo (vsTermCode),
                              psUsuario       => pk_login.vgsUSR,
                              psUniversidad   => vsCamp,
                              psSinPiePag     => 'A',
                              psSinLogo       => 'A',
                              psTituloSinFr   => 'COLUMNAS',
                              psDetalle       => cabeceroGral ()
                                                || cabeceroDet (regDetalle.area, regDetalle.areaDesc));
            vgsInicoPag := 'SALTO';
      END IF;


      if    vsArea    <> regDetalle.area THEN      --md-07
      --IF vsAreaDesc <> regDetalle.areaDesc THEN  --md-07
         HTP.
          p ( '<tr><td colspan="' || vnColumnas
            || '" style="border-left:solid #ffffff 1.0pt; border-right:solid #ffffff 1.0pt;"></td></tr>'
            || cabeceroDet (regDetalle.area, regDetalle.areaDesc));
      END IF;

      vsImgCorrecto :=
            '<img width="13" height="13" border="0" src="/imagenes/'
         || regDetalle.stat || '.jpg"/>';

      vsGradCodeNoUsado := NULL;
      vsGmodCodeNoUsado := NULL;
      vsTermCodeNoUsado := NULL;

      IF regDetalle.stat = csSincursar THEN
         datosNoUsados (regDetalle.subjCode,
                        regDetalle.crseCode,
                        regDetalle.Regla,
                        regDetalle.Area );

         IF vsTermCodeNoUsado IS NOT NULL THEN
            regDetalle.term := vsTermCodeNoUsado;
         END IF;

         IF vsGradCodeNoUsado IS NOT NULL THEN
            regDetalle.grde := vsGradCodeNoUsado;
         END IF;

         IF vsGmodCodeNoUsado IS NOT NULL THEN
            regDetalle.gmod := vsGmodCodeNoUsado;
         END IF;
      END IF;

      IF vnElectivo > 0 THEN
         HTP.p ('<tr>' || '<td>');
      ELSE
         HTP.p ('<tr>' || '<td style="border-right:none;">');
      END IF;

      IF regDetalle.subjCode||regDetalle.crseCode IS NULL THEN
          HTP.p ('<a href="javascript:fLovMate(' || ''''
             || NVL (regDetalle.crnn || '''', '''''')         || ','''
             || regDetalle.term      || ''','''
             || regDetalle.clave     || ''','''
             || regDetalle.TITL      || ''')">'
             || regDetalle.TITL
             --||regDetalle.TITL||'-'||regDetalle.subjCode||'-'||regDetalle.crseCode||'-'||regDetalle.Regla||'-'||regDetalle.Area
             || '</a></td>');
      ELSE
      HTP.p ('<a href="javascript:fLovMate(' || ''''
             || NVL (regDetalle.crnn || '''', '''''') || ','''
             || regDetalle.term      || ''','''
             || regDetalle.subjCode  || regDetalle.crseCode  || ''','''
             || regDetalle.TITL      || ''')">'
             || regDetalle.TITL
             --||regDetalle.TITL||'-'||regDetalle.subjCode||'-'||regDetalle.crseCode||'-'||regDetalle.Regla||'-'||regDetalle.Area
             || '</a></td>');
      END IF;

      IF vnElectivo > 0  THEN
         HTP.p ('<td align="center">' || regDetalle.Atrt || '</td>');
      ELSE
         HTP.p ('<td align="center" style="border-left:none;"></td>');
      END IF;

      vgCalificacion := null;
      IF regDetalle.stat = csAcred THEN
          vgCalificacion := regDetalle.grde;

      ELSE
          IF   regDetalle.grde <> 'AC' THEN
            vgCalificacion := regDetalle.grde;
          END IF;
          --regDetalle.term := null;
          --regDetalle.gmod := null;
      END IF;

      IF regDetalle.term IS NULL THEN
        regDetalle.cred := '';
      END IF;
      
      -- YA CON LOS VALORES SOLO SE MANDAN A IMPRIMIR
      HTP.p ( '<td align="center">'  || '<a href="javascript:preRequisitos('''
                                                                            || regDetalle.TITL          || ''','''
                                                                            || regDetalle.termCode      || ''','''
                                                                            || regDetalle.subjCode      || ''','''
                                                                            || regDetalle.crseCode      || ''')">'
         || regDetalle.Serc          || '</a></td>'
         || '<td align="center">'    ||  regDetalle.cred   || '</td>'
         || '<td align="center">'    || regDetalle.term   || '</td>'
         || '<td align="center">'    || vgCalificacion    || '</td>'
         || '<td align="center">'    || regDetalle.gmod   || '</td>'
         || '<td align="center">'    || vsImgCorrecto     || '</td>'  || '</tr>');

      vsArea := regDetalle.area;
      vsAreaDesc := regDetalle.areaDesc;
      vnExists := 1;
      
   END LOOP;

   IF vnExists = 0   THEN
      HTP.p ('<tr><th colspan="' || vnColumnas || '"><font color="#ff0000">'
             || PK_sisRepImp.vgsResultado      || '</font></th></tr>');
   ELSE
      HTP.p ('</table><br/>
              <table border="1" cellpadding="0" cellspacing="0" style="border:solid #DDDDDD 1.0pt;" width="47%">
              <tr bgcolor="#efefef">
                  <th colspan="3" style="border:solid #DDDDDD 1.0pt;">REQUISITOS CURRICULARES</td></tr>
              <tr bgcolor="#efefef">
                   <th width="27%" style="border:solid #DDDDDD 1.0pt;"><b>Requisito           </td>
                   <th width="10%" style="border:solid #DDDDDD 1.0pt;"><b>Estado              </td>
                   <th width="10%" style="border:solid #DDDDDD 1.0pt;"><b>Acreditaci&oacuten </td></tr>
              ');

      FOR regNoc IN cuNoCapp LOOP
         HTP.p ('<tr>'
                || '<td align="left"   valign="top" style="border:solid #DDDDDD 1.0pt;" >'
                || regNoc.ncrqcode           || '</td>'
                || '<td align="center" valign="top" style="border:solid #DDDDDD 1.0pt;" >'
                || regNoc.ncstcode           || '</td>'
                || '<td align="center" valign="top" style="border:solid #DDDDDD 1.0pt;" >'
                || regNoc.ncstdate           || '</td>'
                || '</tr>');
      END LOOP;

      HTP.p ('</table>
              <table border="0" cellpadding="0" cellspacing="0" width="50%" >
              <tr><td>
              <div id="divDatoMateria" style="position:absolute;z-index:5;visibility:hidden"></div>
              </td></tr>
              </table>');

      --código java script
      js;

      -- La variable es una bandera que al tener el valor "imprime" no colocara el salto de pagina para impresion
      PK_sisRepImp.vgsSaltoImp := 'Imprime';

      -- Es omitido el encabezado del reporte pero se agrega el salto de pagina
      PK_sisRepImp.P_EncabezadoDeReporte (psReclDesc,
                                          vnColumnas,
                                          tabColumna,
                                          'PIE',
                                          psSinPiePag   => 'A');
   END IF;

   HTP.p ('</body></html>');

 
   DELETE SWRDOUS;

   DELETE SWRDORQ;

   DELETE SWRSEMF;

   DELETE SWRDOCN;

   DELETE SWRHIAC;
   
   
  
   COMMIT;
   
EXCEPTION
   WHEN OTHERS
   THEN
      HTP.P (SQLERRM);
 
      DELETE SWRDOUS;

      DELETE SWRDORQ;

      DELETE SWRSEMF;

      DELETE SWRDOCN;

      DELETE SWRHIAC;
      
      
  
      COMMIT;

END PWRASAG;
/
