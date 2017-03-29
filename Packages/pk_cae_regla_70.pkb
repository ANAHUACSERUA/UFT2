CREATE OR REPLACE PACKAGE BODY BANINST1.pk_Cae_Regla_70 IS
/******************************************************************************
PAQUETE:            BANINST1.pk_Cae_Regla_70
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la aplicacion de diferentes regalas
                    para el proceso de Revoacion del CAE
AUTOR:              Roman Ruiz
FECHA:              25-feb-2014
-------------------------------------------------
moficacion  :       md-01
objetivo    :       procedimeinto de validacion de Matricula
                    procedimiento de validacion si es Egresado
autor       :       Roman Ruiz
Fecha       :       6 marzo 2014
*********************************************************************************
modificacion :  md-01
objetivo     :  se adiciona una función para que el proceso de 70%
               y otros validaciones se hagan por rut especifico.
autor        : Roman Ruiz
fecha        : 18-jul-2014

*********************************************************************************
modificacion :  md-03
objetivo     : modificaciones vistas con monica.
autor        : Roman Ruiz
fecha        :21-jul-2014
*********************************************************************************
modificacion : md-04
objetivo     : se adiciona status unico y historia en twrcaes
autor        : Roman Ruiz
fecha        : 28-jul-2014
*********************************************************************************
modificacion :  md-05
objetivo     : se adiciona entradas a TWRCARL.
autor        : Roman Ruiz
fecha        : 04-ago-2014
*********************************************************************************
modificacion :  md-06
objetivo     : se cambia el p_main a funcion para regresar detalle y se envia rut en especifico
autor        : Roman Ruiz
fecha        : 21-ago-2014
*********************************************************************************
modificacion :  md-07
objetivo     : se adiciona solo twacral a alumnos activos
               y con leyenda de preseleccionados sin restriccion
autor        : Roman Ruiz
fecha        : 26-ago-2014
*********************************************************************************
modificacion :  md-08
objetivo     : la regla del 70 se aplica integra al primera carga  de fuas ,
               todas las demas no se checa la validación de cae en años anteriores(twacral).
autor        : Roman Ruiz
fecha        : 24-sep-2014
*********************************************************************************
modificacion :  md-09
objetivo     : para la regla del 70 evalua si tiene el 70 porciento aprovado..
               no importa si tiene matrias faltantes de calificar..
               si no lo pasa entonces si se notifica que materias faltan por calificar.
autor        : Roman Ruiz
fecha        : 20-ene-2015
*********************************************************************************
modificacion :  md-10
objetivo     : para la regla del 70 se quitan todas aquellas materias que el CRN
                el campo de  SCBCRSE_CREDIT_HR_LOW = 0
autor        : Roman Ruiz
fecha        : 23-ene-2015
******************************************************************************/

    --Mensajes de Error
    cgsErr20401      CONSTANT VARCHAR2(4000) := 'No esta configurada la secuencia para la generacion de archivo Salida CAE Matricula1';
    cgsErr20402      CONSTANT VARCHAR2(4000) := 'No se pudo obtener un numero de archivo';
    cgsErr20403      CONSTANT VARCHAR2(4000) := 'No se encontró el archivo especificado';
    cgsErr20404      CONSTANT VARCHAR2(4000) := 'No se encontraron los registros correspondientes al archivo';
    cgsErr20405      CONSTANT VARCHAR2(4000) := 'El archivo recien leido difiere del original. Posible corrupción de datos';
    cgsErr20406      CONSTANT VARCHAR2(4000) := 'No se encontraron los datos del alumno';
    cgsErr20407      CONSTANT VARCHAR2(4000) := 'No se encontraron los datos del apoderado';
    cgsErr20408      CONSTANT VARCHAR2(4000) := 'No esta configurado el Año para proceso CAE';
    csRS            constant varchar2(2) := 'RS';     --renovante superior
    csRR            constant varchar2(2) := 'RR';     --renovante resagado
    csRE            constant varchar2(2) := 'RE';     --renovante con error
    csR7            constant varchar2(2) := 'R7';     --renovante procede regla del 70%
    ciPrcntAP       constant number(3,1) := 0.7;      --porcentaje aprovatorio
    csStatUni       constant varchar2(3) := 'RES' ;    --Respaldado    --md-04
    csCAE           constant varchar2(3) := 'CAE';     --CAE           --md-05
    csAS            constant varchar2(2) := 'AS';      --md-07
    csAL            constant varchar2(2) := 'AL';      --md-07

    vsYEAR     varchar2(4);
    vsTxtErr   varchar2(200);
    vsDv       char(1);
    vsRut      varchar2(10);
    viSequencia    number(5);
    vi_pidm  number;   --md-06

    -- cursor de alumnos que se les calcula reglas del CAE - 70%
    cursor curEvalStd is
          select a.TWRCAES_rut     RUT,
                 a.TWRCAES_rut_dv  DV,
                 a.TWRCAES_PIDM    PIDM,
                 a.TWRCAES_SEQ_NUM SEQ_NUM
          from TWRCAES  a
          WHERE a.TWRCAES_STATUS_CODE  IN ('PSR',  'PS' , 'RE' , 'R7' )
          and a.TWRCAES_SEND_SEQ is null
          and a.TWRCAES_YEAR = vsYEAR
         -- and a.TWRCAES_RUT = 16470216
          --and a.TWRCAES_PIDM in (85583,84094))
          and a.TWRCAES_SEQ_NUM = (select max(b.TWRCAES_SEQ_NUM)   --para traer el max mov del rut
                                   from  TWRCAES b
                                   WHERE b.TWRCAES_STATUS_CODE  IN ( 'PSR','PS' ,'RE' , 'R7' )
                                   and b.TWRCAES_SEND_SEQ is null
                                   and b.TWRCAES_YEAR = vsYEAR
                                   and a.TWRCAES_RUT = b.TWRCAES_RUT
                                   and a.TWRCAES_RUT_DV = b.TWRCAES_RUT_DV)
          and a.TWRCAES_RUT||a.TWRCAES_RUT_DV not in              -- discriminar los rut ya reportados
                                               (select c.TWRCAES_RUT||c.TWRCAES_RUT_DV
                                                  from   TWRCAES c
                                                  where  c.TWRCAES_YEAR = vsYEAR
                                                  and    c.TWRCAES_STATUS_CODE in ( 'RS', 'RR' ))   --respaldados sup , resagado
          order by  a.TWRCAES_RUT;

  --md-06 start
  -- cursor de alumnos que se les calcula reglas del CAE - 70%
    cursor curEvalStdPidm is
          select a.TWRCAES_rut     RUT,
                 a.TWRCAES_rut_dv  DV,
                 a.TWRCAES_PIDM    PIDM,
                 a.TWRCAES_SEQ_NUM SEQ_NUM
          from TWRCAES  a
          WHERE a.TWRCAES_STATUS_CODE  IN ('PSR', 'PS' , 'RE' , 'R7' )
          and a.TWRCAES_SEND_SEQ is null
          and a.TWRCAES_YEAR = vsYEAR
          and a.TWRCAES_PIDM = vi_pidm
          and a.TWRCAES_SEQ_NUM = (select max(b.TWRCAES_SEQ_NUM)   --para traer el max mov del rut
                                   from  TWRCAES b
                                   WHERE b.TWRCAES_STATUS_CODE  IN ( 'PSR','PS' ,'RE' , 'R7' )
                                   and b.TWRCAES_SEND_SEQ is null
                                   and b.TWRCAES_YEAR = vsYEAR
                                   and a.TWRCAES_RUT = b.TWRCAES_RUT
                                   and a.TWRCAES_RUT_DV = b.TWRCAES_RUT_DV)
          and a.TWRCAES_RUT||a.TWRCAES_RUT_DV not in              -- discriminar los rut ya reportados
                                               (select c.TWRCAES_RUT||c.TWRCAES_RUT_DV
                                                  from   TWRCAES c
                                                  where  c.TWRCAES_YEAR = vsYEAR
                                                  and    c.TWRCAES_STATUS_CODE in ( 'RS', 'RR' ))   --respaldados sup , resagado
          order by  a.TWRCAES_RUT;

  --md-06 end

 -- md-01 start se saca de p_main y se pone como global
        -- cursor para econtrar el PIDM
    cursor curPidm is
            SELECT  sgbstdn_pidm
                   ,SGBSTDN_TERM_CODE_EFF
                   ,sgbstdn_activity_date
            FROM   sgbstdn
                  ,spbpers
            WHERE  spbpers_name_suffix = vsRut||'-'||vsDv
            AND    sgbstdn_pidm = spbpers_pidm
            ORDER BY SGBSTDN_TERM_CODE_EFF desc, sgbstdn_activity_date ;

 -- md-01  end

