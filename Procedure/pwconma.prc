CREATE OR REPLACE PROCEDURE BANINST1.PWCONMA (psReclDesc VARCHAR2)
IS
/******************************************************************************
PROCEDIMIENTO:          BANINST1.PWCONMA
OBJETIVO:               Reporte de Contratos y Matriculados Completo
AUTORES:                Guillermo Almazan Iba?ez
FECHA:                  10/12/2010
****************************************************************
modificacion :          md-01 agregar a que se vean contratos en status X
autor        :          Roman Ruiz
fecha        :          23-ago-2013

modificacion :          md-02 agregar filtro de contrato por pregrado y postgrado
                        md-02-a  roman ruiz  falto adicionar ..
autor        :          Virgilio De la Cruz
fecha        :          11-ene-2014

modificacion :          md-03  se agrega validacion para recibir nulos en variables
                               fuera del query.
autor        :          Roman ruiz
fecha        :          11-feb-2014


modificacion :          md-04 se cambia formato numerico 
autor        :          Roman ruiz
fecha        :          16-may-2016 


******************************************************************************/
   vnRow         INTEGER := 0;
   vnExists      INTEGER := 0;
   vnColumnas    INTEGER := 33;
   vsProg        smrprle.smrprle_program_desc%TYPE;
   vsStat        sgbstdn.sgbstdn_stst_code%TYPE;
   vsStatus      sgbstdn.sgbstdn_stst_code%TYPE;
   vsType        sgbstdn.sgbstdn_styp_code%TYPE;
   vsDstatus     stvstst.stvstst_desc%TYPE;
   vnRegSte      NUMBER(1);
   vsYear        VARCHAR2(4);
   vsYterm       VARCHAR2(4);
   vsTerm        VARCHAR2(2);
   vsTermStatus  VARCHAR2(8);
   vsStatusCntr  VARCHAR2(8);
   vdIni         twbcntr.twbcntr_issue_date%TYPE;
   vdFin         twbcntr.twbcntr_issue_date%TYPE;
   vsCont        twbcntr.twbcntr_num%TYPE;
   tabColumna    Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag   VARCHAR2 (10) := NULL;

   vsTipoCntr    VARCHAR2(15);         --md-02
   
   vsMontoCon    varchar2(20);      --md-04

