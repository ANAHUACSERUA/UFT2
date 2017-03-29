DROP PROCEDURE BANINST1.PWCCSXM;

CREATE OR REPLACE PROCEDURE BANINST1.PWCCSXM (psReclDesc VARCHAR2)
IS

  --Esto es autoria de Guillermo Almazan Ibañez, por si alguien pregunta

  --GVH: 2012 06 27, cambie el query con la nueva logica de banderas de estados
  --y se corrigió

   vnRow         INTEGER := 0;
   vnExists      INTEGER := 0;
   vnColumnas    INTEGER := 7;
   vsFecha       twrccas.twrccas_date%type;
   vsCtecs       twrccas.twrccas_num%type;
   tabColumna   Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag   VARCHAR2 (10) := NULL;
CURSOR cuCCSXM (vsFecha in twrccas.twrccas_date%type,
                vsCtecs in twrccas.twrccas_num%type)
  IS
SELECT
	TWRCCAM_CCAS_NUM ccg
	,TO_CHAR (twrccam_date, 'DD/MM/YYYY HH24:MI:SS') fecha_ccg
	,NVL(guriden_desc, TWRCCAM_CCAM_USER) matriculador
	,twrccam_num ccm
	,TO_CHAR (twrccam_date, 'DD/MM/YYYY HH24:MI:SS') fecha_ccm
	,COUNT(TWBDOCU_SEQ_NUM) documentos
	,SUM(TWBDOCU_NOM_AMOUNT) monto
FROM
	TWRCCAM
	,TWRCCMD
	,TWBDOCU
	,TWVPAYM
	,GURIDEN
WHERE
	TWRCCMD_CCAM_USER = TWRCCAM_CCAM_USER
	AND TWRCCMD_CCAM_NUM = TWRCCAM_NUM
	AND TWBDOCU_SEQ_NUM = TWRCCMD_DOCU_SEQ_NUM
	AND TWVPAYM_CODE = TWBDOCU_PAYM_CODE
	AND TWVPAYM_ONLINE_IND = 'Y'
	AND TWVPAYM_USER_VIEWABLE_IND = 'Y'
	AND pk_Matricula.f_GetBanStQ('PAGADO',TWBDOCU_STATUS_IND) = 'Y'
	AND GURIDEN_USER_ID(+) = TWRCCAM_CCAM_USER
	AND (TRUNC (twrccam_date) = vsFecha OR vsFecha IS NULL)
	AND (twrccam_ccas_num = vsCtecs OR vsCtecs IS NULL)
GROUP BY
	TWRCCAM_CCAS_NUM
	,TO_CHAR (twrccam_date, 'DD/MM/YYYY HH24:MI:SS')
	,NVL(guriden_desc, TWRCCAM_CCAM_USER)
	,twrccam_num
	,TO_CHAR (twrccam_date, 'DD/MM/YYYY HH24:MI:SS');

BEGIN

   IF Pk_Login.F_ValidacionDeAcceso (pk_login.vgsUSR)
   THEN
      RETURN;
   END IF;

    /* Parámetros */
    --Se busca el valor de la cookie (parámetro) para asignarlo al filtro del query.
    vsFecha := pk_ObjHtml.getValueCookie ('pdIni');
    vsCtecs := pk_ObjHtml.getValueCookie ('psCont');

  -- Número de columnas de la tabla --
   FOR vnI IN 1 .. vnColumnas
   LOOP
      tabColumna.EXTEND (vnI);
      tabColumna (vnI) := NULL;
   END LOOP;

   /* Encabezado de las columnas */

   tabColumna (1) := 'Corte Caja Sup';
   tabColumna (2) := 'Fecha Corte Caja Sup';
   tabColumna (3) := 'Matriculador';
   tabColumna (4) := 'Corte Caja Mat';
   tabColumna (5) := 'Fecha Corte Caja Mat';
   tabColumna (6) := 'Total de Documentos';
   tabColumna (7) := 'Monto del Corte';

      FOR regRep IN cuCCSXM(vsFecha, vsCtecs) LOOP
          IF 70 = vnRow OR 0 = vnRow THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
             vsInicioPag := 'SALTO';
             vnRow  := 0;
          END IF;

          htp.p(
          '<tr>
          <td valign="top">'||regRep.ccg||'</td>
          <td valign="top">'||regRep.fecha_ccg||'</td>
          <td valign="top">'||regRep.matriculador||'</td>
          <td valign="top">'||regRep.ccm||'</td>
          <td valign="top">'||regRep.fecha_ccm||'</td>
          <td valign="top">'||regRep.documentos||'</td>
          <td valign="top">'||regRep.monto||'</td>');

          vnExists   := 1;
          vnRow      := vnRow + 1;
      END LOOP;

   IF vnExists = 0
   THEN
      HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;

   HTP.p ('</table><br/></body></html>');
EXCEPTION
   WHEN OTHERS
   THEN
      HTP.P (SQLERRM);
END PWCCSXM;
/


DROP PUBLIC SYNONYM PWCCSXM;

CREATE PUBLIC SYNONYM PWCCSXM FOR BANINST1.PWCCSXM;


GRANT EXECUTE ON BANINST1.PWCCSXM TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWCCSXM TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWCCSXM TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWCCSXM TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWCCSXM TO WWW2_USER;