--Prototipos de procedimientos y funciones privadas
Function F_EvaluaAlumnoActivo ( pi_pidm number ) Return number;

Function F_EvaluaCaeAnterior ( pi_pidm number ) Return number;


--md-01 start

--Function F_EvaluaTieneMatricula ( pi_pidm number ) Return number;
--
--Function F_EvaluaEsEgresado ( pi_pidm number ) Return number;

--md-01  endd

    /******************************************************************************
    PROCEDIMIENTO:      p_Main
    OBJETIVO:           Evalua los registros validos para las reglas
                           - alumno este activo
                           - Inexistencia de cae años anteriores
                           - 70 %
    ******************************************************************************/
--PROCEDURE p_Main is            --md-06
function p_Main( pi_pidm number default null, pi_fuas number default null ) Return number is
--vsDv           char(1);        md-01
--vsRut          varchar2(10);   md-01
viPidm         number(10);
viSeqn         number(6);
viProcede      number(1);
vsStatus       varchar2(2);
vs_Termino     number(1);      --md-06

BEGIN

   vs_Termino := 0; --md-06
   -- obtener el año general de procesos CAE
   vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

   --Si no se encontró el nombre de la secuencia mandamos error
   IF vsYEAR IS NULL THEN

      RAISE_APPLICATION_ERROR(-20408, cgsErr20408, TRUE);
      return vs_Termino;      --md-06
   END IF;

   -- abro el cursor princiapl y empiezo a evaluar cada alumno
   if pi_pidm is null then
       FOR curStd in curEvalStd loop

          vsRut     := curStd.RUT;
          vsDv      := curStd.DV;
          viSeqn    := curStd.SEQ_NUM;
          viProcede := 1;         -- si viprocede cambia a 0=error,  1=exito
          vsTxtErr  := '';
          viPidm    := null;

          -- busco el PDIM mas reciente.
          for cPidm in curPidm loop
             viPidm := cPidm.sgbstdn_pidm;
             exit; -- forzo la salida con esto siempre obtengo el 1o
          end loop;

          if viPidm is null then  -- no tengo pidm
             viProcede := 0;
             vsTxtErr  := 'No existe PIM actual.';
          else
             -- basicamente es evaluar al alumno por rut, los N procesos y
             -- si cualquiera NO procede,  entonces se maraca como error.

             -- regla alumno activo
             -- viProcede := F_EvaluaAlumnoActivo(viPidm);  --md-03

             --md-03  if viProcede = 1 then -- existe por lo tanto continuo revisando
             -- regla no CAE
             if pi_fuas = 1 then                             --md-08
                viProcede := F_EvaluaCaeAnterior(viPidm);
             else                                            --md-08 start
                viProcede :=  1;
             end if;                                         --md-08 end

             if viProcede = 1 then -- no tiene cae de años anteriores y continuo
                -- regla del 70%   --ultima validacion
                viProcede := F_Evalua70Prcntf(viPidm);

             end if;

             -- end if ;  --md-03

          end if;  --end if de pidm

          -- seleccionar status del registro despues de validaciones.
          if viProcede = 0 then   -- no procedio
             vsStatus := csRE ;
          else --si procede
             vsStatus := csR7 ;
             vsTxtErr := 'Regla 70% OK';
          end if;

          -- limito linea de error
          vsTxtErr := trim( substr(vsTxtErr,1,200));

          --md-04 start
          select count(1) into viSequencia
          from twrcaes
          where TWRCAES_YEAR = vsYEAR
          and TWRCAES_RUT  = vsRut;

          viSequencia := viSequencia + 1;

           insert into TWRCAES
                           (  TWRCAES_RUT            ,
                              TWRCAES_RUT_DV         ,
                              TWRCAES_SEQ_NUM        ,
                              TWRCAES_STATUS_CODE    ,
                              TWRCAES_PIDM           ,
                              TWRCAES_FILE_SEQ       ,
                              TRWCAES_CNTR_NUM       ,
                              TWRCAES_SEND_SEQ       ,
                              TWRCAES_TYPE           ,
                              TWRCAES_LOAD_STAT      ,
                              TWRCAES_LOAD_ERROR     ,
                              TWRCAES_PROCESS_ERROR  ,
                              TWRCAES_REG_ERROR      ,
                              TWRCAES_YEAR           ,
                              TWRCAES_USER           ,
                              TWRCAES_ACTIVITY_DATE  ,
                              TWRCAES_STATUS_UNI )
                     values ( vsRut
                             ,vsDv
                             ,viSequencia   -- consecutivo conforme mov del rut
                             ,vsStatus      -- status calculado
                             ,viPidm
                             ,null           -- numero de arch carga
                             ,null           -- TRWCAES_CNTR_NUM
                             ,null           -- TWRCAES_SEND_SEQ
                             ,'P'            -- C de carga
                             ,null          -- null si no tiene error
                             ,vsTxtErr       -- errores en la carga de arch
                             , null          -- eror en proceso
                             , null          -- error (glosa)
                             ,vsYEAR
                             ,'BANNER'       --vgsUsr
                             ,sysdate
                             ,csStatUni);     --se agrega status Unico


          /*
          -- actulizo la tabla de bitacora.
          update TWRCAES set  TWRCAES_STATUS_CODE   = vsStatus
                            , TWRCAES_TYPE          = 'P'
                            , TWRCAES_PROCESS_ERROR = vsTxtErr
                            , TWRCAES_ACTIVITY_DATE = sysdate
          where TWRCAES_RUT  = vsRut
          and   TWRCAES_RUT_DV = vsDv
          and   TWRCAES_SEQ_NUM = viSeqn
          and   TWRCAES_YEAR = vsYEAR;
          */   --md-04 end

       END LOOP; --- PRINCIPAL curEvalStd
   else
      -- regla del 70% por pidm en especifico
       vi_pidm := pi_pidm;

       FOR curStd in curEvalStdPidm loop

          vsRut     := curStd.RUT;
          vsDv      := curStd.DV;
          viSeqn    := curStd.SEQ_NUM;
          viProcede := 1;         -- si viprocede cambia a 0=error,  1=exito
          vsTxtErr  := '';
          viPidm    := null;

          -- busco el PDIM mas reciente.
          for cPidm in curPidm loop
             viPidm := cPidm.sgbstdn_pidm;
             exit; -- forzo la salida con esto siempre obtengo el 1o
          end loop;

          if viPidm is null then  -- no tengo pidm
             viProcede := 0;
             vsTxtErr  := 'No existe PIM actual.';
          else
              -- regla no CAE
             if pi_fuas = 1 then                             --md-08
                viProcede := F_EvaluaCaeAnterior(viPidm);
             else                                            --md-8 start
                 viProcede := 1;
             end if;                                         --md-8 end

             if viProcede = 1 then -- no tiene cae de años anteriores y continuo
                -- regla del 70%   --ultima validacion
                viProcede := F_Evalua70Prcntf(viPidm);
             end if;
          end if;  --end if de pidm

          -- seleccionar status del registro despues de validaciones.
          if viProcede = 0 then   -- no procedio
             vsStatus := csRE ;
          else --si procede
             vsStatus := csR7 ;
             vsTxtErr := 'Regla 70% OK';
          end if;

          -- limito linea de error
          vsTxtErr := trim( substr(vsTxtErr,1,200));

          select count(1) into viSequencia
          from twrcaes
          where TWRCAES_YEAR = vsYEAR
          and TWRCAES_RUT  = vsRut;

          viSequencia := viSequencia + 1;

           insert into TWRCAES
                           (  TWRCAES_RUT            ,
                              TWRCAES_RUT_DV         ,
                              TWRCAES_SEQ_NUM        ,
                              TWRCAES_STATUS_CODE    ,
                              TWRCAES_PIDM           ,
                              TWRCAES_FILE_SEQ       ,
                              TRWCAES_CNTR_NUM       ,
                              TWRCAES_SEND_SEQ       ,
                              TWRCAES_TYPE           ,
                              TWRCAES_LOAD_STAT      ,
                              TWRCAES_LOAD_ERROR     ,
                              TWRCAES_PROCESS_ERROR  ,
                              TWRCAES_REG_ERROR      ,
                              TWRCAES_YEAR           ,
                              TWRCAES_USER           ,
                              TWRCAES_ACTIVITY_DATE  ,
                              TWRCAES_STATUS_UNI )
                     values ( vsRut
                             ,vsDv
                             ,viSequencia   -- consecutivo conforme mov del rut
                             ,vsStatus      -- status calculado
                             ,viPidm
                             ,null           -- numero de arch carga
                             ,null           -- TRWCAES_CNTR_NUM
                             ,null           -- TWRCAES_SEND_SEQ
                             ,'P'            -- C de carga
                             ,null          -- null si no tiene error
                             ,vsTxtErr       -- errores en la carga de arch
                             , null          -- eror en proceso
                             , null          -- error (glosa)
                             ,vsYEAR
                             ,'BANNER'       --vgsUsr
                             ,sysdate
                             ,csStatUni);     --se agrega status Unico
       END LOOP; --- PRINCIPAL curEvalStd

   end if;

   commit;

   vs_Termino := 1;

   return vs_Termino;