CURSOR cuReporte_Cambio (vsProg in smrprle.smrprle_program_desc%TYPE,
   vsStat in sgbstdn.sgbstdn_stst_code%TYPE,
   vsType in stvstyp.stvstyp_code%TYPE,
   vsYear in VARCHAR2,
   vdIni in twbcntr.twbcntr_issue_date%TYPE,
   vdFin in twbcntr.twbcntr_issue_date%TYPE,
   vsCont in twbcntr.twbcntr_num%TYPE)
  IS
  select anio, contrato, fecha_cntr, monto_cntr, periodo_cntr, tipo_periodo, comm_cntr, id, rut_al, alumno, direccion_al, region_al, comuna_al,
         telefono_al, psu, sexo, coreo_pers, periodo_adm, via, tipo_code, tipo, tipo_alumno, estatus_alumno, actualizacion_estatus,
         programa, prog_desc, rut_apoderado, apoderado, direccion_ap, region_ap, comuna_ap, tel_ap_tf, tel_ap_tm, email_pers
  from (select substr(twbcntr_term_code, 1, 4)                                                         anio
       , twbcntr_num                                                                                   contrato
       , twbcntr_status_ind                                                                            status
       , twbcntr_issue_date                                                                            fecha_cntr
       , twbcntr_term_code                                                                             periodo_cntr
       , decode(TWBCNTR_TERM_TYPE, 'A', 'Anual',
                                   '1', 'Primer Semestre',
                                   '2', 'Segundo Semestre',
                                   (select decode(STVTERM_TRMT_CODE, 'A', 'Anual', 'S', 'Semestral')
                                    from STVTERM
                                    where STVTERM_CODE = TWBCNTR_TERM_CODE))                           tipo_periodo
       , pk_matricula.f_MontoContrato(twbcntr_num)                                                   monto_cntr
       --, to_char(pk_matricula.f_MontoContrato(twbcntr_num), pk_contrato.ConstglFormato)                monto_cntr
       , pk_matricula.f_comecont(twbcntr_num)                                                          comm_cntr
       , f_get_id(twbcntr_pidm)                                                                        id
       , f_get_rut(twbcntr_pidm)                                                                       rut_al
       ,  f_format_name(twbcntr_pidm, 'LF30')                                                          alumno
       , pk_matricula.f_DirAlumno(twbcntr_pidm)                                                        direccion_al
       , pk_matricula.f_RegAlumno(twbcntr_pidm)                                                        region_al
       , pk_matricula.f_ComuAlumno(twbcntr_pidm)                                                       comuna_al
       , f_get_telefono_al(twbcntr_pidm, 'TFPA')                                                       telefono_al
       , pk_AdMat.f_get_psu_pond(twbcntr_pidm, twbcntr_term_code)                                  psu
       , f_get_sexo(twbcntr_pidm)                                                                      sexo
       , f_get_mail_pers(twbcntr_pidm)                                                                 coreo_pers
       , sgbstdn_term_code_admit                                                                       periodo_adm
       , pk_catalogo.admision(sgbstdn_admt_code)                                                       via
       , sgbstdn_admt_code                                                                             via_code
       , fwatyaluft(twbcntr_pidm, twbcntr_term_code)                                                   tipo_code
       , decode(fwatyaluft(twbcntr_pidm, twbcntr_term_code),'N','Nuevo Ingreso','A','Avanzado')        tipo
       , pk_catalogo.TipoAlumno(sgbstdn_styp_code)                                                     tipo_alumno
       --, f_student_get_desc('stvstst', sgbstdn_stst_code, 30)                                        estatus_alumno
       , f_student_get_desc('stvstst', BANINST1.F_GET_STST_SGB(twbcntr_pidm), 30)                      estatus_alumno
       , f_get_status(twbcntr_pidm, sgbstdn_stst_code)                                                 actualizacion_estatus
       , TWBCNTR_ORI_PROGRAM                                                                           programa
       , pk_catalogo.programa(TWBCNTR_ORI_PROGRAM)                                                     prog_desc
       , twbcntr_rut                                                                                   rut_apoderado
       , pk_MatApoderado.f_NombreCompleto(twbcntr_rut)                                                 apoderado
       , pk_MatApoderado.f_Direccion(twbcntr_rut, twbcntr_term_code)                                   direccion_ap
       , pk_MatApoderado.f_Region(twbcntr_rut, twbcntr_term_code)                                      region_ap
       , pk_MatApoderado.f_Comuna(twbcntr_rut, twbcntr_term_code)                                      comuna_ap
       , pk_MatApoderado.f_Telefono(twbcntr_rut, 'PR', twbcntr_term_code)                              tel_ap_tf
       , pk_MatApoderado.f_Telefono(twbcntr_rut, 'TMSO', twbcntr_term_code)                            tel_ap_tm
       , pk_MatApoderado.f_Email(twbcntr_rut, 'PERS', twbcntr_term_code)                               email_pers
from   twbcntr
     , sgbstdn g1
where g1.sgbstdn_pidm = twbcntr_pidm
  and g1.sgbstdn_term_code_eff =
                    (select max(g2.sgbstdn_term_code_eff)
                       from sgbstdn g2
                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
  -- and twbcntr_status_ind = 'A'              --md-01
  and twbcntr_status_ind in ( 'A','X')         --md-01
  and twbcntr_type_code is null                --md-02-a
  and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num)
  and (sgbstdn_stst_code = vsStat or vsStat is null)
  /*
  and exists (select 1 from saradap
                    where saradap_pidm = sgbstdn_pidm
                    and saradap_program_1 = sgbstdn_program_1
                    and saradap_term_code_entry like (vsYear||'%') or vsYear is null)*/
  and (sgbstdn_styp_code = vsType or vsType is null))
where (programa = vsProg or vsProg is null)
and (periodo_cntr like (vsYear||'%') or vsYear is null)
--and (fecha_cntr between vdIni and vdFin or vdFin is null or vdIni is null)
and (vdIni is null or fecha_cntr >= vdIni)
and (vdFin is null or fecha_cntr < vdFin+1)
and (contrato = vsCont or vsCont is null)
order by anio;

