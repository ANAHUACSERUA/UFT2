CREATE OR REPLACE PROCEDURE BANINST1.PWLIBVP(psReclDesc VARCHAR2)
IS
/******************************************************************************
PROCEDIMIENTO:          BANINST1.PWLIBVP
OBJETIVO:               Reporte Libro de Venta
AUTORES:                Virgilio De la Cruz Jardón
FECHA:                  07/10/2013
****************************************************************/
   vnTotalMontoBoletas INTEGER:=0;
   vnTotalMontoFacturas INTEGER:=0;
   vnTotalMontoNotCre         INTEGER := 0;
   vnTotalMontoContratosSolos         INTEGER := 0;
   vnRowsContratosSolos  INTEGER := 0;
   vnRowBoletas        INTEGER := 0;
   vnRowFacturas        INTEGER := 0;
   vnRowNotcre        INTEGER := 0;
   vnExistsCntr     INTEGER := 0;
   vnExistsBol     INTEGER := 0;
   vnExistsFac     INTEGER := 0;
   vnExistsNotcre     INTEGER := 0;
   vnColumnas   INTEGER := 9;
   vsMes        VARCHAR2(4);
   vsYear       VARCHAR2(4);
   vsCont       twbcntr.twbcntr_num%TYPE;
   vsId            VARCHAR2(9);
   tabColumna   Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag   VARCHAR2 (10) := NULL;
   flag BOOLEAN;
   csFmt                VARCHAR2(50) := 'fm999,999,999,999,999,999,999,999,999,999';
    csDate                VARCHAR2(20) := 'DD/MM/YYYY';

--Este cursor nos trae los contratos sin boleta ni factura asociada
CURSOR cu_Contratos_sin_bol_y_sin_fac (
  vsMes in varchar2,
  vsYear in VARCHAR2,
  vsCont in twbcntr.twbcntr_num%TYPE,
  vsID in VARCHAR2

   )
  IS
  SELECT
            TWBCNTR_NUM num_cntr,
            TO_CHAR(TWBCNTR_ISSUE_DATE,'DD/MM/YYYY')  fecha_de_generacion_cntr
            , f_get_id(twbcntr_pidm) id_alumno
            , f_get_rut(twbcntr_pidm)  rut_alumno
            ,  f_format_name(twbcntr_pidm, 'LF30')  nombre_alumno
            , f_student_get_desc('stvstst', BANINST1.F_GET_STST_SGB(twbcntr_pidm), 30)  status_alumno
             ,pk_catalogo.programa(TWBCNTR_ORI_PROGRAM)   prog_desc
             ,pk_Matricula.f_MontoContrato(TWBCNTR_NUM) monto
           FROM
            TWBCNTR,
            sgbstdn g1
        WHERE
        g1.sgbstdn_pidm = twbcntr_pidm
        and g1.sgbstdn_term_code_eff =
                    (select max(g2.sgbstdn_term_code_eff)
                       from sgbstdn g2
                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
        and twbcntr_status_ind in ( 'A','X')
        and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num)
           and  TWBCNTR_STATUS_IND <> 'C'
            AND (vsMes is NULL OR TO_CHAR(TWBCNTR_ISSUE_DATE,'MM')=vsMes)
            AND (vsYear is NULL OR TO_CHAR(TWBCNTR_ISSUE_DATE,'YYYY')=vsYear)
            --and pk_Matricula.f_MontoContrato(TWBCNTR_NUM) > 180
            and (vsCont IS NULL OR vsCont = twbcntr_num)
            and (vsID IS NULL OR vsID = f_get_id(twbcntr_pidm))
            and TWBCNTR_NUM NOT IN ( SELECT TWBBOLE_CNTR_NUM FROM TWBBOLE WHERE TWBBOLE_STATUS_IND ='A')
            and TWBCNTR_NUM NOT IN ( SELECT TWBFCTU_CNTR_NUM FROM TWBFCTU WHERE TWBFCTU_STATUS_IND ='A')
            and twbcntr_type_code = 'CFC'
            order by TWBCNTR_ISSUE_DATE;

--Este cursor nos trae los contratos con boleta asignada