end p_Main;

--procedimiento para un rut en particular
-- parametros rut
-- retorna error : porque no fue valido la función
--         valor :  0 novalido ,  1 valido
Function F_MainXRut( ps_rut varchar2, ps_error out varchar  ) Return number is

viPidm         number(10);
viSeqn         number(6);
viProcede      number(1);
vsStatus       varchar2(2);
lsRut          varchar2(10);
lsDv           varchar2(1);

    -- cursor de alumnos que se les calcula reglas del CAE - 70%
    cursor curEvalStd1 is
          select a.TWRCAES_rut     RUT,
                 a.TWRCAES_rut_dv  DV,
                 a.TWRCAES_PIDM    PIDM,
                 a.TWRCAES_SEQ_NUM SEQ_NUM
          from TWRCAES  a
          WHERE a.TWRCAES_STATUS_CODE  IN ( 'PSR','PS' , 'RE' , 'R7' )
          and a.TWRCAES_SEND_SEQ is null
          and a.TWRCAES_YEAR = vsYEAR
          and a.TWRCAES_RUT = vsRut
          --and a.TWRCAES_PIDM in (85583,84094))
          and a.TWRCAES_SEQ_NUM = (select max(b.TWRCAES_SEQ_NUM)   --para traer el max mov del rut
                                   from  TWRCAES b
                                   WHERE b.TWRCAES_STATUS_CODE  IN ('PSR', 'PS' ,'RE' , 'R7' )
                                   and b.TWRCAES_SEND_SEQ is null
                                   and b.TWRCAES_YEAR = vsYEAR
                                   and a.TWRCAES_RUT = b.TWRCAES_RUT
                                   and a.TWRCAES_RUT_DV = b.TWRCAES_RUT_DV)
          and a.TWRCAES_RUT||a.TWRCAES_RUT_DV not in              -- discriminar los rut ya reportados
                                               (select c.TWRCAES_RUT||c.TWRCAES_RUT_DV
                                                  from   TWRCAES c
                                                  where  c.TWRCAES_YEAR = vsYEAR
                                                  and    c.TWRCAES_STATUS_CODE in ( 'RS', 'RR' ));

BEGIN

   viProcede := 0;

   -- obtener el año general de procesos CAE
   vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

   --Si no se encontró el nombre de la secuencia mandamos error
   IF vsYEAR IS NULL THEN
      ps_error := cgsErr20408;
      return viProcede;
   END IF;

   IF ps_rut IS NULL THEN
      ps_error := 'El Rut no puede ser Nulo';
      return viProcede;
   END IF;

   -- rompo el rut en rut-dv
   --rut
   vsRut := substr(ps_rut, 1, instr( ps_rut,'-')-1);
   --dv
   vsDv  := substr(ps_rut, instr(ps_rut,'-')+1);

   -- abro el cursor princiapl y empiezo a evaluar cada alumno
   FOR curStd1 in curEvalStd1 loop

      vsRut     := curStd1.RUT;
      vsDv      := curStd1.DV;
      viSeqn    := curStd1.SEQ_NUM;
      viProcede := 1;         -- si viprocede cambia a 0=error,  1=exito
      vsTxtErr  := '';
      viPidm    := null;

      -- busco el PDIM mas reciente.
      for cPidm in curPidm loop
         viPidm := cPidm.sgbstdn_pidm;
         exit; -- forzo la salida con esto siempre obtengo el 1o

      end loop;

      if viPidm is null then  -- no tengo pidm
         viProcede := 0;
         vsTxtErr  := 'No existe PIM actual.';

      else
         -- basicamente es evaluar al alumno por rut, los N procesos y
         -- si cualquiera NO procede entonces se maraca como error.

         --md-03  if viProcede = 1 then -- existe por lo tanto continuo revisando
            -- regla no CAE
         viProcede := F_EvaluaCaeAnterior(viPidm);

         if viProcede = 1 then -- no tiene cae de años anteriores y continuo
            -- regla del 70%   --ultima validacion
            viProcede := F_Evalua70Prcntf(viPidm);

         end if;

      end if;  --end if de pidm

      -- seleccionar status del registro despues de validaciones.
      if viProcede = 0 then   -- no procedio
         vsStatus := csRE ;
      else --si procede
         vsStatus := csR7 ;
      end if;

      -- limito linea de error
      vsTxtErr := trim( substr(vsTxtErr,1,200));

      --md-04 start
      select count(1) into viSequencia
      from twrcaes
      where TWRCAES_YEAR = vsYEAR
      and TWRCAES_RUT  = vsRut;

       insert into TWRCAES
                       (  TWRCAES_RUT            ,
                          TWRCAES_RUT_DV         ,
                          TWRCAES_SEQ_NUM        ,
                          TWRCAES_STATUS_CODE    ,
                          TWRCAES_PIDM           ,
                          TWRCAES_FILE_SEQ       ,
                          TRWCAES_CNTR_NUM       ,
                          TWRCAES_SEND_SEQ       ,
                          TWRCAES_TYPE           ,
                          TWRCAES_LOAD_STAT      ,
                          TWRCAES_LOAD_ERROR     ,
                          TWRCAES_PROCESS_ERROR  ,
                          TWRCAES_REG_ERROR      ,
                          TWRCAES_YEAR           ,
                          TWRCAES_USER           ,
                          TWRCAES_ACTIVITY_DATE  ,
                          TWRCAES_STATUS_UNI )
                 values ( vsRut
                         ,vsDv
                         ,viSequencia   -- consecutivo conforme mov del rut
                         ,vsStatus      -- status calculado
                         ,viPidm
                         ,null           -- numero de arch carga
                         ,null           -- TRWCAES_CNTR_NUM
                         ,null           -- TWRCAES_SEND_SEQ
                         ,'P'            -- C de carga
                         ,null          -- null si no tiene error
                         ,vsTxtErr       -- errores en la carga de arch
                         , null          -- eror en proceso
                         , null          -- error (glosa)
                         ,vsYEAR
                         ,'BANNER'       --vgsUsr
                         ,sysdate
                         ,csStatUni);     --se agrega status Unico


   END LOOP; --- PRINCIPAL curEvalStd

   ps_error := vsTxtErr;
   return viProcede;

