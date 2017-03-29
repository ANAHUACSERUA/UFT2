DROP PROCEDURE BANINST1.PWRAIMD;

CREATE OR REPLACE PROCEDURE BANINST1.PWRAIMD(psReclDesc VARCHAR2) IS
/*
        Nombre: Reporte de alumnos inscritos con menos de 18 créditos
         Fecha: 02/03/2011
        Modulo: Selección de Cursos
         Autor: MAC

*/

ckNombres    owa_cookie.vc_arr;
ckValores    owa_cookie.vc_arr;
ckCount      INTEGER;
vgsInicoPag  VARCHAR2(10) := NULL; -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
vgsUSR       VARCHAR2(500);

  vnRow      INTEGER                := 0;
  vnExists   INTEGER                := 0;
  vnColumnas INTEGER                := 5;
  tabColumna Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);
  vsPerio    VARCHAR2(20)           := NULL;
  vsUniv     VARCHAR2(20)           := NULL;
  vsProgr    VARCHAR2(20)           := NULL;
  vsFacu     VARCHAR2(20)           := NULL;
  vsSeccion  VARCHAR2(3)            := NULL;
  vsTermCode VARCHAR2(6)            := NULL;

  CURSOR cuReporte(psUniv  VARCHAR2 DEFAULT NULL,
                   psPerio VARCHAR2 DEFAULT NULL,
                   psFacu  VARCHAR2 DEFAULT NULL) IS
         SELECT SFRSTCR_TERM_CODE                        termCode,
                SGBSTDN_CAMP_CODE                        campCode,
                Pk_Catalogo.COLEGIO(SGBSTDN_COLL_CODE_1) collDesc,
                SPRIDEN_ID                               Id,
                F_GET_RUT(SPRIDEN_PIDM)                  RUT,
                Pk_Catalogo.NOMBRE(SPRIDEN_PIDM)         Nombre,
                SUM(NVL(SFRSTCR_CREDIT_HR,0))            Creditos
           FROM SGBSTDN A,
                SPRIDEN,
                SFRSTCR
          WHERE SPRIDEN_PIDM             = A.SGBSTDN_PIDM
            AND SPRIDEN_CHANGE_IND      IS NULL
            AND A.SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                              FROM SGBSTDN B
                                             WHERE B.SGBSTDN_PIDM           = A.SGBSTDN_PIDM
                                               AND B.SGBSTDN_STST_CODE      = 'AS'
                                               AND B.SGBSTDN_TERM_CODE_EFF <= SFRSTCR_TERM_CODE
                                           )
            AND SFRSTCR_PIDM             = SPRIDEN_PIDM
            AND NVL(SFRSTCR_CREDIT_HR,0) > 0
            AND SFRSTCR_RSTS_CODE       IN ('RE','RW')
            AND (SFRSTCR_TERM_CODE   = psPerio OR psPerio IS NULL)
            AND (SGBSTDN_CAMP_CODE   = psUniv  OR psUniv IS NULL)
            AND (SGBSTDN_COLL_CODE_1 = psFacu  OR psFacu  IS NULL)
         HAVING SUM(NVL(SFRSTCR_CREDIT_HR,0)) < 18
          GROUP BY SFRSTCR_TERM_CODE,
                   SGBSTDN_CAMP_CODE,
                   SGBSTDN_COLL_CODE_1,
                   SPRIDEN_PIDM,
                   SPRIDEN_ID
          ORDER BY termCode DESC, collDesc, NOMBRE;

  BEGIN
      /* Check/update the user's web session */
      IF Pk_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

      --son buscadas los valores de las cookies para asignar los valores del filtro del query.
      ckCount := 0;
      owa_cookie.get_all(ckNombres,ckValores,ckCount);

     IF ckCount != 0 THEN
        FOR vnCOKIES IN 1..ckCount LOOP
            IF    ckNOMBRES(vnCOKIES) = 'psUnive' THEN
                  vsUniv := ckValores(vnCOKIES);

            ELSIF ckNOMBRES(vnCOKIES) = 'psPerio' THEN
                  vsPerio  := ckValores(vnCOKIES);

            ELSIF ckNOMBRES(vnCOKIES) = 'psFacu' THEN
                  vsFacu := ckValores(vnCOKIES);

            ELSIF ckNOMBRES(vnCOKIES) = 'cookSeccion' THEN
                  vsSeccion := ckValores(vnCOKIES);

            END IF;
        END LOOP;
     END IF;

     -- las instrucciones determinan el largo de la tabla
     FOR vnI IN 1..vnColumnas LOOP
         tabColumna.EXTEND(vnI);
         tabColumna(vnI) := NULL;
     END LOOP;

     tabColumna(1) := 'Escuela';
     tabColumna(2) := 'ID';
     tabColumna(3) := 'RUT';
     tabColumna(4) := 'Nombre';
     tabColumna(5) := 'Cr&eacute;ditos inscritos';

     FOR regRep IN cuReporte(vsUniv, vsPerio, vsFacu) LOOP
         IF vsTermCode IS NULL OR vsTermCode <> regRep.TermCode OR vnRow = 30 THEN
            Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vgsInicoPag,'1',psSubtitulo=>'Periodo '||regRep.TermCode,psUsuario=>vgsUSR,psSeccion=>vsSeccion,psUniversidad=>regRep.campCode);
            vgsInicoPag := 'SALTO';

            vnRow  := 0;
         END IF;

         htp.p('
         <tr>
         <td valign="top">'||regRep.collDesc||'</td>
         <td valign="top">'||regRep.Id      ||'</td>
         <td valign="top">'||regRep.RUT     ||'</td>
         <td valign="top">'||regRep.Nombre  ||'</td>
         <td valign="top">'||regRep.Creditos||'</td>
         </tr>
         ');

         vsTermCode := regRep.TermCode;
         vnExists := 1;
         vnRow    := vnRow + 1;
     END LOOP;

     IF vnExists = 0 THEN
        htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
     ELSE
        -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
        Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

        -- es omitido el encabezado del reporte pero se agrega el salto de pagina
        Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>vgsUSR, psSeccion=>vsSeccion);
     END IF;

     htp.p('</table></body></html>');

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);

  END PWRAIMD;
/


DROP PUBLIC SYNONYM PWRAIMD;

CREATE PUBLIC SYNONYM PWRAIMD FOR BANINST1.PWRAIMD;


GRANT EXECUTE ON BANINST1.PWRAIMD TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRAIMD TO WWW2_USER;
