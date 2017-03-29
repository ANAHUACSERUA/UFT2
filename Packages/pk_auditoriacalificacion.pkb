DROP PACKAGE BODY BANINST1.PK_AUDITORIACALIFICACION;

CREATE OR REPLACE PACKAGE BODY BANINST1.PK_AuditoriaCalificacion IS

/*
Autor: MAC
Fecha: 20/10/2010
Tarea: Realiza la auditoria de la calificaciones del sistema de calificaciones

*/

ckNombres    owa_cookie.vc_arr;
ckValores    owa_cookie.vc_arr;
ckCount      INTEGER;
vgsInicoPag  VARCHAR2(10) := null;
vgsUSR       VARCHAR2(500);

PROCEDURE P_Auditoria(psReclDesc VARCHAR2) IS

vsId           VARCHAR2(10)  := NULL;
vsName         VARCHAR2(300) := NULL;
vsClassGris    VARCHAR2(20)  := NULL;
vsModificacion VARCHAR2(50)  := NULL;
vsNRC          VARCHAR2(10)  := NULL;
vnExists       INTEGER       := 0;
vnColumnas     INTEGER       := 10;
tabColumna     PK_sisRepImp.tipoTabla := PK_sisRepImp.tipoTabla(1);

vsCamp         VARCHAR2(10)  := NULL;
vsTerm         VARCHAR2(10)  := NULL;
vsColl         VARCHAR2(10)  := NULL;
vnPidm         NUMBER        := NULL;
vsCrnn         VARCHAR2(10)  := NULL;


CURSOR cuReporte(psCamp VARCHAR2,
psTerm VARCHAR2,
				   psColl VARCHAR2,
				   pnPidm NUMBER,
				   psCrnn VARCHAR2 DEFAULT NULL) IS
SELECT SHRMRKA_PIDM                                       Alumno,
		        SPRIDEN_ID                                         Id,
                F_GET_RUT(SPRIDEN_PIDM)                         Rut,
				INITCAP(REPLACE(SPRIDEN_LAST_NAME,'*',' '))||
	            INITCAP(REPLACE(SPRIDEN_FIRST_NAME,'*',' '))       Nombre,
NVL((SELECT SHRGCOM_DESCRIPTION
FROM SHRGCOM
WHERE SHRGCOM_TERM_CODE = SHRMRKA_TERM_CODE
AND SHRGCOM_CRN       = SHRMRKA_CRN
AND SHRGCOM_ID        = SHRMRKA_GCOM_ID),'Criterio eliminado') Criterio,
	    SHRMRKA_AUDIT_SEQ_NO                               Secuencia,
	    (SELECT STVGCHG_DESC
	       FROM STVGCHG
		  WHERE STVGCHG_CODE = SHRMRKA_GCHG_CODE)          MotivoCambio,
	    SHRMRKA_GRDE_CODE                                  Calificacion,
	    SHRMRKA_MARKER                                     Coordinador,
	    SHRMRKA_AUDIT_MESSAGE                              Mensaje,
			    SHRMRKA_GCHG_CODE                                  motivoCode,
			    SHRMRKA_TERM_CODE                                  Term,
				SHRMRKA_CRN                                        Crn,
				SHRMRKA_GCOM_ID                                    Gcom,
				TO_CHAR(SHRMRKA_GCOM_DATE,'DD/MM/YYYY')            fechaOrigen,
				SCBCRSE_SUBJ_CODE                                  Subj,
				SCBCRSE_CRSE_NUMB                                  Crse,
				SCBCRSE_TITLE                                      Titl
FROM SHRMRKA A, SPRIDEN, SCBCRSE B, SSBSECT SS
WHERE SPRIDEN_CHANGE_IND IS NULL
			AND SHRMRKA_PIDM        = SPRIDEN_PIDM
AND SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
AND SCBCRSE_EFF_TERM  = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
FROM SCBCRSE SC
WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB)
			AND SHRMRKA_TERM_CODE = SS.SSBSECT_TERM_CODE
			AND SHRMRKA_CRN		  = SS.SSBSECT_CRN
			AND (SS.SSBSECT_CRN      = psCrnn OR psCrnn IS NULL)
			AND SHRMRKA_MARKER      IS NULL
			AND SCBCRSE_COLL_CODE    = psColl
			AND SS.SSBSECT_TERM_CODE = psTerm
			AND SS.SSBSECT_CAMP_CODE = psCamp
		  UNION ALL