end F_MainXRut;

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
funcion F_EvaluaAlumnoActivo
objetivo : verificar que el alumno este como activo
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function F_EvaluaAlumnoActivo( pi_pidm number ) return number is

  vi_Existe    number(6);
  viProcedeAC  number(1);

cursor CurStatErr is
   select (SGBSTDN_STST_CODE || ' En Periodo ' || SGBSTDN_TERM_CODE_EFF) errcode
   from sgbstdn
   where sgbstdn_pidm = pi_pidm
   and   SGBSTDN_TERM_CODE_EFF = (select max(SGBSTDN_TERM_CODE_EFF)
                                  from sgbstdn
                                  where sgbstdn_pidm = pi_pidm);

begin

   viProcedeAC:= 1; -- valor de retrono (si existe = 1  no existe = 0)

   select count(1) into vi_Existe
   from sgbstdn
   where sgbstdn_pidm = pi_pidm
   and   SGBSTDN_STST_CODE = 'AS'
   and   SGBSTDN_TERM_CODE_EFF = (select max(SGBSTDN_TERM_CODE_EFF)
                                  from sgbstdn
                                  where sgbstdn_pidm = pi_pidm);

   --el alumno no existe y marco error
   if  vi_Existe = 0 then

      viProcedeAC := 0;
      vsTxtErr := 'Alumno InActivo Con Status ';

      for cStatErr in CurStatErr loop
         vsTxtErr := vsTxtErr || trim(cStatErr.errcode);
      end loop;

   end if;

   return viProcedeAC;

end F_EvaluaAlumnoActivo;

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
funcion F_EvaluaCaeAnterior
objetivo : verificar que el alumno por que se pregunta no tenga CAE en
           la tabla de Twacral en años anteriores
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function F_EvaluaCaeAnterior( pi_pidm number ) return number is

  viCAEAnterior  number(6);
  viProcedeCAE    number(1);
  viAnioAnt      number(4);

begin

   viProcedeCAE := 1; -- valor de retrono (si existe = 1  no existe = 0)

   -- año previo al que se procesa
   viAnioAnt   := vsYEAR - 1;

   -- contabilizacion en twacral  para determinar si tenia cae anterior..
   select count(*) into viCAEAnterior
   from twrcral
   where TWRCRAL_PIDM = pi_pidm
   and TWRCRAL_CRET_CODE = 'CAE'
   --md-03 and  substr(TWRCRAL_TERM_CODE,1,4)  <= viAnioAnt
   and  substr(TWRCRAL_TERM_CODE,1,4)  = viAnioAnt     -- md-03  solo anio anterior
   and TWRCRAL_DOCU_SEQ_NUM is not null ;              --md-03  aplicado

   --el alumno tiene CAE en Años anteriores
   if  viCAEAnterior >= 1 then

      vsTxtErr := vsTxtErr || ' Alumno Con CAE En Años Anteriores. ';
      viProcedeCAE := 0;

   end if;

   return viProcedeCAE;

end F_EvaluaCaeAnterior;


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
funcion F_Evalua70Prcnt
objetivo : verificar que el alumno las materias que estan inscritas en el periodo
           , al menos el 70% esten aprovadas.
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function F_Evalua70Prcntf( pi_pidm number ) return number is

  vi70Prcnt        number(6);
  viProcede70      number(1);
  viAnioAnt        number(4);
  viTermAnterior   varchar2(10);
  viTotalMaterias  number(4);
  viVerificaMate   number(4);
  viMateAprovada   number(4);
  viMateReprovada  number(4);
  viPorcentaje     number(5,2);
  viX              number(4);
  vsTermCode       varchar2(6);
  viTckn           number(2);
  vsCrn            varchar2(5);
  viTermPrevios    varchar2(10);
  viIncremento     number(3);       --md-03
  viPeriodos       number(2) := 3;  --md-03

-- crusor de total de materias inscritas
cursor CurMateriasInscritas is
       Select *
       From sfrstcr
       Where SFRSTCR_PIDM = pi_pidm
       AND SFRSTCR_TERM_CODE Like viTermAnterior
       and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
       And SFRSTCR_RSTS_CODE In ('RW','RE')
       and SFRSTCR_CRN  NOT IN  ( select SSBSECT_CRN                 --md-10start
                                    from ssbsect t  ,  SCBCRSE e 
                                   where SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                                     and SSBSECT_CRSE_NUMB    = SCBCRSE_CRSE_NUMB
                                     and SCBCRSE_CREDIT_HR_LOW = 0);           --md-10 end

--cursor de materias inscritas  y su tkrn_seq_num
cursor curCrnTckn is
       Select SHRTCKN_TERM_CODE, SHRTCKN_SEQ_NO, SHRTCKN_CRN
        From sfrstcr, shrtckn
        Where SFRSTCR_PIDM = pi_pidm
        AND SFRSTCR_TERM_CODE Like viTermAnterior
        And  SFRSTCR_RSTS_CODE In ('RW','RE')
        and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
        and SFRSTCR_PIDM = shrtckn_PIDM
        and SFRSTCR_TERM_CODE = shrtckn_TERM_CODE
        and SFRSTCR_CRN       = shrtckn_crn
        AND SFRSTCR_CRN NOT IN  ( select SSBSECT_CRN          --md-10 start
                                    from ssbsect t  ,  SCBCRSE e 
                                   where SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                                     and SSBSECT_CRSE_NUMB    = SCBCRSE_CRSE_NUMB
                                     and SCBCRSE_CREDIT_HR_LOW = 0)     --md-10 end    
        and shrtckn_TERM_CODE = ( select max(a.shrtckn_TERM_CODE)
                                    from shrtckn a
                                   where a.shrtckn_PIDM = pi_pidm
                                     and a.shrtckn_TERM_CODE Like viTermAnterior
                                     and a.SHRTCKN_CRN = SFRSTCR_CRN);

-- cursor de calificaciones de matarias en base si esta aprovada
cursor matAprovada is
   select  SHRGRDE_PASSED_IND
   from shrtckg sh, SHRGRDE
   where sh.shrtckg_PIDM = pi_pidm
   AND sh.shrtckg_TERM_CODE =  vsTermCode
   and sh.SHRTCKG_TCKN_SEQ_NO = viTckn
   AND sh.SHRTCKG_SEQ_NO = (select max(shh.SHRTCKG_SEQ_NO)
                              from shrtckg shh
                             where shh.shrtckg_PIDM = sh.shrtckg_PIDM
                               AND shh.shrtckg_TERM_CODE = sh.shrtckg_TERM_CODE
                               and shh.SHRTCKG_TCKN_SEQ_NO = sh.SHRTCKG_TCKN_SEQ_NO)
   and SHRGRDE_CODE = SHRTCKG_GRDE_CODE_FINAL
   and shrgrde_levl_code = 'LI';

