CREATE OR REPLACE PROCEDURE BANINST1.PWMATCP (psReclDesc VARCHAR2)
IS
/******************************************************************************
PROCEDIMIENTO:          BANINST1.PWMATCO
OBJETIVO:               Reporte de Matriculados CFC
AUTORES:                Guillermo Almazan Iba?ez
FECHA:                  29/04/2011
Modificacion
  28/Marzo/2012         EAMM       Se quitaron columnas de apoderado y se puso
                                   nueva por cambio de carrera
******************************************************************************/
   vnRow         INTEGER := 0;
   vnExists      INTEGER := 0;
   vnColumnas    INTEGER := 20;
   vsProg        smrprle.smrprle_program_desc%TYPE;
   vsSsts        sgbstdn.sgbstdn_stst_code%TYPE;
   vsType        sgbstdn.sgbstdn_styp_code%TYPE;
   vsYear        VARCHAR2(4);
   vdIni         twbcntr.twbcntr_issue_date%TYPE;
   vdFin         twbcntr.twbcntr_issue_date%TYPE;
   vsCont        twbcntr.twbcntr_num%TYPE;
   tabColumna    Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag   VARCHAR2 (10) := NULL;
   vsTermStatus VARCHAR2(8);
   vsStatusCntr VARCHAR2(8);
   vsStatus      sgbstdn.sgbstdn_stst_code%TYPE;
--   vnTest       VARCHAR2(10);
CURSOR cuReporte_Cambio (vsProg in smrprle.smrprle_program_desc%TYPE,
   vsSsts in stvstst.stvstst_code%TYPE,
   vsType in stvstyp.stvstyp_code%TYPE,
   vsYear in VARCHAR2,
   vdIni in twbcntr.twbcntr_issue_date%TYPE,
   vdFin in twbcntr.twbcntr_issue_date%TYPE,
   vsCont in twbcntr.twbcntr_num%TYPE)
  IS
  select anio, contrato, fecha_cntr, monto_cntr, periodo_cntr, tipo_periodo, comm_cntr, id, rut_al, alumno, direccion_al, region_al, comuna_al,
         telefono_al, sexo, coreo_pers, periodo_adm, via, tipo_code, tipo, tipo_alumno, estatus_alumno,
--         actualizacion_estatus,
         program_anterior,
         programa, prog_desc
--    , rut_apoderado, apoderado, direccion_ap, region_ap, comuna_ap, tel_ap_tf, tel_ap_tm, email_pers
  from (select substr(twbcntr_term_code, 1, 4)                                                          anio
       , twbcntr_num                                                                                    contrato
       , twbcntr_status_ind                                                                             status
       , twbcntr_issue_date                                                                             fecha_cntr
       , twbcntr_term_code                                                                              periodo_cntr
       , decode(TWBCNTR_TERM_TYPE, 'A', 'Anual',
                                   '1', 'Primer Semestre',
                                   '2', 'Segundo Semestre',
                                   (select decode(STVTERM_TRMT_CODE, 'A', 'Anual', 'S', 'Semestral')
                                    from STVTERM
                                    where STVTERM_CODE = TWBCNTR_TERM_CODE))                           tipo_periodo
       --, pk_matricula.f_MontoContrato(twbcntr_num)                                                    monto_cntr
       , to_char(pk_matricula.f_MontoContrato(twbcntr_num), pk_contrato.ConstglFormato)                 monto_cntr
       , pk_matricula.f_comecont(twbcntr_num)                                                           comm_cntr
       , f_get_id(twbcntr_pidm)                                                                         id
       , f_get_rut(twbcntr_pidm)                                                                        rut_al
       , f_format_name(twbcntr_pidm, 'LF30')                                                            alumno
       , pk_matricula.f_DirAlumno(twbcntr_pidm)                                                         direccion_al
       , pk_matricula.f_RegAlumno(twbcntr_pidm)                                                         region_al
       , pk_matricula.f_ComuAlumno(twbcntr_pidm)                                                        comuna_al
       , f_get_telefono_al(twbcntr_pidm, 'TFPA')                                                        telefono_al
--       , pk_AdMat.f_get_psu_pond(twbcntr_pidm, twbcntr_term_code)                                       psu
       , f_get_sexo(twbcntr_pidm)                                                                       sexo
       , (
               select
                goremal_email_address
             from
                goremal
            where
                goremal_pidm = twbcntr_pidm
                and goremal_emal_code = 'UFT'
                and rownum = 1
       )                                                                                                coreo_pers
       , sgbstdn_term_code_admit                                                                        periodo_adm
       , pk_catalogo.admision(sgbstdn_admt_code)                                                        via
       , sgbstdn_admt_code                                                                              via_code
       , fwatyaluft(twbcntr_pidm, twbcntr_term_code)                                                    tipo_code
       , decode(fwatyaluft(twbcntr_pidm, twbcntr_term_code),'N','Nuevo Ingreso','A','Avanzado')         tipo
       , pk_catalogo.TipoAlumno(sgbstdn_styp_code)                                                      tipo_alumno
       , f_student_get_desc('stvstst', sgbstdn_stst_code, 30)                                           estatus_alumno
--       , f_get_status(twbcntr_pidm, sgbstdn_stst_code)                                                  actualizacion_estatus
       , F_GET_PROGRAMA_ANT(TWBCNTR_PIDM, TWBCNTR_TERM_CODE, TWBCNTR_ORI_PROGRAM)                       program_anterior
       , TWBCNTR_ORI_PROGRAM                                                                            programa
       , pk_catalogo.programa(TWBCNTR_ORI_PROGRAM)                                                      prog_desc
--       , twbcntr_rut                                                                                    rut_apoderado
--       ,  pk_MatApoderado.f_NombreCompleto(twbcntr_rut)                                                 apoderado
--       , pk_MatApoderado.f_Direccion(twbcntr_rut, twbcntr_term_code)                                    direccion_ap
--       , pk_MatApoderado.f_Region(twbcntr_rut, twbcntr_term_code)                                       region_ap
--       , pk_MatApoderado.f_Comuna(twbcntr_rut, twbcntr_term_code)                                       comuna_ap
--       , pk_MatApoderado.f_Telefono(twbcntr_rut, 'PR', twbcntr_term_code)                               tel_ap_tf
--       , pk_MatApoderado.f_Telefono(twbcntr_rut, 'TMSO', twbcntr_term_code)                             tel_ap_tm
--       , pk_MatApoderado.f_Email(twbcntr_rut, 'PERS', twbcntr_term_code)                                email_pers
from   twbcntr
     , sgbstdn g1
--     , swbfolk sw
where g1.sgbstdn_pidm = twbcntr_pidm
  and g1.sgbstdn_term_code_eff =
                    (select max(g2.sgbstdn_term_code_eff)
                       from sgbstdn g2
                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
--  and sw.swbfolk_pidm = twbcntr_pidm
--  and sw.swbfolk_term_code = twbcntr_term_code
--  and sw.swbfolk_rut = twbcntr_rut
  and twbcntr_status_ind = 'A'
  and TWBCNTR_TYPE_CODE ='CFC'
  and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num)
  and (sgbstdn_stst_code = vsSsts or vsSsts is null)
  and (sgbstdn_styp_code = vsType or vsType is null))