--md-02
CURSOR cuReporte_Cambio_Postgrado (vsProg in smrprle.smrprle_program_desc%TYPE,
   vsStat in sgbstdn.sgbstdn_stst_code%TYPE,
   vsType in stvstyp.stvstyp_code%TYPE,
   vsYear in VARCHAR2,
   vdIni in twbcntr.twbcntr_issue_date%TYPE,
   vdFin in twbcntr.twbcntr_issue_date%TYPE,
   vsCont in twbcntr.twbcntr_num%TYPE)
  IS
  select anio, contrato, fecha_cntr, monto_cntr, periodo_cntr, tipo_periodo, comm_cntr, id, rut_al, alumno, direccion_al, region_al, comuna_al,
         telefono_al, psu, sexo, coreo_pers, periodo_adm, via, tipo_code, tipo, tipo_alumno, estatus_alumno, actualizacion_estatus,
         programa, prog_desc, rut_apoderado, apoderado, direccion_ap, region_ap, comuna_ap, tel_ap_tf, tel_ap_tm, email_pers
  from (select substr(twbcntr_term_code, 1, 4)                                                         anio
       , twbcntr_num                                                                                   contrato
       , twbcntr_status_ind                                                                            status
       , twbcntr_issue_date                                                                            fecha_cntr
       , twbcntr_term_code                                                                             periodo_cntr
       , decode(TWBCNTR_TERM_TYPE, 'A', 'Anual',
                                   '1', 'Primer Semestre',
                                   '2', 'Segundo Semestre',
                                   (select decode(STVTERM_TRMT_CODE, 'A', 'Anual', 'S', 'Semestral')
                                    from STVTERM
                                    where STVTERM_CODE = TWBCNTR_TERM_CODE))                           tipo_periodo
       , pk_matricula.f_MontoContrato(twbcntr_num)                                                   monto_cntr
       --, to_char(pk_matricula.f_MontoContrato(twbcntr_num), pk_contrato.ConstglFormato)                monto_cntr
       , pk_matricula.f_comecont(twbcntr_num)                                                          comm_cntr
       , f_get_id(twbcntr_pidm)                                                                        id
       , f_get_rut(twbcntr_pidm)                                                                       rut_al
       ,  f_format_name(twbcntr_pidm, 'LF30')                                                          alumno
       , pk_matricula.f_DirAlumno(twbcntr_pidm)                                                        direccion_al
       , pk_matricula.f_RegAlumno(twbcntr_pidm)                                                        region_al
       , pk_matricula.f_ComuAlumno(twbcntr_pidm)                                                       comuna_al
       , f_get_telefono_al(twbcntr_pidm, 'TFPA')                                                       telefono_al
       , pk_AdMat.f_get_psu_pond(twbcntr_pidm, twbcntr_term_code)                                  psu
       , f_get_sexo(twbcntr_pidm)                                                                      sexo
       , f_get_mail_pers(twbcntr_pidm)                                                                 coreo_pers
       , sgbstdn_term_code_admit                                                                       periodo_adm
       , pk_catalogo.admision(sgbstdn_admt_code)                                                       via
       , sgbstdn_admt_code                                                                             via_code
       , fwatyaluft(twbcntr_pidm, twbcntr_term_code)                                                     tipo_code
       , decode(fwatyaluft(twbcntr_pidm, twbcntr_term_code),'N','Nuevo Ingreso','A','Avanzado')          tipo
       , pk_catalogo.TipoAlumno(sgbstdn_styp_code)                                                     tipo_alumno
       --, f_student_get_desc('stvstst', sgbstdn_stst_code, 30)                                        estatus_alumno
       , f_student_get_desc('stvstst', BANINST1.F_GET_STST_SGB(twbcntr_pidm), 30)                      estatus_alumno
       , f_get_status(twbcntr_pidm, sgbstdn_stst_code)                                                 actualizacion_estatus
       , TWBCNTR_ORI_PROGRAM                                                                           programa
       , pk_catalogo.programa(TWBCNTR_ORI_PROGRAM)                                                         prog_desc
       , twbcntr_rut                                                                                   rut_apoderado
       , pk_MatApoderado.f_NombreCompleto(twbcntr_rut)                     apoderado
       , pk_MatApoderado.f_Direccion(twbcntr_rut, twbcntr_term_code)                                        direccion_ap
       , pk_MatApoderado.f_Region(twbcntr_rut, twbcntr_term_code)                                        region_ap
       , pk_MatApoderado.f_Comuna(twbcntr_rut, twbcntr_term_code)                                       comuna_ap
       , pk_MatApoderado.f_Telefono(twbcntr_rut, 'PR', twbcntr_term_code)                                  tel_ap_tf
       , pk_MatApoderado.f_Telefono(twbcntr_rut, 'TMSO', twbcntr_term_code)                                tel_ap_tm
       , pk_MatApoderado.f_Email(twbcntr_rut, 'PERS', twbcntr_term_code)                              email_pers
from   twbcntr
     , sgbstdn g1
where g1.sgbstdn_pidm = twbcntr_pidm
  and g1.sgbstdn_term_code_eff =
                    (select max(g2.sgbstdn_term_code_eff)
                       from sgbstdn g2
                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
  -- and twbcntr_status_ind = 'A'              --md-01
  and twbcntr_status_ind in ( 'A','X')         --md-01
  and twbcntr_type_code = 'CFC'                --md-02
  and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num)
  and (sgbstdn_stst_code = vsStat or vsStat is null)
  and (sgbstdn_styp_code = vsType or vsType is null))