-- cursor de contabilización de materias aprovadas y reprobadas.
-- en teoria solo regresa 2 registros Y , N  con cantidad.
cursor CurMateriaAprovadas is
   select  SHRGRDE_PASSED_IND aprovada , count(1) valor
   from shrtckg, SHRGRDE
   where shrtckg_PIDM = pi_pidm
   AND shrtckg_TERM_CODE LIKE viTermAnterior
   and SHRTCKG_TCKN_SEQ_NO in (Select SHRTCKN_SEQ_NO
                                 From sfrstcr, shrtckn
                                Where SFRSTCR_PIDM = pi_pidm
                                  AND SFRSTCR_TERM_CODE Like viTermAnterior
                                  And  SFRSTCR_RSTS_CODE In ('RW','RE')
                                  and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
                                  and SFRSTCR_PIDM = shrtckn_PIDM
                                  and SFRSTCR_TERM_CODE = shrtckn_TERM_CODE
                                  and SFRSTCR_CRN       = shrtckn_crn)
   and  shrtckg_term_code = (select max(b.shrtckg_term_code)
                               from shrtckg b
                              where b.shrtckg_PIDM = pi_pidm
                                AND b.shrtckg_TERM_CODE LIKE viTermAnterior
                                and b.SHRTCKG_TCKN_SEQ_NO = SHRTCKG_TCKN_SEQ_NO)
   and SHRGRDE_CODE = SHRTCKG_GRDE_CODE_FINAL
   and shrgrde_levl_code = 'LC'
   group by SHRGRDE_PASSED_IND;

-- cursor de materias que faltan por calificar
cursor cuMatSinCalificar is
      Select SFRSTCR_CRN
      From sfrstcr
      Where SFRSTCR_PIDM = pi_pidm
      AND SFRSTCR_TERM_CODE Like  viTermAnterior
      And SFRSTCR_RSTS_CODE In ('RW','RE')
      and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
      and SFRSTCR_CRN not in ( select SHRTCKN_CRN
                                 from shrtckn
                                Where shrtckn_PIDM = pi_pidm
                                  AND shrtckn_TERM_CODE Like  viTermAnterior)
      AND SFRSTCR_CRN NOT IN  ( select SSBSECT_CRN        --md-10 start
                                  from ssbsect t  ,  SCBCRSE e 
                                 where SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                                   and SSBSECT_CRSE_NUMB    = SCBCRSE_CRSE_NUMB
                                   and SCBCRSE_CREDIT_HR_LOW = 0);      --md-10 end                         ;

begin

    -- valor de retrono (inicia en 1 por cualquier error cambia a 0,
    --                   entonces se debe de considerar como fallido)
   viProcede70 := 1;
   vsTxtErr := '';

   -- obtener el año general de procesos CAE
   vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

   -- año previo al que se procesa
   viAnioAnt   := vsYEAR - 1;
   -- periodo previo
   viTermAnterior := viAnioAnt || '%';

   viTotalMaterias := 0;
   viVerificaMate  := 0;

   -- obtengo las materias inscritas hasta 3 años anteriores.
   -- md-03 start
   viIncremento := 0;
   While viIncremento <=  viPeriodos  loop

     -- tomando años anteriores
     viIncremento := viIncremento + 1;
     viAnioAnt   := vsYEAR - viIncremento;
     -- periodo previo
     viTermAnterior := viAnioAnt || '%';

      for cMateriaInscrita in CurMateriasInscritas loop
         viTotalMaterias := viTotalMaterias + 1 ;
      end loop;

      if viTotalMaterias >= 1  then
         -- si tiene materias hago incremento mayor para salir del loop
         viIncremento := viPeriodos + 1;
      end if;

   end loop;
   -- md-03 end

   -- alumno sin materias
   if viTotalMaterias = 0 then
      vsTxtErr := vsTxtErr || ' Alumno Sin Materias Inscritas. ';
      viProcede70 := 0;

   else   -- tiene materias continuo con validaciones.
      --  md-09 start
         viMateAprovada  := 0;
         viMateReprovada := 0;
         viPorcentaje    := 0;
         for curCrnTc in curCrnTckn loop

            vsTermCode := curCrnTc.SHRTCKN_TERM_CODE ;
            viTckn     := curCrnTc.SHRTCKN_SEQ_NO ;
            vsCrn      := curCrnTc.SHRTCKN_CRN ;

            -- sumando las materias aprovadas y reprobadas
            for crAprovado in matAprovada loop
              -- viPorcentaje := viPorcentaje + 1;
               if crAprovado.SHRGRDE_PASSED_IND = 'Y' then
                  viMateAprovada := viMateAprovada + 1;
               else
                  viMateReprovada := viMateReprovada + 1;
               end if;
               exit;  -- para que solo pase una vez.
            end loop;

         end loop;
         
         viPorcentaje := viMateAprovada / viTotalMaterias ;
         if viPorcentaje < ciPrcntAP then  --si es menor al % aprovatorio es error.
            vsTxtErr := vsTxtErr || ' No Cumplio El 70% ';
            viProcede70 := 0;
             
            if viMateAprovada + viMateReprovada < viTotalMaterias then
               -- faltan materias por calificar. 
               vsTxtErr := vsTxtErr || ' por Materias sin Calificar. CRN  ';
               viProcede70 := 0;

               -- obtener el detalle de CRN sin Calificar
               for cuMSCalificar in cuMatSinCalificar loop

                 vsTxtErr := substr(vsTxtErr ||  cuMSCalificar.SFRSTCR_CRN || ' , ',1,200);

               end loop;

               -- quitando la ultima coma
               viX := length ( vsTxtErr );
               vsTxtErr := substr(vsTxtErr, 1 , viX - 2);                  
                             
            end if; 
             
         else
            -- todo ok procede regla
            viProcede70 := 1;
         end if;
      
      -- md-09 end
   end if;

   vsTxtErr := substr(vsTxtErr,1,200);

   return viProcede70;

end F_Evalua70Prcntf;

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
funcion F_Evalua70Prcnt
objetivo : verificar que el alumno las materias que estan inscritas en el periodo
           , al menos el 70% esten aprovadas.
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function F_Evalua70Prcnt( pi_pidm number, ps_error out varchar  ) return number is

  vi70Prcnt        number(6);
  viProcede70      number(1);
  viAnioAnt        number(4);
  viTermAnterior   varchar2(10);
  viTotalMaterias  number(4);
  viVerificaMate   number(4);
  viMateAprovada   number(4);
  viMateReprovada  number(4);
  viPorcentaje     number(5,2);
  viX              number(4);
  vsTermCode       varchar2(6);
  viTckn           number(2);
  vsCrn            varchar2(5);
  viIncremento     number(3);       --md-03
  viPeriodos       number(2) := 3;  --md-03

-- crusor de total de materias inscritas
cursor CurMateriasInscritas is
       Select *
       From sfrstcr
       Where SFRSTCR_PIDM = pi_pidm
       AND SFRSTCR_TERM_CODE Like viTermAnterior
       And  SFRSTCR_RSTS_CODE In ('RW','RE')
       and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
       and SFRSTCR_CRN NOT IN (select SSBSECT_CRN      --md-10 start
                                 from ssbsect t  ,  SCBCRSE e 
                                where SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                                  and SSBSECT_CRSE_NUMB    = SCBCRSE_CRSE_NUMB
                                  and SCBCRSE_CREDIT_HR_LOW = 0) ;   --md-10 end