where (programa = vsProg or vsProg is null)

and (periodo_cntr like (vsYear||'%') or vsYear is null)
and (fecha_cntr between vdIni and vdFin or vdFin is null or vdIni is null)
and (contrato = vsCont or vsCont is null);

BEGIN

    IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

    /* Par?metros */
    --Se busca el valor de la cookie (par?metro) para asignarlo al filtro del query.
    vsProg  := pk_ObjHtml.getValueCookie ('psProgr');
    vsSsts  := pk_ObjHtml.getValueCookie ('psSstst');
    vsType  := pk_ObjHtml.getValueCookie ('psTyAl');
    vsYear := pk_ObjHtml.getValueCookie ('psYear');
    vdIni   := pk_ObjHtml.getValueCookie ('pdIni');
    vdFin   := pk_ObjHtml.getValueCookie ('pdFin');
    vsCont  := pk_ObjHtml.getValueCookie ('psCont');

  -- N?mero de columnas de la tabla --
   tabColumna.EXTEND (vnColumnas);

   /* Encabezado de las columnas */
   tabColumna (1) := 'A?o';
   tabColumna (2) := 'Id';
   tabColumna (3) := 'RUT';
   tabColumna (4) := 'Alumno';
   tabColumna (5) := 'Direcci&oacute;n';
   tabColumna (6) := 'Regi&oacute;n';
   tabColumna (7) := 'Comuna';
   tabColumna (8) := 'Tel&eacute;fono';
--   tabColumna (9) := 'Promedio PSU';
   tabColumna (9) := 'Sexo';
   tabColumna (10) := 'E-mail';
   tabColumna (11) := 'Periodo Ingreso';
   tabColumna (12) := 'Periodo Matricula';
   tabColumna (13) := 'Tipo Periodo';
   tabColumna (14) := 'Estatus del Alumno<br>al hacer contrato';
   tabColumna (15) := 'Estatus del Alumno<br>actual';
   tabColumna (16) := 'Periodo Estatus del<br>alumno actual ';
   tabColumna (17) := 'Tipo de Alumno';
--   tabColumna (16) := 'Actualizaci?n Status Alumno ';
   tabColumna (18) := 'Programa Anterior';
   tabColumna (19) := 'Programa';
   tabColumna (20) := 'Descripci&oacute;n Programa';