where (programa = vsProg or vsProg is null)
and (periodo_cntr like (vsYear||'%') or vsYear is null)
--and (fecha_cntr between vdIni and vdFin or vdFin is null or vdIni is null)
and (vdIni is null or fecha_cntr >= vdIni)
and (vdFin is null or fecha_cntr < vdFin+1)
and (contrato = vsCont or vsCont is null);


BEGIN


   IF Pk_Login.F_ValidacionDeAcceso (pk_login.vgsUSR)
   THEN
      RETURN;
   END IF;

    /* Par?metros */
    --Se busca el valor de la cookie (par?metro) para asignarlo al filtro del query.

    vsProg  := pk_ObjHtml.getValueCookie ('psProgr');
    vsStat  := pk_ObjHtml.getValueCookie ('psSstst');
    vsType  := pk_ObjHtml.getValueCookie ('psTyAl');
    vsYear  := pk_ObjHtml.getValueCookie ('psYear');
    vdIni   := pk_ObjHtml.getValueCookie ('pdIni');
    vdFin   := pk_ObjHtml.getValueCookie ('pdFin');
    vsCont  := pk_ObjHtml.getValueCookie ('psCont');

    --md-02
    vsTipoCntr := pk_ObjHtml.getValueCookie ('psTCntr');

  -- N?mero de columnas de la tabla --
   tabColumna.EXTEND (vnColumnas);


   /* Encabezado de las columnas */
   tabColumna (1) := 'Año';
   tabColumna (2) := 'Contrato';
   tabColumna (3) := 'Fecha';
   tabColumna (4) := 'Monto';
   tabColumna (5) := 'Comentario';
   tabColumna (6) := 'Id';
   tabColumna (7) := 'RUT';
   tabColumna (8) := 'Alumno';
   tabColumna (9) := 'Direccion';
   tabColumna (10) := 'Region';
   tabColumna (11) := 'Comuna';
   tabColumna (12) := 'Telefono';
   tabColumna (13) := 'Promedio PSU';
   tabColumna (14) := 'Sexo';
   tabColumna (15) := 'E-mail';
   tabColumna (16) := 'Periodo Ingreso';
   tabColumna (17) := 'Periodo Matricula';
   tabColumna (18) := 'Tipo Periodo';
   tabColumna (19) := 'Tipo de Alumno';
   --tabColumna (18) := 'Tipo de Admisi?n';
   --tabColumna (19) := 'Tipo de Alumno';
   tabColumna (20) := 'Estatus del Alumno<br>al hacer contrato';
   tabColumna (21) := 'Estatus del Alumno<br>actual';
   tabColumna (22) := 'Periodo Estatus del<br>alumno actual ';
   tabColumna (23) := 'Actualizacion Status Alumno ';
   tabColumna (24) := 'Programa';
   tabColumna (25) := 'Descripcion Programa';
   tabColumna (26) := 'Rut Apoderado';
   tabColumna (27) := 'Apoderado';
   tabColumna (28) := 'Direccion';
   tabColumna (29) := 'Region';
   tabColumna (30) := 'Comuna';
   tabColumna (31) := 'Telefono Personal';
   tabColumna (32) := 'Telefono Movil';
   tabColumna (33) := 'E-mail Personal';