--cursor de materias inscritas  y su tkrn_seq_num
cursor curCrnTckn is
       Select SHRTCKN_TERM_CODE, SHRTCKN_SEQ_NO, SHRTCKN_CRN
        From sfrstcr, shrtckn
        Where SFRSTCR_PIDM = pi_pidm
        AND SFRSTCR_TERM_CODE Like viTermAnterior
        And  SFRSTCR_RSTS_CODE In ('RW','RE')
        and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
        and SFRSTCR_PIDM = shrtckn_PIDM
        and SFRSTCR_TERM_CODE = shrtckn_TERM_CODE
        and SFRSTCR_CRN       = shrtckn_crn
        AND SFRSTCR_CRN NOT IN  ( select SSBSECT_CRN          --md-10 start
                                    from ssbsect t  ,  SCBCRSE e --materia ofertada
                                   where SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                                     and SSBSECT_CRSE_NUMB    = SCBCRSE_CRSE_NUMB
                                     and SCBCRSE_CREDIT_HR_LOW = 0)  --md-10 end
        and shrtckn_TERM_CODE = ( select max(a.shrtckn_TERM_CODE)
                                    from shrtckn a
                                   where a.shrtckn_PIDM = pi_pidm
                                     and a.shrtckn_TERM_CODE Like viTermAnterior
                                     and a.SHRTCKN_CRN = SFRSTCR_CRN);

-- cursor de calificaciones de matarias en base si esta aprovada
cursor matAprovada is
   select  SHRGRDE_PASSED_IND
   from shrtckg sh, SHRGRDE
   where sh.shrtckg_PIDM = pi_pidm
   AND sh.shrtckg_TERM_CODE =  vsTermCode
   and sh.SHRTCKG_TCKN_SEQ_NO = viTckn
   AND sh.SHRTCKG_SEQ_NO = (select max(shh.SHRTCKG_SEQ_NO)
                            from shrtckg shh
                            where shh.shrtckg_PIDM = sh.shrtckg_PIDM
                            AND shh.shrtckg_TERM_CODE = sh.shrtckg_TERM_CODE
                            and shh.SHRTCKG_TCKN_SEQ_NO = sh.SHRTCKG_TCKN_SEQ_NO)
   and SHRGRDE_CODE = SHRTCKG_GRDE_CODE_FINAL
   and shrgrde_levl_code = 'LI';

-- cursor de contabilización de materias aprovadas y reprobadas.
-- en teoria solo regresa 2 registros Y , N  con cantidad.
cursor CurMateriaAprovadas is
   select  SHRGRDE_PASSED_IND aprovada , count(1) valor
   from shrtckg, SHRGRDE
   where shrtckg_PIDM = pi_pidm
   AND shrtckg_TERM_CODE LIKE viTermAnterior
   and SHRTCKG_TCKN_SEQ_NO in (Select SHRTCKN_SEQ_NO
                                From sfrstcr, shrtckn
                                Where SFRSTCR_PIDM = pi_pidm
                                AND SFRSTCR_TERM_CODE Like viTermAnterior
                                And  SFRSTCR_RSTS_CODE In ('RW','RE')
                                and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
                                and SFRSTCR_PIDM = shrtckn_PIDM
                                and SFRSTCR_TERM_CODE = shrtckn_TERM_CODE
                                and SFRSTCR_CRN       = shrtckn_crn)
   and  shrtckg_term_code = (select max(b.shrtckg_term_code)
                             from shrtckg b
                             where b.shrtckg_PIDM = pi_pidm
                             AND b.shrtckg_TERM_CODE LIKE viTermAnterior
                             and b.SHRTCKG_TCKN_SEQ_NO = SHRTCKG_TCKN_SEQ_NO)
   and SHRGRDE_CODE = SHRTCKG_GRDE_CODE_FINAL
   and shrgrde_levl_code = 'LC'
   group by SHRGRDE_PASSED_IND;

-- cursor de materias que faltan por calificar
cursor cuMatSinCalificar is
      Select SFRSTCR_CRN
      From sfrstcr
      Where SFRSTCR_PIDM = pi_pidm
      AND SFRSTCR_TERM_CODE Like  viTermAnterior
      And SFRSTCR_RSTS_CODE In ('RW','RE')
      and nvl(SFRSTCR_ERROR_FLAG,'x') <> 'D'
      and SFRSTCR_CRN not in ( select SHRTCKN_CRN
                                 from shrtckn
                                Where shrtckn_PIDM = pi_pidm
                                  AND shrtckn_TERM_CODE Like  viTermAnterior)
      AND SFRSTCR_CRN NOT IN ( select SSBSECT_CRN        --md-10 start
                                 from ssbsect t  ,  SCBCRSE e 
                                where SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                                  and SSBSECT_CRSE_NUMB    = SCBCRSE_CRSE_NUMB
                                  and SCBCRSE_CREDIT_HR_LOW = 0);   --md-10 end                               ;

begin

    -- valor de retrono (inicia en 1 por cualquier error cambia a 0,
    --                   entonces se debe de considerar como fallido)
   viProcede70 := 1;

   vsTxtErr := '';

   -- obtener el año general de procesos CAE
   vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

   -- año previo al que se procesa
   viAnioAnt   := vsYEAR - 1;
   -- periodo previo
   viTermAnterior := viAnioAnt || '%';

   viTotalMaterias := 0;
   viVerificaMate  := 0;

   -- obtengo las materias inscritas hasta 3 años anteriores.
   -- md-03 start
   viIncremento := 0;
   While viIncremento <=  viPeriodos  loop

     -- tomando años anteriores
     viIncremento := viIncremento + 1;
     viAnioAnt   := vsYEAR - viIncremento;
     -- periodo previo
     viTermAnterior := viAnioAnt || '%';

      for cMateriaInscrita in CurMateriasInscritas loop
         viTotalMaterias := viTotalMaterias + 1 ;
      end loop;

      if viTotalMaterias >= 1  then
         -- si tiene materias hago incremento mayor para salir del loop
         viIncremento := viPeriodos + 1;
      end if;

   end loop;
   -- md-03 end

   -- alumno sin materias
   if viTotalMaterias = 0 then
      vsTxtErr := vsTxtErr || ' Alumno Sin Materias Inscritas. ';
      viProcede70 := 0;

   else   -- tiene materias continuo con validaciones.
     -- md-09 start
         viMateAprovada  := 0;
         viMateReprovada := 0;
         viPorcentaje    := 0;
         for curCrnTc in curCrnTckn loop  -- materias inscritas. 

            vsTermCode := curCrnTc.SHRTCKN_TERM_CODE ;
            viTckn     := curCrnTc.SHRTCKN_SEQ_NO ;
            vsCrn      := curCrnTc.SHRTCKN_CRN ;

            for crAprovado in matAprovada loop -- sumando las materias aprovadas y reprobadas
               --viPorcentaje := viPorcentaje + 1;
               if crAprovado.SHRGRDE_PASSED_IND = 'Y' then
                  viMateAprovada := viMateAprovada + 1;
               else
                  viMateReprovada := viMateReprovada + 1;
               end if;
               exit;  -- para que solo pase una vez.
            end loop;

         end loop;
         
         viPorcentaje := viMateAprovada / viTotalMaterias ;
         if viPorcentaje < ciPrcntAP then  --si es menor al % aprovatorio es error.
            vsTxtErr := vsTxtErr || ' No Cumplio El 70% ';
            viProcede70 := 0;
             
            if viMateAprovada + viMateReprovada < viTotalMaterias then
               -- faltan materias por calificar. 
               vsTxtErr := vsTxtErr || ' por Materias sin Calificar. CRN  ';
               viProcede70 := 0;

               -- obtener el detalle de CRN sin Calificar
               for cuMSCalificar in cuMatSinCalificar loop

                 vsTxtErr := substr(vsTxtErr ||  cuMSCalificar.SFRSTCR_CRN || ' , ',1,200);

               end loop;

               -- quitando la ultima coma
               viX := length ( vsTxtErr );
               vsTxtErr := substr(vsTxtErr, 1 , viX - 2);                  
                             
            end if; 
             
         else
            -- todo ok procede regla
            viProcede70 := 1;
         end if;

    --md-09 end 
   end if;

   ps_error :=  substr(vsTxtErr,1,200);

   return viProcede70;