--   tabColumna (19) := 'Rut Apoderado';
--   tabColumna (20) := 'Apoderado';
--   tabColumna (21) := 'Direcci?n';
--   tabColumna (22) := 'Regi?n';
--   tabColumna (23) := 'Comuna';
--   tabColumna (24) := 'Tel?fono Personal';
--   tabColumna (25) := 'Tel?fono Movil';
--   tabColumna (26) := 'E-mail Personal';


      FOR regRep IN cuReporte_Cambio(vsProg, vsSsts, vsType, vsYear, vdIni, vdFin, vsCont) LOOP
          IF vnRow = 0 THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
             vsInicioPag := 'SALTO';
             vnRow  := 0;
          END IF;



         select sgbstdn_stst_code, sgbstdn_term_code_eff into vsStatus, vsTermStatus from sgbstdn x
        where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
        and x.sgbstdn_term_code_eff =
                    (select max(y.sgbstdn_term_code_eff)
                       from sgbstdn y
                      where x.sgbstdn_pidm = y.sgbstdn_pidm);

   --END IF;



--      vnTest := f_Get_pidm(regRep.id);
      BEGIN
      select sgbstdn_stst_code into vsStatusCntr from sgbstdn x
      where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
      and x.sgbstdn_term_code_eff =
                    (select max(y.sgbstdn_term_code_eff)
                      from sgbstdn y
                      where x.sgbstdn_pidm = y.sgbstdn_pidm
                      and y.sgbstdn_term_code_eff <= regRep.periodo_cntr);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsStatusCntr := '';
      END;


--      select sgbstdn_stst_code into vsStatusCntr from sgbstdn x
--      where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
--      and x.sgbstdn_term_code_eff =
--                    (select max(sgbstdn_term_code_eff)
--                      from sgbstdn
--                      where sgbstdn_pidm = f_Get_pidm(regRep.id));



--      select sgbstdn_stst_code into vsStatusCntr from sgbstdn x
--      where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
--      and x.sgbstdn_term_code_eff =
--                    (select max(y.sgbstdn_term_code_eff)
--                      from sgbstdn y
--                      where x.sgbstdn_pidm = y.sgbstdn_pidm
--                      and y.sgbstdn_term_code_eff<= regRep.periodo_cntr);



          IF vsStatusCntr <> '' THEN
            htp.p(
            '<tr>
            <td valign="top">'||regRep.anio||'</td>
            <td valign="top">'||regRep.id||'</td>
            <td valign="top">'||regRep.rut_al||'</td>
            <td valign="top">'||regRep.alumno||'</td>
            <td valign="top">'||regRep.direccion_al||'</td>
            <td valign="top">'||regRep.region_al||'</td>
            <td valign="top">'||regRep.comuna_al||'</td>
            <td valign="top">'||regRep.telefono_al||'</td>
            <td valign="top">'||regRep.sexo||'</td>
            <td valign="top">'||regRep.coreo_pers||'</td>
            <td valign="top">'||regRep.periodo_adm||'</td>
            <td valign="top">'||regRep.periodo_cntr||'</td>
            <td valign="top">'||regRep.tipo_periodo||'</td>
            <td valign="top">'||f_student_get_desc('stvstst', vsStatusCntr, 30)||'</td>
            <td valign="top">'||f_student_get_desc('stvstst', vsStatus, 30)||'</td>
            <td valign="top">'||vsTermStatus||'</td>
            <td valign="top">'||regRep.tipo_alumno||'</td>
            <td valign="top">'||regRep.program_anterior||'</td>
            <td valign="top">'||regRep.programa||'</td>
            <td valign="top">'||regRep.prog_desc||'</td>');

          ELSE
            htp.p(
            '<tr>
            <td valign="top">'||regRep.anio||'</td>
            <td valign="top">'||regRep.id||'</td>
            <td valign="top">'||regRep.rut_al||'</td>
            <td valign="top">'||regRep.alumno||'</td>
            <td valign="top">'||regRep.direccion_al||'</td>
            <td valign="top">'||regRep.region_al||'</td>
            <td valign="top">'||regRep.comuna_al||'</td>
            <td valign="top">'||regRep.telefono_al||'</td>
            <td valign="top">'||regRep.sexo||'</td>
            <td valign="top">'||regRep.coreo_pers||'</td>
            <td valign="top">'||regRep.periodo_adm||'</td>
            <td valign="top">'||regRep.periodo_cntr||'</td>
            <td valign="top">'||regRep.tipo_periodo||'</td>
            <td valign="top">'||f_student_get_desc('stvstst',vsStatusCntr,30)||'</td>
            <td valign="top">'||f_student_get_desc('stvstst', vsStatus, 30)||'</td>
            <td valign="top">'||vsTermStatus||'</td>
            <td valign="top">'||regRep.tipo_alumno||'</td>
            <td valign="top">'||regRep.program_anterior||'</td>
            <td valign="top">'||regRep.programa||'</td>
            <td valign="top">'||regRep.prog_desc||'</td>');
          END IF;

          vnExists   := 1;
          vnRow      := vnRow + 1;
      END LOOP;

   IF vnExists = 0 THEN
      HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de p?gina para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;

   HTP.p ('</table><br/></body></html>');

EXCEPTION
   WHEN OTHERS THEN
      HTP.P (SQLERRM);
      htp.p('<br>');
      htp.p(DBMS_UTILITY.format_error_backtrace);
--      htp.p('<br>');
--      htp.p(vnTest);
END PWMATCP;
/