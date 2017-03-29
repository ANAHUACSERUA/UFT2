CREATE OR REPLACE PROCEDURE BANINST1.PWRBALC(psReclDesc   VARCHAR2) IS
/******************************************************************************
   NAME:       PWRBALC  (original PWRPGST)
            
   PURPOSE:    reporte de balance 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------ 
   1.0        10-mar-2015  ROMAN RUIZ     Balance de Alumno de beca CAE
--------------------------------
cambio              md-01
objetivo            se adiciona columna de tipo de beneficio c = cae m = minieduc
autor               roman ruiz
fecha               24-jun-201

******************************************************************************/

    --Numero de renglones
    vnRow                PLS_INTEGER := 0;
    --Bandera para mostrar si hubo datos
    vnExists             INTEGER := 0;
    --Numero de columnas
    vnColumnas           INTEGER := 14;
    --Arreglo (nested table) donde se guardan los encabezados de las columnas
    tabColumna            Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla();
    -- la variable es una bandera que al tener el valor "imprime" no colocara
    --el salto de página para impresion
    vsInicoPag            VARCHAR2(10) := NULL;
    
    --Período de busqueda
    vsPeriodo    VARCHAR2(30) := NULL;
    vsAnio       varchar2(4);
    vsRut        varchar2(10);
    viPidm       number(8);
    vsIdAlumno   varchar2(9);
    vsNombre     varchar2(200);
    viMonto      number(16,2); 
    vnSaldoAnual number(16,4);
    vnSaldoFinal number(16,4);
    vnYear       number(4);
    vnRowAlumn   number(6);    
    vdDiaDep     date;
    vsDiaDep     varchar2(13);
    
    vsTipoBene   varchar2(1);    --md-01
      
     cursor cu_Spriden_id is    
          select SPRIDEN_PIDM pidm, replace (SPRIDEN_FIRST_NAME || ' ' || SPRIDEN_LAST_NAME, '*', ' ') nombre
          from spriden
          where  SPRIDEN_ID = vsIdAlumno  --'00010960'
          and SPRIDEN_CHANGE_IND is null
          order by  SPRIDEN_ACTIVITY_DATE desc;

     cursor cu_Spriden_pid is
          select SPRIDEN_ID id, replace (SPRIDEN_FIRST_NAME || ' ' || SPRIDEN_LAST_NAME, '*', ' ') nombre
          from spriden
          where  SPRIDEN_pidm = viPidm   --'00010960'
          and SPRIDEN_CHANGE_IND is null
          order by  SPRIDEN_ACTIVITY_DATE desc;

     cursor cu_rut is
          select SPBPERS_NAME_SUFFIX rut
          from spbpers
          where SPBPERS_PIDM =   viPidm;
          
     cursor cur_MainPidm is 
           select distinct TWRCABA_PIDM pidm
           from twrcaba
           where vsAnio in (TWRCABA_ANIO_LICITA,0)
           and viPidm in (TWRCABA_PIDM,0)
           and TWRCABA_TIPO_BENE = vsTipoBene       --md-01
           order by TWRCABA_PIDM;

     cursor cur_PidmAnio is
           select twrcaba_anio_licita anio , count(*) renglones
           from twrcaba
           where vsAnio in (TWRCABA_ANIO_LICITA,0)
           and   TWRCABA_PIDM = viPidm
           and TWRCABA_TIPO_BENE = vsTipoBene       --md-01
           group by twrcaba_anio_licita
           order by TWRCABA_ANIO_LICITA;

     cursor cur_PidmMov is
            select *
            from twrcaba
            where TWRCABA_ANIO_LICITA = vnYear
            and   TWRCABA_PIDM = viPidm
            and TWRCABA_TIPO_BENE = vsTipoBene       --md-01
            order by TWRCABA_SEQ_NUM;