end F_Evalua70Prcnt;

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
funcion F_EvaluaTieneMatricula
objetivo : verificar que el alumno por que se pregunta esta Matriculado
           en el perido anterior (año)
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function F_EvaluaTieneMatricula( pi_pidm number ) return number is

  viMatAnterior  number(6);
  viProcedeMat    number(1);
  viAnioAnt      number(4);
  vsPeriodosAnt  varchar2(10);

begin
   vsTxtErr := '';

   vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

   viProcedeMat := 1; -- valor de retrono (si existe = 1  no existe = 0)

   -- año previo al que se procesa
   viAnioAnt   := vsYEAR - 1;
   vsPeriodosAnt :=  viAnioAnt || '%';

   select count(*) into viMatAnterior
   from twbcntr
   where TWBCNTR_PIDM =  pi_pidm
   and TWBCNTR_TERM_CODE like vsPeriodosAnt;


   --el alumno No tiene matricula en periodo inmediato anterior.
   if  viMatAnterior <= 0  then

      vsTxtErr := vsTxtErr || ' Alumno Sin Matricula en Periodo Anterior. ';
      viProcedeMat := 0;

   end if;

   return viProcedeMat;

end F_EvaluaTieneMatricula;

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
funcion F_EvaluaTieneMatriculaActual
objetivo : verificar que el alumno por que se pregunta esta Matriculado
           en el perido actual
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function F_EvaluaTieneMatriculaActual( pi_pidm number ) return number is

  viMatActual  number(6);
  viProcedeMat    number(1);
  viAnio      number(4);
  vsPeriodos  varchar2(10);

begin

   vsTxtErr := '';

   vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

   viProcedeMat := 1; -- valor de retrono (si existe = 1  no existe = 0)

   -- año al que se procesa
   viAnio  := vsYEAR ;
   vsPeriodos :=  viAnio || '%';

   select count(*) into viMatActual
   from twbcntr
   where TWBCNTR_PIDM =  pi_pidm
   and TWBCNTR_TERM_CODE like vsPeriodos;

   --el alumno No tiene matricula en periodo actual.
   if  viMatActual <= 0  then

      vsTxtErr := vsTxtErr || ' Alumno Sin Matricula en Periodo Actual. ';
      viProcedeMat := 0;

   end if;

   return viProcedeMat;

end F_EvaluaTieneMatriculaActual;


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
funcion F_EvaluaEsEgresado
objetivo : verificar que el alumno su ultimo status sea Egresado
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function F_EvaluaEsEgresado( pi_pidm number ) return number is

  viEsEgresado  number(6);
  viProcedeEgre  number(1);

begin

   vsTxtErr := '';

   viProcedeEgre := 1; -- valor de retrono (si procede = 1  no procede = 0)

   select count(*) into viEsEgresado
   from sgbstdn
   where sgbstdn_pidm = pi_pidm
   and SGBSTDN_STST_CODE = 'EG'    -- status de egresado
   and SGBSTDN_TERM_CODE_EFF = ( select max(SGBSTDN_TERM_CODE_EFF)
                                 from sgbstdn
                                 where sgbstdn_pidm = pi_pidm);

   --el alumno No tiene matricula en periodo inmediato anterior.
   if  viEsEgresado <= 0  then

      vsTxtErr := vsTxtErr || ' Alumno es Egresado. ';
      viProcedeEgre := 0;

   end if;

   return viProcedeEgre;

end F_EvaluaEsEgresado;

--md-05 start
Function F_AltaTwacral ( pi_pidm number , ps_status varchar , ps_error out varchar  ) Return number is

vsMajr      varchar2(4);
viAlta       number(16,2);
vsYEAR       varchar2(4);
vsPeriodos   VARCHAR2(8);
vsSigAnio    varchar2(4);
vsMontoBeca  number(16,2);
vsY          varchar2(1) := 'Y';
vsExiste     number(3);
vsStatus     varchar2(6);

cursor cu_Mayor is
      select s.SGBSTDN_TERM_CODE_EFF, s.SGBSTDN_MAJR_CODE_1, s.SGBSTDN_PIDM
      from SGBSTDN s
      where s.SGBSTDN_PIDM = pi_pidm
      AND  s.SGBSTDN_TERM_CODE_EFF = ( SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                        FROM SGBSTDN SS
                                        WHERE SS.SGBSTDN_PIDM = s.SGBSTDN_PIDM);

cursor cu_beca is
    select TWBCRET_AMOUNT
    from twbcret
    where TWBCRET_MAJR_CODE = vsMajr
    AND TWBCRET_CODE = csCAE
    and TWBCRET_TERM_CODE = vsPeriodos;

-- md-07 start
cursor cu_StdnActivo is
    select count(1)  exite
    from sgbstdn t
    where t.SGBSTDN_PIDM = pi_pidm
    and t.SGBSTDN_STST_CODE in (csAS, csAL)
    and t.SGBSTDN_TERM_CODE_EFF = (select max( tt.SGBSTDN_TERM_CODE_EFF)
                                   from sgbstdn tt
                                   where tt.SGBSTDN_PIDM = t.SGBSTDN_PIDM );
-- md-07 end