CURSOR cu_Boletas (
  vsMes in varchar2,
  vsYear in VARCHAR2,
  vsCont in twbcntr.twbcntr_num%TYPE,
  vsID in VARCHAR2

   )
  IS
       SELECT
            TWBCNTR_NUM num_cntr,
            TO_CHAR(TWBCNTR_ISSUE_DATE,'DD/MM/YYYY')  fecha_de_generacion_cntr
            , f_get_id(twbcntr_pidm) id_alumno
            , f_get_rut(twbcntr_pidm)  rut_alumno
            ,  f_format_name(twbcntr_pidm, 'LF30')  nombre_alumno
            , f_student_get_desc('stvstst', BANINST1.F_GET_STST_SGB(twbcntr_pidm), 30)  status_alumno
             ,pk_catalogo.programa(TWBCNTR_ORI_PROGRAM)   prog_desc
           ,TWBBOLE_BOL_NUM boleta
             ,pk_Matricula.f_MontoContrato(TWBCNTR_NUM) monto
           FROM
            TWBCNTR,
            sgbstdn g1,
            TWBBOLE
        WHERE
        g1.sgbstdn_pidm = twbcntr_pidm
        and g1.sgbstdn_term_code_eff =
                    (select max(g2.sgbstdn_term_code_eff)
                       from sgbstdn g2
                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
        and twbcntr_status_ind in ( 'A','X')
        and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num)
           and  TWBCNTR_STATUS_IND <> 'C'
            AND (vsMes is NULL OR TO_CHAR(TWBBOLE_DATE,'MM')=vsMes)
            AND (vsYear is NULL OR TO_CHAR(TWBBOLE_DATE,'YYYY')=vsYear)
            --and pk_Matricula.f_MontoContrato(TWBCNTR_NUM) > 180
            and (vsCont IS NULL OR vsCont = twbcntr_num)
            and (vsID IS NULL OR vsID = f_get_id(twbcntr_pidm))
            and TWBBOLE_CNTR_NUM = twbcntr_num
            and TWBBOLE_STATUS_IND = 'A'
            and twbcntr_type_code = 'CFC'
            order by TWBCNTR_ISSUE_DATE;

--Este cursor nos trae los contratos con factura asociada
CURSOR cu_Facturas (
  vsMes in varchar2,
  vsYear in VARCHAR2,
  vsCont in twbcntr.twbcntr_num%TYPE,
  vsID in VARCHAR2

   )
  IS
       SELECT
            TWBCNTR_NUM num_cntr,
            TO_CHAR(TWBCNTR_ISSUE_DATE,'DD/MM/YYYY')  fecha_de_generacion_cntr
            , f_get_id(twbcntr_pidm) id_alumno
            , f_get_rut(twbcntr_pidm)  rut_alumno
            ,  f_format_name(twbcntr_pidm, 'LF30')  nombre_alumno
            , f_student_get_desc('stvstst', BANINST1.F_GET_STST_SGB(twbcntr_pidm), 30)  status_alumno
             ,pk_catalogo.programa(TWBCNTR_ORI_PROGRAM)   prog_desc
            ,TWBFCTU_FACT_NUM factura
              ,pk_Matricula.f_MontoContrato(TWBCNTR_NUM) monto
        FROM
            TWBCNTR,
            sgbstdn g1,
            TWBFCTU
        WHERE
        g1.sgbstdn_pidm = twbcntr_pidm
        and g1.sgbstdn_term_code_eff =
                    (select max(g2.sgbstdn_term_code_eff)
                       from sgbstdn g2
                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
        and twbcntr_status_ind in ( 'A','X')
        and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num)
           and  TWBCNTR_STATUS_IND <> 'C'
            AND (vsMes is NULL OR TO_CHAR(TWBFCTU_DATE,'MM')=vsMes)
            AND (vsYear is NULL OR TO_CHAR(TWBFCTU_DATE,'YYYY')=vsYear)
            --and pk_Matricula.f_MontoContrato(TWBCNTR_NUM) >180
            and (vsCont IS NULL OR vsCont = twbcntr_num)
            and (vsID IS NULL OR vsID = f_get_id(twbcntr_pidm))
            and twbcntr_num = TWBFCTU_CNTR_NUM
            --and TWBFCTU_STATUS_IND ='A'
            and twbcntr_type_code = 'CFC'
            ORDER BY
            TWBCNTR_ISSUE_DATE;