BEGIN

   --Seguridad de GWAMNUR
   IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
   
   vsTipoBene := 'C';    --md-01 

   -- obtiene los valores de las cookies para asignar los valores del filtro del query:
   vsPeriodo   := pk_objHtml.getValueCookie('psAño');
   --vsPeriodo := 2014;
   vsAnio      := SUBSTR(vsPeriodo,1,4);

   if vsAnio is null or vsAnio < 0 then
      vsAnio := 0;
   end if;
   
   vsIdAlumno := pk_objHtml.getValueCookie('psId');
   
   viPidm := 0;
   if vsIdAlumno is null or vsIdAlumno < 0 then
      viPidm := 0;
   else
      for cuSpriden  in cu_Spriden_id loop
          viPidm := cuSpriden.pidm;
      end loop;
   end if;

   -- Redimensiono el arreglo (tabla anidada) de encabezados de columnas
   tabColumna.EXTEND(vnColumnas);
   --Guardamos los encabezados en el arreglo de columnas
   tabColumna( 1) := '<center> Id Alumno';
   tabColumna( 2) := '<center> Rut';
   tabColumna( 3) := '<center> Nombre';
   tabColumna( 4) := '<center> Año';
   tabColumna( 5) := '<center> Banco';
   tabColumna( 6) := '<center> Deposito Banco'; 
   tabColumna( 7) := '<center> Seguro Banco';
   tabColumna( 8) := '<center> Total CAE';
   tabColumna( 9) := '<center> Dia Deposito';
   tabColumna(10) := '<center> No Documento';
   tabColumna(11) := '<center> Tipo Documento';
   tabColumna(12) := '<center> Monto Pago';
   tabColumna(13) := '<center> Dia Pago';
   tabColumna(14) := '<center> Saldo';

   vnExists     := 0;
   vsIdAlumno   := '0';
   vnSaldoAnual := 0;
   vnSaldoFinal := 0;
   vnYear       := 0;
   vnRow        := 0;
   vnRowAlumn   := 0;

   -----------------------------------------------------------------
   for cuMainPidm in cur_MainPidm loop
      vnRow    := vnRow + 1;
      vnExists := 1;
      if vnRow = 1 then  --Si es el primer renglon de cada página...
         Pk_Sisrepimp.P_EncabezadoDeReporte( psReclDesc ,vnColumnas ,tabColumna , vsInicoPag ,'1' ,psUsuario=>pk_login.vgsUSR  );
         vsInicoPag := 'SALTO';
      END IF;
             
      viPidm := cuMainPidm.pidm;   --pidm al que voy a seguir.
      vnRowAlumn   := 1;
      vnSaldoFinal := 0;
      for cuAnio in cur_PidmAnio loop
         vnYear       := cuAnio.anio;   -- anio para pidm 
         vnSaldoAnual := 0;

         for cuPidMov in cur_PidmMov loop    --detalle de movimientos por anio
            if vnRowAlumn = 1 then
               -- tomo datos grales de alumno 
               for cuid in cu_Spriden_pid loop
                  vsIdAlumno := cuid.id;
                  vsNombre   := cuid.nombre;
                  exit;
               end loop;
               vsRut := 'N.A.';
               for curut in cu_rut loop
                   vsRut := curut.rut;
                   exit;
               end loop;

               HTP.P('<tr> <td> ' || vsIdAlumno || '</td> <td>' || vsRut || '</td> <td>'|| vsNombre ||'</td> ');
            else
               HTP.P('<tr> <td colspan="3"></td>');
            end if;
            -- imprimiento ya el detalle 
            if nvl(length(cuPidMov.TWRCABA_BANK_CODE),0) >= 1 
               and nvl(cuPidMov.TWRCABA_MONTO_DEPOSITO,0) >= 0  
               and cuPidMov.TWRCABA_TIPO_DOCUMENTO is null  then   -- datos en banco deposito
               
               viMonto := nvl(cuPidMov.TWRCABA_MONTO_DEPOSITO,0) +  nvl(cuPidMov.TWRCABA_MONTO_FIANZA,0);
               
               if nvl(length(cuPidMov.TWRCABA_BANK_CODE),0) > 0 then
                 vdDiaDep := cuPidMov.TWRCABA_ENTRY_DATE;   --TWRCABA_APPLY_DATE;
               else
                 vdDiaDep := cuPidMov.TWRCABA_ACTIVITY_DATE; 
               end if;  
               
               vsDiaDep := to_char(vdDiaDep, 'DD/Mon/yyyy');
               
               HTP.P('<td>'|| vnYear || '</td>');
               HTP.P('<td>'|| cuPidMov.TWRCABA_BANK_CODE ||'</td>');
               HTP.P('<td>'|| cuPidMov.TWRCABA_MONTO_DEPOSITO ||'</td>');
               HTP.P('<td>'|| cuPidMov.TWRCABA_MONTO_FIANZA ||'</td>');
               HTP.P('<td>'|| viMonto ||'</td>');
               HTP.P('<td>'|| vsDiaDep ||'</td>');
               HTP.P('<td></td> <td></td> <td></td> <td></td> <td></td></tr> ');
            else   --datos de pagos. 
               if nvl(length(cuPidMov.TWRCABA_BANK_CODE),0) > 0 then
                 vdDiaDep := cuPidMov.TWRCABA_ENTRY_DATE;   --TWRCABA_APPLY_DATE;
               else
                 vdDiaDep := cuPidMov.TWRCABA_ACTIVITY_DATE;
               end if;  
            
               --vdDiaDep   := cuPidMov.TWRCABA_ENTRY_DATE;
               vsDiaDep   := to_char(vdDiaDep, 'DD/Mon/yyyy');
               HTP.P('<td>' || vnYear  || '</td> <td></td> <td></td> <td></td> <td></td> <td></td> ');
               HTP.P('<td>' || cuPidMov.TWRCABA_NO_DOCUMENTO || '</td>');
               HTP.P('<td>' || cuPidMov.TWRCABA_TIPO_DOCUMENTO || '</td>');
               HTP.P('<td>' || cuPidMov.TWRCABA_MONTO_PAGO || '</td>');
               HTP.P('<td>' || vsDiaDep || '</td>'); 
               HTP.P('<td> </td> </tr>');
               viMonto := nvl(cuPidMov.TWRCABA_MONTO_PAGO,0) * -1;
            end if;

            vnSaldoAnual := vnSaldoAnual + viMonto;
            vnRowAlumn := vnRowAlumn + 1;
         end loop; -- end cur_PidmMov
         
         HTP.P('<tr> <td colspan="12"></td> <td>Saldo Anual '|| vnYear ||' </td>  <td align=right >' || vnSaldoAnual ||'</td> </tr> ');
         vnSaldoFinal := vnSaldoFinal + vnSaldoAnual; 
         
      end loop; -- end cur_PidmAnio
      HTP.P('<tr> <td colspan="12"></td> <td>Saldo Total </td>  <td align=right >'|| vnSaldoFinal || ' </td> </tr> ');
      HTP.P('<tr> <td colspan="14"></td>');
   end loop;  -- end cuMainPidm 
 
    IF vnExists = 0 THEN
        --NO SE ENCONTRARON DATOS
        htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
    ELSE
        -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de p¿gina para impresion
        Pk_Sisrepimp.vgsSaltoImp := 'Imprime';
        -- es omitido el encabezado del reporte pero se agrega el salto de pagina
        Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
    END IF;

    --Fin de la pagina
    htp.p('</table><br/></body></html>');
    
    EXCEPTION
             WHEN NO_DATA_FOUND THEN
               NULL;
             WHEN OTHERS THEN
               -- Consider logging the error and then re-raise
               RAISE;
END PWRBALC;
/