SELECT SHRMRKA_PIDM                                       Alumno,
		        SPRIDEN_ID                                         Id,
                F_GET_RUT(SPRIDEN_PIDM)                         Rut,
				INITCAP(REPLACE(SPRIDEN_LAST_NAME,'*',' '))||
	            INITCAP(REPLACE(SPRIDEN_FIRST_NAME,'*',' '))       Nombre,
NVL((SELECT SHRGCOM_DESCRIPTION
FROM SHRGCOM
WHERE SHRGCOM_TERM_CODE = SHRMRKA_TERM_CODE
AND SHRGCOM_CRN       = SHRMRKA_CRN
AND SHRGCOM_ID        = SHRMRKA_GCOM_ID),'-')  Criterio,
	    SHRMRKA_AUDIT_SEQ_NO                               Secuencia,
	    (SELECT STVGCHG_DESC
	       FROM STVGCHG
		  WHERE STVGCHG_CODE = SHRMRKA_GCHG_CODE)          MotivoCambio,
	    SHRMRKA_GRDE_CODE                                  Calificacion,
	    SHRMRKA_MARKER                                     Coordinador,
	    SHRMRKA_AUDIT_MESSAGE                              Mensaje,
			    SHRMRKA_GCHG_CODE                                  motivoCode,
			    SHRMRKA_TERM_CODE                                  Term,
				SHRMRKA_CRN                                        Crn,
				SHRMRKA_GCOM_ID                                    Gcom,
				TO_CHAR(SHRMRKA_ACTIVITY_DATE,'DD/MM/YYYY')        fechaOrigen,
				SCBCRSE_SUBJ_CODE                                  Subj,
				SCBCRSE_CRSE_NUMB                                  Crse,
				SCBCRSE_TITLE                                      Titl
FROM SHRMRKA A, SPRIDEN, SCBCRSE B, SSBSECT SS
WHERE SPRIDEN_CHANGE_IND IS NULL
			AND SHRMRKA_PIDM        = SPRIDEN_PIDM
AND SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
AND SCBCRSE_EFF_TERM  = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
FROM SCBCRSE SC
WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB)
			AND SHRMRKA_TERM_CODE = SS.SSBSECT_TERM_CODE
			AND SHRMRKA_CRN		  = SS.SSBSECT_CRN
			AND (SS.SSBSECT_CRN      = psCrnn OR psCrnn IS NULL)
			AND SHRMRKA_MARKER       = pnPidm
			AND SCBCRSE_COLL_CODE    = psColl
			AND SS.SSBSECT_TERM_CODE = psTerm
			AND SS.SSBSECT_CAMP_CODE = psCamp
		  ORDER BY Crn, Gcom, Nombre, Secuencia;

BEGIN
IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

--son buscadas los valores de las cookies para asignar los valores del filtro del query.
	  ckCount := 0;
owa_cookie.get_all(ckNombres,ckValores,ckCount);

IF ckCount != 0 THEN
	 FOR vnCOKIES IN 1..ckCount LOOP
	 IF    ckNOMBRES(vnCOKIES) = 'psUnive' THEN
	       vsCamp := ckValores(vnCOKIES);

	 ELSIF ckNOMBRES(vnCOKIES) = 'psPerio' THEN
	       vsTerm := ckValores(vnCOKIES);

	 ELSIF ckNOMBRES(vnCOKIES) = 'psEsclR' THEN
	       vsColl := ckValores(vnCOKIES);

	 ELSIF ckNOMBRES(vnCOKIES) = 'psProfC' THEN
	       vnPidm := ckValores(vnCOKIES);

ELSIF ckNOMBRES(vnCOKIES) = 'psCrnAu' THEN
	       vsCrnn := ckValores(vnCOKIES);

END IF;
END LOOP;
END IF;

-- las instrucciones determinan el largo de la tabla
FOR vnI IN 1..vnColumnas LOOP
	      tabColumna.EXTEND(vnI);
	      tabColumna(vnI) := NULL;
	  END LOOP;

	  tabColumna(1) := 'CRN';
	  tabColumna(2) := 'Nombre de la materia';
	  tabColumna(3) := 'Alumno';
	  tabColumna(4) := 'Criterio';
	  tabColumna(5) := 'Motivo del cambio';
	  tabColumna(6) := 'Calificaci&oacute;n';
	  tabColumna(7) := 'Profesor / Coordinador';
	  tabColumna(8) := 'Operaci&oacute;n';
	  tabColumna(9) := 'Fecha de Registro / Modificaci&oacute;n';

	  FOR regRep IN cuReporte(vsCamp,vsTerm,vsColl,vnPidm,vsCrnn) LOOP

			 IF vsNRC IS NULL OR vsNRC <> regRep.Crn THEN
		        PK_sisRepImp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vgsInicoPag,'1','#cccccc','Periodo '||vsTerm||'<br>'||pk_Catalogo.Colegio(vsColl),vgsUSR, 21, vsCamp);