--Este cursor nos trae los contratos con nota de crédito asociada
CURSOR cu_NotasCredito (
  vsMes in varchar2,
  vsYear in VARCHAR2,
  vsCont in twbcntr.twbcntr_num%TYPE,
  vsID in VARCHAR2

   )
  IS
       SELECT
            TWBCNTR_NUM num_cntr,
            TO_CHAR(TWBCNTR_ISSUE_DATE,'DD/MM/YYYY')  fecha_de_generacion_cntr
            , f_get_id(twbcntr_pidm) id_alumno
            , f_get_rut(twbcntr_pidm)  rut_alumno
            ,  f_format_name(twbcntr_pidm, 'LF30')  nombre_alumno
            , f_student_get_desc('stvstst', BANINST1.F_GET_STST_SGB(twbcntr_pidm), 30)  status_alumno
             ,pk_catalogo.programa(TWBCNTR_ORI_PROGRAM)   prog_desc
              ,TWBNOCR_NOCR_NUM notcredito
              ,pk_Matricula.f_MontoContrato(TWBCNTR_NUM) monto
        FROM
            TWBCNTR,
            sgbstdn g1,
            TWBNOCR
        WHERE
        g1.sgbstdn_pidm = twbcntr_pidm
        and g1.sgbstdn_term_code_eff =
                    (select max(g2.sgbstdn_term_code_eff)
                       from sgbstdn g2
                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
        and twbcntr_status_ind in ( 'A','X')
        and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num)
           and  TWBCNTR_STATUS_IND <> 'C'
            AND (vsMes is NULL OR TO_CHAR(TWBNOCR_DATE,'MM')=vsMes)
            AND (vsYear is NULL OR TO_CHAR(TWBNOCR_DATE,'YYYY')=vsYear)
            --and pk_Matricula.f_MontoContrato(TWBCNTR_NUM) >180
            and (vsCont IS NULL OR vsCont = twbcntr_num)
            and (vsID IS NULL OR vsID = f_get_id(twbcntr_pidm))
            and twbcntr_num = TWBNOCR_CNTR_NUM
            and TWBNOCR_STATUS_IND ='A'
            and twbcntr_type_code = 'CFC'
            ORDER BY
            TWBCNTR_ISSUE_DATE;



BEGIN

    -- valida que el usuario tenga acceso a la base de datos:
    IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

    /* Par?metros */
    --Se busca el valor de la cookie (par?metro) para asignarlo al filtro del query.
    vsYear := pk_ObjHtml.getValueCookie ('psAño');
    vsCont  := pk_ObjHtml.getValueCookie ('psCont');
    vsID    := pk_ObjHtml.getValueCookie ('psID');
    vsMes := pk_ObjHtml.getValueCookie ('psMes');