--MD-02

IF vsTipoCntr ='PREGRADO'
THEN
      FOR regRep IN cuReporte_Cambio(vsProg, vsStat, vsType, vsYear, vdIni, vdFin, vsCont) LOOP
      
         vsMontoCon := 0;     --md-04
      
          IF vnRow = 0 THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
             vsInicioPag := 'SALTO';
             vnRow  := 0;
          END IF;

         begin   --md-03
           select count(1) into vnRegSte from sgbstdn x
           where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
           and x.sgbstdn_term_code_eff =
                    (select max(y.sgbstdn_term_code_eff)
                       from sgbstdn y
                      where x.sgbstdn_pidm = y.sgbstdn_pidm
                      and y.sgbstdn_term_code_eff like (vsYear||'%'));
         exception when no_data_found then  --md-03 start
           vnRegSte := null;
         end;                               --md-03 end



--   IF vnRegSte > 0 then
--       select sgbstdn_stst_code, sgbstdn_term_code_eff into vsStatus, vsTermStatus from sgbstdn x
--        where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
--        and x.sgbstdn_term_code_eff =
--                    (select max(y.sgbstdn_term_code_eff)
--                       from sgbstdn y
--                      where x.sgbstdn_pidm = y.sgbstdn_pidm
--                      and y.sgbstdn_term_code_eff like (vsYear||'%'));
--
--   END IF;

  -- IF vnRegSte = 0  THEN
       begin                                       --md-03
          select sgbstdn_stst_code, sgbstdn_term_code_eff into vsStatus, vsTermStatus from sgbstdn x
          where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
          and x.sgbstdn_term_code_eff =
                    (select max(y.sgbstdn_term_code_eff)
                       from sgbstdn y
                      where x.sgbstdn_pidm = y.sgbstdn_pidm);
        exception when no_data_found then          --md-03 start
          vsStatus := null;
          vsTermStatus := null;
        end;                                       --md-03 end

   --END IF;



        begin                                      --md-03
          select sgbstdn_stst_code into vsStatusCntr from sgbstdn x
           where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
           and x.sgbstdn_term_code_eff =
                    (select max(y.sgbstdn_term_code_eff)
                       from sgbstdn y
                      where x.sgbstdn_pidm = y.sgbstdn_pidm
                      and y.sgbstdn_term_code_eff<= regRep.periodo_cntr);
        exception when no_data_found then         --md-03 start
          vsStatusCntr := null;
        end;                                      --md-03 end


         IF vsStatus IS NOT NULL THEN
           begin
              select trunc(swrales_chan_date) into vsDstatus
              from swrales
              where swrales_pidm = f_Get_pidm(regRep.id)
              and swrales_stst_code = vsStatus
              and swrales_chan_num = (select max (swrales_chan_num)
                                      from swrales
                                      where swrales_pidm = f_Get_pidm(regRep.id)
                                      and swrales_stst_code = vsStatus);
           exception when no_data_found then
              vsDstatus := null;
           end;

         END IF;
         
         vsMontoCon := to_char(regRep.monto_cntr, pk_contrato.ConstglFormato );   --md-04 
         vsMontoCon := trim( replace ( replace ( replace ( vsMontoCon , '.', '|') , ',', '.') , '|', ',')) ;
         
          htp.p(
          '<tr>
          <td valign="top">'||regRep.anio||'</td>
          <td valign="top">'||regRep.contrato||'</td>
          <td valign="top">'||regRep.fecha_cntr||'</td>
          <td valign="top">'||  vsMontoCon ||'</td>
          <td valign="top">'||regRep.comm_cntr||'</td>
          <td valign="top">'||regRep.id||'</td>
          <td valign="top">'||regRep.rut_al||'</td>
          <td valign="top">'||regRep.alumno||'</td>
          <td valign="top">'||regRep.direccion_al||'</td>
          <td valign="top">'||regRep.region_al||'</td>
          <td valign="top">'||regRep.comuna_al||'</td>
          <td valign="top">'||regRep.telefono_al||'</td>
          <td valign="top">'||regRep.psu||'</td>
          <td valign="top">'||regRep.sexo||'</td>
          <td valign="top">'||regRep.coreo_pers||'</td>
          <td valign="top">'||regRep.periodo_adm||'</td>
          <td valign="top">'||regRep.periodo_cntr||'</td>
          <td valign="top">'||regRep.tipo_periodo||'</td>
          <td valign="top">'||regRep.tipo_alumno||'</td>
          <td valign="top">'||f_student_get_desc('stvstst', vsStatusCntr, 30)||'</td>
          <td valign="top">'||f_student_get_desc('stvstst', vsStatus, 30)||'</td>
          <td valign="top">'||vsTermStatus||'</td>
          <td valign="top">'||vsDstatus||'</td>
          <td valign="top">'||regRep.programa||'</td>
          <td valign="top">'||regRep.prog_desc||'</td>
          <td valign="top">'||regRep.rut_apoderado||'</td>
          <td valign="top">'||regRep.apoderado||'</td>
          <td valign="top">'||regRep.direccion_ap||'</td>
          <td valign="top">'||regRep.region_ap||'</td>
          <td valign="top">'||regRep.comuna_ap||'</td>
          <td valign="top">'||regRep.tel_ap_tf||'</td>
          <td valign="top">'||regRep.tel_ap_tm||'</td>
          <td valign="top">'||regRep.email_pers||'</td>');
          --<td valign="top">'||regRep.via||'</td>
          --<td valign="top">'||regRep.tipo||'</td>


          vnExists   := 1;
          vnRow      := vnRow + 1;
      END LOOP;

   IF vnExists = 0
   THEN
      HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de p?gina para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;

   HTP.p ('</table><br/></body></html>');
END IF;

IF vsTipoCntr ='POSTGRADO'  THEN
     
 FOR regRep IN cuReporte_Cambio_Postgrado(vsProg, vsStat, vsType, vsYear, vdIni, vdFin, vsCont) LOOP
          
         vsMontoCon := 0;   --md-04
      
          IF vnRow = 0 THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
             vsInicioPag := 'SALTO';
             vnRow  := 0;
          END IF;

          begin                                         --md-03
            select count(1) into vnRegSte from sgbstdn x
            where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
            and x.sgbstdn_term_code_eff =
                       (select max(y.sgbstdn_term_code_eff)
                          from sgbstdn y
                         where x.sgbstdn_pidm = y.sgbstdn_pidm
                         and y.sgbstdn_term_code_eff like (vsYear||'%'));
          exception when no_data_found then          --md-03 start
            vnRegSte := null;
          end;                                       --md-03 end

--   IF vnRegSte > 0 then
--       select sgbstdn_stst_code, sgbstdn_term_code_eff into vsStatus, vsTermStatus from sgbstdn x
--        where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
--        and x.sgbstdn_term_code_eff =
--                    (select max(y.sgbstdn_term_code_eff)
--                       from sgbstdn y
--                      where x.sgbstdn_pidm = y.sgbstdn_pidm
--                      and y.sgbstdn_term_code_eff like (vsYear||'%'));
--
--   END IF;

  -- IF vnRegSte = 0  THEN
          begin                                       --md-03
             select sgbstdn_stst_code, sgbstdn_term_code_eff into vsStatus, vsTermStatus from sgbstdn x
             where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
             and x.sgbstdn_term_code_eff =
                       (select max(y.sgbstdn_term_code_eff)
                          from sgbstdn y
                         where x.sgbstdn_pidm = y.sgbstdn_pidm);
          exception when no_data_found then          --md-03 start
            vsStatus     := null;
            vsTermStatus := null;
          end;                                       --md-03 end

   --END IF;



          begin                                      --md-03
             select sgbstdn_stst_code into vsStatusCntr from sgbstdn x
             where x.sgbstdn_pidm = f_Get_pidm(regRep.id)
             and x.sgbstdn_term_code_eff =
                           (select max(y.sgbstdn_term_code_eff)
                              from sgbstdn y
                             where x.sgbstdn_pidm = y.sgbstdn_pidm
                               and y.sgbstdn_term_code_eff<= regRep.periodo_cntr);
          exception when no_data_found then          --md-03 start
            vsStatusCntr  := null;
          end;                                       --md-03 end


         IF vsStatus IS NOT NULL THEN
            begin
                select trunc(swrales_chan_date) into vsDstatus
                  from swrales
                 where swrales_pidm = f_Get_pidm(regRep.id)
                   and swrales_stst_code = vsStatus
                   and swrales_chan_num = (select max (swrales_chan_num)
                                           from swrales
                                           where swrales_pidm = f_Get_pidm(regRep.id)
                                            and swrales_stst_code = vsStatus);
            exception when no_data_found then
            vsDstatus := null;

            end;

         END IF;
         
         vsMontoCon := to_char(regRep.monto_cntr, pk_contrato.ConstglFormato );   --md-04
         vsMontoCon := trim( replace ( replace ( replace ( vsMontoCon , '.', '|') , ',', '.') , '|', ',')) ;

          htp.p(
          '<tr>
          <td valign="top">'||regRep.anio||'</td>
          <td valign="top">'||regRep.contrato||'</td>
          <td valign="top">'||regRep.fecha_cntr||'</td>
          <td valign="top">'|| vsMontoCon ||'</td>
          <td valign="top">'||regRep.comm_cntr||'</td>
          <td valign="top">'||regRep.id||'</td>
          <td valign="top">'||regRep.rut_al||'</td>
          <td valign="top">'||regRep.alumno||'</td>
          <td valign="top">'||regRep.direccion_al||'</td>
          <td valign="top">'||regRep.region_al||'</td>
          <td valign="top">'||regRep.comuna_al||'</td>
          <td valign="top">'||regRep.telefono_al||'</td>
          <td valign="top">'||regRep.psu||'</td>
          <td valign="top">'||regRep.sexo||'</td>
          <td valign="top">'||regRep.coreo_pers||'</td>
          <td valign="top">'||regRep.periodo_adm||'</td>
          <td valign="top">'||regRep.periodo_cntr||'</td>
          <td valign="top">'||regRep.tipo_periodo||'</td>
          <td valign="top">'||regRep.tipo_alumno||'</td>
          <td valign="top">'||f_student_get_desc('stvstst', vsStatusCntr, 30)||'</td>
          <td valign="top">'||f_student_get_desc('stvstst', vsStatus, 30)||'</td>
          <td valign="top">'||vsTermStatus||'</td>
          <td valign="top">'||vsDstatus||'</td>
          <td valign="top">'||regRep.programa||'</td>
          <td valign="top">'||regRep.prog_desc||'</td>
          <td valign="top">'||regRep.rut_apoderado||'</td>
          <td valign="top">'||regRep.apoderado||'</td>
          <td valign="top">'||regRep.direccion_ap||'</td>
          <td valign="top">'||regRep.region_ap||'</td>
          <td valign="top">'||regRep.comuna_ap||'</td>
          <td valign="top">'||regRep.tel_ap_tf||'</td>
          <td valign="top">'||regRep.tel_ap_tm||'</td>
          <td valign="top">'||regRep.email_pers||'</td>');
          --<td valign="top">'||regRep.via||'</td>
          --<td valign="top">'||regRep.tipo||'</td>


          vnExists   := 1;
          vnRow      := vnRow + 1;
      END LOOP;

   IF vnExists = 0
   THEN
      HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de p?gina para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;

   HTP.p ('</table><br/></body></html>');
END IF;


EXCEPTION
   WHEN OTHERS
   THEN
      HTP.P (SQLERRM );
--END IF;

END PWCONMA; 
/
