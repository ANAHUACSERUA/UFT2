DROP PROCEDURE BANINST1.PWRASEA;

CREATE OR REPLACE PROCEDURE BANINST1.PWRASEA(psReclDesc VARCHAR2) IS
/*
         Tarea: Alumnos sin encuesta asignada
                Se busca si un alumno le falta la encuesta del SEPRAD
        Modulo: Evaluación Docente (SEPRAD)
         Fecha: 23/12/2010.
         Autor: GEPC

  Modificación:
*/

  vsEncu VARCHAR2(30)   := NULL;
  vsTerm VARCHAR2(7)    := NULL;
  vsPtrm VARCHAR2(1000) := NULL;
  vnRow  INTEGER        := 0;

  csY    CONSTANT VARCHAR2(1) := 'Y';
  csShl  CONSTANT VARCHAR2(1) := '/';
  csEsp  CONSTANT VARCHAR2(1) := ' ';
  csAS   CONSTANT VARCHAR2(2) := 'AS';
  csCamp CONSTANT VARCHAR2(6) := F_CONTEXTO();
  cn0    CONSTANT NUMBER(1)   := 0;

  CURSOR cuMateria(psEncu VARCHAR2,
                   psTerm VARCHAR2,
                   psPtrm VARCHAR2 DEFAULT NULL
                  ) IS
         SELECT SFRSTCR_TERM_CODE                            AS Term,
                SPRIDEN_PIDM                                 AS idenPidm,
                SPRIDEN_ID                                   AS idenId,
                SPRIDEN_LAST_NAME||csEsp||SPRIDEN_FIRST_NAME AS idenName,
                SGBSTDN_STST_CODE                            AS STST,
                SGBSTDN_LEVL_CODE                            AS LEVL,
                SS.SSBSECT_CRN                               AS Crn,
                SS.SSBSECT_CAMP_CODE                         AS Camp,
                A.SCBCRSE_COLL_CODE                          AS Coll,
                A.SCBCRSE_SUBJ_CODE                          AS Subj,
                A.SCBCRSE_CRSE_NUMB                          AS Crse,
                A.SCBCRSE_TITLE                              AS Titulo,
                SS.SSBSECT_PTRM_CODE                         AS PTRM
           FROM SCBCRSE A,
                SSBSECT SS,
                SFRSTCR,
                SPRIDEN,
                SGBSTDN A
          WHERE SFRSTCR_TERM_CODE        = psTerm
            AND SFRSTCR_RSTS_CODE       IN (SELECT STVRSTS_CODE FROM STVRSTS WHERE STVRSTS_INCL_SECT_ENRL = csY)
            AND SFRSTCR_PIDM             = SPRIDEN_PIDM
            AND SPRIDEN_CHANGE_IND      IS NULL
            AND A.SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                              FROM SGBSTDN B
                                             WHERE B.SGBSTDN_PIDM      = A.SGBSTDN_PIDM
                                               AND B.SGBSTDN_STST_CODE = csAS
                                           )
            AND A.SGBSTDN_STST_CODE      = csAS
            AND SFRSTCR_PIDM             = A.SGBSTDN_PIDM
            AND A.SCBCRSE_SUBJ_CODE      = SS.SSBSECT_SUBJ_CODE
            AND A.SCBCRSE_CRSE_NUMB      = SS.SSBSECT_CRSE_NUMB
            AND A.SCBCRSE_EFF_TERM       = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                              FROM SCBCRSE SC
                                             WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                               AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                               AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                           )
            AND SS.SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
            AND SS.SSBSECT_CRN       = SFRSTCR_CRN
            AND SS.SSBSECT_CAMP_CODE = csCamp
            AND (INSTR(csShl||SS.SSBSECT_PTRM_CODE||csShl,csShl||psPtrm) > cn0 OR psPtrm = csShl OR psPtrm IS NULL)
            AND NOT EXISTS (SELECT NULL
                              FROM SVRESAS
                             WHERE SVRESAS_TERM_CODE = SFRSTCR_TERM_CODE
                               AND SVRESAS_CRN       = SFRSTCR_CRN
                               AND SVRESAS_TSSC_CODE = psEncu
                               AND SVRESAS_PIDM      = SFRSTCR_PIDM
                           )
            AND EXISTS (SELECT NULL
                          FROM SVRESAF
                         WHERE SVRESAF_TERM_CODE = SFRSTCR_TERM_CODE
                           AND SVRESAF_CRN       = SFRSTCR_CRN
                           AND SVRESAF_TSSC_CODE = psEncu
                       )
          ORDER BY A.SCBCRSE_SUBJ_CODE,A.SCBCRSE_CRSE_NUMB,SPRIDEN_LAST_NAME||csEsp||SPRIDEN_FIRST_NAME;

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      vsEncu := pk_objhtml.getValueCookie('psSeprd');
      vsTerm := pk_objhtml.getValueCookie('psSpTCO');
      vsPtrm := NVL(pk_objhtml.getValueCookie('psPtrmP'),'/');

      htp.p('<html><head><title>'||psReclDesc||'</title>');

      -- la aplicación no se guarda en el cache de la maquina.
      pk_ObjHTML.P_NoCache;

      --código css
      pk_ObjHTML.P_CssTabs;

      htp.p('<script language="JavaScript"><!--');
      htp.p('function fImprimeReporte() {
      window.focus()
      print();
      }');
      htp.p('//--></script>
      <script language="javascript" src="kwacnls.js"></script>
      ');

      htp.p('</head><body bgcolor="#ffffff" class="bodyCeroR"><br/>
      <br/>
      <table border="0" cellpadding="2" cellspacing="1" width="100%" bgcolor="#ffffff" bordercolor="#ffffff">
             <tr><td width="10%" rowspan="3" valign="top"><img src="/imagenes/logo_uft.jpg" tabindex="-1" width="110" height="40" border="0"></td>
                 <td width="90%" class="tdTitulo"><b>&nbsp;&nbsp;'||REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(psReclDesc,'~aacute','&aacute'),'~eacute','&eacute'),'~iacute','&iacute'),'~oacute','&oacute'),'~uacute','&uacute')||' '||vsTerm||'</b></td></tr>
             <tr><th align="left">'||vsEncu||' - '||pK_Seprad1.F_Encuesta(vsEncu)||'</th></tr>
             <tr><td>&nbsp;&nbsp;'||pK_Seprad1.F_Fecha||'</td></tr>
             <tr><td colspan="2">&nbsp;</td>
      </table>');

      htp.p('<table border="1" cellpadding="2" cellspacing="1" width="100%" bgcolor="#ffffff" bordercolor="#cccccc">');

      htp.p('
      <tr bgcolor="#efefef">
      <th>'||f_Label(14)||'</th><!--Periodo    -->
      <th>'||f_Label(13)||'</th><!--Expediente -->
      <th>'||f_Label(38)||'</th><!--Nombre     -->
      <th>'||f_Label(82)||'</th><!--RUT        -->
      <th>'||f_Label(71)||'</th><!--Estatus    -->
      <th>'||f_Label(72)||'</th><!--Nivel      -->
      <th>'||f_Label(19)||'</th><!--Crn        -->
      <th>'||f_Label(73)||'</th><!--Campus     -->
      <th>'||f_Label(16)||'</th><!--Escuela    -->
      <th>'||f_Label(44)||'</th><!--Subj       -->
      <th>'||f_Label(45)||'</th><!--Crse       -->
      <th>'||f_Label(46)||'</th><!--Titulo     -->
      <th>'||f_Label(74)||'</th><!--Parte de periodo-->
      </tr>
      ');

      FOR regMat IN cuMateria(vsEncu, vsTerm, vsPtrm) LOOP
          vnRow := 1;

          htp.p('<tr>
          <td>'||regMat.Term  ||'</td>
          <td>'||regMat.idenId    ||'</td>
          <td>'||regMat.idenName  ||'</td>
          <td>'||f_get_rut(regMat.idenPidm)||'</td>
          <td>'||regMat.STST  ||'</td>
          <td>'||regMat.LEVL  ||'</td>
          <td>'||regMat.Crn   ||'</td>
          <td>'||regMat.Camp  ||'</td>
          <td>'||regMat.Coll  ||'</td>
          <td>'||regMat.Subj  ||'</td>
          <td>'||regMat.Crse  ||'</td>
          <td>'||regMat.Titulo||'</td>
          <td>'||regMat.PTRM  ||'</td>
          </tr>
          ');
      END LOOP;

      IF vnRow = 0 THEN
         htp.p('<tr><th colspan="12">Los alumnos ya tienen asignada la encuesta</th></tr>');
      END IF;

      htp.p('</table><br/><br/></body></html>');

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);
  END PWRASEA;
/


DROP PUBLIC SYNONYM PWRASEA;

CREATE PUBLIC SYNONYM PWRASEA FOR BANINST1.PWRASEA;


GRANT EXECUTE ON BANINST1.PWRASEA TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRASEA TO WWW2_USER;