/*Contratos son facturas ni  boletas asociadas*/
  -- N?mero de columnas de la tabla --
   tabColumna.EXTEND (vnColumnas);


   /* Encabezado de las columnas */
   tabColumna (1) := 'Contrato';
   tabColumna (2) := 'Fecha';
   tabColumna (3) := 'Id';
   tabColumna (4) := 'RUT';
   tabColumna (5) := 'Alumno';
   tabColumna (6) := 'Estatus del Alumno';
   tabColumna (7) := 'Descripción Programa';
   tabColumna (8) := 'Boleta';
   tabColumna (9) := 'Monto';
     Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);

      FOR regCntr IN cu_Contratos_sin_bol_y_sin_fac(vsMes,vsYear,vsCont,vsID) LOOP
          IF vnRowsContratosSolos = 0 THEN

              vsInicioPag := 'SALTO';
             vnRowsContratosSolos  := 0;

          END IF;

          htp.p(
          '<tr>
            <td valign="top">'||regCntr.num_cntr||'</td>
            <td valign="top">'||regCntr.fecha_de_generacion_cntr||'</td>
            <td valign="top">'||regCntr.id_alumno||'</td>
            <td valign="top">'||regCntr.rut_alumno ||'</td>
            <td valign="top">'||regCntr.nombre_alumno||'</td>
            <td valign="top">'||regCntr.status_alumno||'</td>
            <td valign="top">'||regCntr.prog_desc ||'</td>
            <td valign="top"> NA</td>
            <td valign="top">'||TO_CHAR(regCntr.monto,csFmt)||'</td></tr>');
            vnTotalMontoContratosSolos :=  vnTotalMontoContratosSolos + regCntr.monto;
          vnExistsCntr   := 1;

          vnRowsContratosSolos      := vnRowsContratosSolos + 1;
      END LOOP;
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>MONTO TOTAL DE CONTRATOS SIN BOLETA NI FACTURA ASOCIADA</b></td>
       <td><b>' || TO_CHAR(vnTotalMontoContratosSolos,csFmt)||'</td></tr>');
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>CANTIDAD DE CONTRATOS SIN BOLETA NI FACTURA ASOCIADA</b></td>
       <td><b>' ||TO_CHAR(vnRowsContratosSolos,csFmt)||'</td></tr>');



   IF vnExistsBol = 0
   THEN
           Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);


   END IF;

   HTP.p ('</table><br/>');


