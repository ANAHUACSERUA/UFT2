CREATE OR REPLACE PACKAGE BODY BANINST1.kwacrev IS
/*
           Tarea: Registro de criterios de evaluación
--         Fecha: 25/10/2006.
           Autor: GEPC
        Objetivo: Asignar los criterios de evaluación alos cursos y alumnos inscritos a ellos

    Modificación: 14/04/2008
                  GEPC
                  Se agrego el filtro SOBTERM_DYNAMIC_SCHED_TERM_IND = 'Y' en el cursor cuTerm del
                  procedimiento P_CursoPorPeriodo.

                  Para evitar que se muestre la Programación Académica de periodos futuros que
                  apenas se capturando y muchas ocasiones los profesores aun no comenta o avisa
                  que darán esas materias


    Modificación: 26/09/2008
                  GEPC
                  Agregar el PIDM de profesor que registra las calificaciones


    Modificación: 01/09/2009
                  GEPC
                  --Fue actualizado el código de la aplicación por que guardaba el tipo de modalidad
                    de evaluación como "undefined", esto se debe a un error de JavaScript por usar un
                    navegador de Intenet diferente a "IE"


    Modificación: 09/09/2009
                  GEPC
                  -- Cambio de formato en la letra para la selección de componentes

    Modificación: 01/09/2010
                  GEPC
                  * Se cambio la propiedad "alt" por "label" del tag "<option>" del "objeto <select name="psName">"
                    del procedimiento "P_DefinicionDeComponentes"

    mod :   md-01
           se hacen las adecuaciones para su funcionameinto en UFT
           Roman Ruiz
           20/abr/2014

    mod : md-02
          se regresa los codigos y no la descripcion en el campo de SHRGCOM_NAME
          roman ruiz
          17/may/2014}

    mod : md-03
         se agrega la vaidacion de fecha a no permitir modificar..
         roman ruiz
         27-jun-2014

    mod : md-04
         cambio en formatos y titulos .
         roman ruiz
         03-jul-2014



*/

  TYPE reg_criterios IS RECORD(rCode SWVCOMP.SWVCOMP_CODE%TYPE,
                               rDesc SWVCOMP.SWVCOMP_DESC%TYPE,
                               rTipo SWVCOMP.SWVCOMP_TIPO%TYPE,
                               rPond SWVCOMP.SWVCOMP_PONDERACION%TYPE,
                               rMinA SWVCOMP.SWVCOMP_GRADE_MIN_APRO%TYPE
                              );

  TYPE tableCriterios IS TABLE OF reg_criterios INDEX BY BINARY_INTEGER;
  TYPE tablaCRN       IS TABLE OF VARCHAR2(6);

  tabCrit     tableCriterios;
  global_pidm spriden.spriden_pidm%type;
  vgsTerm     VARCHAR2(6) := NULL;
  vgsCrnn     VARCHAR2(6) := NULL;
  vgnFechaEval        NUMBER := 0;

  cs1        CONSTANT VARCHAR2(1)  := '1';
 -- csF        CONSTANT VARCHAR2(1)  := 'F';
  csM        CONSTANT VARCHAR2(1)  := 'M';
  csN        CONSTANT VARCHAR2(1)  := 'N';
  csY        CONSTANT VARCHAR2(1)  := 'Y';
  csS        CONSTANT VARCHAR2(1)  := 'S';
  csC        CONSTANT VARCHAR2(1)  := 'C';
  csP        CONSTANT VARCHAR2(1)  := 'P';
  csEsp      CONSTANT VARCHAR2(1)  := ' ';
  csF         CONSTANT VARCHAR2(1) := 'F';
  csAst      CONSTANT VARCHAR2(1)  := '*';
  csNull     CONSTANT VARCHAR2(1)  := NULL;
  csLC       CONSTANT VARCHAR2(2)  := 'LC';
  csLT       CONSTANT VARCHAR2(2)  := 'LT';
  csOE       CONSTANT VARCHAR2(2)  := 'OE';
  csRW       CONSTANT VARCHAR2(2)  := 'RW';
  csRE       CONSTANT VARCHAR2(2)  := 'RE';
  cs10       CONSTANT VARCHAR2(2)  := '10';
  csPAG      CONSTANT VARCHAR2(3)  := 'PAG';
  csCRE      CONSTANT VARCHAR2(3)  := 'CRE';
  cs10p0     CONSTANT VARCHAR2(4)  := '10.0';
  cs90p0     CONSTANT VARCHAR2(4)  := '90.0';
  cs99p99    CONSTANT VARCHAR2(5)  := '99.99';
  csFinal    CONSTANT VARCHAR2(5)  := 'Final';
  cs9990p99  CONSTANT VARCHAR2(7)  := '9990.99';
  csParcial  CONSTANT VARCHAR2(7)  := 'Parcial';
  cs99990p99 CONSTANT VARCHAR2(8)  := '99990.99';
  csDDMMYYYY CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
  csUser     CONSTANT VARCHAR2(32) := USER;
  cdSysDate  CONSTANT DATE         := SYSDATE;
  cn0        CONSTANT NUMBER(1)    := 0;
  cn1        CONSTANT NUMBER(1)    := 1;
  cn2        CONSTANT NUMBER(1)    := 2;
  cn10       CONSTANT NUMBER(2)    := 10;



  CURSOR cuCalulaGrade(psTerm VARCHAR2,
                       psCrn  VARCHAR2,
                       psIncl SHRGCOM.SHRGCOM_INCL_IND%TYPE,
                       pnPidm NUMBER DEFAULT NULL
                      ) IS
          SELECT SHRMRKS_PIDM                                                               AS Pidm,
                 shkegrb.f_get_grade_code('ESCALALC',
                 (SUM(SHRGCOM_WEIGHT * (SHRMRKS_PERCENTAGE/100))/SUM (shrgcom_weight))*100) AS Grade,
                 --SUM(TO_NUMBER(SHRMRKS_GRDE_CODE,cs99p99) * SHRGCOM_WEIGHT)/SUM(SHRGCOM_WEIGHT) AS Grade,
                 COUNT(DISTINCT SHRGCOM_ID)                                                 AS gcomCrit,
                 COUNT(DISTINCT DECODE(SHRMRKS_GRDE_CODE,NULL,NULL,SHRMRKS_GCOM_ID))        AS mrksCrit
            FROM SHRMRKS, SHRGCOM
           WHERE EXISTS (SELECT NULL
                           FROM SFRSTCR
                          WHERE SFRSTCR_RSTS_CODE IN (csRW,csRE)
                            AND SFRSTCR_PIDM       = SHRMRKS_PIDM
                            AND SFRSTCR_CRN        = psCrn
                            AND SFRSTCR_TERM_CODE  = psTerm
                           AND (SFRSTCR_ERROR_FLAG <> csF  OR SFRSTCR_ERROR_FLAG IS NULL)
                        )
             AND SHRMRKS_TERM_CODE = psTerm
             AND SHRMRKS_CRN       = psCrn
             AND SHRMRKS_GCOM_ID   = SHRGCOM_ID
             AND SHRMRKS_TERM_CODE = SHRGCOM_TERM_CODE
             AND SHRMRKS_CRN       = SHRGCOM_CRN
             AND SHRGCOM_INCL_IND  = psIncl
             AND (SHRMRKS_PIDM     = pnPidm OR pnPidm IS NULL)
            GROUP BY SHRMRKS_PIDM;

  CURSOR cuCalulaGradeF(psTerm VARCHAR2,
                        psCrn  VARCHAR2,
                        psIncl SHRGCOM.SHRGCOM_INCL_IND%TYPE,
                        pnPidm NUMBER DEFAULT NULL
                       ) IS
         SELECT SHRMRKS_PIDM                                                               AS Pidm,
                shkegrb.f_get_grade_code('ESCALALC',
                (SUM(SHRGCOM_WEIGHT * (SHRMRKS_PERCENTAGE/100))/SUM (shrgcom_weight))*100) AS Grade,
                --SUM(TO_NUMBER(SHRMRKS_GRDE_CODE,cs99p99) * SHRGCOM_WEIGHT)/SUM(SHRGCOM_WEIGHT) AS Grade,
                COUNT(DISTINCT SHRGCOM_ID)                                                 AS gcomCrit,
                COUNT(DISTINCT DECODE(SHRMRKS_GRDE_CODE,NULL,NULL,SHRMRKS_GCOM_ID))        AS mrksCrit
           FROM SHRMRKS, SHRGCOM
          WHERE SHRMRKS_TERM_CODE = psTerm
            AND SHRMRKS_CRN       = psCrn
            AND SHRMRKS_GCOM_ID   = SHRGCOM_ID
            AND SHRMRKS_TERM_CODE = SHRGCOM_TERM_CODE
            AND SHRMRKS_CRN       = SHRGCOM_CRN
            AND (SHRMRKS_PIDM     = pnPidm OR pnPidm IS NULL)
            AND (SHRGCOM_INCL_IND = psIncl OR psIncl = cs1)
            AND EXISTS (SELECT NULL
                          FROM SFRSTCR
                         WHERE SFRSTCR_RSTS_CODE IN (csRW,csRE)
                           AND SFRSTCR_PIDM       = SHRMRKS_PIDM
                           AND SFRSTCR_CRN        = psCrn
                           AND SFRSTCR_TERM_CODE  = psTerm
                           AND (SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL)

                       )
            AND EXISTS (SELECT NULL
                          FROM SHRGCOM M
                         WHERE M.SHRGCOM_TERM_CODE = psTerm
                           AND M.SHRGCOM_CRN       = psCrn
                           AND M.SHRGCOM_INCL_IND  = csF
                           AND psIncl              = cs1
                       )
          GROUP BY SHRMRKS_PIDM;

  --cuComponentes
  CURSOR cuComponentes(psTerm VARCHAR2,
                       psCrn  VARCHAR2,
                       pnId   NUMBER DEFAULT NULL) IS
         SELECT SHRGCOM_SEQ_NO                              AS Seqc,
                SHRGCOM_NAME                                AS Name,
                SHRGCOM_DESCRIPTION                         AS Desk,
                TO_CHAR(SHRGCOM_WEIGHT,cs9990p99)           AS Weig,
                TO_CHAR(SHRGCOM_TOTAL_SCORE,cs99990p99)     AS Scor,
                TO_CHAR(SHRGCOM_DATE,csDDMMYYYY)            AS Datt,
                SHRGCOM_INCL_IND                            AS Incl,
                SHRGCOM_GRADE_SCALE                         AS Scal,
                TO_CHAR(SHRGCOM_MIN_PASS_SCORE,cs9990p99)   AS Pass,
                SHRGCOM_ID                                  AS Iddi,
                (SELECT SHBGSCH_DESCRIPTION
                   FROM SHBGSCH
                  WHERE SHBGSCH_NAME = SHRGCOM_GRADE_SCALE)        AS scalDesc,
                DECODE(SHRGCOM_INCL_IND,csM,csParcial,csF,csFinal) AS InclDesc,
                DECODE(SWVCOMP_TIPO,csM,cn1,csF,cn2)               AS compTipo,
                SHRGCOM_PASS_IND                            AS Must      --md-01
           FROM SHRGCOM,SWVCOMP
          WHERE SHRGCOM_NAME      = SWVCOMP_CODE -- md-02  --SWVCOMP_DESC     --md-01
            and SHRGCOM_INCL_IND  = SWVCOMP_TIPO     --md-01
            AND SHRGCOM_TERM_CODE = psTerm
            AND SHRGCOM_CRN       = psCrn
            AND (SHRGCOM_ID = pnId OR pnId IS NULL)
          ORDER BY compTipo,
                   SWVCOMP_ORDEN,
                   SHRGCOM_SEQ_NO;

  --LA FUNCION RETORNA SI YA FUE ROLADA LA CALIFICACIÓN.
  FUNCTION rolado(psTerm VARCHAR2,
                  psCrn  VARCHAR2
                 ) RETURN INTEGER;

  --DEVUELVE EL TOTAL DE LAS PONDERACIONES POR TIPO DE EVALUACION
  FUNCTION ponderacion(psTerm VARCHAR2,
                       psCRn  VARCHAR2,
                       psIncl VARCHAR2 DEFAULT NULL
                      ) RETURN NUMBER;

  -- devuelve si se encuntra en un periodo valida para dar de alta calificaciones.
  FUNCTION F_Fecha(psTerm VARCHAR2,
                   psCrn  VARCHAR2 ) RETURN NUMBER;

  --la funcion identifica si el curso es de modalidad N y es de licenciatura
  FUNCTION modoCalificacionNivel(psTerm VARCHAR2,
                                 psCrnn VARCHAR2
                                ) RETURN NUMBER;

  --obtiene curso maestro
  FUNCTION obtieneMaestro(psTerm VARCHAR2,
                          psCrn  VARCHAR2
                         ) RETURN VARCHAR2;

  --RETORNA LA CANTIDAD DE ELEMENTOS POR COMPONENTW
  PROCEDURE cantidadDeComponentes(psTerm                    VARCHAR2,
                                  psCrn                     VARCHAR2,
                                  psComCode          IN OUT VARCHAR2,
                                  psComMaxm          IN OUT VARCHAR2,
                                  pnPonderacionTotal IN OUT NUMBER
                                 );

  --EL PROCEDIMIENTO PRESENTA LOS CURSOS POR PERIODO QUE IMPARTE EL PROFESO
  PROCEDURE termCrn(psPrograma VARCHAR2 DEFAULT NULL);

  --MUESTRA LA PÁGINA DESPUES DE REALIZANA MODIFICACIÓN DE LA ESCALA DE CALIFICACION
  PROCEDURE guardaComponenteHtml(psTerm VARCHAR2,
                                 psCrn  VARCHAR2,
                                 psMsg  VARCHAR2
                                );

  --RETORNA LOS GRUPOS SIMULTANEOS
  PROCEDURE simultaneos(psTerm VARCHAR2,
                        psCrn  VARCHAR2,
                        pnRow  IN OUT INTEGER,
                        tabCrn IN OUT tablaCRN
                       );

  --getExitsGrde
  FUNCTION getExitsGrde(psTermCode VARCHAR2,
                        pnCrn      NUMBER,
                        pnGcomId   NUMBER
                       ) RETURN VARCHAR2 IS

  vsExiste VARCHAR2(5) := NULL;

  BEGIN
      SELECT DECODE(COUNT(cn1), cn0, csNull, csAst||COUNT(cn1))
        INTO vsExiste
        FROM SHRMRKS
       WHERE SHRMRKS_GRDE_CODE IS NOT NULL
         AND SHRMRKS_GCOM_ID    = pnGcomId
         AND SHRMRKS_CRN        = pnCrn
         AND SHRMRKS_TERM_CODE  = psTermCode;

      RETURN vsExiste;

  END getExitsGrde;

  --LA FUNCION RETORNA SI YA FUE ROLADA LA CALIFICACIÓN.
  FUNCTION rolado(psTerm VARCHAR2,
                  psCrn  VARCHAR2
                 ) RETURN INTEGER IS

  vnRoll INTEGER := cn0;

  BEGIN
      SELECT COUNT(cn1)
        INTO vnRoll
        FROM SHRMRKS
       WHERE SHRMRKS_TERM_CODE = psTerm
         AND SHRMRKS_CRN       = psCrn
         AND SHRMRKS_ROLL_DATE IS NOT NULL;

      IF vnRoll = cn0 THEN

         SELECT COUNT(cn1)
           INTO vnRoll
           FROM SFRSTCR
          WHERE SFRSTCR_TERM_CODE = psTerm
            AND SFRSTCR_CRN       = psCrn
            AND (SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL)
            AND SFRSTCR_GRDE_DATE IS NOT NULL
           -- AND SFRSTCR_RSTS_CODE IN (csRE,csRW);  --md-01
            AND SFRSTCR_RSTS_CODE IN (SELECT STVRSTS_CODE
                                        FROM STVRSTS
                                       WHERE STVRSTS_GRADABLE_IND = 'Y');

      END IF;

      RETURN vnRoll;

  END rolado;

  --DEVUELVE EL TOTAL DE LAS PONDERACIONES POR TIPO DE EVALUACION
  FUNCTION ponderacion(psTerm VARCHAR2,
                       psCRn  VARCHAR2,
                       psIncl VARCHAR2 DEFAULT NULL
                      ) RETURN NUMBER IS

  vnPonderacion NUMBER := cn0;

  BEGIN
      SELECT NVL(SUM(SHRGCOM_WEIGHT),cn0)  INTO vnPonderacion
        FROM SHRGCOM
       WHERE SHRGCOM_TERM_CODE = psTerm
         AND SHRGCOM_CRN       = psCrn
         AND (SHRGCOM_INCL_IND = psIncl OR psIncl IS NULL);

      RETURN vnPonderacion;

  EXCEPTION
      WHEN OTHERS THEN
           RETURN vnPonderacion;
  END ponderacion;


    FUNCTION F_Fecha (psTerm VARCHAR2, psCrn VARCHAR2)  RETURN NUMBER  IS

    vbFecha   NUMBER := 0;
    vdFecha   DATE;

      -- 0 verdarero pasa 1 falso no pasa
   CURSOR cuFecha IS
          SELECT TRUNC (SWBDTCR_END_DATE) EndDT
            FROM SWBDTCR
           WHERE SWBDTCR_TERM_CODE = psTerm
             AND (SWBDTCR_COLL_CODE IN  (SELECT SCBCRSE_COLL_CODE
                                         FROM SCBCRSE S
                                         WHERE (SCBCRSE_SUBJ_CODE, SCBCRSE_CRSE_NUMB) IN (SELECT SSBSECT_SUBJ_CODE, SSBSECT_CRSE_NUMB
                                                                                          FROM SSBSECT
                                                                                          WHERE SSBSECT_CRN = psCrn)
                                         AND S.SCBCRSE_EFF_TERM = (SELECT MAX (SS.SCBCRSE_EFF_TERM)
                                                                   FROM SCBCRSE SS
                                                                   WHERE SS.SCBCRSE_SUBJ_CODE = S.SCBCRSE_SUBJ_CODE
                                                                   AND SS.SCBCRSE_CRSE_NUMB = S.SCBCRSE_CRSE_NUMB))
                                    OR SWBDTCR_COLL_CODE = 'ZZ')
         ORDER BY SWBDTCR_END_DATE DESC;

   BEGIN

      vdFecha := csNull;
      vbFecha := 1;

      FOR curFecha IN cuFecha  LOOP
         vdFecha := curFecha.EndDT;
         EXIT; -- asi me aseguro que solo toma el primero segun el orenamiento del cursor
      END LOOP;

      -- SI LA FECHA ES MAYOR O IGUAL AL DIA DE HOY pasa (deja hacer insert y delete)
      -- is es menor no pasa  (definido el 20/jun/2014) con marce y lulu..

      IF vdFecha is null or vdFecha = null then
         vbFecha := 1;
      end if;

      IF TRUNC(vdFecha) < TRUNC(SYSDATE) THEN
         vbFecha := 1;
      END IF;

      IF TRUNC(vdFecha) >= TRUNC(SYSDATE)  THEN
         vbFecha := 0;
      END IF;

      RETURN vbFecha;

   EXCEPTION
      WHEN OTHERS  THEN
         RETURN vbFecha;
   END;

  --la funcion identifica si el curso es de modalidad N y es de licenciatura
  FUNCTION modoCalificacionNivel(psTerm VARCHAR2,
                                   psCrnn VARCHAR2
                                  ) RETURN NUMBER IS

  vnGmodLevl INTEGER := 0;

  BEGIN
      SELECT COUNT(cn1)
        INTO vnGmodLevl
        FROM SCRLEVL A, SSBSECT
       WHERE A.SCRLEVL_EFF_TERM = (SELECT MAX(B.SCRLEVL_EFF_TERM)
                                     FROM SCRLEVL B
                                    WHERE B.SCRLEVL_SUBJ_CODE = A.SCRLEVL_SUBJ_CODE
                                      AND B.SCRLEVL_CRSE_NUMB = A.SCRLEVL_CRSE_NUMB)
         AND A.SCRLEVL_SUBJ_CODE = SSBSECT_SUBJ_CODE
         AND A.SCRLEVL_CRSE_NUMB = SSBSECT_CRSE_NUMB
         AND SSBSECT_GMOD_CODE   = csN
         AND SCRLEVL_LEVL_CODE  IN (csLC,csLT)
         AND SSBSECT_CRN         = psCrnn
         AND SSBSECT_TERM_CODE   = psTerm;

      RETURN vnGmodLevl;

  EXCEPTION
      WHEN OTHERS THEN
           RETURN 0;
  END modoCalificacionNivel;

  --obtiene curso maestro
  FUNCTION obtieneMaestro(psTerm VARCHAR2,
                          psCrn  VARCHAR2
                         ) RETURN VARCHAR2 IS


  vsCRnn VARCHAR2(6) := NULL;

  CURSOR cuMaestro IS
         SELECT SWRXLST_CRN AS Crn
           FROM SWRXLST
          WHERE SWRXLST_TERM_CODE   = psTerm
            AND SWRXLST_TYPE        = csM
            AND SWRXLST_XLST_GROUP IN (SELECT SWRXLST_XLST_GROUP
                                         FROM SWRXLST
                                        WHERE SWRXLST_TYPE      = csS
                                          AND SWRXLST_TERM_CODE = psTerm
                                          AND SWRXLST_CRN       = psCrn
                                      );
  BEGIN

      FOR regMae IN cuMaestro LOOP
          vsCRnn := regMae.Crn;
      END LOOP;

      RETURN NVL(vsCRnn,psCrn);

  END obtieneMaestro;

  --RETORNA LOS GRUPOS SIMULTANEOS
  PROCEDURE simultaneos(psTerm VARCHAR2,
                        psCrn  VARCHAR2,
                        pnRow  IN OUT INTEGER,
                        tabCrn IN OUT tablaCRN
                       ) IS

  CURSOR cuSimultaneo IS
         SELECT SWRXLST_CRN AS Crn
           FROM SWRXLST
          WHERE SWRXLST_TERM_CODE   = psTerm
            AND SWRXLST_TYPE        = csS
            AND SWRXLST_XLST_GROUP IN (SELECT SWRXLST_XLST_GROUP
                                         FROM SWRXLST
                                        WHERE SWRXLST_TYPE      = csM
                                          AND SWRXLST_TERM_CODE = psTerm
                                          AND SWRXLST_CRN       = psCrn  )
            AND EXISTS (SELECT NULL
                          FROM SSBSECT
                         WHERE SSBSECT_TERM_CODE = psTerm
                           AND SSBSECT_CRN       = psCrn );

  BEGIN
      pnRow := 0;

      FOR regSim IN cuSimultaneo LOOP
          pnRow := pnRow + 1;

          tabCrn.EXTEND(pnRow);
          tabCrn(pnRow) := regSim.Crn;
      END LOOP;

  END simultaneos;

  --RETORNA LA CANTIDAD DE ELEMENTOS POR COMPONENTE
  PROCEDURE cantidadDeComponentes(psTerm                    VARCHAR2,
                                  psCrn                     VARCHAR2,
                                  psComCode          IN OUT VARCHAR2,
                                  psComMaxm          IN OUT VARCHAR2,
                                  pnPonderacionTotal IN OUT NUMBER
                                 ) IS

  --cuModalidad
  CURSOR cuModalidad IS
         SELECT SWVCOMP_CODE                         AS compCode,
                DECODE(SWVCOMP_TIPO,csM,cn1,csF,cn2) AS compTipo,
                NVL(SHRGCO.gcomSeqn,cn0)             AS compSecn
           FROM SWVCOMP,
                (SELECT MAX(SHRGCOM_SEQ_NO) AS gcomSeqn,
                        SHRGCOM_NAME        AS gcomName
                   FROM SHRGCOM
                  WHERE SHRGCOM_TERM_CODE = psTerm
                    AND SHRGCOM_CRN       = psCrn
                  GROUP BY SHRGCOM_NAME
                ) SHRGCO
         WHERE SWVCOMP_CODE = SHRGCO.gcomName(+) --md-02
       --  where SWVCOMP_DESC = shrgco.gcomName(+)  --md-01
          ORDER BY compTipo, SWVCOMP_ORDEN;

  BEGIN
      -- se busca el componente con mayor secuencia.
      FOR regComp IN cuModalidad LOOP
          psComCode := psComCode||'"'||regComp.compCode||'",';
          psComMaxm := psComMaxm||regComp.compSecn||',';
      END LOOP;

      psComCode := psComCode||'""';
      psComMaxm := psComMaxm||'0';

      -- se obtiene la ponderación total de los componentes para que no sea mayor a 100%
      pnPonderacionTotal := 0;

      BEGIN
          SELECT NVL(SUM(SHRGCOM_WEIGHT),cn0)
            INTO pnPonderacionTotal
            FROM SHRGCOM
           WHERE SHRGCOM_TERM_CODE = psTerm
             AND SHRGCOM_CRN       = psCrn;
      EXCEPTION
          WHEN OTHERS THEN
               NULL;
      END;

  END cantidadDeComponentes;

  --EL PROCEDIMEITO GENERA LOS FRAIMS DE LA APLICACIÓN
  PROCEDURE Criterios(psPrograma VARCHAR2 DEFAULT NULL) IS

  --genera el encabezado de la pagina de acuerdo al look and feel del SSB
  -- encabezado
  procedure encabezado is

  vsId   varchar2(10)  := null;
  vsName varchar2(300) := null;
  csDate constant varchar2(60) := to_char(sysdate, 'Mon DD, YYYY HH24:MI pm');
  csCamp constant varchar2(6)  := f_Contexto();


  begin
      select spriden_id,
             spriden_first_name||' '||
             spriden_last_name
        into vsId,
             vsName
        from spriden
       where spriden_pidm        = global_pidm
         and spriden_change_ind is null;

      htp.p('
      <html lang="en">
      <head>
      <meta http-equiv="content-type" content="text/html; charset=iso-8859-15">
      <meta http-equiv="pragma" name="cache-control" content="no-cache">
      <meta http-equiv="cache-control" name="cache-control" content="no-cache">
      <link rel="stylesheet" href="/css/all/web_defaultapp.css" type="text/css">
      <link rel="stylesheet" href="/css/web_defaultprint.css" type="text/css" media="print">
      <title>registro de criterios de evaluación</title>');

   --hoja de estilos de wtailor
   htp.p(PK_ObjHTML.vgsCssBanner);

   P_CssTabs;      --md-04

    htp.p('
      </head><body>

      <DIV class="headerwrapperdiv">
           <DIV class="pageheaderdiv1">
                <p>
                <TABLE CLASS="plaintable" WIDTH="100%" cellSpacing=0 cellPadding=0 border=0>
                       <TR><TD CLASS="pldefault"></TD>
                           </TR>
                       <TR>
                           <TD class=bgtabon width="100%" colSpan=2><IMG SRC="/wtlgifs/web_transparent.gif" ALT="Transparent Image" TITLE="Transparent Image"  NAME="web_transparent" HSPACE=0 VSPACE=0 BORDER=0 HEIGHT=3 WIDTH=10></TD></TR>
                </TABLE>
           </DIV>

      <TABLE CLASS="plaintable" WIDTH="100%">
             <TR><TD CLASS="pldefault"></TD>
                 <TD CLASS="pldefault"><p class="rightaligntext">
                     <SPAN class="pageheaderlinks">
                           <A HREF="javascript:Menu(''MENU'');"  class="submenulinktext2" >REGRESAR AL MENÚ</A>
                           |
                           <A HREF="javascript:Menu(''SALI'');" accesskey="3" class="submenulinktext2">SALIR</A>

                     </span>
      </TD>
      </TR>
      </TABLE>
      </DIV>

     
      <form  name="frmMenu" id="frmMenu" action="twbkwbis.P_GenMenu"  target="_top" metod="get">
      <input type="hidden" name="name" value="bmenu.P_FacMainMnu" />
      </form>

      <form  name="frmSali" action="twbkwbis.P_Logout"  target="_top" metod="get">
      </form>

      <DIV class="pagetitlediv">
      <TABLE  CLASS="plaintable" SUMMARY="Esta tabla despliega el t¿ulo y encabezado est¿co" WIDTH="100%">
      <TR>
      <TD CLASS="pldefault">
      <H2>Registro de criterios de evaluación</H2>
      </TD>
      <TD CLASS="pldefault">
      &nbsp;
      </TD>
      <TD CLASS="pldefault"><p class="rightaligntext">
      <DIV class="staticheaders">
      '||vsId||' '||vsName||'<br>
      '||csDate||'<br>
       Institución actual es '||csCamp||'
      </div>
      </TD>
      </TR>
      <TR>
      <TD class="bg3" width="100%" colSpan=3><IMG SRC="/wtlgifs/web_transparent.gif" ALT="Transparent Image" TITLE="Transparent Image"  NAME="web_transparent" HSPACE=0 VSPACE=0 BORDER=0 HEIGHT=3 WIDTH=10></TD>
      </TR>
      </TABLE>
      <a name="main_content"></a>
      </DIV>
      <DIV class="pagebodydiv">
      ');

  end encabezado;

  BEGIN
      IF NOT twbkwbis.f_validuser(global_pidm) THEN RETURN; END IF;

      -- devuelve el periodo seleccionado en el sistema de webTailor
      vgsTerm := twbkwbis.f_getParam(global_pidm,'TERM');

      -- devuelve el crn seleccionado en el sistema de webTailor
      vgsCrnn := twbkwbis.f_getParam(global_pidm,'CRN');

      vgsCrnn:= obtieneMaestro(vgsTerm, vgsCrnn);

      --genera el encabezado de la pagina de acuerdo al look and feel del SSB
      encabezado;

      --bwckfrmt.p_open_doc('kwacrev.Criterios');

      --el procedimiento presenta los cursos por periodo que imparte el profeso
      termCrn(psPrograma);

      twbkwbis.P_CloseDoc;

  END Criterios;

  --EL PROCEDIMIENTO PRESENTA LOS CURSOS POR PERIODO QUE IMPARTE EL PROFESO
  PROCEDURE termCrn(psPrograma VARCHAR2 DEFAULT NULL) IS

  vsGschName SSBSECT.SSBSECT_GSCH_NAME%TYPE       := NULL;
  vsGschDesc SHBGSCH.SHBGSCH_DESCRIPTION%TYPE     := NULL;
  vsGschPorc SHBGSCH.SHBGSCH_PASS_PERCENTAGE%TYPE := NULL;
  vnGmodLevl INTEGER                              := 0;
  vnRow      INTEGER                              := 0;

  csLC      CONSTANT VARCHAR2(2)  := 'LC';
  csCamp    CONSTANT VARCHAR2(6)  := F_CONTEXTO();
  csSysDate CONSTANT VARCHAR2(10) := TO_CHAR(SYSDATE,'DD/MM/YYYY');

  procedure codigoJS is

  --cuComponente
  cursor cuComponente is
         select swvcomp_code                         as compCode,
                swvcomp_desc                         as compDesc,
                swvcomp_tipo                         as compTipo,
                decode(swvcomp_tipo,csM,cn1,csF,cn2) as ordnTipo,
                swvcomp_ponderacion                  as compPond,
                swvcomp_grade_min_apro               as compMinm
           from swvcomp
          order by ordnTipo,swvcomp_orden;

  --arrayJavaScriptDetalle: crea un array para manipularlo en una función JavaScript para el detalle de criterios
  procedure arrayJavaScript(psNameArray varchar2,
                            psValue     varchar2
                           ) is

  begin
      htp.prn('var '||psNameArray||' = new Array(');

      for vnI in 1..vnRow loop
          if    psValue = 'Code' then
                htp.prn('"'||tabCrit(vnI).rCode||'",');

          elsif psValue = 'Desc' then
                htp.prn('"'||tabCrit(vnI).rDesc||'",');

          elsif psValue = 'Tipo' then
                htp.prn('"'||tabCrit(vnI).rTipo||'",');

          elsif psValue = 'Pond' then
                htp.prn('"'||tabCrit(vnI).rPond||'",');

          elsif psValue = 'MinA' then
                htp.prn('"'||tabCrit(vnI).rMinA||'",');

          end if;
      end loop;

      htp.prn('null);');
      htp.p(' ');
      htp.p(' ');
  end arrayJavaScript;

  begin
      --Criterios de evaluación Parciales
      for regCmp in cuComponente LOOP
          vnRow := vnRow + 1;

          tabCrit(vnRow).rCode := regCmp.compCode;
          tabCrit(vnRow).rDesc := regCmp.compDesc;
          tabCrit(vnRow).rTipo := regCmp.compTipo;
          tabCrit(vnRow).rPond := regCmp.compPond;
          tabCrit(vnRow).rMinA := regCmp.compMinm;
      END LOOP;

      htp.p('
      <script language="javascript" src="kwaslct.js"></script>
      <script language="javascript" src="kwatime.js?psMensaje=Se est&aacute; cargando la página<br/>Espere un momento..."></script>

      <script type="text/javascript"><!--
      javascript:window.history.forward(1);

      var vgnPidm       = ' ||global_pidm||';
      var vgsTerm       = "'||vgsTerm    ||'";
      var vgsCrnn       = "'||vgsCrnn    ||'";
      var vnGmLvl       = ' ||vnGmodLevl ||';
      var vgsGschName   = "'||vsGschName ||'";
      var vgsGschDesc   = "'||vsGschDesc ||'";
      var vgsGschPorc   = "'||vsGschPorc ||'";
      var vgsFecha      = "'||csSysDate  ||'";
      var objSelectTerm = document.frmTerm.psTerm;
      var objSelectCrnn = document.frmTerm.psCrnn;
      var objBottomSave = document.frmComponente.btnSave;
      var objTextSeqc   = document.frmComponente.psSeqc;
      var objSelectName = document.frmComponente.psName;
      var objTextWeig   = document.frmComponente.psWeig;
      var objTextIncl   = document.frmComponente.psIncl;
      var objTextDued   = document.frmComponente.psDued;
      var objTextPass   = document.frmComponente.psPass;
      var objTextIddi   = document.frmComponente.psIddi;
      var objTextMust   = document.frmComponente.psMust;

      var objEditSeqA = document.frmEditaComponente.psSeqcAnt;
      var objEditNamA = document.frmEditaComponente.psNameAnt;
      var objEditSeqc = document.frmEditaComponente.psSeqc;
      var objEditIddi = document.frmEditaComponente.pnIddi;
      var objEditName = document.frmEditaComponente.psName;
      var objEditWeig = document.frmEditaComponente.psWeig;
      var objEditIncl = document.frmEditaComponente.psIncl;
      var objEditPass = document.frmEditaComponente.psPass;
      var objEditTerm = document.frmEditaComponente.psTerm;
      var objEditCrnn = document.frmEditaComponente.psCrn;
      var objEditMust = document.frmEditaComponente.psMust;

      var arrComp       = new Array();
      var arrSeqc       = new Array();
      var arrCompCode   = new Array();
      var arrCompTipo   = new Array();
      var arrCompIdii   = new Array();
      var arrCompWeig   = new Array();
      var vgsInsUpd     = null;
      var vgsName       = null;
      var vgsSeqc       = null;
      var vgnPonT       = null;
      var vgnPonP       = null;
      var vgnPonF       = null;
      var vgnGmLv       = null;
      ');

      arrayJavaScript('arrCode','Code');
      arrayJavaScript('arrDesc','Desc');
      arrayJavaScript('arrTipo','Tipo');
      arrayJavaScript('arrPond','Pond');
      arrayJavaScript('arrMinm','Minm');

      --setFecha
      htp.p(
      'function setFecha() {
         objTextDued.value = vgsFecha;
      } //setFecha
      '
      );

      --crnPorTerm
      htp.p(
      'function crnPorTerm(psTerm){
         //la funcion se encuentra en kwatime.js
         iniciaVentana();

         document.getElementById("fraCrit04").src = "aboutBlank";

         limpiaObjetos();

         colocaPonderaciones("","","");

         cargaSelectCall("kwactlg.catalogo", "psCatalogo=SSBSECT&psFiltro1=" + psTerm + "&psFiltro2=" + vgnPidm, objSelectCrnn, "ALL", "concluyeProceso()");

      }//crnPorTerm
      ');

      --concluyeProceso
      htp.p(
      'function concluyeProceso() {

         objSelectCrnn.focus();

         if(vgsCrnn != "") {
            objSelectCrnn.value = vgsCrnn;

            consultaModalidades();
         }

         //la funcion se encuentra en kwatime.js
         closeWindowTime();
      } //concluyeProceso
      ');

      ----consultaModalidades
      htp.p(
      'function consultaModalidades(){
      //la funcion se encuentra en kwatime.js
      iniciaVentana();

      var vsTerm = objSelectTerm.options[objSelectTerm.selectedIndex].value;
      var vsCrnn = objSelectCrnn.options[objSelectCrnn.selectedIndex].value;

      document.frmComponentes.psTerm.value = vsTerm;
      document.frmComponentes.psCrn.value  = vsCrnn;

      limpiaObjetos();

      colocaPonderaciones("","","");

      document.frmComponentes.submit();

      procesoTerminado();
      }//consultaModalidades
      ');

      ----fRevisaTerm
      htp.p(
      'function fRevisaTerm() {
         objSelectTerm.focus();

         if(vgsTerm != "") {
            objSelectTerm.value = vgsTerm;

            setTimeout("crnPorTerm(" + vgsTerm + ")",2000);
         } else {
            //la funcion se encuentra en kwatime.js
            closeWindowTime();
         }
      }//fRevisaTerm
      ');

      ----Menu
      htp.p(
      'function Menu(psAcction) {
         var vnTotal = vgnPonT;
         var vnTotaP = vgnPonP;
         var vnTotaF = vgnPonF;
         var vbTF    = false;

        // if((parseFloat(vnTotaP)>60 || parseFloat(vnTotaP)<40) && parseFloat(vnTotal) == 100 && vnGmLvl>0){
        //    alert("Recuerde que el total de las ponderaciones de las modalidades de evaluación parcial deben estar entre el 40% y el 60%");
        //    vbTF = true;
        // }

        //  md-04 start
        // if((parseFloat(vnTotaF)>60 || parseFloat(vnTotaF)<40) && parseFloat(vnTotal) == 100 && vnGmLvl>0){
        //    alert("Recuerde que el total de las ponderaciones de las modalidades de evaluación final deben estar entre el 40% y el 60%");
        //    vbTF = true;
        // }
        //  md-04 end

        // if(parseFloat(vnTotal) == 100) {
        //    null;
        // } else if(parseFloat(vnTotal) < 100) {
        //    alert("Recuerde que el total de las ponderaciones de las modalidades de evaluación deben ser igual al 100%");
        //    vbTF = true;
        // }

         if(vbTF) {
            return;
         } else {
                   if(psAcction == "MENU") {
                      document.frmMenu.submit();
            } else if(psAcction == "SALI") {
                      document.frmSali.submit();
            }
         }
      } //Menu

      ');

      --procesoTerminado
      htp.p(
      'function procesoTerminado() {
          setTimeout("criterios()", 1000);
      } //procesoTerminado
      '
      );

      --criterios
      htp.p(
      'function criterios() {
         cargaSelectCall("kwactlg.catalogo", "psCatalogo=SWVCOM2", objSelectName, "ALL", "fraCrit04.inicializaValores()");

         //la funcion se encuentra en kwatime.js
         closeWindowTime();
      } //criterios
      '
      );

      --calificacionMinima
      htp.p(
      'function calificacionMinima(psModalidad) {
         var vbExiste = true;
         var vnI      = 0;
         var vsValor  = null;

         if (psModalidad == "") { return ""; }

         while(vbExiste) {
               if(arrCode[vnI] == psModalidad) {
                  vbExiste = false;
                  vsValor  = arrMinm[vnI];
               }
               vnI++;
         }

         if(vsValor=="" || vsValor==null) {
            vsValor = vgsGschPorc;
         }

         return vsValor;

      } //calificacionMinima
      '
      );

      --ponderacion
      htp.p(
      'function ponderacion(psModalidad) {
         var vbExiste = true;
         var vnI      = 0;
         var vsValor  = null;

         if (psModalidad == "") { return ""; }

         while(vbExiste) {
               if(arrCode[vnI] == psModalidad) {
                  vbExiste = false;
                  vsValor  = arrPond[vnI];
               }
               vnI++;
         }

         return vsValor;

      } //ponderacion
      '
      );

      ---secuenciaDecomponente
      htp.p(
      'function secuenciaDecomponente(psComponente) {
        var vnSecuencia = 0;
        var vsMiniPass  = calificacionMinima(psComponente);
        var vsPondera   = ponderacion(psComponente);

        for(var vnI=0; vnI<=arrComp.length; vnI++) {
            if(psComponente == arrComp[vnI]   && vgsInsUpd == "INSERT") {
               vnSecuencia = 1 + arrSeqc[vnI];

            } else if (psComponente == vgsName && vgsInsUpd == "UPDATE") {
                       vnSecuencia = vgsSeqc;

            } else if (psComponente == arrComp[vnI]   && vgsInsUpd == "UPDATE") {
                       vnSecuencia = 1 + arrSeqc[vnI];
            }
        }

        objTextPass.value = vsMiniPass;
        objTextWeig.value = vsPondera;
        objTextSeqc.value = vnSecuencia;

        if(psComponente == "REF") {
           objTextWeig.disabled = true;
        } else {
           objTextWeig.disabled = false;
           objTextWeig.focus();
        }
      } //secuenciaDecomponente
      ');

      --guardaComponente
      htp.p(
      'function guardaComponente() {
         var vsSeqc   = objTextSeqc.value;
         var vsComp   = objSelectName.options[objSelectName.selectedIndex].value;
         var vsTerm   = objSelectTerm.options[objSelectTerm.selectedIndex].value;
         var vsCrnn   = objSelectCrnn.options[objSelectCrnn.selectedIndex].value;

         var vsWeig   = objTextWeig.value;
         var vsDued   = objTextDued.value;
         var vsIncl   = objTextIncl.value;
         var vsGrad   = vgsGschName;
         var vsPorc   = vgsGschPorc;
         var vsPass   = objTextPass.value;
         var vnPonT   = vgnPonT;
         var vnPonP   = vgnPonP;
         var vnPonF   = vgnPonF;
         var vnGmLv   = vgnGmLv;
         var vbExists = false;

         var vbMust = document.frmComponente.psMust.checked;
         var vsMust = "";

         if (vbMust) {vsMust="Y";} else {vsMust="N";}
         ');




          htp.p('

        if(' || vgnFechaEval  || ' == 1) {
            alert("No tiene perimido eliminar/modificar sus criterios");
            return false;
         }

         if(vsWeig == "")  { alert("Ingrese el valor del componente." ); document.frmComponente.psWeig.focus(); return false;}
         if(isNaN(vsWeig)) { alert("El valor que ingreso no es valido"); document.frmComponente.psWeig.focus(); return false;}
         if(parseFloat(vsWeig) > 999.99)  { alert("La cantidad que igreso debe ser menor a 999.99"); document.frmComponente.psWeig.focus(); return false;}
         if(parseFloat(vsWeig) > 9999.99) { alert("La cantidad que igreso debe ser menor a 9999.99"); document.frmComponente.psMark.focus(); return false;}

         if(vgsInsUpd == "UPDATE") {
            for(var vnI=0; vnI<arrCompCode.length; vnI++) {
                if((vsComp+vsSeqc) == arrCompCode[vnI]) {
                   arrCompWeig[vnI] = vsWeig;
                   vbExists         = true;
                }
            }

            if(vbExists){
               vnPonT = 0;
               vnPonP = 0;
               vnPonF = 0;

               for(var vnI=0; vnI<arrCompCode.length; vnI++) {
                          if(arrCompTipo[vnI] == "M") {
                             vnPonP = parseFloat(vnPonP) + parseFloat(arrCompWeig[vnI]);
                   } else if(arrCompTipo[vnI] == "F") {
                             vnPonF = parseFloat(vnPonF) + parseFloat(arrCompWeig[vnI]);
                   }
               }

               vnPonT = parseFloat(vnPonP) + parseFloat(vnPonF);
            }

         } else {
            var vnPonT = vnPonT + parseFloat(vsWeig);

            //validaciones para 40% y 60%
            if(vsIncl == "M") { vnPonP = parseFloat(vnPonP) + parseFloat(vsWeig); }
            if(vsIncl == "F") { vnPonF = parseFloat(vnPonF) + parseFloat(vsWeig); }
         }


         if(vsPass == "") {vsPass = vsPorc;}

         if(vsComp == "") {
            alert("Debe seleccionar el componente.");
            objSelectName.focus();
            return false;
         }

         if(vsDued == "") { alert("Ingrese la fecha."); document.frmComponente.psDued.focus(); return false;}

         if(isNaN(vsPass)) { alert("El valor que ingreso no es valido");  document.frmComponente.psPass.focus(); return false;}
         if(parseFloat(vsPass) > 100) { alert("La cantidad que igreso debe ser menor a 100"); document.frmComponente.psPass.focus(); return false;}


        // if( ((vsIncl == "M" && vnPonP>70) || (vsIncl == "M" && (vnPonP>70 || vnPonP<20) && vnPonT==100)) && vnGmLv>0 ) {
        //     alert("El total de la ponderacion de la modalidad de evaluación parcial debe estar entre el 70% y 20%");
        //     alert("ponderacion p " + vnPonP);
        //     alert("ponderacion F " + vnPonF);
        //     alert("total " +vnPonT);
        //     alert("inicial "+vnGmLv)
        //     return false;
        // }

        // if( ((vsIncl == "F" && vnPonP>60) || (vsIncl == "F" && (vnPonF>60 || vnPonF<20) && vnPonT==100)) && vnGmLv>0 ) {
        //     alert("El total de la ponderacion de evaluación final debe estar entre el 60% y 20%");
        //     return false;
        // }

         if(vnPonT > 100) {
            alert("La ponderación total de los componentes es mayor a 100.\n\n Modifique la ponderación del componente que acaba de capturar");
            document.frmComponente.psWeig.focus();
            return false;
         }

         document.frmGuardaComponente.psPorc.value = vgsGschPorc;

         deshabilitaObjetos(true);


          if(vgsInsUpd == "INSERT") {
                   document.frmGuardaComponente.psSeqc.value = vsSeqc;
                   document.frmGuardaComponente.psName.value = vsComp;
                   document.frmGuardaComponente.psWeig.value = vsWeig;
                   document.frmGuardaComponente.psDued.value = vsDued;
                   document.frmGuardaComponente.psIncl.value = vsIncl;
                   document.frmGuardaComponente.psGrad.value = vsGrad;
                   document.frmGuardaComponente.psPass.value = vsPass;
                   document.frmGuardaComponente.psTerm.value = vsTerm;
                   document.frmGuardaComponente.psCrn.value  = vsCrnn;
                   document.frmGuardaComponente.psMust.value = vsMust;
                   document.frmGuardaComponente.submit();

         } else if(vgsInsUpd == "UPDATE") {
                   objEditSeqc.value = vsSeqc;
                   objEditName.value = vsComp;
                   objEditWeig.value = vsWeig;
                   objEditIncl.value = vsIncl;
                   objEditPass.value = vsPass;
                   objEditTerm.value = vsTerm;
                   objEditCrnn.value = vsCrnn;
                   objEditMust.value = vsMust;
                   document.frmEditaComponente.submit();
         }

      } //guardaComponente
      ');

      ---modalidades
      htp.p(
      'function modalidades(psModalidad) {
         var vbExiste = true;
         var vnI      = 0;
         var vsValor  = null;

         if (psModalidad == "") { return ""; }

         while(vbExiste) {
               if(arrCode[vnI] == psModalidad) {
                  vbExiste = false;
                  vsValor  = arrTipo[vnI];
               }
               vnI++;
         }

         objTextIncl.value = vsValor;

         secuenciaDecomponente(psModalidad);
      } //modalidades
      ');

      --colocaPonderaciones
      htp.p(
      'function colocaPonderaciones(pnPondPar, pnPondFin, pnPondTot) {
         vsPondPar = "";
         vsPondFin = "";
         vsPondTot = "";

         document.getElementById("thDescEVP").innerHTML = "&nbsp;";
         document.getElementById("thDescEVF").innerHTML = "&nbsp;";
         document.getElementById("thDescTOT").innerHTML = "&nbsp;";

         if(pnPondPar != "") {
            vsPondPar = pnPondPar + "%";
            document.getElementById("thDescEVP").innerHTML = "Ponderación de las modalidades de evaluación parcial:";
         }

         if(pnPondFin != "") {
            vsPondFin = pnPondFin + "%";
            document.getElementById("thDescEVF").innerHTML = "Ponderación de las modalidades de evaluación final:";
         }

         if(pnPondTot != "") {
            vsPondTot = pnPondTot + "%";
            document.getElementById("thDescTOT").innerHTML = "Total de ponderaciones de las modalidades de evaluación:";
         }

         document.getElementById("thPondEVP").innerHTML = vsPondPar;
         document.getElementById("thPondEVF").innerHTML = vsPondFin;
         document.getElementById("thPondTOT").innerHTML = vsPondTot;

         limpiaObjetos();
      } //colocaPonderaciones
      ');

      --setValores
      htp.p(
      'function setValores(parrComp,parrSeqc,psInsUpd,pnPondTot,pnPondPar,pnPondFin,pnGmLv,pnRoll) {
         arrComp   = parrComp;
         arrSeqc   = parrSeqc;
         vgsInsUpd = psInsUpd;
         vgnPonT   = pnPondTot;
         vgnPonP   = pnPondPar;
         vgnPonF   = pnPondFin;
         vgnGmLv   = pnGmLv;

         if (pnRoll > 0) {
             objBottomSave.disabled = true;
         } else {
             objBottomSave.disabled = false;
         }

      } //setValores
      '
      );

      --limpiaObjetos
      htp.p(
      'function limpiaObjetos() {
         objTextSeqc.value   = "";
         objTextWeig.value   = "";
         objTextIncl.value   = "";
         objTextDued.value   = vgsFecha;
         objTextPass.value   = "";
         objSelectName.value = "";
         objTextMust.value   = "N";

         objEditSeqA.value   = "";
         objEditNamA.value   = "";
         objEditSeqc.value   = "";
         objEditName.value   = "";
         objEditWeig.value   = "";
         objEditIncl.value   = "";
         objEditPass.value   = "";
         objEditTerm.value   = "";
         objEditCrnn.value   = "";
         objEditMust.value   = "N";

         arrCompCode         = null;
         arrCompTipo         = null;
         arrCompIdii         = null;
         arrCompWeig         = null;

      } //limpiaObjetos
      '
      );

      --deshabilitaObjetos()
      htp.p(
      'function deshabilitaObjetos(pbTrFl) {
         objSelectName.disabled = pbTrFl;
         objTextWeig.disabled   = pbTrFl;
         objTextIncl.disabled   = pbTrFl;
         objTextPass.disabled   = pbTrFl;
         objSelectTerm.disabled = pbTrFl;
         objSelectCrnn.disabled = pbTrFl;
         objBottomSave.disabled = pbTrFl;
      } //limpiaObjetos
      '
      );

      --actualizaComponente
      htp.p(
      'function actualizaComponente(pnIddi, pnSeqc, psName, pnWeig, pdDatt, pnPass, psIncl, prrCompCode, prrCompTipo, prrCompIdii, prrCompWeig) {
         objTextIddi.value   = pnIddi;
         objTextSeqc.value   = pnSeqc;
         objSelectName.value = psName;
         objTextWeig.value   = pnWeig;
         objTextDued.value   = pdDatt;
         objTextPass.value   = pnPass;
         objTextIncl.value   = psIncl;

         objEditSeqA.value   = pnSeqc;
         objEditNamA.value   = psName;
         objEditIddi.value   = pnIddi;

         arrCompCode         = null;
         arrCompTipo         = null;
         arrCompIdii         = null;
         arrCompWeig         = null;

         arrCompCode         = prrCompCode;
         arrCompTipo         = prrCompTipo;
         arrCompIdii         = prrCompIdii;
         arrCompWeig         = prrCompWeig;

         vgsInsUpd           = "UPDATE";

      } //actualizaComponentepnIddi
      '
      );


      htp.p(
      '
      setFecha();

      cargaSelectCall("kwactlg.catalogo", "psCatalogo=STVTERM&psFiltro1=CRITERIOS&psFiltro2=" + vgnPidm, objSelectTerm, "ALL", "fRevisaTerm()");

      -->
      </script>
      ');
  end codigoJS;

  --obtienePonderacionEscala
  procedure obtienePonderacionEscala is

  begin
      select shbgsch_name,
             shbgsch_description,
             shbgsch_pass_percentage
        into vsGschName,
             vsGschDesc,
             vsGschPorc
        from shbgsch
       where shbgsch_levl_code = csLC
         and (shbgsch_camp_code = csCamp or shbgsch_camp_code is null);
  exception
      when others then
           null;
  end obtienePonderacionEscala;

  BEGIN
      --revisa si el curso es del modo de calificacio N y el nivel es de licenciatura
      vnGmodLevl := modoCalificacionNivel(vgsTerm,vgsCrnn);

      --obtienePonderacionEscala
      obtienePonderacionEscala;

      htp.p(
      '
      <body  onUnLoad="javascript:Menu(''MENU'');">
      <br/>
      <form name="frmTerm" id="frmTerm">
      <table border="1" cellpadding="2" cellspacing="1" width="100%" bgcolor="#ffffff">
             <tr><td width="16%" class="delabel"   style="border:solid 1pt #ffffff;">Selecciona el periodo</td>
                 <td width="30%" bgcolor="#efefef" style="border:solid 1pt #ffffff;">
                     <select name="psTerm" id="psTerm" onChange="crnPorTerm(this.value);" style="width:100%;">
                     </select>
                     </td>
                 <td width="54%" rowspan="2" style="border:solid 1pt #ffffff;">
                     </td></tr>
             <tr><td class="delabel" style="border:solid 1pt #ffffff;">Selecciona el curso</td>
                 <td bgcolor="#efefef" style="border:solid 1pt #ffffff;">
                     <select name="psCrnn" id="psCrnn" onChange="consultaModalidades();" style="width:100%;">
                     </select>
                     </td></tr>
      </table>
      </form>
      ');

      IF psPrograma IS NOT NULL THEN
         htp.p('
         <A HREF="twbkwbis.P_GenMenu?name=bmenu.ProgramasMagisteriales"  class=submenulinktext2 onMouseover="window.status=''Regresar a programas magisteriales''; return true" onMouseout="window.status=''''; return true" onFocus="window.status=''Regresar a programas magisteriales''; return true" onBlur="window.status=''''; return true" >Regresar a programas magisteriales</a>
         ');
      END IF;

      htp.p('
      <form name="frmComponentes" id="frmScala" action="kwacrev.Componentes" target="fraCrit04" method="post">
      <input type="hidden" name="psTerm" />
      <input type="hidden" name="psCrn" />
      </form>

      <form name="frmComponente" onSubmit="return false;">
      <table border="1" cellpadding="2" cellspacing="1" width="100%" bordercolor="#ffffff" bgcolor="#ffffff">
             <tr><td colspan="5" style="border:solid 1pt #ffffff;"></td>
                 <td style="border:solid 1pt #ffffff;">
                     <input type="button" id="btnSave" id="btnSave" class="btnAA" value="Guardar" tabindex="8" onClick="guardaComponente();" style="width:100%;" DISABLED />
                     </td>
                 </tr>
             <tr><td width="8%" valign="bottom" class="tdLabelNvl2pi" style="border:solid 1pt #ffffff;">
                     Secuencia<br>de la modalidad
                     </td>
                 <td width="40%" valign="bottom" class="tdLabelNvl2pi" style="border:solid 1pt #ffffff;">
                     <img src="/wtlgifs/web_required.gif" name="imgReqr" />
                     &nbsp;Modalidad de evaluaci&oacute;n
                     </td>
                 <td width="20%" valign="bottom" class="tdLabelNvl2pi" style="border:solid 1pt #ffffff;">
                     <img src="/wtlgifs/web_required.gif" name="imgReqr" />
                     &nbsp;Ponderaci&oacute;n de la<br>modalidad de evaluación.<br>Total = 100%
                     </td>
                 <td width="15%" valign="bottom" class="tdLabelNvl2pi" style="border:solid 1pt #ffffff;">
                     Fecha de captura
                     </td>
                 <td width="5%" valign="bottom" class="tdLabelNvl2pi" style="border:solid 1pt #ffffff;">
                     Must Pass
                     </td>
                 <td width="15%" valign="bottom" class="tdLabelNvl2pi" style="border:solid 1pt #ffffff;">
                     Calificaci&oacute;n m&iacute;nima para acreditar la modalidad
                     </td>
                 </tr>
             <tr bgcolor="#efefef">
                 <td style="border:solid 1pt #ffffff;">
                     <input type="text" name="psSeqc" maxlength="7" tabindex="-1" value="" style="text-align:right;background-color:#efefef;width:100%;" onKeypress="if ( (event.keyCode < 46) || ((event.keyCode > 46) && (event.keyCode < 48)) || (event.keyCode > 57 ) ) event.returnValue = false;"  DISABLED READONLY></td>
                 <td style="border:solid 1pt #ffffff;">
                     <select name="psName" id="psName" onChange="modalidades(this.value);" style="width:100%;">
                     </select>
                     </td>
                 <td style="border:solid 1pt #ffffff;">                 
                     <input type="text"   name="psWeig" value="" maxlength="6"  style="text-align:right;width:100%;" onKeypress="if ( (event.keyCode < 46) || ((event.keyCode > 46) && (event.keyCode < 48)) || (event.keyCode > 57 ) ) event.returnValue = false;" />
                     <input type="hidden" name="psIncl" value="" />
                     <input type="hidden" name="psIddi" value="" />
                     </td>
                 <td style="border:solid 1pt #ffffff;">
                     <input type="text"   name="psDued" value="" maxlength="10" style="text-align:center;background-color:#efefef;width:100%;" onBlur="validaFecha(this);" DISABLED READONLY />
                     </td>
                 <td style="border:solid 1pt #ffffff;">
                     <input type="checkbox" name="psMust" value="N" maxlength="6" style="text-align:center;background-color:#efefef;width:100%;" />
                     </td>
                 <td style="border:solid 1pt #ffffff;">
                     <input type="text"   name="psPass" value="" maxlength="6"  style="text-align:center;background-color:#efefef;width:100%;" DISABLED READONLY />
                     </td>
                     </tr>
      </table>
      </form>

      <iframe src="aboutBlank" name="fraCrit04" id="fraCrit04" frameborder="0" scrolling="yes" width="100%" height="200px;">
      </iframe>

      <br/>
      <br/>
      <br/>

      <table border="0" cellpadding="2" cellspacing="1" bordercolor="#ffffff" bgcolor="#ffffff" width="100%">
             <tr bgcolor="#ffffff">
                 <td width="13%"></td>
                 <td width="35%" align="right" bgcolor="#efefef"  id="thDescEVP">&nbsp;</td>
                 <td width="15%" align="center" bgcolor="#efefef" id="thPondEVP">&nbsp;</td>
                 <td width="15%">&nbsp;</td>
                 </tr>
             <tr bgcolor="#ffffff">
                 <td width="13%"></td>
                 <td width="35%" align="right" bgcolor="#efefef"  id="thDescEVF">&nbsp;</td>
                 <td width="15%" align="center" bgcolor="#efefef" id="thPondEVF">&nbsp;</td>
                 <td>&nbsp;</td>
                 </tr>
             <tr bgcolor="#ffffff">
                 <td width="13%"></td>
                 <td width="35%" align="right" bgcolor="#efefef" id="thDescTOT">&nbsp;</td>
                 <td width="15%" align="center" bgcolor="#efefef" id="thPondTOT">&nbsp;</td>
                 <td></td>
                 </tr>
         </table>
      <br/>

      <form name="frmGuardaComponente" action="kwacrev.guardaComponente" target="fraCrit04" method="post">
      <input type="hidden" name="psSeqc" />
      <input type="hidden" name="psName" />
      <input type="hidden" name="psWeig" />
      <input type="hidden" name="psDued" />
      <input type="hidden" name="psIncl" />
      <input type="hidden" name="psGrad" />
      <input type="hidden" name="psPass" />
      <input type="hidden" name="psTerm" />
      <input type="hidden" name="psCrn"  />
      <input type="hidden" name="psPorc" />
      <input type="hidden" name="psMust" />
      </form>

      <form name="frmEditaComponente" action="kwacrev.editaComponente" target="fraCrit04" method="post">
      <input type="hidden" name="psSeqcAnt" />
      <input type="hidden" name="psNameAnt" />
      <input type="hidden" name="pnIddi"    />
      <input type="hidden" name="psSeqc"    />
      <input type="hidden" name="psName"    />
      <input type="hidden" name="psWeig"    />
      <input type="hidden" name="psIncl"    />
      <input type="hidden" name="psPass"    />
      <input type="hidden" name="psTerm"    />
      <input type="hidden" name="psCrn"     />
      <input type="hidden" name="psMust"    />
      </form>
      '
      );

      codigoJS;

      --kwNotRefresh.script;

      htp.p('</body>');

  END termCrn;

  --PRESENTA EL LISTADO DE COMPONENTES
  PROCEDURE Componentes(psTerm  VARCHAR2 DEFAULT NULL,
                        psCrn   VARCHAR2 DEFAULT NULL
                       ) IS

  vsComponente       VARCHAR2(4000) := NULL;
  vsSecuencia        VARCHAR2(4000) := NULL;
  vsCompCode         VARCHAR2(4000) := NULL;
  vsCompTipo         VARCHAR2(4000) := NULL;
  vsCompIdii         VARCHAR2(4000) := NULL;
  vsCompWeig         VARCHAR2(4000) := NULL;
  vnImg              INTEGER        := 0;
  vnPonderacionTotal NUMBER         := 0;
  vsMust               VARCHAR2 (2)  := NULL;   --md-01

  cnGmodLevl         CONSTANT INTEGER       := modoCalificacionNivel(psTerm,psCrn);
  cnPonderacionParcl CONSTANT NUMBER        := ponderacion(psTerm,psCrn,csM);
  cnPonderacionFinal CONSTANT NUMBER        := ponderacion(psTerm,psCrn,csF);
  cnRoll             CONSTANT INTEGER       := rolado(psTerm,psCrn);
  csFuncionImg       VARCHAR2(300) := 'onMouseOver="fImagenes(this,2);" onMouseOut="fImagenes(this,0);" onMouseDown="fImagenes(this,1);" onMouseUp="fImagenes(this,2);" onFocus="fImagenes(this,1);" onBlur="fImagenes(this,0);"';

  --codigoJava
  procedure codigoJava is

  begin
      htp.p(
      '<script type="text/javascript"><!--
      javascript:window.history.forward(1);

      var arrgComp    = new Array('||vsComponente||');
      var arrgSeqc    = new Array('||vsSecuencia ||');

      var arrCompCode = new Array('||vsCompCode||');
      var arrCompTipo = new Array('||vsCompTipo||');
      var arrCompIdii = new Array('||vsCompIdii||');
      var arrCompWeig = new Array('||vsCompWeig||');

      var vgsInsUpd   = "INSERT";
      var vgnGmLv     = ' ||cnGmodLevl||';
      var vgsTerm     = "'||psTerm    ||'";
      var vgsCrnn     = "'||psCrn     ||'";

      vgnPondTot      = '||vnPonderacionTotal||';
      vgnPondPar      = '||cnPonderacionParcl||';
      vgnPondFin      = '||cnPonderacionFinal||';
      vgnRoll         = '||cnRoll||';
      borrar          = new Image();
      borrarSin       = new Image();
      borrarOver      = new Image();
      borrar.src      = "/imagenes/borrar.gif";
      borrarSin.src   = "/imagenes/borrar_sin.gif";
      borrarOver.src  = "/imagenes/borrar_over.gif";

      editar          = new Image();
      editarSin       = new Image();
      editarOver      = new Image();
      editar.src      = "/imagenes/editar.gif";
      editarSin.src   = "/imagenes/editar_sin.gif";
      editarOver.src  = "/imagenes/editar_over.gif";
      ');

      --inicializaValores
      htp.p(
      'function inicializaValores() {
         parent.setValores(arrgComp,arrgSeqc,vgsInsUpd,vgnPondTot,vgnPondPar,vgnPondFin,vgnGmLv,vgnRoll);
      } //inicializaValores
      '
      );

      ---fImagenes
      htp.p('function fImagenes(psIMG,pnTipo,pnImg) {
             var arrNam = new Array("Eliminar","Editar");
             var arrImg = new Array("borrar","editar");
             var vsTipo = "";

                    if(pnTipo == 1 || pnTipo == 3) {
                    vsTipo = ".src";
             } else if(pnTipo == 0) {
                    vsTipo = "Sin.src";
             } else if(pnTipo == 2) {
                       vsTipo = "Over.src";
             }

             document[psIMG.name].src   = eval(arrImg[pnImg] + vsTipo);
             document[psIMG.name].title = arrNam[pnImg];
             window.status              = arrNam[pnImg];
      } //fImagenes
      ');

      ---eliminaComponente
      htp.p(
      'function eliminaComponente(pnIddi,psDesc) {

           if(' || vgnFechaEval  || ' == 1) {
            alert("No tiene perimido eliminar/modificar sus criterios");
            return false;
            }

          var vbConfirma = confirm("Desea eliminar el componente " + psDesc + " ?");

          if(vbConfirma){
             document.frmEliminaComponente.target       = "fraCrit04";
             document.frmEliminaComponente.action       = "kwacrev.eliminaComponente";
             document.frmEliminaComponente.pnIddi.value = pnIddi;
             document.frmEliminaComponente.psTerm.value = vgsTerm;
             document.frmEliminaComponente.psCrn.value  = vgsCrnn;
             document.frmEliminaComponente.submit();
          }
      } //eliminaComponente
      ');

      ---editaComponente
      htp.p(
      'function editaComponente(pnIddi, pnSeqc, psName, pnWeig, pdDatt, pnPass, psIncl) {
         parent.actualizaComponente(pnIddi, pnSeqc, psName, pnWeig, pdDatt, pnPass, psIncl, arrCompCode, arrCompTipo, arrCompIdii, arrCompWeig);
      } //editaComponente
      ');

      --ponderaciones
      htp.p(
      'function ponderaciones() {
         parent.deshabilitaObjetos(false);

         parent.colocaPonderaciones(vgnPondPar, vgnPondFin, vgnPondTot);

         inicializaValores();
      } //ponderaciones
      ');

      htp.p(
      '
      -->
      </script>
      ');

  end codigoJava;

  --retorna la cantidad de elementos por componente
  procedure componentesActuales is

  --cuModalidad
  cursor cuModalidad is
         select swvcomp_code                         as compCode,
                swvcomp_tipo                         as compTipo,
                shrgco.gcomSeqn                      as compSeqn,
                shrgco.gcomIdii                      as compIdii,
                shrgco.gcomWeig                      as compWeig,
                decode(swvcomp_tipo,csM,cn1,csF,cn2) as orden2
           from swvcomp,
                (select shrgcom_id     as gcomIdii,
                        shrgcom_name   as gcomName,
                        shrgcom_seq_no as gcomSeqn,
                        shrgcom_weight as gcomWeig
                   from shrgcom
                  where shrgcom_term_code = psTerm
                    and shrgcom_crn       = psCrn
                ) shrgco
          where swvcomp_code = shrgco.gcomName  --md-02
        --  where SWVCOMP_DESC = shrgco.gcomName    --md-01
          order by orden2, swvcomp_orden;

  begin
      -- se busca el componente con mayor secuencia.
      for regComp in cuModalidad loop
          vsCompCode := vsCompCode||'"'||regComp.compCode||regComp.compSeqn||'",';
          vsCompTipo := vsCompTipo||'"'||regComp.compTipo||'",';
          vsCompIdii := vsCompIdii     ||regComp.compIdii||',';
          vsCompWeig := vsCompWeig     ||regComp.compWeig||',';
      end loop;

      vsCompCode := vsCompCode||'""';
      vsCompTipo := vsCompTipo||'""';
      vsCompIdii := vsCompIdii||'00';
      vsCompWeig := vsCompWeig||'00';

  END componentesActuales;

  BEGIN

       --global_pidm :=109489;
       --psTerm      := '201425';
       --psCrn       := '25161';

      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;

      cantidadDeComponentes(psTerm,psCrn,vsComponente,vsSecuencia,vnPonderacionTotal);

      vgnFechaEval := F_Fecha(psTerm,psCrn);

      componentesActuales;

      htp.p('<html><head><title>&nbsp;</title>');



      -- la aplicación no se guarda en el cache de la maquina.
      --PK_ObjRuaHTML.P_NoCache;
      PK_ObjHTML.P_NoCache;

      --código css
      --PK_ObjRuaHTML.P_CssTabs;
      BANINST1.kwacrev.P_CssTabs;

      codigoJava;

      vgnFechaEval := F_Fecha(psTerm,psCrn);

      htp.p(
      '
      </head>
      <body class="bodyCero" bgcolor="#ffffff" onLoad="ponderaciones();">
      <table border="1" cellpadding="2" cellspacing="1" bordercolor="#efefef" bgcolor="#ffffff" width="100%">
      '
      );

 --        htp.p('alert(" fecha " + ' || psTerm || psCrn||vgnFechaEval);
     --1553         <td width="10%" align="center">'||regComp.Name||regComp.Seqc||'</td> md-01 se elimina de pantalla

      FOR regComp IN cuComponentes(psTerm,psCrn) LOOP
          vnImg := vnImg + 1;

          htp.p('
          <tr bgcolor="#ffffff" '||PK_ObjHTML.vgsRenglon||'>
          <td valign="top" align="center" width="8%" style="border:solid #efefef 1.0pt;">'||regComp.Seqc||'</td>
          <td valign="top" align="left"   width="40%" style="border:solid #efefef 1.0pt;">
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                     <tr>
                         <td width="50%">'||regComp.Desk||'</td>
                         <td width="20%">'||regComp.InclDesc||' = '||regComp.Incl||
              '</td></tr></table>
               </td>
          <td valign="top" align="center" width="20%" style="border:solid #efefef 1.0pt;">'||regComp.Weig||'</td>
          <td valign="top" align="center" width="15%" style="border:solid #efefef 1.0pt;">'||regComp.Datt||'</td>
          ');
          -- <td valign="top" align="center" width="15%" style="border:solid #efefef 1.0pt;">'||regComp.Datt||getExitsGrde(psTerm,psCrn,regComp.Iddi)||'</td>   --md-04

         IF regComp.Must = 'Y' THEN
            HTP.p (
            '<td valign="top" align="center" width="5%" style="border:solid 1pt #efefef;">'||
            '<input type="checkbox" disabled name="psMust" checked class="chkA"></td>'
            );
         ELSE
            HTP.p (
            '<td valign="top" align="center" width="5%" style="border:solid 1pt #efefef;">'||
            '<input type="checkbox" disabled name="psMust" class="chkA" style="text-align:center; bordercolor:#ffffff; background-color:#ffffff; " ></td>'
            );


         END IF;

        HTP.p (
          '<td valign="top" align="right"  width="5%"  style="border:solid #efefef 1.0pt;">'||regComp.Pass||'</td>
          <td valign="top" align="right"  width="4%"  style="border:solid #efefef 1.0pt;">
          ');

       IF cnRoll = 0 THEN
          csFuncionImg := 'onMouseOver="fImagenes(this,2,0);" onMouseOut="fImagenes(this,0,0);" onMouseDown="fImagenes(this,1,0);" onMouseUp="fImagenes(this,2,0);" onFocus="fImagenes(this,1,0);" onBlur="fImagenes(this,0,0);"';
          
          htp.p('<img src="/imagenes/borrar_sin.gif" name="psBorra'||vnImg||'" value="0" '||csFuncionImg||' border="0" onClick="eliminaComponente('||regComp.Iddi||','''||regComp.Desk||''');"/>');
       END IF;

       htp.p('</td><td valign="top" align="right" width="4%" style="border:solid #efefef 1.0pt;">');

       IF cnRoll = 0 THEN
          csFuncionImg := 'onMouseOver="fImagenes(this,2,1);" onMouseOut="fImagenes(this,0,1);" onMouseDown="fImagenes(this,1,1);" onMouseUp="fImagenes(this,2,1);" onFocus="fImagenes(this,1,1);" onBlur="fImagenes(this,0,1);"';
          
          htp.p('<img src="/imagenes/editar_sin.gif" name="psEdita'||vnImg||'" value="1" '||csFuncionImg||' border="0" onClick="editaComponente('||regComp.Iddi||','||regComp.Seqc||','''||regComp.Name||''','||regComp.Weig||','''||regComp.Datt||''','||regComp.Pass||','''||regComp.Incl||''');"/>');
       END IF;

          htp.p('</td></tr>');
      END LOOP;

      htp.p('</table>');

      IF vnImg = 0 THEN
         htp.p(
         '<center>
          <font size="5">No existen componentes registrados</font>
          </center>
         ');
      END IF;


      htp.p(
      '
      <form name="frmEliminaComponente" method="post">
      <input type="hidden" name="psTerm" />
      <input type="hidden" name="psCrn"  />
      <input type="hidden" name="pnIddi" />
      </form>

      </body></html>
      ');
  END Componentes;

  --EL PROCEDIMIENTO GUARDA LOS componentes
  PROCEDURE guardaComponente(psSeqc VARCHAR2,
                             psName VARCHAR2,
                             psWeig VARCHAR2,
                             psDued VARCHAR2,
                             psIncl VARCHAR2,
                             psGrad VARCHAR2,
                             psPass VARCHAR2,
                             psTerm VARCHAR2,
                             psCrn  VARCHAR2,
                             psPorc VARCHAR2,
                             psMust VARCHAR2   --md-01
                            ) IS

  tabCrn    tablaCRN       := tablaCRN(1);
  vnRow     INTEGER        := 0;
  vnError   INTEGER        := 0;
  vnExiste  INTEGER        := 0;
  vnSeqc    NUMBER         := TO_NUMBER(psSeqc);
  vnWeig    NUMBER         := TO_NUMBER(psWeig);
  vnPass    NUMBER         := TO_NUMBER(psPass);
  vnId      NUMBER         := 0;
  vsPass    VARCHAR2(1)    := 'N';
  vsMensaje VARCHAR2(5000) := 'El componente ha sido registrado';
  vsDesc    VARCHAR2(200)  := NULL;
  vsMust    VARCHAR2 (1)   := 'N';     --md-01

  cdDued     CONSTANT DATE        := TO_DATE(psDued,'DD/MM/YYYY');
  csEscalaLC CONSTANT VARCHAR2(8) := 'ESCALALC';
  cn0        CONSTANT NUMBER(1)   := 0;
  cn1        CONSTANT NUMBER(1)   := 1;
  cn5        CONSTANT NUMBER(1)   := 5;
  cn80       CONSTANT NUMBER(2)   := 80;
  cn100      CONSTANT NUMBER(3)   := 100;
  cnCntAp    constant number(3)   := 70;


  --cuAlumnos
  CURSOR cuAlumnos(psTer VARCHAR2,
                   psNrc VARCHAR2
                  ) IS
         SELECT SFRSTCR_PIDM AS Pidm
           FROM SFRSTCR
          WHERE SFRSTCR_TERM_CODE  = psTer
            AND SFRSTCR_CRN        = psNrc
            AND SFRSTCR_RSTS_CODE IN (csRE,csRW)
            AND (SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL);

  --confirma total
  function ponderacionCompleta(psTerm varchar2,
                               psCrnn varchar2
                              ) return boolean is

  vnPonderacion number(4) := 0;

  begin
      select sum(shrgcom_weight)
        into vnPonderacion
        from shrgcom
       where shrgcom_crn       = psCrnn
         and shrgcom_term_code = psTerm;

      return (nvl(vnPonderacion,cn0) >= cn100);

  exception
      when no_data_found then
           return false;
      when others then
           return false;
  end ponderacionCompleta;

  --colocar bandera de programas magisteriales
  procedure banderaDeCaptura(psTerm varchar2,
                             psCrnn varchar2
                            ) IS

  vsStatus VARCHAR2(1) := csP;
  vnComplt INTEGER     := NULL;

  begin
      select cn5-COUNT(cn1)
        into vnComplt
        from fwrpgsc
       where fwrpgsc_status    = csC
         and fwrpgsc_secc_code = csPAG
         and fwrpgsc_pidm      = global_pidm
         and fwrpgsc_crn       = psCrnn
         and fwrpgsc_term_code = psTerm;

      if vnComplt = cn0 then
         vsStatus := csC;
      end if;

      begin
          update fwbpgsc
             set fwbpgsc_status        = NVL(vsStatus,nvl(fwbpgsc_status,csP)),
                 fwbpgsc_activity_date = cdSysDate,
                 fwbpgsc_user          = csUser
           where fwbpgsc_pidm       = global_pidm
             and fwbpgsc_secc_code  = csPAG
             and fwbpgsc_status    <> csC
             and fwbpgsc_crn        = psCrnn
             and fwbpgsc_term_code  = psTerm;

          if sql%rowcount = cn0 then
             begin
                 insert into fwbpgsc
                 (
                  fwbpgsc_pidm, fwbpgsc_secc_code, fwbpgsc_term_code, fwbpgsc_crn, fwbpgsc_status
                 )
                 values
                 (
                  global_pidm,  csPAG,             psTerm,            psCrnn,       nvl(vsStatus,csP)
                 );
             exception
                 when dup_val_on_index then
                      null;
                 when others then
                      null;
             end;
          end if;

      end;

      begin
          update fwrpgsc
             set fwrpgsc_status        = csC,
                 fwrpgsc_activity_date = cdSysDate,
                 fwrpgsc_user          = csUser
           where fwrpgsc_pidm       = global_pidm
             and fwrpgsc_secc_code  = csPAG
             and fwrpgsc_subs_secc  = csCRE
             and fwrpgsc_crn        = psCrnn
             and fwrpgsc_term_code  = psTerm;

          if sql%rowcount = cn0 then
             begin
                 insert into fwrpgsc
                 (
                  fwrpgsc_pidm,      fwrpgsc_secc_code, fwrpgsc_subs_secc,
                  fwrpgsc_term_code, fwrpgsc_crn,       fwrpgsc_status
                 )
                 values
                 (
                  global_pidm,       csPAG,             csCRE,
                  psTerm,            psCrnn,            csC
                 );
             exception
                 when dup_val_on_index then
                      null;
                 when others then
                      null;
             end;
          end if;
      end;

  end banderaDeCaptura;

  --inserta asistenciA
  procedure insertAsistencia(psTerm varchar2,
                             psCrnn varchar2
                            ) is

  begin
      insert into swbcasm
      (swbcasm_term_code,
       swbcasm_crn,
       swbcasm_pond,
       swbcasm_asm
      )
      values
      (psTerm,
       psCrnn,
       vnPass,
       csY
      );
  exception
      when dup_val_on_index then
           null;
      when others then
           null;
  end insertAsistencia;

  BEGIN
      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;

      vgnFechaEval :=  f_Fecha(psTerm, psCrn);
      if vgnFechaEval = 1 then
         guardaComponenteHtml(psTerm, psCrn, 'No tiene perimido eliminar/modificar sus criterios');

         return;
      end if ;

      IF psName = 'undefined' THEN
         guardaComponenteHtml(psTerm, psCrn, 'Existe un error con la modalidad de evaluación (GUARDAR)');
         RETURN;
      END IF;



      -- el procedimiento muestra los cursos simultaneos
      simultaneos(psTerm, psCrn, vnRow, tabCrn);

      -- se agrega el curso al array de los simultaneos
      vnRow := vnRow + 1;
      tabCrn.EXTEND(vnRow);
      tabCrn(vnRow) := psCrn;

      --se obtiene un concecutivo por componente del curso
      SELECT SHBGSEQ.NEXTVAL
        INTO vnId
        FROM DUAL;

      --se obtiene la descripción del componente
      SELECT SWVCOMP_DESC
        INTO vsDesc
        FROM SWVCOMP
       WHERE SWVCOMP_CODE = psName;

      FOR vnI IN 1..vnRow LOOP
          vnExiste := 0;

          --se agrega la escala de calificación a los cursos
          UPDATE SSBSECT
             SET SSBSECT_GSCH_NAME = csEscalaLC
           WHERE SSBSECT_TERM_CODE = psTerm
             AND SSBSECT_CRN       = tabCrn(vnI);

          --criterio de asistencia minima
          /* md-01 start
          IF psName = 'ASM' THEN
             vsPass := 'Y';

             insertAsistencia(psTerm,tabCrn(vnI));
          ELSE
             vsPass := 'N';
          END IF;
          --md-01 end */

          --verifica que no exista el componente
          SELECT COUNT(cn1)
            INTO vnExiste
            FROM SHRGCOM
           WHERE SHRGCOM_TERM_CODE = psTerm
             AND SHRGCOM_CRN       = tabCrn(vnI)
             AND SHRGCOM_NAME      = psName
             AND SHRGCOM_SEQ_NO    = vnSeqc;

          IF vnExiste = 0 THEN
             --registra el componente al curso
             BEGIN
                 INSERT INTO SHRGCOM
                 (
                  SHRGCOM_SEQ_NO,   SHRGCOM_NAME,
                  SHRGCOM_DESCRIPTION,
                  SHRGCOM_WEIGHT,   SHRGCOM_TOTAL_SCORE,
                  SHRGCOM_DATE,
                  SHRGCOM_INCL_IND, SHRGCOM_GRADE_SCALE, SHRGCOM_MIN_PASS_SCORE,
                  SHRGCOM_ID,       SHRGCOM_TERM_CODE,   SHRGCOM_CRN,
                  SHRGCOM_PASS_IND
                 )
                 VALUES
                 (vnSeqc,    psName,     --  vsDesc --md-02, --psName, --md-01
                  vsDesc||csEsp||vnSeqc,
                  vnWeig,           cnCntAp, -- cn100
                  cdDued,
                  psIncl,           psGrad,              vnPass,
                  vnId,             psTerm,              tabCrn(vnI),
                  psMust  --vsMust  --vsPass  --md-01
                 );

             EXCEPTION
                 WHEN DUP_VAL_ON_INDEX THEN
                      vnError   := 1;
                      vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');
                 WHEN OTHERS THEN
                      vnError   := 1;
                      vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');
             END;

             --registra el componente a los alumnos del curso
             FOR regAlu IN cuAlumnos(psTerm, tabCrn(vnI)) LOOP
                 BEGIN
                     INSERT INTO SHRMRKS
                     (
                      SHRMRKS_TERM_CODE, SHRMRKS_CRN,           SHRMRKS_PIDM,
                      SHRMRKS_GCOM_ID,   SHRMRKS_ACTIVITY_DATE, SHRMRKS_USER_ID,
                      SHRMRKS_GCOM_DATE, SHRMRKS_GCHG_CODE,     SHRMRKS_MARKER
                     )
                     VALUES
                     (
                      psTerm,            tabCrn(vnI),           regAlu.Pidm,
                      vnId,              cdSysDate,             csUser,
                      cdDued,            csOE,                  global_pidm
                     );
                 EXCEPTION
                     WHEN DUP_VAL_ON_INDEX THEN
                          vnError   := 1;
                          vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');
                     WHEN OTHERS           THEN
                          vnError   := 1;
                          vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');
                 END;
             END LOOP;

             /* md-01 start
             IF ponderacionCompleta(psTerm, tabCrn(vnI)) THEN

                banderaDeCaptura(psTerm, tabCrn(vnI));

             END IF;
             md-01 end */
          END IF;
      END LOOP;

      --en caso de exista un error se aplica el rollback
      IF vnError = 0 THEN COMMIT; ELSE ROLLBACK; END IF;

      guardaComponenteHtml(psTerm, psCrn, vsMensaje);

  EXCEPTION
      WHEN OTHERS THEN
           vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');

           ROLLBACK;

           guardaComponenteHtml(psTerm, psCrn, vsMensaje);

  END guardaComponente;

  --MUESTRA LA PÁGINA DESPUES DE REALIZANA MODIFICACIÓN DE LA ESCALA DE CALIFICACION
  PROCEDURE guardaComponenteHtml(psTerm  VARCHAR2,
                                 psCrn   VARCHAR2,
                                 psMsg   VARCHAR2
                                ) IS

  BEGIN
      htp.p('<html><head><title>&nbsp;</title>');

      -- la aplicación no se guarda en el cache de la maquina.
      --PK_ObjRuaHTML.P_NoCache;
      PK_ObjHTML.P_NoCache;

      htp.p(
      '
      <script language="javascript" src="kwatime.js?psMensaje='||psMsg||'<br/>Espere un momento..."></script>
      <script language="javascript"><!--
      javascript:window.history.forward(1);

      function muestraComponentes() {

        setTimeout("tiempo()",3000);

      } //muestraComponentes

      function tiempo() {
        document.frmComponente.submit();
      } //tiempo

      -->
      </script>

      </head>
      <body bgcolor="#ffffff" class="bodyCero" onLoad="muestraComponentes()">

      <form name="frmComponente" action="kwacrev.Componentes" target="fraCrit04" method="post">
      <input type="hidden" name="psTerm"  value="'||psTerm||'" />
      <input type="hidden" name="psCrn"   value="'||psCrn ||'" />
      </form>

      </body></html>
      ');

  END guardaComponenteHtml;

  --ES ELIMINADO EL COMPONENTE
  PROCEDURE eliminaComponente(psTerm VARCHAR2,
                              psCrn  VARCHAR2,
                              pnIddi NUMBER
                             ) IS

  tabCrn       tablaCRN                      := tablaCRN(1);
  vnId         SHRGCOM.SHRGCOM_ID%TYPE       := NULL;
  vsName       SHRGCOM.SHRGCOM_NAME%TYPE     := NULL;
  vsSeqNo      SHRGCOM.SHRGCOM_SEQ_NO%TYPE   := NULL;
  vsIncl       SHRGCOM.SHRGCOM_INCL_IND%TYPE := NULL;
  vnRow        INTEGER                       := 0;
  vnCalcula    INTEGER                       := 0;
  vsMensaje    VARCHAR2(3000)                := 'El componente ha sido eliminado';
  vsGrade      VARCHAR2(16)                   := NULL;
  vsPorcentaje VARCHAR2(16)                   := NULL;

  cn100 CONSTANT NUMBER(3) := 100;
  cnCntAp constant number(3) := 70;

  --elimina asistenciA
  procedure deleteAsistencia(psTerm varchar2,
                             psCrnn varchar2
                            ) is
  begin
      delete swbcasm
       where swbcasm_crn       = psCrnn
         and swbcasm_term_code = psTerm;
  end deleteAsistencia;

  --colocar bandera de programas magisteriales
  procedure banderaDeCaptura(psTerm varchar2,
                             psCrnn varchar2
                            ) IS

  begin
      begin
          update fwbpgsc
             set fwbpgsc_status        = csP,
                 fwbpgsc_activity_date = cdSysDate,
                 fwbpgsc_user          = csUser
           where fwbpgsc_pidm      = global_pidm
             and fwbpgsc_secc_code = csPAG
             and fwbpgsc_crn       = psCrnn
             and fwbpgsc_term_code = psTerm;

          if sql%rowcount = cn0 then
             begin
                 insert into fwbpgsc
                 (
                  fwbpgsc_pidm, fwbpgsc_secc_code, fwbpgsc_term_code,
                  fwbpgsc_crn,  fwbpgsc_status
                 )
                 values
                 (
                  global_pidm,  csPAG,             psTerm,
                  psCrnn,       csP
                 );
             exception
                 when dup_val_on_index then
                      null;
                 when others then
                      null;
             end;
          end if;

      end;

      begin
          update fwrpgsc
             set fwrpgsc_status        = csP,
                 fwrpgsc_activity_date = cdSysDate,
                 fwrpgsc_user          = csUser
           where fwrpgsc_pidm      = global_pidm
             and fwrpgsc_secc_code = csPAG
             and fwrpgsc_subs_secc = csCRE
             and fwrpgsc_crn       = psCrnn
             and fwrpgsc_term_code = psTerm;

          if sql%rowcount = cn0 then
             begin
                 insert into fwrpgsc
                 (
                  fwrpgsc_pidm,      fwrpgsc_secc_code, fwrpgsc_subs_secc,
                  fwrpgsc_term_code, fwrpgsc_crn,       fwrpgsc_status
                 )
                 values
                 (
                  global_pidm,       csPAG,             csCRE,
                  psTerm,            psCrnn,            csP
                 );
             exception
                 when dup_val_on_index then
                      null;
                 when others then
                      null;
             end;
          end if;
      end;

  end banderaDeCaptura;

  --confirma total
  function ponderacionCompleta(psTerm varchar2,
                               psCrnn varchar2
                              ) return boolean is

  vnPonderacion number(4) := 0;
  vnPublicado   number(4) := 0;
  vbWeight      boolean   := false;
  vbPublic      boolean   := false;

  begin
      begin
          select sum(shrgcom_weight)
            into vnPonderacion
            from shrgcom
           where shrgcom_crn       = psCrnn
             and shrgcom_term_code = psTerm;

          vbWeight := (nvl(vnPonderacion,cn0) < cn100);

      exception
          when no_data_found then
               vbWeight := false;
          when others then
               vbWeight := false;
      end;

      select count(cn1)
        into vnPublicado
        from fwrpblc
       where fwrpblc_publicar  = csY
         and fwrpblc_crn       = psCrnn
         and fwrpblc_term_code = psTerm;

      vbPublic := (vnPublicado > cn0);

      if vbPublic then
         return false;
      end if;

      return vbWeight;

  end ponderacionCompleta;

  BEGIN
      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;

      -- el procedimiento muestra los cursos simultaneos
      simultaneos(psTerm, psCrn, vnRow, tabCrn);

      -- obtenemos el componente que va hacer eliminado
      SELECT SHRGCOM_NAME,SHRGCOM_SEQ_NO,DECODE(SHRGCOM_INCL_IND,'F','1',SHRGCOM_INCL_IND)
        INTO vsName, vsSeqNo, vsIncl
        FROM SHRGCOM
       WHERE SHRGCOM_TERM_CODE = psTerm
         AND SHRGCOM_CRN       = psCrn
         AND SHRGCOM_ID        = pnIddi;

      -- es borrado el componente asigando a los alumnos (real o independiente)
      DELETE FROM SHRMRKS
       WHERE SHRMRKS_TERM_CODE = psTerm
         AND SHRMRKS_CRN       = psCrn
         AND SHRMRKS_GCOM_ID   = pnIddi;

      -- es borrado el componente del curso (real o independiente)
      DELETE FROM SHRGCOM
       WHERE SHRGCOM_TERM_CODE = psTerm
         AND SHRGCOM_CRN       = psCrn
         AND SHRGCOM_ID        = pnIddi;

     /* md-01 start

      IF vsName = 'ASM' THEN
         deleteAsistencia(psTerm, psCrn);
      END IF;


      IF ponderacionCompleta(psTerm, psCrn) THEN
         --colocar bandera de programas magisteriales
         banderaDeCaptura(psTerm, psCrn);
      END IF;
      md-01 end */

      -- es borrado el componente asigando a los cursos simultaneos
      FOR vnI IN 1..vnRow LOOP
          -- obtenemos el componente que va hacer eliminado
          BEGIN
              SELECT SHRGCOM_ID
                INTO vnId
                FROM SHRGCOM
               WHERE SHRGCOM_TERM_CODE = psTerm
                 AND SHRGCOM_CRN       = tabCrn(vnI)
                 AND SHRGCOM_NAME      = vsName
                 AND SHRGCOM_SEQ_NO    = vsSeqNo;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   NULL;
          END;

           /* md-01 start

          IF vsName = 'ASM' THEN
             deleteAsistencia(psTerm, tabCrn(vnI));
          END IF;


          IF ponderacionCompleta(psTerm,  tabCrn(vnI)) THEN
             --colocar bandera de programas magisteriales
             banderaDeCaptura(psTerm, tabCrn(vnI));
          END IF;
          md-01 end */

          DELETE FROM SHRMRKS
           WHERE SHRMRKS_TERM_CODE = psTerm
             AND SHRMRKS_CRN       = tabCrn(vnI)
             AND SHRMRKS_GCOM_ID   = vnId;

          DELETE FROM SHRGCOM
           WHERE SHRGCOM_TERM_CODE = psTerm
             AND SHRGCOM_CRN       = tabCrn(vnI)
             AND SHRGCOM_ID        = vnId;
      END LOOP;

      -- se agrega el curso al array de los simultaneos
      vnRow := vnRow + 1;
      tabCrn.EXTEND(vnRow);
      tabCrn(vnRow) := psCrn;

      COMMIT;

      --recalcula calificaciones
      FOR vnI IN 1..vnRow LOOP
          UPDATE SFRSTCR
             SET SFRSTCR_GRDE_CODE_MID = NULL,
                 SFRSTCR_GRDE_CODE     = NULL
           WHERE SFRSTCR_TERM_CODE  = psTerm
             AND SFRSTCR_CRN        = tabCrn(vnI)
             AND SFRSTCR_RSTS_CODE IN (csRW,csRE)
             AND (SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL) ;

          FOR regCal IN cuCalulaGrade(psTerm, tabCrn(vnI), vsIncl) LOOP
              --vsGrade   := LTRIM(RTRIM(TO_CHAR(ROUND(regCal.Grade,cn1),cs90p0)));
              vsGrade      := regCal.Grade;
              vsPorcentaje := ROUND((REPLACE(vsGrade,',','.') * cn10),cn1);              
              
              IF vsGrade IS NOT NULL AND regCal.gcomCrit = regCal.mrksCrit THEN
                  BEGIN
                      UPDATE SHRCMRK
                         SET SHRCMRK_PERCENTAGE  = vsPorcentaje,
                             SHRCMRK_GRDE_CODE   = vsGrade
                       WHERE SHRCMRK_TERM_CODE   = psTerm
                         AND SHRCMRK_CRN         = tabCrn(vnI)
                         AND SHRCMRK_RECTYPE_IND = csM
                         AND SHRCMRK_PIDM        = regCal.Pidm
                         AND SHRCMRK_ROLL_DATE  IS NULL;

                      IF SQL%ROWCOUNT = cn0 THEN
                            INSERT INTO SHRCMRK
                            (
                             SHRCMRK_PIDM,        SHRCMRK_TERM_CODE, SHRCMRK_CRN,
                             SHRCMRK_RECTYPE_IND, SHRCMRK_USER_ID,   SHRCMRK_ACTIVITY_DATE,
                             SHRCMRK_PERCENTAGE,                     SHRCMRK_GRDE_CODE
                            )
                            VALUES
                            (
                             regCal.Pidm,         psTerm,            tabCrn(vnI),
                             csM,                 csUser,            cdSysDate,
                             vsPorcentaje,        vsGrade
                            );
                      END IF;
                  END;
              END IF;

--              UPDATE SFRSTCR
--                 SET SFRSTCR_GRDE_CODE_MID = DECODE(vsGrade,cs10p0,cs10,vsGrade)
--               WHERE SFRSTCR_TERM_CODE     = psTerm
--                 AND SFRSTCR_CRN           = tabCrn(vnI)
--                 AND SFRSTCR_PIDM          = regCal.Pidm
--                 AND SFRSTCR_RSTS_CODE    IN (csRW,csRE)
--                 AND (SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL);

              vsGrade := NULL;
          END LOOP;

          FOR regCal IN cuCalulaGradeF(psTerm, tabCrn(vnI), cs1) LOOP
              --vsGrade := LTRIM(RTRIM(TO_CHAR(ROUND(regCal.Grade,cn1),cs90p0)));
              vsGrade      := regCal.Grade;
              vsPorcentaje := ROUND((REPLACE(vsGrade,',','.') * cn10),cn1);
              
              IF vsGrade IS NOT NULL AND regCal.gcomCrit = regCal.mrksCrit THEN
                 BEGIN
                     UPDATE SHRCMRK
                        SET SHRCMRK_PERCENTAGE  = vsPorcentaje,
                            SHRCMRK_GRDE_CODE   = vsGrade
                      WHERE SHRCMRK_TERM_CODE   = psTerm
                        AND SHRCMRK_CRN         = tabCrn(vnI)
                        AND SHRCMRK_RECTYPE_IND = csF
                        AND SHRCMRK_PIDM        = regCal.Pidm
                        AND SHRCMRK_ROLL_DATE  IS NULL;

                     IF SQL%ROWCOUNT = cn0 THEN
                        INSERT INTO SHRCMRK
                        (
                         SHRCMRK_PIDM,        SHRCMRK_TERM_CODE, SHRCMRK_CRN,
                         SHRCMRK_RECTYPE_IND, SHRCMRK_USER_ID,   SHRCMRK_ACTIVITY_DATE,
                         SHRCMRK_PERCENTAGE,                     SHRCMRK_GRDE_CODE
                        )
                        VALUES
                        (
                         regCal.Pidm,         psTerm,            tabCrn(vnI),
                         csF,                 csUser,            cdSysDate,
                         vsPorcentaje,        vsGrade
                        );
                     END IF;
                 END;
              END IF;

--              UPDATE SFRSTCR
--                 SET SFRSTCR_GRDE_CODE  = DECODE(vsGrade,cs10p0,cs10,vsGrade)
--               WHERE SFRSTCR_TERM_CODE  = psTerm
--                 AND SFRSTCR_CRN        = tabCrn(vnI)
--                 AND SFRSTCR_PIDM       = regCal.Pidm
--                 AND SFRSTCR_RSTS_CODE IN (csRW,csRE)
--                 AND (SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL);

              vsGrade := NULL;
          END LOOP;
      END LOOP;

      COMMIT;

      guardaComponenteHtml(psTerm, psCrn, vsMensaje);

  EXCEPTION
      WHEN OTHERS THEN
           vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');

           ROLLBACK;

           guardaComponenteHtml(psTerm, psCrn, vsMensaje);

  END eliminaComponente;

  --EL PROCEDIMIENTO ACTUALIZA LOS componenteS
  PROCEDURE editaComponente(psSeqcAnt VARCHAR2,
                            psNameAnt VARCHAR2,
                            pnIddi    NUMBER,
                            psSeqc    VARCHAR2,
                            psName    VARCHAR2,
                            psWeig    VARCHAR2,
                            psIncl    VARCHAR2,
                            psPass    VARCHAR2,
                            psTerm    VARCHAR2,
                            psCrn     VARCHAR2,
                            psMust VARCHAR2   --md-01
                           ) IS

  tabCrn       tablaCRN                  := tablaCRN(1);
  vnId         SHRGCOM.SHRGCOM_ID%TYPE   := NULL;
  vsDesc       SWVCOMP.SWVCOMP_DESC%TYPE := NULL;
  vnRow        INTEGER                   := 0;
  vnSeqc       NUMBER                    := TO_NUMBER(psSeqc);
  vnWeig       NUMBER                    := TO_NUMBER(psWeig);
  vnMin        NUMBER                    := TO_NUMBER(psPass);
  vsMensaje    VARCHAR2(5000)            := 'El componente ha sido registrado';
  vsPass       VARCHAR2(1)               := 'N';
  vsGrade      VARCHAR2(16)               := NULL;
  vsPorcentaje VARCHAR2(16)               := NULL;

  BEGIN
      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;

    --md-03 start

      vgnFechaEval :=  f_Fecha(psTerm, psCrn);
      if vgnFechaEval = 1 then
         guardaComponenteHtml(psTerm, psCrn, 'No tiene perimido eliminar/modificar sus criterios');

         return;
      end if ;

    --md-03 end


      IF 'undefined' IN (psNameAnt,psName) THEN
         guardaComponenteHtml(psTerm, psCrn, 'Existe un error con la modalidad de evaluación (EDITAR)');

         RETURN;
      END IF;

      --se obtiene la descripción del componente
      SELECT SWVCOMP_DESC
        INTO vsDesc
        FROM SWVCOMP
       WHERE SWVCOMP_CODE = psName;

      -- el procedimiento muestra los cursos simultaneos
      simultaneos(psTerm, psCrn, vnRow, tabCrn);

      --criterio de asistencia minima
      /*
      IF psName = 'ASM' THEN
         vsPass := 'Y';
      ELSE
         vsPass := 'N';
      END IF;
      */

      -- es actualizado el curso real o independiente
      BEGIN
          UPDATE SHRGCOM
             SET SHRGCOM_SEQ_NO         = vnSeqc,
                 SHRGCOM_NAME           = psName,--vsDesc , --md-02     --psName, md-01
                 SHRGCOM_DESCRIPTION    = vsDesc||csEsp||vnSeqc,
                 SHRGCOM_WEIGHT         = vnWeig,
                 SHRGCOM_INCL_IND       = psIncl,
                 SHRGCOM_MIN_PASS_SCORE = vnMin,
                 SHRGCOM_PASS_IND       = psMust
           WHERE SHRGCOM_TERM_CODE      = psTerm
             AND SHRGCOM_CRN            = psCrn
             AND SHRGCOM_ID             = pnIddi;

          IF SQL%ROWCOUNT = 0 THEN
             vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');
          END IF;
      END;

      -- son actualizados los cursos simultaneos
      FOR vnI IN 1..vnRow LOOP
          -- obtenemos el componente que va hacer eliminado
          BEGIN
              SELECT SHRGCOM_ID
                INTO vnId
                FROM SHRGCOM
               WHERE SHRGCOM_TERM_CODE = psTerm
                 AND SHRGCOM_CRN       = tabCrn(vnI)
                 AND SHRGCOM_NAME      = psNameAnt
                 AND SHRGCOM_SEQ_NO    = psSeqcAnt;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   NULL;
          END;

          UPDATE SHRGCOM
              SET SHRGCOM_SEQ_NO         = vnSeqc,
                  SHRGCOM_NAME           = psName,  --vsDesc , md-02     --psName, --md-01
                  SHRGCOM_DESCRIPTION    = vsDesc||csEsp||vnSeqc,
                  SHRGCOM_WEIGHT         = vnWeig,
                  SHRGCOM_INCL_IND       = psIncl,
                  SHRGCOM_MIN_PASS_SCORE = vnMin,
                  SHRGCOM_PASS_IND       = psMust
            WHERE SHRGCOM_TERM_CODE      = psTerm
              AND SHRGCOM_CRN            = tabCrn(vnI)
              AND SHRGCOM_ID             = vnId;
      END LOOP;

      -- se agrega el curso al array de los simultaneos
      vnRow := vnRow + 1;
      tabCrn.EXTEND(vnRow);
      tabCrn(vnRow) := psCrn;

      COMMIT;

      --recalcula calificaciones
      FOR vnI IN 1..vnRow LOOP
          FOR regCal IN cuCalulaGrade(psTerm, tabCrn(vnI), csM) LOOP
              --vsGrade := LTRIM(RTRIM(TO_CHAR(ROUND(regCal.Grade,cn1),cs90p0)));
              vsGrade      := regCal.Grade;
              vsPorcentaje := ROUND((REPLACE(vsGrade,',','.') * cn10),cn1);
              
              IF vsGrade IS NOT NULL AND regCal.gcomCrit = regCal.mrksCrit THEN
                 UPDATE SHRCMRK
                    SET SHRCMRK_PERCENTAGE  = vsPorcentaje,
                        SHRCMRK_GRDE_CODE   = vsGrade
                  WHERE SHRCMRK_TERM_CODE   = psTerm
                    AND SHRCMRK_CRN         = tabCrn(vnI)
                    AND SHRCMRK_RECTYPE_IND = csM
                    AND SHRCMRK_PIDM        = regCal.Pidm
                    AND SHRCMRK_ROLL_DATE  IS NULL;
              END IF;

--              UPDATE SFRSTCR
--                 SET SFRSTCR_GRDE_CODE_MID = DECODE(vsGrade,cs10p0,cs10,vsGrade)
--               WHERE SFRSTCR_TERM_CODE     = psTerm
--                 AND SFRSTCR_CRN           = tabCrn(vnI)
--                 AND SFRSTCR_GRDE_DATE    IS NULL
--                 AND SFRSTCR_PIDM          = regCal.Pidm
--                 AND( SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL)
--                 AND SFRSTCR_RSTS_CODE    IN (csRE,csRW);

              vsGrade := NULL;
          END LOOP;

          FOR regCal IN cuCalulaGradeF(psTerm, tabCrn(vnI), cs1) LOOP
              --vsGrade   := LTRIM(RTRIM(TO_CHAR(ROUND(regCal.Grade,cn1),cs90p0)));
              vsGrade      := regCal.Grade;
              vsPorcentaje := ROUND((REPLACE(vsGrade,',','.') * cn10),cn1);
              
              IF vsGrade IS NOT NULL AND regCal.gcomCrit = regCal.mrksCrit THEN
                 UPDATE SHRCMRK
                    SET SHRCMRK_PERCENTAGE  = vsPorcentaje,
                        SHRCMRK_GRDE_CODE   = vsGrade
                  WHERE SHRCMRK_TERM_CODE   = psTerm
                    AND SHRCMRK_CRN         = tabCrn(vnI)
                    AND SHRCMRK_RECTYPE_IND = csF
                    AND SHRCMRK_PIDM        = regCal.Pidm
                    AND SHRCMRK_ROLL_DATE  IS NULL;
              END IF;
              
--              UPDATE SFRSTCR
--                 SET SFRSTCR_GRDE_CODE  = DECODE(vsGrade,cs10p0,cs10,vsGrade)
--               WHERE SFRSTCR_TERM_CODE  = psTerm
--                 AND SFRSTCR_CRN        = tabCrn(vnI)
--                 AND SFRSTCR_GRDE_DATE IS NULL
--                 AND SFRSTCR_PIDM       = regCal.Pidm
--                 AND (SFRSTCR_ERROR_FLAG <> csF OR SFRSTCR_ERROR_FLAG IS NULL)
--                 AND SFRSTCR_RSTS_CODE IN (csRE,csRW);

              vsGrade := NULL;
          END LOOP;
      END LOOP;

      --en caso de exista un error se aplica el rollback
      COMMIT;

      guardaComponenteHtml(psTerm, psCrn, vsMensaje);

  EXCEPTION
      WHEN OTHERS THEN
           vsMensaje := REPLACE(REPLACE(REPLACE(SQLERRM,'"',' ') ,')',' ') ,'(',' ');

           guardaComponenteHtml(psTerm, psCrn, vsMensaje);

  END editaComponente;

 PROCEDURE P_CssTabs
   IS
   BEGIN
      --TR { HEIGHT: 20px}
      HTP.p (
         '
      <style type="text/css">
        BODY.bodyCeroR {MARGIN: 0pt 5pt}
        BODY.bodyCero { MARGIN: 0pt}
        BODY.bodyCursorW { CURSOR: wait}
        BODY.bodyCursorW2 { CURSOR: wait; MARGIN: 0pt 5pt}
        BODY.bodyCursorD { CURSOR: default}
        TABLE { BORDER-TOP: medium none; BORDER-RIGHT: medium none; BORDER-COLLAPSE: collapse; BORDER-BOTTOM: medium none; BORDER-LEFT: medium none}
        TR.CEL0Height08 { FONT-SIZE: 6pt; HEIGHT: 8px; BACKGROUND-COLOR: #cccccc}
        TR.CELHeightr20 { FONT-SIZE: 6pt; HEIGHT: 8px; BACKGROUND-COLOR: #294f8e}
        
        TR.trSeparador { HEIGHT: 8px}
        TR.trSeparado4 { HEIGHT: 4px}
        TR.trTabSepara { HEIGHT: 15px}
        TR.CEL0r { FONT-WEIGHT: bold; COLOR: #ffffff; BACKGROUND-COLOR: #294f8e}
        TR.CEL2r { FONT-WEIGHT: normal; COLOR: #888888; BACKGROUND-COLOR: #efefef}
        TR.CEL0r2 { FONT-WEIGHT: bold; COLOR: #ffffff; TEXT-DECORATION: underline; BACKGROUND-COLOR: #294f8e}
        TR.CEL2r2 { FONT-WEIGHT: bold; COLOR: #000000; TEXT-DECORATION: underline; BACKGROUND-COLOR: #cccccc}
        TR.CEL0s { FONT-SIZE: 6pt; HEIGHT: 8px; COLOR: #000000; BACKGROUND-COLOR: #294f8e}
        TR.CEL2s { FONT-SIZE: 6pt; HEIGHT: 8px; BACKGROUND-COLOR: #cccccc}
        TH { FONT-SIZE: 10pt; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif}
        TH.thFont8 { FONT-SIZE: 8pt}
        TH.thFont7 { FONT-SIZE: 7pt}
        TH.thTitulo { FONT-SIZE: 13pt}
        TD { FONT-SIZE: 10pt; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif}
        TD.tdFont8 {FONT-SIZE: 8pt}
        TD.tdFont7 { FONT-SIZE: 7pt}
        TD.tdTitulo { FONT-SIZE: 11pt}
        TD.tdLabel { FONT-SIZE: 10pt; FONT-WEIGHT: bold; BACKGROUND-COLOR: #e3e5ee}
        TD.tdLabelNvl2 { FONT-SIZE: 10pt; FONT-WEIGHT: bold; BACKGROUND-COLOR: #e3e5ee}
        TD.tdLabelNvl2pi { FONT-SIZE: 8pt; BACKGROUND-COLOR: #e3e5ee}
        TD.tdLabelNvl3 { FONT-SIZE: 10pt; FONT-WEIGHT: bold; BACKGROUND-COLOR: #dddddd}
        TD.tdLabelNvl4 { FONT-SIZE: 10pt; BACKGROUND-COLOR: #e3e5ee}
        TD.td03 { FONT-SIZE: 3pt}
        SELECT { FONT-SIZE: 10pt; FONT-FAMILY: Arial, Helvetica, sans-serif; WIDTH: 100%; BACKGROUND-COLOR: #ffffff}
        INPUT { FONT-SIZE: 10pt; BORDER-TOP: 1pt inset; HEIGHT: 20px; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif; BORDER-RIGHT: 1pt inset; BORDER-BOTTOM: 1pt inset; BORDER-LEFT: 1pt inset; WIDTH: 100%; BACKGROUND-COLOR: #ffffff}
        INPUT.btnAA { FONT-SIZE: 10pt; BORDER-TOP: 1pt outset; HEIGHT: 22px; BORDER-RIGHT: 1pt outset; BORDER-BOTTOM: 1pt outset; BORDER-LEFT: 1pt outset; BACKGROUND-COLOR: #cccccc}
        INPUT.btnAA11 { FONT-SIZE: 12pt; BORDER-TOP: 1pt outset; HEIGHT: 22px; BORDER-RIGHT: 1pt outset; BORDER-BOTTOM: 1pt outset; FONT-WEIGHT: bold; BORDER-LEFT: 1pt outset; BACKGROUND-COLOR: #cccccc}
        INPUT.txtTitulo { FONT-SIZE: 14pt; BORDER-TOP: 0pt outset; HEIGHT: 25px; BORDER-RIGHT: 0pt outset; BORDER-BOTTOM: 0pt outset; FONT-WEIGHT: bold; BORDER-LEFT: 0pt outset}
        INPUT.txtOnFocus { FONT-SIZE: 10pt; BORDER-TOP: 1pt inset; HEIGHT: 20px; BORDER-RIGHT: 1pt inset; BORDER-BOTTOM: 1pt inset; FONT-WEIGHT: bold; COLOR: #000000; BORDER-LEFT: 1pt inset; BACKGROUND-COLOR: #b1c9e1}
        INPUT.btnOnFocus { FONT-SIZE: 10pt; BORDER-TOP: 1pt outset; HEIGHT: 22px; BORDER-RIGHT: 1pt outset; BORDER-BOTTOM: 1pt outset; FONT-WEIGHT: bold; COLOR: #000000; BORDER-LEFT: 1pt outset; BACKGROUND-COLOR: #b1c9e1}
        INPUT.btnOnFocus11 { FONT-SIZE: 10pt; BORDER-TOP: 1pt outset; HEIGHT: 22px; BORDER-RIGHT: 1pt outset; BORDER-BOTTOM: 1pt outset; FONT-WEIGHT: bold; COLOR: #000000; BORDER-LEFT: 1pt outset; BACKGROUND-COLOR: #b1c9e1}
        INPUT.btn01 { FONT-SIZE: 10pt; BORDER-TOP: 2pt outset; HEIGHT: 25px; BORDER-RIGHT: 2pt outset; BORDER-BOTTOM: 2pt outset; BORDER-LEFT: 2pt outset; WIDTH: 100%; BACKGROUND-COLOR: #ffffff}
        INPUT.bkg01 { BACKGROUND-COLOR: #b1c9e1}
        INPUT.bkg02 { BACKGROUND-COLOR: #ffffff}
        TEXTAREA.bkg01ar { BACKGROUND-COLOR: #b1c9e1}
        TEXTAREA.bkg02ar { BACKGROUND-COLOR: #ffffff}
        INPUT.btnAb { FONT-SIZE: 10pt; BORDER-TOP: 0pt outset; HEIGHT: 100%; BORDER-RIGHT: 0pt outset; BORDER-BOTTOM: 0pt outset; FONT-WEIGHT: bold; COLOR: #ffffff; BORDER-LEFT: 0pt outset; BACKGROUND-COLOR: #294f8e}
        INPUT.btnAb1 { FONT-SIZE: 11pt; BORDER-TOP: 0pt outset; HEIGHT: 100%; BORDER-RIGHT: 0pt outset; BORDER-BOTTOM: 0pt outset; FONT-WEIGHT: bold; COLOR: #b1c9e1; TEXT-DECORATION: underline; BORDER-LEFT: 0pt outset; BACKGROUND-COLOR: #ffffff}
        INPUT.btnAc { FONT-SIZE: 10pt; BORDER-TOP: 0pt outset; HEIGHT: 100%; BORDER-RIGHT: 0pt outset; BORDER-BOTTOM: 0pt outset; COLOR: #888888; BORDER-LEFT: 0pt outset; BACKGROUND-COLOR: #efefef}
        INPUT.btnAc1 { FONT-SIZE: 11pt; BORDER-TOP: 0pt outset; HEIGHT: 100%; BORDER-RIGHT: 0pt outset; BORDER-BOTTOM: 0pt outset; FONT-WEIGHT: bold; COLOR: #aaaaaa; TEXT-DECORATION: underline; BORDER-LEFT: 0pt outset; BACKGROUND-COLOR: #efefef}
        INPUT.chkA { BORDER-TOP: 0pt outset; HEIGHT: 23px; BORDER-RIGHT: 0pt outset; BORDER-BOTTOM: 0pt outset; BORDER-LEFT: 0pt outset; WIDTH: 23px; BACKGROUND-COLOR: #efefef}
        INPUT.oculto { FONT-SIZE: 1pt; BORDER-TOP: 0pt inset; HEIGHT: 0px; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif; BORDER-RIGHT: 0pt inset; BORDER-BOTTOM: 0pt inset; BORDER-LEFT: 0pt inset; WIDTH: 0px; BACKGROUND-COLOR: #ffffff}
        INPUT.ocultoEF { FONT-SIZE: 10pt; BORDER-TOP: 0pt inset; HEIGHT: 100%; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif; BORDER-RIGHT: 0pt inset; BORDER-BOTTOM: 0pt inset; BORDER-LEFT: 0pt inset; WIDTH: 100%; BACKGROUND-COLOR: #ffffff}
        INPUT.ocultoDesc { FONT-SIZE: 10pt; BORDER-TOP: 0pt inset; BORDER-RIGHT: 0pt inset; BORDER-BOTTOM: 0pt inset; BORDER-LEFT: 0pt inset; BACKGROUND-COLOR: #e3e5ee}
        INPUT.ocultoDesh { BORDER-TOP: 0pt inset; BORDER-RIGHT: 0pt inset; BORDER-BOTTOM: 0pt inset; BORDER-LEFT: 0pt inset; BACKGROUND-COLOR: #efefef}
        P { FONT-SIZE: 10pt; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif}
        P.mensajeDIPeS { FONT-SIZE: 12pt}
        P.avisoFalla {FONT-SIZE: 20pt; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif; COLOR: #00aa00}
        .CEL0 { CURSOR: crosshair; FONT-SIZE: 10pt; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif; FONT-WEIGHT: bold; BACKGROUND-COLOR: #e3e5ee}
        .CEL2 { FONT-SIZE: 10pt; FONT-FAMILY: Arial Narrow, verdana, helvetica, sans-serif; BACKGROUND-COLOR: #ffffff}
      </style>');
   END P_CssTabs;

END kwacrev;
/