vgsInicoPag := 'SALTO';
			 END IF;

IF    regRep.motivoCode = 'OE' AND regRep.Mensaje = 'Record Insert' THEN
			       regRep.MotivoCambio := '';
		           vsModificacion      := 'Registro de criterio de evaluaci&oacute;n';

			 ELSIF regRep.Mensaje = 'Record Delete' THEN
		           vsModificacion := 'Criterio de evaluaci&oacute;n eliminado';

			 ELSIF regRep.motivoCode = 'OE' AND regRep.Mensaje = 'Record Update' THEN
		           vsModificacion     := 'Original';

			 ELSIF regRep.motivoCode <> 'OE' AND regRep.Mensaje = 'Record Update' THEN
		           vsModificacion := 'Modificaci&oacute;n';

ELSIF regRep.motivoCode <> 'OE' AND regRep.Mensaje = 'Record Delete' THEN
		           vsModificacion := 'Borrado';

		     ELSE
			       vsModificacion := regRep.Mensaje;
			 END IF;

			 P_IdName(regRep.Coordinador, vsId, vsName);

htp.p('<tr>
<td  width="5%"  valign="top">'||regRep.Crn||'</td>
<td width="15%" valign="top">'||regRep.Subj||' '||regRep.Crse||' '||regRep.Titl||'</td>
<td width="10%" valign="top" '||vsClassGris||'>
	 <table border="0" width="100%" cellpadding="2" cellspacing="0">
		    <tr><td valign="top" width="100%" '||vsClassGris||'>'||regRep.Id||'</td></tr>
			<tr><td valign="top" width="100%" '||vsClassGris||'>'||regRep.Nombre||'</td></tr>
            <tr><td valign="top" width="100%" '||vsClassGris||'>'||regRep.Rut||'</td></tr>
	 </table></td>
<td width="10%" valign="top">'||regRep.Criterio    ||'</td>
<td width="10%" valign="top">'||regRep.MotivoCambio||'</td>
<td width="5%"  valign="top" align="right">'||regRep.Calificacion||'</td>
		     <td width="15%" valign="top">
	 <table border="0" width="100%" cellpadding="2" cellspacing="0">
			<tr><td width="100%" valign="top">'||vsId  ||'</td></tr>
				        <tr><td width="100%" valign="top">'||vsName||'</td></tr>
	 </table></td>
<td width="10%" valign="top">'||vsModificacion    ||'</td>
<td width="20%" valign="top">'||regRep.fechaOrigen||'</td>
</tr>');

			 vnExists := 1;
			 vsNRC    := regRep.Crn;
			 vsId     := NULL;
			 vsName   := NULL;

	  END LOOP;

	  -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
	  PK_sisRepImp.vgsSaltoImp := 'Imprime';

-- es omitido el encabezado del reporte pero se agrega el salto de pagina
PK_sisRepImp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,'PIE','0',psUsuario=>vgsUSR);

	  IF vnExists = 0 THEN
	     htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||PK_sisRepImp.vgsResultado||'</font></th></tr>');
	  END IF;

	  htp.p('</table></body></html>');

END P_Auditoria;

--EL PROCEDIMIENTO RETORNA ID Y NOMBRE DE LA PERSONA
PROCEDURE P_IdName(pnPidm NUMBER,
psId   IN OUT VARCHAR2,
					 psName IN OUT VARCHAR2) IS

BEGIN
SELECT SPRIDEN_ID,
	         INITCAP(REPLACE(SPRIDEN_LAST_NAME,'*',' '))||
	         INITCAP(REPLACE(SPRIDEN_FIRST_NAME,'*',' '))
	    INTO psId,
		     psName
FROM SPRIDEN
WHERE SPRIDEN_PIDM = pnPidm
AND SPRIDEN_CHANGE_IND IS NULL;
EXCEPTION
WHEN OTHERS THEN
	       NULL;
END P_IdName;


END PK_AuditoriaCalificacion;
/


DROP PUBLIC SYNONYM PK_AUDITORIACALIFICACION;

CREATE PUBLIC SYNONYM PK_AUDITORIACALIFICACION FOR BANINST1.PK_AUDITORIACALIFICACION;


GRANT EXECUTE ON BANINST1.PK_AUDITORIACALIFICACION TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_AUDITORIACALIFICACION TO WWW2_USER;
