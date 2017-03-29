CREATE OR REPLACE PROCEDURE BANINST1.PWRANIN(psReclDesc VARCHAR2) IS

/*
        Nombre: Reporte de alumnos Nuevo ingreso sin continuidad de estudios
              CREATE  VIC..
              DATE     12/NOV/2014
        ----

*/

  vnRow                 INTEGER                := 0;
  vnExists              INTEGER                := 0;
  vnColumnas        INTEGER                := 9;
  tabColumna        Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);
  vsid                  VARCHAR2(10)           := NULL;
  vsrut                 VARCHAR2(12)           := NULL;
   vgsInicioPag  VARCHAR2(30) := NULL;         -- bandera que al tener el valor "imprime" no colocará el salto de página para impresión
  vbEnca                BOOLEAN                := TRUE;
  vsEnca                VARCHAR2(1)   := 'N'  ;
   vnRegsPag            PLS_INTEGER := 99999;
   vsnivel              twbcntr.twbcntr_num%type;
   vsperio              sgbstdn.SGBSTDN_TERM_CODE_ADMIT%type;
   vsfacu           varchar2(4);
   csSlh                 varchar2(1)  :=';';


  CURSOR cuReporte(psperio  VARCHAR2, psnivel  varchar2, psfacu  varchar2     ) IS
      select  distinct    SD.SPRIDEN_PIDM                             as pidm,
              SP.SPBPERS_NAME_SUFFIX             as rut,
              SD.SPRIDEN_ID                                  as ids,
              SD.SPRIDEN_LAST_NAME                   as apellido,
              SD.SPRIDEN_FIRST_NAME                  as nombre,
              substr( A.SGBSTDN_TERM_CODE_ADMIT,1,4)    as año_admit,
              SARAPPD_APDC_CODE                           as decision,
              A.SGBSTDN_PROGRAM_1                    as programa,
               SM.SMRPRLE_PROGRAM_DESC         as prog_desc
        FROM   SGBSTDN   A,
                    SPRIDEN    sd,
                    spbpers     sp,
                    SMRPRLE    sm,
                    sarappd     pp,
                    saradap    pd
        WHERE     A.SGBSTDN_PIDM          =   sd.SPRIDEN_PIDM
           and       A.SGBSTDN_PIDM          =   SP.SPBPERS_PIDM
           and       sm.SMRPRLE_PROGRAM   =   A.SGBSTDN_PROGRAM_1
           AND      SARADAP_PIDM = SPBPERS_PIDM
           AND      SARAPPD_PIDM         = SARADAP_PIDM
           AND      SARADAP_APPL_NO   = SARAPPD_APPL_NO
           AND      SARAPPD_TERM_CODE_ENTRY = SARADAP_TERM_CODE_eNTRY
           AND      SARAPPD_APDC_CODE in ( 'CO' , 'CO2', 'IN')   --desición
           AND      FWATYALUFT(SARADAP_PIDM, SARADAP_TERM_CODE_eNTRY) = 'N'   -- esto es la clave de nuevo ingresoo
           and      not exists (select 1 from twbcntr  tb
                       where tb.twbcntr_pidm = SARADAP_PIDM)
                       and        SD.SPRIDEN_CHANGE_IND  is null
         AND ( A.SGBSTDN_COLL_CODE_1 = psFacu  OR psFacu IS NULL)
         and  ( A.SGBSTDN_TERM_CODE_ADMIT = psPerio  OR psPerio is null)
         -- AND  (instr(csSlh||psnivel, csSlh||SARADAP_LEVL_CODE||csSlh) > 0 or   psnivel= csSlh  OR  psnivel is null)
         AND ( SARADAP_LEVL_CODE  = psnivel   OR psnivel is null)
 order by 1            ;

  BEGIN
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      --son buscadas los valores de las cookies para asignar los valores del filtro del query.
      --vsPerio   := pk_ObjHtml.getValueCookie('psPerio');
      vsperio    := pk_ObjHtml.getValueCookie('psPerio');
     vsnivel    := pk_ObjHtml.getValueCookie('psNivel');
     vsfacu    := pk_ObjHtml.getValueCookie('psEscu');


      -- las instrucciones determinan el largo de la tabla
      FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

      tabColumna(1) := 'Periodo Parametro';
      tabColumna(2) := 'ID';
      tabColumna(3) := 'RUT';
      tabColumna(4) := 'Apellidos Paterno*Materno';
      tabColumna(5) := 'Nombre';
      tabColumna(6) := 'Año Ingreso';
      tabColumna(7) := 'Decisión postulación';
      tabColumna(8) := 'Programa';
      tabColumna(9) := 'Descripción Programa';
vnRow := 0;

      FOR regRep IN cuReporte (vsperio,vsnivel,vsfacu) LOOP
       vsid    := regRep.pidm ;

        --Incremento el contador de renglones
        vnRow := vnRow + 1;
        vnExists := 1; --Bandera para indicar que hubo resultados



          IF MOD(vnRow, vnRegsPag) = 1  THEN
            --imprimo el encabezado de reporte
          pk_sisRepImp.p_EncabezadodeReporte(psReclDesc, vnColumnas, tabColumna, vgsInicioPag, '1',
                                                   psSubtitulo   => 'Periodo: &nbsp;'||vsperio||' - '||pk_Catalogo.PERIODO(vsperio)||'<br>'||'Escuela: &nbsp;'||vsfacu||' - '||pk_Catalogo.COLEGIO(vsfacu),
                                                   psUniversidad => 'UFT');

            vgsInicioPag := 'SALTO';
        END IF;



            htp.p('<tr>
         <td valign="top" align="left">' ||vsperio||'</td>
          <td valign="top" align="left">' ||regRep.rut||'</td>
          <td valign="top" align="left">' ||regRep.ids||'</td>
          <td valign="top" align="left">' ||regRep.apellido      ||'</td>
          <td valign="top" align="left">' ||regRep.nombre  ||'</td>
          <td valign="top" align="left">' ||regRep.año_admit||'</td>
          <td valign="top" align="left">' ||regRep.decision||'</td>
          <td valign="top" align="left">' ||regRep.programa||'</td>
          <td valign="top" align="left">' ||regRep.prog_desc||'</td>
          </tr>');


      END LOOP;

     IF vnExists = 0 THEN
         htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||pk_sisRepImp.vgsResultado||'</font></th></tr>');
      ELSE
         -- bandera que al tener el valor "imprime" no colocará el salto de página para impresión:
         pk_sisrepimp.vgsSaltoImp := 'Imprime';

         -- omite el encabezado del reporte pero se agrega el salto de página:
         pk_sisRepImp.p_EncabezadodeReporte(psReclDesc, vnColumnas, tabColumna, 'PIE', '0', psUsuario => pk_login.vgsUsr);
      END IF;

      htp.p('</table><br/></body></html>');

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);

  END PWRANIN;
/