begin

   -- incializando variables.
    vsMajr := null;
    vsMontoBeca := null;
    viAlta := 0;    -- 0 no procede 1 si..
    vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');
    -- se buscara valor de beca cae en el sig anio al configurado en el
    -- proceso cae y solo en periodo 'xxxx10'
   -- vsSigAnio := vsYEAR + 1;  -- md-06
    vsSigAnio := vsYEAR ;  -- md-06
    vsPeriodos :=  vsSigAnio || '10';
    vsExiste := 0;

   -- md-07 statt
    --- verifica que el alumno este activo
    select count(1)  exite  into vsExiste
    from sgbstdn t
    where t.SGBSTDN_PIDM = pi_pidm
    and t.SGBSTDN_STST_CODE in (csAS, csAL)
    and t.SGBSTDN_TERM_CODE_EFF = (select max( tt.SGBSTDN_TERM_CODE_EFF)
                                   from sgbstdn tt
                                   where tt.SGBSTDN_PIDM = t.SGBSTDN_PIDM );
    if vsExiste <= 0 then
       ps_error := ' Alumno No Activo ';
       return viAlta;
    else
       --dejando la variable otra vez igual
       vsExiste := 0;
    end if ;

    -- verifica que el status del alumno este preseleccionado sin restriccion
    select COUNT(1) valido into vsExiste
    from twvcaes
    where upper(TWVCAES_DESCRIPTION) like '%PRESELECCIONADO%'
    AND NOT upper(TWVCAES_DESCRIPTION) like '%RESTRICC%'
    AND TWVCAES_CODE = ps_status;

    if vsExiste <= 0 then
       ps_error := ' Glosa No Válida para  Alta en TWACRAL ';
       return viAlta;
    else
       --dejando la variable otra vez igual
       vsExiste := 0;
    end if ;

   --md-07 end

   -- buscando Majr
    for cuMayor in cu_Mayor loop
       vsMajr := cuMayor.SGBSTDN_MAJR_CODE_1;
    end looP;
    if vsMajr = null then
       ps_error := ' Sin Majr ';
       return viAlta;
    end if ;

    -- buscando monto de la beca
    for cuBeca in cu_beca loop
        vsMontoBeca := cuBeca.TWBCRET_AMOUNT;
    end loop;
    if vsMontoBeca  is null then
      ps_error := ' Monto CAE no Configurado ';
      return viAlta;
    end if ;

    select count(*) into vsExiste
    from twrcral
    where TWRCRAL_PIDM = pi_pidm
    and TWRCRAL_CRET_CODE = csCAE
    and TWRCRAL_TERM_CODE = vsPeriodos
    and TWRCRAL_MAJR_CODE = vsMajr;

    if vsExiste = 0 then

        BEGIN
           insert into twrcral(
                               TWRCRAL_PIDM ,
                               TWRCRAL_CRET_CODE,
                               TWRCRAL_TERM_CODE,
                               TWRCRAL_MAJR_CODE,
                               TWRCRAL_NEW_ENRL_IND,
                               TWRCRAL_DOCU_SEQ_NUM,
                               TWRCRAL_ACTIVITY_DATE,
                               TWRCRAL_USER         ,
                               TWRCRAL_APP_AMOUNT  )
                          values (pi_pidm
                                 , csCAE
                                 , vsPeriodos
                                 , vsMajr
                                 , vsY
                                 , null
                                 , sysdate
                                 , 'BANINST'
                                 , vsMontoBeca);

           --ALTA EXITOSA
              ps_error :=  'Alta en twacral ';
              return vsMontoBeca;

         EXCEPTION
                 WHEN OTHERS THEN
                   -- Consider logging the error and then re-raise
                   ps_error := ' error en alta';
                   return viAlta;
        END;
    else
      ps_error := ' Con Cae Existente previamente ';
      return viAlta;
    end if;


end F_AltaTwacral;

Function F_AltaTwacralHistorica ( pi_pidm number , ps_error out varchar  ) Return number is

vsMajr      varchar2(4);
viAlta       number(16,2);
vsYEAR       varchar2(4);
vsPeriodos   VARCHAR2(8);
vsSigAnio    varchar2(4);
vsMontoBeca  number(16,2);
vsY          varchar2(1) := 'Y';
vsExiste     number(3);
vsStatus     varchar2(6);

cursor cu_Mayor is
      select s.SGBSTDN_TERM_CODE_EFF, s.SGBSTDN_MAJR_CODE_1, s.SGBSTDN_PIDM
      from SGBSTDN s
      where s.SGBSTDN_PIDM = pi_pidm
      AND  s.SGBSTDN_TERM_CODE_EFF = ( SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                        FROM SGBSTDN SS
                                        WHERE SS.SGBSTDN_PIDM = s.SGBSTDN_PIDM);

cursor cu_beca is
    select TWBCRET_AMOUNT
    from twbcret
    where TWBCRET_MAJR_CODE = vsMajr
    AND TWBCRET_CODE = csCAE
    and TWBCRET_TERM_CODE = vsPeriodos;

-- md-07 start
cursor cu_StdnActivo is
    select count(1)  exite
    from sgbstdn t
    where t.SGBSTDN_PIDM = pi_pidm
    and t.SGBSTDN_STST_CODE in (csAS, csAL)
    and t.SGBSTDN_TERM_CODE_EFF = (select max( tt.SGBSTDN_TERM_CODE_EFF)
                                   from sgbstdn tt
                                   where tt.SGBSTDN_PIDM = t.SGBSTDN_PIDM );
-- md-07 end

begin

   -- incializando variables.
    vsMajr := null;
    vsMontoBeca := null;
    viAlta := 0;    -- 0 no procede 1 si..
    vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');
    -- se buscara valor de beca cae en el sig anio al configurado en el
    -- proceso cae y solo en periodo 'xxxx10'
   -- vsSigAnio := vsYEAR + 1;  -- md-06
    vsSigAnio := vsYEAR ;  -- md-06
    vsPeriodos :=  vsSigAnio || '10';
    vsExiste := 0;

   -- md-07 statt
    --- verifica que el alumno este activo
    select count(1)  exite  into vsExiste
    from sgbstdn t
    where t.SGBSTDN_PIDM = pi_pidm
    and t.SGBSTDN_STST_CODE in (csAS, csAL)
    and t.SGBSTDN_TERM_CODE_EFF = (select max( tt.SGBSTDN_TERM_CODE_EFF)
                                   from sgbstdn tt
                                   where tt.SGBSTDN_PIDM = t.SGBSTDN_PIDM );
    if vsExiste <= 0 then
       ps_error := ' Alumno No Activo ';
       return viAlta;
    else
       --dejando la variable otra vez igual
       vsExiste := 0;
    end if ;

   -- no se verifica status para historica
--   -- verifica que el status del alumno este preseleccionado sin restriccion
--    select COUNT(1) valido into vsExiste
--    from twvcaes
--    where upper(TWVCAES_DESCRIPTION) like '%PRESELECCIONADO%'
--    AND NOT upper(TWVCAES_DESCRIPTION) like '%RESTRICC%'
--    AND TWVCAES_CODE = ps_status;
--
--    if vsExiste <= 0 then
--       ps_error := ' Glosa No Válida para  Alta en TWACRAL ';
--       return viAlta;
--    else
--       --dejando la variable otra vez igual
--       vsExiste := 0;
--    end if ;


   --md-07 end

   -- buscando Majr
    for cuMayor in cu_Mayor loop
       vsMajr := cuMayor.SGBSTDN_MAJR_CODE_1;
    end looP;
    if vsMajr = null then
       ps_error := ' Sin Majr ';
       return viAlta;
    end if ;

    -- buscando monto de la beca
    for cuBeca in cu_beca loop
        vsMontoBeca := cuBeca.TWBCRET_AMOUNT;
    end loop;
    if vsMontoBeca  is null then
      ps_error := ' Monto CAE no Configurado ';
      return viAlta;
    end if ;

    select count(*) into vsExiste
    from twrcral
    where TWRCRAL_PIDM = pi_pidm
    and TWRCRAL_CRET_CODE = csCAE
    and TWRCRAL_TERM_CODE = vsPeriodos
    and TWRCRAL_MAJR_CODE = vsMajr;

    if vsExiste = 0 then

        BEGIN
           insert into twrcral(
                               TWRCRAL_PIDM ,
                               TWRCRAL_CRET_CODE,
                               TWRCRAL_TERM_CODE,
                               TWRCRAL_MAJR_CODE,
                               TWRCRAL_NEW_ENRL_IND,
                               TWRCRAL_DOCU_SEQ_NUM,
                               TWRCRAL_ACTIVITY_DATE,
                               TWRCRAL_USER         ,
                               TWRCRAL_APP_AMOUNT  )
                          values (pi_pidm
                                 , csCAE
                                 , vsPeriodos
                                 , vsMajr
                                 , vsY
                                 , null
                                 , sysdate
                                 , 'BANINST'
                                 , vsMontoBeca);

           --ALTA EXITOSA
              ps_error :=  'Alta en twacral ';
              return vsMontoBeca;

         EXCEPTION
                 WHEN OTHERS THEN
                   -- Consider logging the error and then re-raise
                   ps_error := ' error en alta';
                   return viAlta;
        END;
    else
      ps_error := ' Con Cae Existente previamente ';
      return viAlta;
    end if;


end F_AltaTwacralHistorica;

--md-05 end

END pk_Cae_Regla_70;
/
