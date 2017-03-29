CREATE OR REPLACE PACKAGE BODY BANINST1.kwaciti IS

/*
          Tarea: Consulta de citas para la inscripción de los alumnos de  - UFT -
          Fecha: 18 MAY 2011.
          Autor: JCCR

  Observaciones: Aplican los Filtros 1.- Campus   2.-Nivel   3.-Clase   4.-Creditos  5.-Escuela  6.-Carrera
                 para obtener la Cita de Inscripción

       Modifica: 01/08/2011
                 JCCR
                 * Se Ajusta VAlidaciones, Quitando  CAMP_CODE y tomando el Contexto Original
                   en la busqueda de las Citas y VAlidaciones en SGBSTDN

       Modifica: 04/08/2011
                 JCCR
                 * Se Ajusta que cuando no tiene Creditos en vez de nulo , se coloca CERO

       Modifica: 22/12/2011
                 GEPC
                 * Se agrega la auditoria a la cita que consulta el alumno

       Modifica: 02/01/2012
                 GEPC
                 * Se agrega la validación de tipo de alumno

      Adecuacion: 08-Dic-2014  md-01
                  roman ruiz
                  se toma el programa de Rua y se hacen adecuaciones para
                  su funcionamiento  en UFT

*/

   TYPE regSgbstdn IS RECORD(rLevlCode  SGBSTDN.SGBSTDN_LEVL_CODE%TYPE,
                             rLevlDesc  STVLEVL.STVLEVL_DESC%TYPE,
                             rCollCode  SGBSTDN.SGBSTDN_COLL_CODE_1%TYPE,
                             rCollDesc  STVCOLL.STVCOLL_DESC%TYPE,
                             rCampCode  varchar2(6), --SGBSTDN.SGBSTDN_VPDI_CODE%TYPE,  --md-01
                             rCampDesc  STVCAMP.STVCAMP_DESC%TYPE,
                             rMajrCode  SGBSTDN.SGBSTDN_MAJR_CODE_1%TYPE,
                             rMajrDesc  STVMAJR.STVMAJR_DESC%TYPE,
                             rProgCode  SGBSTDN.SGBSTDN_PROGRAM_1%TYPE,
                             rStypCode  SGBSTDN.SGBSTDN_STYP_CODE%TYPE,
                             rCreditos  NUMBER
                         );

  TYPE tableSgbstdn  IS TABLE OF regSgbstdn INDEX BY BINARY_INTEGER;


  global_pidm      SPRIDEN.SPRIDEN_PIDM%TYPE;
  tblSgbstdn       tableSgbstdn;
  vslevel          varchar2(2)    := null;
  vsLevl           varchar2(50)   := null;
  vsColle          varchar2(2)    := null;
  vsColl           varchar2(300)  := null;
  vsCampC          varchar2(3)    := null;
  vsMajor          varchar2(4)    := null;
  vsStyp           varchar2(1)    := null;
  vsProg           varchar2(12)   := null;
  vsMajrCode       varchar2(50)   := null;
  vsMajrDesc       varchar2(200)  := null;
  vsClassCode      VARCHAR2(3)   := NULL;
  vsClassDesc      VARCHAR2(200) := NULL;
  vnCreditos       number         := null;
  vnPromP          decimal(7,3)   := null;
  vnPromPa         decimal(7,3)   := 0;
  vsNombre2        varchar2(300)  := null;
  vsId             varchar2(11)   := null;

  vbBandera        boolean      := true;
  vnUnicaCita      integer      := 0;

  vdBitacoraInicio DATE         := null;
  vdDateBeg1       date         := null;
  vdDateEnd1       date         := null;
  vsHourBeg1       varchar2(10) := null;
  vsHourEnd1       varchar2(10) := null;

  csA        CONSTANT VARCHAR2(1) := 'A';
  csO        CONSTANT VARCHAR2(1) := 'O';
  csRUA_P    CONSTANT VARCHAR2(5) := 'RUA_P';
  cdTysDate  CONSTANT DATE        := TRUNC(SYSDATE);
  cnHH24MI   CONSTANT NUMBER(4)   := TO_NUMBER(TO_CHAR(SYSDATE,'HH24MI'),'9999');

  PROCEDURE infoStudent(psTerm VARCHAR2);

  procedure infoStudent(psTerm VARCHAR2) IS

  sobterm_rec sobterm%ROWTYPE;
  cnPidm     constant number(9)   := global_pidm;
  csTermCode constant varchar2(6) := psTerm;
  csEsp      constant varchar2(1) := ' ';
  csAst      constant varchar2(1) := '*';
  lsPTerm    varchar2(6);       --md-01

  --md-01 start

  cursor cu_prevTerm is
        select SZRCTRL_PREV_TERM_CODE
        from SZRCTRL
        WHERE    SZRCTRL_TERM_CODE_HOST = psTerm
        AND  SZRCTRL_PREV_TERM_CODE IS NOT NULL
        ORDER BY SZRCTRL_SEQ_NO;

  --md-01 end

  begin
       -- Información General del Estudiante
       begin
           select  sgbstdn_levl_code                                                AS LevlCode,
                   (select stvlevl_desc
                      from stvlevl
                     where stvlevl_code = sgbstdn_levl_code
                   )                                                                AS LevlDesc,
                   sgbstdn_coll_code_1                                              AS CollCode,
                   (select stvcoll_desc
                      from stvcoll
                     where stvcoll_code = sgbstdn_coll_code_1
                   )                                                                AS CollDesc,
                   'UFT'                                             AS CampCode, -- a.sgbstdn_vpdi_code  --md-01
                   (select stvcamp_desc
                      from stvcamp
                     where stvcamp_code = 'UFT' --a.sgbstdn_vpdi_code   -md-01
                   )                                                                AS CampDesc,
                   sgbstdn_majr_code_1                                              AS MajrCode,
                   (select stvmajr_desc
                      from stvmajr
                     where stvmajr_code = sgbstdn_majr_code_1
                   )                                                                AS MajrDesc,
                   sgbstdn_program_1                                                AS ProgCode,
                   sgbstdn_styp_code                                                AS StypCode,
                   NVL(shksels.f_get_credit_hours(a.sgbstdn_pidm,
                                                  a.sgbstdn_levl_code,
                                                  csO
                                                 )
                       ,cn0)                                                        AS Creditos
              bulk collect into tblSgbstdn
              from sgbstdn a
             where a.sgbstdn_term_code_eff  = (select max(b.sgbstdn_term_code_eff)
                                                 from sgbstdn b
                                                where --b.sgbstdn_vpdi_code      = a.sgbstdn_vpdi_code -- md-01
                                                --  and b.sgbstdn_vpdi_code     <> 'UFT_P' -- csRUA_P
                                                 -- and
                                                  b.sgbstdn_term_code_eff <= csTermCode
                                                  and b.sgbstdn_pidm           = cnPidm
                                              )
               and a.sgbstdn_stst_code      = csAS
               --and a.sgbstdn_vpdi_code     <> csRUA_P                                            --md-01
               and a.sgbstdn_levl_code     IN (csLC,'LI',csLV)
               and a.sgbstdn_pidm           = cnPidm;

       exception
           when others then
                null;
       end;

       sobterm_rec := soksels.f_get_sobterm_row(csTermCode);

       --obtener la clase del alumno
       soklibs.p_class_calc(cnPidm,
                            tblSgbstdn(1).rLevlCode,
                            csTermCode,
                            sobterm_rec.sobterm_incl_attmpt_hrs_ind,
                            vsClassCode,
                            vsClassDesc
                           );


       --- Promedio Acumulado
       --so lo sse usa para mostrar información al alumno no es aplicado para filtrar la cita de inscripción
       --md-01 start

       begin

        /*
           select TRUNC( (sum(shrtgpa_quality_points) / sum(shrtgpa_gpa_hours)), 2)
              into vnPromPa
              from shrtgpa, shrgpal
             where shrtgpa_pidm            = cnPidm
               and shrtgpa_levl_code       = vslevel
               and shrtgpa_pidm            = SHRGPAL_PIDM
               and shrgpal_levl_code       = SHRTGPA_LEVL_CODE
               and shrgpal_gpa_type_ind    = SHRTGPA_GPA_TYPE_IND;
          */

          for cuPTerm in cu_prevTerm loop
              lsPTerm := cuPTerm.SZRCTRL_PREV_TERM_CODE;
          end loop;

          select trunc(SHRTGPA_GPA,3)
               into vnPromPa
          from shrtgpa
          where shrtgpa_pidm = cnPidm
          and shrtgpa_term_code = lsPTerm
          and rownum = 1 ;

       --md-01 end

       exception
           when others then
                vnPromPa:= 0; --md-01
                null;
       end;

          --- Nombre del Estudiante
       begin
           select replace(spriden_last_name||csEsp||spriden_first_name,csAst,csEsp), spriden_id
             INTO vsNombre2, vsId
             from spriden
            where spriden_pidm        = cnPidm
              and spriden_change_ind is null;
       exception
           when others then
                null;
       end;


  exception
      when no_data_found then
           vbBandera:= FALSE;
      when others then
           vbBandera:= FALSE;
   end infoStudent;

  --CODIGO JAVA SCRIPT
  PROCEDURE JS IS

  BEGIN
      htp.p('<script type="text/javascript">
      <!--
       var objFrmTerm = document.frmTerm;

       //la declaraciòn de la funciòn se encuenra en "kwaslct.js"
       cargaSelectCall("kwactlg.catalogo", "psCatalogo=STVTERM&psFiltro1=CITAINSC", objFrmTerm.psTerm, "ALL", "procesoTerminado();");
       ');

       --muestraCita
        htp.p(
        'function muestraCita(psTerm, psId){

           if(psTerm=="") {
              objFrmTerm.psTerm.focus();
              return false;
           }

           //la función esta declarada en "kwatime.js"
           iniciaVentana();

           //la declaraciòn de la funciòn se encuenra en "kwaslct.js"
           getMensaje("kwaciti.Mensaje","psTerm=" + psTerm ,"divMensaje");
        } //muestraCita
        ');

        --procesoTerminado
        htp.p('
        //La función es llamado por el proceso "getMensaje"
        function procesoTerminado() {
          //la función esta declarada en "kwatime.js"
          closeWindowTime();
        } //procesoTerminado
        ');

        htp.p('
        -->
        </script>
        ');

  END JS;

  --EL PROCEDIMEITO GENERA LOS FRAIMES DE LA APLICACIÓN
  PROCEDURE Cita IS

  --aplicación
  --parametros
  procedure parametros is

  begin
      htp.p(
      '<script language="javascript" src="kwatime.js?psMensaje=La p&aacute;gina se est&aacute; cargando.<br/>Espere un momento por favor...""></script>
      <script language="javascript" src="kwaslct.js"></script>
      '||
      '<br/>'||
      '<form name="frmTerm" onSubmit="return false;">'||
      '<table border="0" cellpadding="2" cellspacing="1" width="100%" bordercolor="#ffffff" bgcolor="#ffffff">'||
             '<tr><td width="25%" align="right" class="delabel">'||
                     'Selecciona el periodo de inscripci&oacute;n ' ||
                     '</td>'||
                 '<td width="40%" bgcolor="#efefef">'||
                     '<select name="psTerm" id="psTerm" onChange="muestraCita(this.value);" style="width:100%"><option value=""></option>'||
                     '<option value=""></option>'||
                     '</select>'||
                     '</td>'||
                 '<td width="35%" rowspan="2">'||
                     '</td>'||
                     '</tr>'||
      '</table>'||
      '</form>'||

      '<br/>'||
      '<div id="divMensaje"></div>'||
      '<br/>'
      );

      --CODIGO JAVA SCRIPT
      JS();
  end parametros;

  BEGIN
      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;

      bwckfrmt.p_open_doc('kwaciti.Cita');

      --aplicación
      parametros();

      twbkwbis.p_closeDoc;

  END Cita;

  --EL PROCEDIMIENTO PRESENTA EL PERIODO DE INSCRIPCIÓN
  PROCEDURE Mensaje(psTerm VARCHAR2) IS

  BEGIN
      -- Para recuperar los valores de PIDM
      IF NOT twbkwbis.f_validuser(global_pidm) THEN RETURN; END IF;

      -- Informacion para revisar Cita

      infoStudent(psTerm);

      -- Si hay Información del Estudiante
      IF  vbBandera  THEN

          -- Obtiene el Id de la Cita de acuerdo a Filtros
          vsColle    := tblSgbstdn(1).rCollCode;
          vsColl     := tblSgbstdn(1).rCollDesc;
          vsCampC    := tblSgbstdn(1).rCampCode;
          vsMajor    := tblSgbstdn(1).rMajrCode;
          vsMajrDesc := tblSgbstdn(1).rMajrDesc;
          vnCreditos := tblSgbstdn(1).rCreditos;
          vsLevel    := tblSgbstdn(1).rLevlCode;
          vsLevl     := tblSgbstdn(1).rLevlDesc;
          vsStyp     := tblSgbstdn(1).rStypCode;
          vnPromPa   := vnPromPa;

          DatosCita(psTerm,
                    vnPromPa,
                    vsColle,
                    vsCampC,
                    vsClassCode,
                    vsMajor,
                    vnCreditos,
                    vsLevel,
                    vdDateBeg1,vdDateEnd1,vsHourBeg1,vsHourEnd1, psStyp=>vsStyp
                   );

          PWRACIT(global_pidm, psTerm,vsColle,vsCampC, vsClassCode,vsMajor,vnCreditos,vsLevel,vsStyp, vdDateBeg1,vdDateEnd1,vsHourBeg1,vsHourEnd1);

        -- Muestra la Cita de acuerdo a Datos
        IF (    (vdDateBeg1 IS NOT NULL) AND (vdDateEnd1 IS NOT NULL)
            AND (vsHourBeg1 IS NOT NULL) AND (vsHourEnd1 IS NOT NULL) ) THEN


           htp.p(
           '<table border="0" cellpadding="2" cellspacing="1" bgcolor="#ffffff" width="100%">'||
           '<tr><td valign="top" width="25%" class="delabel">Alumno:</td>'||
           '<td valign="top" width="40%" colspan="2">'||vsId||' '||vsNombre2||'</td>'||
           '<td width="35%" colspan="2">&nbsp;</td>'||
           '</tr>'||
           '<tr><td valign="top" class="delabel">Escuela:</td>'||
           '<td valign="top" colspan="2">'||vsColl||'</td>'||
           '<td colspan="2">&nbsp;</td>'||
           '</tr>'||
           '<tr><td valign="top" class="delabel">Nivel:</td>'||
           '<td valign="top" colspan="2">'||vsLevl||'</td>'||
           '<td colspan="2">&nbsp;</td>'||
           '</tr>'||
           '<tr><td valign="top" class="delabel">Carrera:</td>'||
           '<td valign="top" colspan="2">'||vsMajor||' - '||vsMajrDesc||'</td>'||
           '<td colspan="2">&nbsp;</td>'||
           '</tr>'||


           '<tr><td valign="top" class="delabel">Fecha y Horario de inscripci&oacute;n:</td>'||
           '<td>'||
           '<table border="0" cellpadding="0" cellspacing="0" width="100%">'||
           '<tr><td bgcolor="#efefef">'||

           '<table border="0" cellpadding="2" cellspacing="1" width="100%">'||
           '<tr>'||
           '<td align="right">Hora de inicio:       </td><td>'||SUBSTR(vsHourBeg1,1,2)||':'||SUBSTR(vsHourBeg1,3,2)||'</td>'||
           '<td align="right">Hora de fin:          </td><td>'||SUBSTR(vsHourEnd1,1,2)||':'||SUBSTR(vsHourEnd1,3,2)||'</td>'||
           '</tr>'||
           '<td align="right">&nbsp;Fecha de inicio:</td><td>'||TO_CHAR(vdDateBeg1,'DD-MM-YYYY')||'</td>'||
           '<td align="right">Fecha de fin:         </td><td>'||TO_CHAR(vdDateEnd1,'DD-MM-YYYY')||'</td>'||
           '</tr></table>'||

           '</td>'||
           '</tr>'||
           '</table>'
           );

        ELSE  -- No hay Cita deacuerdo a Datos
           htp.p('<p align="center"><font size="5">No hay Cita registrada para la fecha de inscripci&oacute;n</font></p>');
        END IF;
      ELSE
           htp.p('<p align="center"><font size="5">No tiene registro de esa fecha de inscripci&oacute;n.</font></p>');
      END IF;

  END Mensaje;

  --DatosCita
  PROCEDURE DatosCita(psTerm    VARCHAR2,
                      pnPromPa  NUMBER,
                      psColl    VARCHAR2,
                      psCamp    VARCHAR2,
                      psClas    VARCHAR2,
                      psMajr    VARCHAR2,
                      psCred    VARCHAR2,
                      psLevl    VARCHAR2,
                      pdDateBeg IN OUT DATE,
                      pdDateEnd IN OUT DATE,
                      psHourBeg IN OUT VARCHAR2,
                      psHourEnd IN OUT VARCHAR2,
                      psHoldST  VARCHAR2 DEFAULT NULL,
                      psStyp    VARCHAR2 DEFAULT NULL
                     ) IS


  TYPE regDCita IS RECORD(rConsec  sfrctrl.sfrctrl_seq_no%type,
                          rBegDate sfrctrl.sfrctrl_begin_date%type,
                          rEndDate sfrctrl.sfrctrl_end_date%type,
                          rBegHrs  sfrctrl.sfrctrl_hour_begin%type,
                          rEndHrs  sfrctrl.sfrctrl_hour_end%type,
                          rNoFilt  integer
                         );

  TYPE tableCita  IS TABLE OF regDCita INDEX BY BINARY_INTEGER;

  tblCita   tableCita;
  vnRows    INTEGER       := 0;

  cnCadFl    CONSTANT INTEGER      := 6;   -- Hace Referencia a los 6 Filtros Solicitados
  csTermCode CONSTANT VARCHAR2(6)  := psTerm;
  csCampCode CONSTANT VARCHAR2(6)  := psCamp;
  csClasCode CONSTANT VARCHAR2(2)  := psClas;
  csStypCode CONSTANT VARCHAR2(2)  := psStyp;
  csCollCode CONSTANT VARCHAR2(2)  := psColl;
  csMajrCode CONSTANT VARCHAR2(10) := psMajr;
  csLevlCode CONSTANT VARCHAR2(2)  := psLevl;
  csCredCode CONSTANT VARCHAR2(20) := psCred;
  csPromedio CONSTANT NUMBER(5,3)  := pnPromPa;
  csI        CONSTANT VARCHAR2(1)  := 'I';
  csE        CONSTANT VARCHAR2(1)  := 'E';

  --cuCitaInscribe
  CURSOR cuCitaInscribe IS
         SELECT *
           FROM SFRCTRL, SZRCTRL
          WHERE SZRCTRL_TERM_CODE_HOST = SFRCTRL_TERM_CODE_HOST
          AND SZRCTRL_SEQ_NO = SFRCTRL_SEQ_NO
          AND (
                   (
                        TRUNC(SFRCTRL_BEGIN_DATE) >= cdTysDate
                    OR cdTysDate BETWEEN TRUNC(SFRCTRL_BEGIN_DATE) AND TRUNC(SFRCTRL_END_DATE)
                      AND (   TO_NUMBER(TO_CHAR(SYSDATE,'HH24MI'),'9999')  BETWEEN TO_NUMBER(SFRCTRL_HOUR_BEGIN) AND TO_NUMBER(SFRCTRL_HOUR_END))

                   )
                OR
                   (
                            cdTysDate BETWEEN TRUNC(SFRCTRL_BEGIN_DATE)     AND TRUNC(SFRCTRL_END_DATE)
                    AND (   cnHH24MI  BETWEEN TO_NUMBER(SFRCTRL_HOUR_BEGIN) AND TO_NUMBER(SFRCTRL_HOUR_END)
                         OR
                            (
                                 TO_NUMBER(SFRCTRL_HOUR_BEGIN) > cnHH24MI
                             AND cnHH24MI NOT BETWEEN TO_NUMBER(SFRCTRL_HOUR_BEGIN) AND TO_NUMBER(SFRCTRL_HOUR_END)
                            )
                        )
                   )
                )
               AND  (csPromedio BETWEEN SZRCTRL_MIN_GPA AND SZRCTRL_MAX_GPA
                 OR SZRCTRL_MIN_GPA IS NULL )
           -- AND (   (    SFRCTRL_CLS_INCL_EXCL = csI
             --        AND (   csClasCode IN (SFRCTRL_CLS_1, SFRCTRL_CLS_2, SFRCTRL_CLS_3, SFRCTRL_CLS_4, SFRCTRL_CLS_5)
               --           OR SFRCTRL_CLS_1||SFRCTRL_CLS_2||SFRCTRL_CLS_3||SFRCTRL_CLS_4||SFRCTRL_CLS_5 IS NULL
                 --        )
                   -- )
                 --OR
                   -- (    SFRCTRL_CLS_INCL_EXCL = csE
                     --AND csClasCode NOT IN (SFRCTRL_CLS_1, SFRCTRL_CLS_2, SFRCTRL_CLS_3, SFRCTRL_CLS_4, SFRCTRL_CLS_5)
                    --)
               -- )
            AND (
                     csStypCode IN (SFRCTRL_STUD_TYPE_1,SFRCTRL_STUD_TYPE_2,SFRCTRL_STUD_TYPE_3,SFRCTRL_STUD_TYPE_4,SFRCTRL_STUD_TYPE_5)
                  OR SFRCTRL_STUD_TYPE_1||SFRCTRL_STUD_TYPE_2||SFRCTRL_STUD_TYPE_3||SFRCTRL_STUD_TYPE_4||SFRCTRL_STUD_TYPE_5 IS NULL
                )
            AND (   (    SFRCTRL_COLL_INCL_EXCL = csI
                     AND (   csCollCode IN (SFRCTRL_COLL_1,SFRCTRL_COLL_2,SFRCTRL_COLL_3,SFRCTRL_COLL_4,SFRCTRL_COLL_5)
                          OR SFRCTRL_COLL_1||SFRCTRL_COLL_2||SFRCTRL_COLL_3||SFRCTRL_COLL_4||SFRCTRL_COLL_5 IS NULL
                         )
                    )
                 OR
                    (    SFRCTRL_COLL_INCL_EXCL = csE
                     AND csCollCode NOT IN (SFRCTRL_COLL_1,SFRCTRL_COLL_2,SFRCTRL_COLL_3,SFRCTRL_COLL_4,SFRCTRL_COLL_5)
                    )
                )
            AND (
                   (    SFRCTRL_MAJR_INCL_EXCL = csI
                    AND (   csMajrCode IN (SFRCTRL_MAJR_1, SFRCTRL_MAJR_2, SFRCTRL_MAJR_3, SFRCTRL_MAJR_4, SFRCTRL_MAJR_5)
                         OR SFRCTRL_MAJR_1||SFRCTRL_MAJR_2||SFRCTRL_MAJR_3||SFRCTRL_MAJR_4||SFRCTRL_MAJR_5 IS NULL
                        )
                   )
                 OR
                   (    SFRCTRL_MAJR_INCL_EXCL = csE
                    AND csMajrCode NOT IN (SFRCTRL_MAJR_1, SFRCTRL_MAJR_2, SFRCTRL_MAJR_3, SFRCTRL_MAJR_4, SFRCTRL_MAJR_5)
                   )
                )
            AND (
                    csLevlCode IN (SFRCTRL_LEVL_1, SFRCTRL_LEVL_2, SFRCTRL_LEVL_3, SFRCTRL_LEVL_4, SFRCTRL_LEVL_5)
                 OR SFRCTRL_LEVL_1||SFRCTRL_LEVL_2||SFRCTRL_LEVL_3||SFRCTRL_LEVL_4||SFRCTRL_LEVL_5 IS NULL
                )
            AND (   SFRCTRL_EARN_HRS_BEGIN||SFRCTRL_EARN_HRS_END IS NULL
                 OR (
                         SFRCTRL_EARN_HRS_BEGIN||SFRCTRL_EARN_HRS_END IS NOT NULL
                    -- AND csCredCode BETWEEN SFRCTRL_EARN_HRS_BEGIN AND SFRCTRL_EARN_HRS_END
                    )
                )
            --AND csCampCode IN (SFRCTRL_CMPS_1,SFRCTRL_CMPS_2,SFRCTRL_CMPS_3,SFRCTRL_CMPS_4,SFRCTRL_CMPS_5)  --md-01
            AND SFRCTRL_TERM_CODE_HOST = csTermCode
          ORDER BY SFRCTRL_BEGIN_DATE;

  BEGIN
      --- Aplicación de Filtros Solicitados, barrido de las Citas del Periodo
      FOR regCita IN cuCitaInscribe LOOP


          vnRows    := vnRows + cn1;

          -- Guarda VAlores de la Cita y Filtros Validados
          tblCita(vnRows).rConsec  := regCita.SFRCTRL_SEQ_NO;
          tblCita(vnRows).rBegDate := regCita.SFRCTRL_BEGIN_DATE;
          tblCita(vnRows).rEndDate := regCita.SFRCTRL_END_DATE;
          tblCita(vnRows).rBegHrs  := regCita.SFRCTRL_HOUR_BEGIN;
          tblCita(vnRows).rEndHrs  := regCita.SFRCTRL_HOUR_END;

      END loop;

      IF vnRows > 0 THEN
         pdDateBeg := tblCita(cn1).rBegDate;
         pdDateEnd := tblCita(cn1).rEndDate;
         psHourBeg := tblCita(cn1).rBegHrs;
         psHourEnd := tblCita(cn1).rEndHrs;
      END IF;

      -- Elimina Tabla de Paso
      tblCita.delete;

  END  DatosCita;

  --Retorna las citas de inscripción para el mobil
  --getCitas
  PROCEDURE getCitas(psID    IN SPRIDEN.SPRIDEN_ID%TYPE,
                     cuCita OUT type_cursor
                    ) IS

  vsTermCode VARCHAR2(6) := NULL;

  csPnts              CONSTANT VARCHAR2(1)  := ':';
  cs0                 CONSTANT VARCHAR2(1)  := '0';
  csUnd               CONSTANT VARCHAR2(1)  := '_';
  csGui               CONSTANT VARCHAR2(3)  := ' - ';
  csUAM               CONSTANT VARCHAR2(3)  := 'UAM';
  csDescUAM           CONSTANT VARCHAR2(14) := 'Anáhuac Mayab';
  cs999998            CONSTANT VARCHAR2(6)  := '999998';
  cs999997            CONSTANT VARCHAR2(6)  := '999997';
  cs999996            CONSTANT VARCHAR2(6)  := '999996';
  csDdMonYyyy         CONSTANT VARCHAR2(11) := 'DD-MON-YYYY';
  csNLS_DATE_LANGUAGE CONSTANT VARCHAR2(26) := 'NLS_DATE_LANGUAGE=SPANISH';
  csID                CONSTANT VARCHAR2(11) := psID;
  cn6                 CONSTANT NUMBER(1)    := 6;
  csBitP              CONSTANT VARCHAR2(10) := 'getCitas: ';

  --cuTerm
  CURSOR cuTerm IS
         SELECT STVTERM_CODE AS termCode
           FROM STVTERM
          WHERE STVTERM_CODE  IN (SELECT SFRCTRL_TERM_CODE_HOST
                                    FROM SFRCTRL
                                   WHERE (
                                          (
                                            TRUNC(SFRCTRL_BEGIN_DATE) >= cdTysDate
                                              AND cdTysDate NOT BETWEEN TRUNC(SFRCTRL_BEGIN_DATE) AND TRUNC(SFRCTRL_END_DATE)
                                          )
                                          OR
                                          (
                                            cdTysDate BETWEEN TRUNC(SFRCTRL_BEGIN_DATE)     AND TRUNC(SFRCTRL_END_DATE)
                                              AND (   cnHH24MI  BETWEEN TO_NUMBER(SFRCTRL_HOUR_BEGIN) AND TO_NUMBER(SFRCTRL_HOUR_END)
                                          OR
                                          (
                                           TO_NUMBER(SFRCTRL_HOUR_BEGIN) > cnHH24MI
                                              AND cnHH24MI NOT BETWEEN TO_NUMBER(SFRCTRL_HOUR_BEGIN) AND TO_NUMBER(SFRCTRL_HOUR_END)
                                                    )
                                                   )
                                           )
                                          )
                                       )
            --AND SUBSTR(STVTERM_CODE,cn6,cn1)  = cs0               --md-01
            AND TRUNC(STVTERM_END_DATE)       > cdTysDate
            AND STVTERM_CODE                 <> cs999998
            AND STVTERM_CODE                 <> cs999997
            AND STVTERM_CODE                 <> cs999996;

 --putBitacora
 PROCEDURE putBitacora(pnPIDM           NUMBER,
                       pdBitacoraInicio DATE,
                       psNavegacion     VARCHAR2
                      )
   IS

 vsCveCamp varchar2(6):=null;

  --getCveCamp
  function getCveCamp return varchar2 is

  vsGetCveCamp varchar2(6) := null;

   begin

   --md-01 start

      select 'UFT' into vsGetCveCamp FROM DUAL;

        /*
       select a.sgbstdn_vpdi_code
         in
         to vsGetCveCamp
         from sgbstdn a
        where a.sgbstdn_term_code_eff = (select max(b.sgbstdn_term_code_eff)
                                           from sgbstdn b
                                          where b.sgbstdn_vpdi_code = a.sgbstdn_vpdi_code
                                            and b.sgbstdn_pidm      = pnPidm
                                        )
          and a.sgbstdn_pidm          = pnPidm
          and rowNum                  = cn1;
*/
  --md-01 end
       return vsGetCveCamp;

   exception
     when no_data_found then
          return null;
     when others        then
          return null;
   end getCveCamp;

  BEGIN
      IF FWABITA() THEN
         vsCveCamp := getCveCamp;

         INSERT INTO SWABITA
        (swabita_pidm,swabita_camp_code,swabita_navegacion,swabita_date_begin,swabita_date_end)
        VALUES
        (pnPIDM      ,vsCveCamp      ,psNavegacion      ,pdBitacoraInicio ,sysdate);

         COMMIT;
      END IF;

  END putBitacora;

  BEGIN
      vdBitacoraInicio := SYSDATE;

      BEGIN
          SELECT SPRIDEN_PIDM
            INTO global_pidm
            FROM SPRIDEN
           WHERE SPRIDEN_CHANGE_IND IS NULL
             AND SPRIDEN_ID          = csID;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               global_pidm := NULL;
          WHEN OTHERS THEN
               global_pidm := NULL;
      END;

      FOR regTer IN cuTerm LOOP
          vsTermCode  := regTer.termCode;
          vsID        := NULL;
          vsNombre2   := NULL;
          vsColl      := NULL;
          vsLevl      := NULL;
          vsMajor     := NULL;
          vsMajrDesc  := NULL;
          vsClassCode := NULL;
          vnCreditos  := NULL;
          vdDateBeg1  := NULL;
          vdDateEnd1  := NULL;
          vsHourBeg1  := NULL;
          vsHourEnd1  := NULL;

          infoStudent(vsTermCode);

          -- Si hay Información del Estudiante
          IF vbBandera THEN

              -- Obtiene el Id de la Cita de acuerdo a Filtros
              FOR vnI IN 1..tblSgbstdn.COUNT LOOP
                  vsColle    := tblSgbstdn(vnI).rCollCode;
                  vsColl     := tblSgbstdn(vnI).rCollDesc;
                  vsCampC    := tblSgbstdn(vnI).rCampCode;
                  vsMajor    := tblSgbstdn(vnI).rMajrCode;
                  vsMajrDesc := tblSgbstdn(vnI).rMajrDesc;
                  vnCreditos := tblSgbstdn(vnI).rCreditos;
                  vsLevel    := tblSgbstdn(vnI).rLevlCode;
                  vsLevl     := tblSgbstdn(vnI).rLevlDesc;
                  vsStyp     := tblSgbstdn(vnI).rStypCode;
                  vdDateBeg1 := NULL;
                  vdDateEnd1 := NULL;
                  vsHourBeg1 := NULL;
                  vsHourEnd1 := NULL;
                  vnPromPa   := vnPromPa;


                  DatosCita(vsTermCode,
                            vnPromPa,
                            vsColle,
                            vsCampC,
                            vsClassCode,
                            vsMajor,
                            vnCreditos,
                            vsLevel,
                            vdDateBeg1,vdDateEnd1,vsHourBeg1,vsHourEnd1, psStyp=>vsStyp
                           );

                     INSERT INTO SWRMEET
                     (SWRMEET_TERM_CODE,
                      SWRMEET_CAMP_CODE,
                      SWRMEET_CAMP_DESC,
                      SWRMEET_PIDM,
                      SWRMEET_HORA_INI,
                      SWRMEET_HORA_FIN,
                      SWRMEET_DATE_INI,
                      SWRMEET_DATE_FIN
                     )
                     VALUES
                     (vsTermCode,
                      tblSgbstdn(vnI).rCampCode,
                      tblSgbstdn(vnI).rCampDesc,
                      global_pidm,
                      SUBSTR(vsHourBeg1,cn1,cn2)||csPnts||SUBSTR(vsHourBeg1,cn3,cn4),
                      SUBSTR(vsHourEnd1,cn1,cn2)||csPnts||SUBSTR(vsHourEnd1,cn3,cn4),
                      TO_CHAR(vdDateBeg1,csDdMonYyyy,csNLS_DATE_LANGUAGE),
                      TO_CHAR(vdDateEnd1,csDdMonYyyy,csNLS_DATE_LANGUAGE)
                     );
             END LOOP;

             COMMIT;

          END IF;
      END LOOP;

      OPEN cuCita FOR
           SELECT SWRMEET_TERM_CODE                      AS termCod,
                  pk_catalogo.periodo(SWRMEET_TERM_CODE) AS termDes,
                  SWRMEET_CAMP_CODE                      AS campCod,
                  DECODE (SWRMEET_CAMP_CODE,csUAM,
                  csDescUAM,SWRMEET_CAMP_DESC)           AS campDes,
                  NVL(SWRMEET_DATE_INI,csUnd)            AS fechIni,
                  NVL(SWRMEET_DATE_FIN,csUnd)            AS fechFin,
                  NVL(SWRMEET_HORA_INI,csUnd)            AS horaIni,
                  NVL(SWRMEET_HORA_FIN,csUnd)            AS horaFin
             FROM SWRMEET
            WHERE SWRMEET_DATE_INI IS NOT NULL
            ORDER BY fechIni;

           DELETE SWRMEET;
           COMMIT;

     putBitacora(f_getPidm(psId),vdBitacoraInicio,csBitP);

  EXCEPTION
      WHEN OTHERS THEN
           DELETE SWRMEET;
           COMMIT;
  END getCitas;


END kwaciti;
/