/*Boletas*/
  -- N?mero de columnas de la tabla --
   tabColumna.EXTEND (vnColumnas);


   /* Encabezado de las columnas */
   tabColumna (1) := 'Contrato';
   tabColumna (2) := 'Fecha';
   tabColumna (3) := 'Id';
   tabColumna (4) := 'RUT';
   tabColumna (5) := 'Alumno';
   tabColumna (6) := 'Estatus del Alumno';
   tabColumna (7) := 'Descripción Programa';
   tabColumna (8) := 'Boleta';
   tabColumna (9) := 'Monto';
     Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);

      FOR regBol IN cu_Boletas(vsMes,vsYear,vsCont,vsID) LOOP
          IF vnRowBoletas = 0 THEN

              vsInicioPag := 'SALTO';
             vnRowBoletas  := 0;

          END IF;

          htp.p(
          '<tr>
            <td valign="top">'||regBol.num_cntr||'</td>
            <td valign="top">'||regBol.fecha_de_generacion_cntr||'</td>
            <td valign="top">'||regBol.id_alumno||'</td>
            <td valign="top">'||regBol.rut_alumno ||'</td>
            <td valign="top">'||regBol.nombre_alumno||'</td>
            <td valign="top">'||regBol.status_alumno||'</td>
            <td valign="top">'||regBol.prog_desc ||'</td>
            <td valign="top">'||regBol.boleta||'</td>
            <td valign="top">'||TO_CHAR(regBol.monto,csFmt)||'</td></tr>');
            vnTotalMontoBoletas := vnTotalMontoBoletas + regBol.monto;
          vnExistsBol   := 1;
          vnRowBoletas      := vnRowBoletas + 1;
      END LOOP;
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>MONTO TOTAL DE BOLETAS</b></td>
       <td><b>' || TO_CHAR(vnTotalMontoBoletas,csFmt)||'</td></tr>');
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>CANTIDAD DE BOLETAS</b></td>
       <td><b>' ||TO_CHAR(vnRowBoletas,csFmt)||'</td></tr>');


   IF vnExistsBol = 0
   THEN
           Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);

   END IF;

   HTP.p ('</table><br/>');


   /*facturas*/

      /* Encabezado de las columnas */
   tabColumna (1) := 'Contrato';
   tabColumna (2) := 'Fecha';
   tabColumna (3) := 'Id';
   tabColumna (4) := 'RUT';
   tabColumna (5) := 'Alumno';
   tabColumna (6) := 'Estatus del Alumno';
   tabColumna (7) := 'Descripción Programa';
   tabColumna (8) := 'Factura';
   tabColumna (9) := 'Monto';
       Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);

      FOR regFac IN cu_Facturas(vsMes,vsYear,vsCont,vsID) LOOP
          IF vnRowFacturas = 0 THEN

              --vsInicioPag := 'SALTO';
             vnRowFacturas  := 0;

          END IF;
          htp.p(
          '<tr>
            <td valign="top">'||regFac.num_cntr||'</td>
            <td valign="top">'||regFac.fecha_de_generacion_cntr||'</td>
            <td valign="top">'||regFac.id_alumno||'</td>
            <td valign="top">'||regFac.rut_alumno ||'</td>
            <td valign="top">'||regFac.nombre_alumno||'</td>
            <td valign="top">'||regFac.status_alumno||'</td>
            <td valign="top">'||regFac.prog_desc ||'</td>
            <td valign="top">'||regFac.factura||'</td>
            <td valign="top">'||TO_CHAR(regFac.monto,csFmt)||'</td></tr>');
            vnTotalMontoFacturas := vnTotalMontofacturas + regFac.monto;
          vnExistsFac   := 1;
         vnRowFacturas      := vnRowFacturas + 1;
      END LOOP;
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>MONTO TOTAL DE FACTURAS</b></td>
       <td><b>' || TO_CHAR(vnTotalMontofacturas,csFmt)||'</td></tr>');
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>CANTIDAD DE  FACTURAS</b></td>
       <td><b>' ||TO_CHAR(vnRowFacturas,csFmt)||'</td></tr>');

   IF vnExistsFac = 0
   THEN
     -- HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
         Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de p?gina para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;


    /*notas de credito */
      /* Encabezado de las columnas */
   tabColumna (1) := 'Contrato';
   tabColumna (2) := 'Fecha';
   tabColumna (3) := 'Id';
   tabColumna (4) := 'RUT';
   tabColumna (5) := 'Alumno';
   tabColumna (6) := 'Estatus del Alumno';
   tabColumna (7) := 'Descripción Programa';
   tabColumna (8) := 'Nota de Crédito';
   tabColumna (9) := 'Monto';
     Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);

      FOR regNc IN cu_NotasCredito(vsMes,vsYear,vsCont,vsID) LOOP
          IF  vnRowNotcre = 0 THEN
                       vnRowNotcre  := 0;
          END IF;
          htp.p(
          '<tr>
            <td valign="top">'||regNc.num_cntr||'</td>
            <td valign="top">'||regNc.fecha_de_generacion_cntr||'</td>
            <td valign="top">'||regNc.id_alumno||'</td>
            <td valign="top">'||regNc.rut_alumno ||'</td>
            <td valign="top">'||regNc.nombre_alumno||'</td>
            <td valign="top">'||regNc.status_alumno||'</td>
            <td valign="top">'||regNc.prog_desc ||'</td>
            <td valign="top">'||regNc.notcredito||'</td>
            <td valign="top">'||TO_CHAR(regNc.monto,csFmt)||'</td></tr>');
            vnTotalMontoNotCre := vnTotalMontoNotCre + regNc.monto;
          vnExistsNotcre   := 1;
          vnRowNotcre      :=  vnRowNotcre + 1;
      END LOOP;
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>MONTO TOTAL DE NOTAS DE CREDITO</b></td>
       <td><b>' || TO_CHAR(vnTotalMontoNotCre,csFmt)||'</td></tr>');
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>CANTIDAD DE NOTAS DE CREDITO</b></td>
       <td><b>' ||TO_CHAR( vnRowNotcre,csFmt)||'</td></tr>');
        htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>
       <td><b></td></tr>');
         htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>
       <td><b></td></tr>');
       -- Se calcula el Total Genera de Ventas del Mes
       -- contratos_solos + facturas + boletas - notas_de_credito
       htp.p('<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td><b>TOTAL GENERAL DE VENTAS DEL MES</b></td>
       <td><b>' ||TO_CHAR(vnTotalMontoContratosSolos+vnTotalMontofacturas+vnTotalMontoBoletas-vnTotalMontoNotCre,csFmt)||'</td></tr>');


   IF vnExistsNotcre = 0
   THEN
         Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
    --HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de p?gina para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';
      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;

   HTP.p ('</table><br/>');
   HTP.p ('</body></html>');

EXCEPTION
   WHEN OTHERS
   THEN
       HTP.P ('<font color=#FF0000>' || SQLERRM ||'</font>');
END PWLIBVP;
/