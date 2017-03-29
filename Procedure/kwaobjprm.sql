CREATE OR REPLACE PACKAGE BODY BANINST1.kwaObjPrm IS
/*
           tarea: sistema de reportes uft
                  genera las opciones de parametros para los reportes
          modulo: general
           fecha: 25/01/2010.
           autor: mac

    modificacion: 16/03/2010
                  gepc
                  * se corrigio la consulta para estraer los cursos del parametro "psdoce"
                  23/12/2010
                  aigui
                  * se bajo la versión de producción

                  27/12/2010
                  jccr
                  * se agrego lo de los certificados de uft

                 06/06/2012
                 marcela y amc
                 * se agrega el parametro en procedimiento PWATTAD

                 08/10/2013
                 vdj
                 *se agrega procedure para mes (psMes)

                 11/01/2014
                 vdj
                 *se agrega procedure para tipo de contrato (psTCntr)

 modify  29-may-2014

*/

  TYPE t_Cursor IS REF CURSOR;
  TYPE t_Record IS RECORD (rCode VARCHAR2(90),
                           rDesc VARCHAR2(300),
                           rKmp1 VARCHAR2(25),
                           rKmp2 VARCHAR2(25),
                           rKmp3 VARCHAR2(25),
                           rKmp4 VARCHAR2(25)
                          );

  TYPE t_Table IS TABLE OF t_Record INDEX BY BINARY_INTEGER;


  vgsObjcsClean SWRRECL.SWRRECL_OBJECT_CLEAN%TYPE := NULL;
  vgsParametro  SWRRECL.SWRRECL_NOMBRE_PAR%TYPE   := NULL;
  vgsParamCopy1 SWRRECL.SWRRECL_NOMBRE_PAR%TYPE   := NULL;
  vgsParamCopy2 SWRRECL.SWRRECL_NOMBRE_PAR%TYPE   := NULL;
  vgsParamCopy3 SWRRECL.SWRRECL_NOMBRE_PAR%TYPE   := NULL;
  vgsOptionAll  SWRRECL.SWRRECL_ALL%TYPE          := NULL;
  vgnOptionDefl SWRRECL.SWRRECL_DEFAULT%TYPE      := NULL;
  vgnTabIndex   NUMBER(2)                         := NULL;

  vgsSiu        NUMBER(9)    := NULL;
  vgnDire       NUMBER(9)    := NULL;
  vgnSicc       NUMBER(9)    := NULL;
  vgsCollCode   VARCHAR2(3)  := NULL;
  vgsTipo       VARCHAR2(20) := NULL;

  vgsCamp       CONSTANT VARCHAR2(6) := 'UFT';
  csAC          CONSTANT VARCHAR2(2) := 'AC';
  csAS          CONSTANT VARCHAR2(2) := 'AS';
  csGnrlEncs    CONSTANT VARCHAR2(7) := 'psSelCo';

  global_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;

  ---begin "declaración de objetos privados"

  --retorna el objeto select con el catalogo de la universidad
  PROCEDURE PRCCAMP;

  --retorna el objeto select con el catalogo del asesor universitario
  PROCEDURE PRCRECR;

  --retorna el objecto select con el catalogo de categorias del profesor
  PROCEDURE PRCATPR;

  --retorna el objeto multiple con el status
  PROCEDURE PWCFCST;

  --retorna el objeto select con las prepas
  PROCEDURE PWCSBGI;

  --retorna el objeto select con las universidades
  PROCEDURE PWCUNDE;

--retorna el objeto select con los Código Cohorte
  PROCEDURE PWRCOHO;

  --retorna el objeto select con las sesiones
  PROCEDURE PWCCISE;

  --retorna el objeto select con los puestos del asesor
  PROCEDURE PWCPTYP;

  --retorna el objeto select con los periodos
  PROCEDURE PWCTERM(psVerano VARCHAR2 DEFAULT NULL);

  --el procedimiento retorna el objeto select con el nivel de bachilleres
  PROCEDURE PWCEDLV;

  --retorna el objeto select con el nivel academico
  PROCEDURE PWCLEVL(psOtherLevl VARCHAR2 DEFAULT NULL);

  --retorna el objeto select con el tipo de prepa
   PROCEDURE PWCLEVL1;

  --retorna el objeto select con el tipo de prepa
  PROCEDURE PWCGEOD;

  --retorna el objeto select con la carrera
  PROCEDURE PWCMAJR;

  --retorna el objeto select con la consulta de escuelas
  PROCEDURE PWCCOLL (psCollCode VARCHAR2 DEFAULT NULL,
                     psGnrlEncs VARCHAR2 DEFAULT NULL);

  --retorna el objeto select con la consulta de los metodos
  PROCEDURE PWCINSM;

  --retorna el objeto select con la consulta de areas acad?micas
  PROCEDURE PWCCUDA;

  --retorna el objeto select con la consulta de atributos
  PROCEDURE PWCATTR;

  --retorna el objeto select con la consulta de los atributos
  PROCEDURE PWCFATT;

  --retorna el objeto select con la consulta de coordinaciones
  PROCEDURE PWCTOPS;

  --retorna el objeto select con la consulta de grados
  PROCEDURE PWCDEGC;

  --retorna el objeto select con la consulta del subj
  PROCEDURE PWCSUBJ;

  --retorna el objeto select con las materias compuestas de subj,crse y descripcion
  PROCEDURE PWCCRSE;

  --el procedimiento retorna el objeto select con los detail code de pagos
  PROCEDURE PWCDETC(psTypeInd VARCHAR2 DEFAULT NULL );

  PROCEDURE PWCTIPO;

  --retorna el objeto select con laos usuarios
  PROCEDURE PWCBRAU;

  PROCEDURE PWCSRCE;

  PROCEDURE PWCIDEN;

  PROCEDURE PWCRIDN;

  --el procedimiento retorna el objeto select con la consulta de categoria
  PROCEDURE PWCFCTG;

  --el procedimiento retorna el objeto select con la consulta de staff
  PROCEDURE PWCFSTP;

  --retorna el objeto select con la consulta de la nacionalidad
  PROCEDURE PWCCITZ;

  --retorna el objeto select con la consulta de los edificios
  PROCEDURE PWCBLDG;

  --el procedimiento retorna el objeto select con la consulta de los docentes
  PROCEDURE PWCASGN;

  --el procedimiento retorna el objeto select con la consulta del status
  PROCEDURE PWCSSTS;

  --el procedimiento retorna el objeto select con la consulta del contrato
  PROCEDURE PWCFCNT;

  --el procedimiento retorna el objeto select con la consulta del bloque
  PROCEDURE PWCBLCK;

  --el procedimiento retorna el objeto select con la consulta de la funcion
  PROCEDURE PWCNIST;

  --retorna el objeto select con el grupo de la lista cruzada
  PROCEDURE PWCGROP;

  --retorna el objeto select con la consulta del status stvstst
  PROCEDURE PWCSTST;

  --retorna el objeto select con la consulta del status stvstst
  PROCEDURE PWCSTYP;

  --retorna el objeto select con la consulta del programa
  PROCEDURE PWCPRLE;

  --retorna el objeto select con la consulta del programa especial
  PROCEDURE PWCATTS;

--retorna el objeto select con la consulta del atributo de admisiones
  PROCEDURE PWATTAD;

  --retorna el objeto select con la consulta de las becas
  PROCEDURE PWCEXPT;

  --retorna el objeto select con la consulta de los salones
  PROCEDURE PWCRDEF;

  --retorna las autorizaciones
  PROCEDURE PWCAUTH;

  --retorna el objeto select de la consulta de tipos de admision
  PROCEDURE PWCADMT;

  --retorna el objeto select con la consulta de la clase
  PROCEDURE PWCCLAS;

  --retorna el objeto select con la consulta de la inscripcion
  PROCEDURE PWCESTS;

  --retorna la seleccion de los objetos por usuario asignado en un campus
  PROCEDURE PWCOBJS;

  --retorna el objeto select con la consulta del tipo de alumno solo a y n
  PROCEDURE PWCTIAN;

  --retorna el objeto select con la consulta de categoria
  PROCEDURE PWCDCAT(psTuiFee VARCHAR2 DEFAULT NULL);

  --el procedimiento retorna el objeto select con la consulta de los tutores
  PROCEDURE PWCADVR;

  --retorna el objeto select con la consulta de contratos
  PROCEDURE PWCCONT;

  --retorna el nombre del hold
  PROCEDURE PWCHLDD;

  --retorna el nombre de la clase
  PROCEDURE PWCGCLA;

  --retorna el objeto select con la consulta para consultar la encuesta de alumnos por egresar.
  PROCEDURE PWCSRVY;

  --regresa la lista de las actividades deportivas
  PROCEDURE PWCACTC;

  --retorna a todos los usuarios
  PROCEDURE PWCUSRL;

  --el procedimiento retorna la parte de periodo
  PROCEDURE PWCPTRM;

  --retorna el objeto select con la consulta de la session
  PROCEDURE PWCSESS;

  --retorna el objeto select con los usuarios que consultan los reportes
  PROCEDURE PWCUSUR;

  --retorna el objeto select con los modulo de los reportes
  PROCEDURE PWCRECM;

  --retorna el objeto select con los reportes del sistema
  PROCEDURE PWCRECL;

  --muestra el catalogo del standar academico
  PROCEDURE PWCASTD;

  --muestra el catalogo del rate
  PROCEDURE PWCRATE(psFiltro VARCHAR2 DEFAULT NULL);

  --muestra los modulos de las aplicaciones
  PROCEDURE PWCMODL;

  --muestra los modulos de las aplicaciones
  PROCEDURE PWCSMDL;

  --el procedimiento retorna el objeto select con la consulta de los creditos
  PROCEDURE PWCSITE;

  --retorna el objeto select con la consulta de modos de calificacion
  PROCEDURE PWCGMOD (psModoGrade VARCHAR2 DEFAULT NULL );

  -- tipo de accesos por programa y por persona
  PROCEDURE PWCGCHG;

  --retorna la selecciones de enciesta
  PROCEDURE PWCGSRC;

  --retorna los grupos de las listas cruzadas
  PROCEDURE PWCXLST;

  --el procedimiento retorna el objeto select con los nrc de los docentes
  PROCEDURE PWCINST;

  --el procedimiento retorna el catalogo "stvdept"
  PROCEDURE PWCDEPT;

  --muestra la encuesta del seprad
  PROCEDURE PWCTSSC;

  -- devuelve el código del medio de pago y su descripción
  PROCEDURE PWCCDOC;

  -- devuelve el código y descripción del colegio
  PROCEDURE PWCCOLE;

  --devuelve la vía de admisión
  PROCEDURE PWCMATRV;

  PROCEDURE PWCMATRA;

  PROCEDURE PWCMATRN;

  PROCEDURE PWRAPDC;

  PROCEDURE PWRAPDD;
  PROCEDURE PWCMARTYP;
  --muestra la lista de matriculadores con corte de caja
  --gvh 20101215
  PROCEDURE PWMATUSR;

  --enlista el tipo de cheque
  --aigui 20101223
  PROCEDURE PWTICHE;

  --enlista los estados del documento
  --aigui 20101223
  PROCEDURE PWSTADO;

  -- lista de trámites escolares
  -- jccr  20101227
  PROCEDURE PWRTRAE;

  -- lista de trámites notas
  -- jccr  20110114
  PROCEDURE PWRTRAN;

  -- hmr - 08/06/2011: lista de opción para datos de contacto:
  PROCEDURE PWCDATC;

  -- gvh: 20120613: Lista de tipos de resultado de carga de registros (archivo)
  PROCEDURE PWCRGRS;

  -- gvh_ 20120711: Lista de tipos de archivos de carga de recaudacion
  PROCEDURE PWCTCGM;

  --retorna la funcion "f_changecode" para pasar vaslores a otros objetos
  PROCEDURE codigoJavaScript(psReporte VARCHAR2);

  --retorina la lista de los estatus del curso ---amc
  PROCEDURE PWRBJMA;

  --presenta la pagina html para asignar valores a otros objetos

  PROCEDURE PWMONTH;
  --vdj 20131008 despliega los meses
  PROCEDURE PWTCNTR;
  --VDJ 20140111
  PROCEDURE  PWCTERP;
  --VDJ Procedimiento que trae periodos de Postgrado CFC
  --RETORNA EL AÑO ACADEMICO Y SE USARA PARA FILTRAR LOS REPORTES
  PROCEDURE PWCACYR;
  
  PROCEDURE PWCPRLP;
  --VDJ Procedimiento que trae programas de Postgrado CFC

  PROCEDURE PWASLCT(psReporte    VARCHAR2,
                    psParametro1 VARCHAR2,
                    psParametro2 VARCHAR2 DEFAULT NULL,
                    psFiltro1    VARCHAR2 DEFAULT NULL,
                    psFiltro2    VARCHAR2 DEFAULT NULL,
                    psFiltro3    VARCHAR2 DEFAULT NULL,
                    psFiltro4    VARCHAR2 DEFAULT NULL,
                    psFiltro5    VARCHAR2 DEFAULT NULL,
                    psFiltro6    VARCHAR2 DEFAULT NULL,
                    psFiltro7    VARCHAR2 DEFAULT NULL,
                    psFiltro8    VARCHAR2 DEFAULT NULL,
                    psFiltro9    VARCHAR2 DEFAULT NULL,
                    psFiltro10   VARCHAR2 DEFAULT NULL,
                    psFiltro11   VARCHAR2 DEFAULT NULL,
                    psForma      VARCHAR2 DEFAULT 'frmDatos',
                    psALL        VARCHAR2 DEFAULT NULL,
                    pnSiu        NUMBER   DEFAULT NULL,
                    pnDire       NUMBER   DEFAULT NULL,
                    pnSicc       NUMBER   DEFAULT NULL

                   );

  FUNCTION FWASLCT(psReporte   VARCHAR2,
                   psParametro VARCHAR2,
                   psFiltro1   VARCHAR2 DEFAULT NULL,
                   psFiltro2   VARCHAR2 DEFAULT NULL,
                   psFiltro3   VARCHAR2 DEFAULT NULL,
                   psFiltro4   VARCHAR2 DEFAULT NULL,
                   psFiltro5   VARCHAR2 DEFAULT NULL,
                   psFiltro6   VARCHAR2 DEFAULT NULL,
                   psFiltro7   VARCHAR2 DEFAULT NULL,
                   psFiltro8   VARCHAR2 DEFAULT NULL,
                   psFiltro9   VARCHAR2 DEFAULT NULL,
                   psFiltro10  VARCHAR2 DEFAULT NULL,
                   psFiltro11  VARCHAR2 DEFAULT NULL,
                   pnSiu       NUMBER   DEFAULT NULL,
                   pnDire      NUMBER   DEFAULT NULL,
                   pnSicc      NUMBER   DEFAULT NULL
                  ) RETURN t_Cursor;

  ---end "declaración de objetos privados"

  --la consulta se obtiene del valor almacenado en swrrecl_condicion_1
  FUNCTION FWASLCT(psReporte   VARCHAR2,
                   psParametro VARCHAR2,
                   psFiltro1   VARCHAR2 DEFAULT NULL,
                   psFiltro2   VARCHAR2 DEFAULT NULL,
                   psFiltro3   VARCHAR2 DEFAULT NULL,
                   psFiltro4   VARCHAR2 DEFAULT NULL,
                   psFiltro5   VARCHAR2 DEFAULT NULL,
                   psFiltro6   VARCHAR2 DEFAULT NULL,
                   psFiltro7   VARCHAR2 DEFAULT NULL,
                   psFiltro8   VARCHAR2 DEFAULT NULL,
                   psFiltro9   VARCHAR2 DEFAULT NULL,
                   psFiltro10  VARCHAR2 DEFAULT NULL,
                   psFiltro11  VARCHAR2 DEFAULT NULL,
                   pnSiu        NUMBER   DEFAULT NULL,
                   pnDire       NUMBER   DEFAULT NULL,
                   pnSicc       NUMBER   DEFAULT NULL
                  ) RETURN t_Cursor IS

  cuQry  t_Cursor;
  csRe   CONSTANT VARCHAR2(2)  := 'RE';
  csRw   CONSTANT VARCHAR2(2)  := 'RW';
  csOE   CONSTANT VARCHAR2(2)  := 'OE';
  csZZ   CONSTANT VARCHAR2(2)  := 'ZZ';
  csS    CONSTANT VARCHAR2(1)  := 'S';
  csA    CONSTANT VARCHAR2(1)  := 'A';
  csO    CONSTANT VARCHAR2(1)  := 'O';
  csY    CONSTANT VARCHAR2(1)  := 'Y';
  csM    CONSTANT VARCHAR2(1)  := 'M';
  csL    CONSTANT VARCHAR2(1)  := 'L';
  csI    CONSTANT VARCHAR2(1)  := 'I';
  csAst  CONSTANT VARCHAR2(1)  := '*';
  csEsp  CONSTANT VARCHAR2(1)  := ' ';
  csShl  CONSTANT VARCHAR2(1)  := '/';
  csCma  CONSTANT VARCHAR2(1)  := ',';
  csDgl  CONSTANT VARCHAR2(3)  := ' - ';
  csASI  CONSTANT VARCHAR2(26) := 'Aplica a selección interna';
  csATU  CONSTANT VARCHAR2(23) := 'Aplica a todos usuarios';
  csAPG  CONSTANT VARCHAR2(26) := 'Aplica a publico en genral';
  csPlan     CONSTANT VARCHAR2(10) := 'PLANEACION';
  csHHMI     CONSTANT VARCHAR2(10) := 'HH24:MI:SS';
  csDDMMRRRR CONSTANT VARCHAR2(10) := 'DD/MM/RRRR';
  cn0        CONSTANT NUMBER(1)    := 0;
  cn1        CONSTANT NUMBER(1)    := 1;
  cn2        CONSTANT NUMBER(1)    := 2;
  cn3        CONSTANT NUMBER(1)    := 3;
  cn4        CONSTANT NUMBER(1)    := 4;

  BEGIN

      IF    psParametro = 'psNmRfE' THEN
            OPEN cuQry FOR
                 SELECT GVRSRVY_SRN cCode,
                        GVRSRVY_SRN cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM GVRSRVY
                  WHERE GVRSRVY_GSRC_CODE = psFiltro1
                  ORDER BY GVRSRVY_SRN;

      ELSIF psParametro = 'psAplic' THEN
            OPEN cuQry FOR
                 SELECT NULL cCode,
                        DECODE(GVRSRVY_TARGET_CODE,csS,csASI,
                                                   csA,csATU,
                                                   csO,csAPG,NULL) cDesc,
                        GVRSRVY_PS_SELECTION_ID                                           cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM GVRSRVY
                  WHERE GVRSRVY_SRN       = psFiltro1
                    AND GVRSRVY_GSRC_CODE = psFiltro2;

      ELSIF psParametro = 'psPgm' THEN
            OPEN cuQry FOR
                 SELECT SMRPRLE_PROGRAM      cCode,
                        SMRPRLE_PROGRAM||csDgl||SMRPRLE_PROGRAM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SMRPRLE
                  WHERE SMRPRLE_PROGRAM IN (SELECT SGBSTDN_PROGRAM_1
                                              FROM SGBSTDN
                                             WHERE SGBSTDN_PIDM = F_GETPIDM(psFiltro1)
                                           )
                  ORDER BY SMRPRLE_PROGRAM;

      ELSIF psParametro = 'psProg' THEN
            OPEN cuQry FOR
                 SELECT SMRPRLE_PROGRAM      cCode,
                        SMRPRLE_PROGRAM||csDgl||SMRPRLE_PROGRAM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SMRPRLE
                  WHERE SMRPRLE_PROGRAM IN (SELECT SGBSTDN_PROGRAM_1
                                              FROM SGBSTDN
                                             WHERE SGBSTDN_PIDM = F_GETPIDM(psFiltro1)
                                           )
                  ORDER BY SMRPRLE_PROGRAM;

      ELSIF psParametro = 'psCurso' THEN
            OPEN cuQry FOR
                 SELECT DISTINCT SSBSECT_CRSE_NUMB                                            cCode,
                                 SSBSECT_CRSE_NUMB||csDgl||
                                 INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,'''','\'''),'"','\"')) cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SSBSECT,
                        SCBCRSE A
                  WHERE SCBCRSE_SUBJ_CODE     = SSBSECT_SUBJ_CODE
                    AND SCBCRSE_CRSE_NUMB     = SSBSECT_CRSE_NUMB
                    AND A.SCBCRSE_EFF_TERM    = (SELECT MAX(B.SCBCRSE_EFF_TERM)
                                                   FROM SCBCRSE B
                                                  WHERE B.SCBCRSE_SUBJ_CODE  = A.SCBCRSE_SUBJ_CODE
                                                    AND B.SCBCRSE_CRSE_NUMB  = A.SCBCRSE_CRSE_NUMB
                                                    AND B.SCBCRSE_EFF_TERM  <= SSBSECT_TERM_CODE
                                                )
                    AND (SSBSECT_TERM_CODE <= psFiltro2 OR psFiltro2 IS NULL)
                    AND (SCBCRSE_COLL_CODE  = psFiltro3 OR psFiltro3 IS NULL)
                    AND SSBSECT_SUBJ_CODE = psFiltro1
                  ORDER BY   cDesc,cCode;

      ELSIF psParametro = 'psMcrse' THEN
            OPEN cuQry FOR
                 SELECT STVSUBJ_CODE cCode,
                        STVSUBJ_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVSUBJ
                  WHERE (
                            (
                                 STVSUBJ_CODE IN (SELECT SSBSECT_SUBJ_CODE
                                                    FROM SSBSECT
                                                   WHERE SSBSECT_TERM_CODE = psFiltro1
                                                 )
                             AND
                                 psFiltro1 IS NOT NULL
                            )
                         OR
                            psFiltro1 IS NULL
                        )
                  ORDER BY STVSUBJ_CODE;
      ELSIF psParametro = 'psCRNp' THEN
            OPEN cuQry FOR
                 SELECT DISTINCT B.SSBSECT_CRN  cCode,
                                 B.SSBSECT_CRN||csEsp||
                                 A.SCBCRSE_TITLE cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SCBCRSE A,
                        SSBSECT B,
                        SIRASGN C
                  WHERE A.SCBCRSE_SUBJ_CODE = B.SSBSECT_SUBJ_CODE
                    AND A.SCBCRSE_CRSE_NUMB = B.SSBSECT_CRSE_NUMB
                    AND A.SCBCRSE_EFF_TERM  = (SELECT MAX(D.SCBCRSE_EFF_TERM)
                                                 FROM SCBCRSE D
                                                WHERE D.SCBCRSE_EFF_TERM <= B.SSBSECT_TERM_CODE
                                                  AND D.SCBCRSE_SUBJ_CODE = B.SSBSECT_SUBJ_CODE
                                                  AND D.SCBCRSE_CRSE_NUMB = B.SSBSECT_CRSE_NUMB
                                              )
                    AND C.SIRASGN_TERM_CODE = B.SSBSECT_TERM_CODE
                    AND C.SIRASGN_CRN       = B.SSBSECT_CRN
                    AND A.SCBCRSE_COLL_CODE = psFiltro3
                    AND C.SIRASGN_PIDM      = psFiltro1
                    AND B.SSBSECT_TERM_CODE = psFiltro2
                    AND B.SSBSECT_CAMP_CODE = vgsCamp
                    AND SIRASGN_PRIMARY_IND = 'Y'
                  ORDER BY cDesc;

      ELSIF psParametro = 'psNRC' THEN
            OPEN cuQry FOR
                 SELECT SIRASGN_CRN cCode,
                        SIRASGN_CRN cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SIRASGN SI
                  WHERE SIRASGN_PIDM        = psFiltro1
                    AND (SIRASGN_TERM_CODE = psFiltro2 OR psFiltro2 IS NULL)
                    AND SIRASGN_PRIMARY_IND = csY
                    AND EXISTS (SELECT null
                                  FROM SFRSTCR
                                 WHERE SFRSTCR_TERM_CODE  = SI.SIRASGN_TERM_CODE
                                   AND SFRSTCR_CRN        = SI.SIRASGN_CRN
                                   AND SFRSTCR_RSTS_CODE IN (csRe,csRw)
                               )
                  ORDER BY SIRASGN_CRN;

      ELSIF psParametro = 'psProC' THEN
            OPEN cuQry FOR
                 SELECT SPRIDEN_PIDM cCode,
                        REPLACE(REPLACE(SPRIDEN_LAST_NAME ||csEsp||
                                        SPRIDEN_FIRST_NAME||csEsp||
                                        SPRIDEN_MI,'ñ','&ntilde;'),csAst,csEsp) cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SPRIDEN
                  WHERE SPRIDEN_CHANGE_IND IS NULL
                    AND SPRIDEN_PIDM       IN (SELECT SIRASGN_PIDM
                                                 FROM SCBCRSE A,
                                                      SSBSECT B,
                                                      SIRASGN
                                                WHERE A.SCBCRSE_SUBJ_CODE = B.SSBSECT_SUBJ_CODE
                                                  AND A.SCBCRSE_CRSE_NUMB = B.SSBSECT_CRSE_NUMB
                                                  AND A.SCBCRSE_EFF_TERM  = (SELECT MAX(C.SCBCRSE_EFF_TERM)
                                                                               FROM SCBCRSE C
                                                                              WHERE C.SCBCRSE_EFF_TERM <= B.SSBSECT_TERM_CODE
                                                                                AND C.SCBCRSE_SUBJ_CODE = B.SSBSECT_SUBJ_CODE
                                                                                AND C.SCBCRSE_CRSE_NUMB = B.SSBSECT_CRSE_NUMB
                                                                            )
                                                  AND SIRASGN_TERM_CODE   = B.SSBSECT_TERM_CODE
                                                  AND SIRASGN_CRN         = B.SSBSECT_CRN
                                                  AND A.SCBCRSE_COLL_CODE = psFiltro1
                                                  AND B.SSBSECT_TERM_CODE = psFiltro2
                                                  AND B.SSBSECT_CAMP_CODE = vgsCamp
                                                  AND SIRASGN_PRIMARY_IND = csY
                                              )
                  ORDER BY cDesc;

      ELSIF psParametro = 'psPeri2' THEN
            OPEN cuQry FOR
                 SELECT STVTERM_CODE cCode,
                        STVTERM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVTERM
                  WHERE STVTERM_TRMT_CODE IS NOT null
                    AND STVTERM_CODE       > psFiltro1
                  ORDER BY STVTERM_CODE DESC;

      ELSIF psParametro = 'psProfC' THEN
            OPEN cuQry FOR
                 SELECT SPRIDEN_PIDM cCode,
                        SPRIDEN_ID||csDgl||
                        REPLACE(REPLACE(SPRIDEN_LAST_NAME ||csEsp||
                                        SPRIDEN_FIRST_NAME||csEsp||
                                        SPRIDEN_MI,'ñ','&ntilde;'),csAst,csEsp) cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SPRIDEN
                  WHERE SPRIDEN_PIDM IN (SELECT SHRMRKA_MARKER
                                           FROM SCBCRSE A,
                                                SSBSECT SS,
                                                SHRMRKA
                                          WHERE SSBSECT_SUBJ_CODE  = SCBCRSE_SUBJ_CODE
                                            AND SSBSECT_CRSE_NUMB  = SCBCRSE_CRSE_NUMB
                                            AND SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                                        FROM SCBCRSE SC
                                                                       WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                                         AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                                         AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                                                     )
                                            AND SHRMRKA_TERM_CODE  = SSBSECT_TERM_CODE
                                            AND SHRMRKA_CRN        = SSBSECT_CRN
                                            AND SHRMRKA_GCHG_CODE <> csOE
                                            AND (SCBCRSE_COLL_CODE = psFiltro1 OR psFiltro1 = csZZ)
                                            AND SSBSECT_TERM_CODE = psFiltro2
                                            AND SSBSECT_CAMP_CODE = psFiltro3
                                        )
                    AND SPRIDEN_CHANGE_IND IS NULL;

      ELSIF psParametro = 'psCrnAu' THEN
            OPEN cuQry FOR
                 SELECT SSBSECT_CRN cCode,
                        SSBSECT_CRN||csDgl||
                        SSBSECT_SUBJ_CODE||
                        SSBSECT_CRSE_NUMB||csDgl||
                        INITCAP(REPLACE(REPLACE(SCBCRSE_TITLE,'''','\'''),'"','\"')) cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SCBCRSE A,
                        SSBSECT SS
                  WHERE SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                    AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                    AND SCBCRSE_EFF_TERM  = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                               FROM SCBCRSE SC
                                              WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                            )
                    AND EXISTS (SELECT NULL
                                  FROM SHRMRKA
                                 WHERE SHRMRKA_TERM_CODE  = SSBSECT_TERM_CODE
                                   AND SHRMRKA_CRN        = SSBSECT_CRN
                                   AND SHRMRKA_GCHG_CODE <> csOE
                                   AND SHRMRKA_MARKER     = psFiltro1
                               )
                    AND SSBSECT_TERM_CODE = psFiltro2
                    AND (SCBCRSE_COLL_CODE = psFiltro4 OR psFiltro4 = csZZ)
                    AND SSBSECT_CAMP_CODE = psFiltro3;

      ELSIF psReporte = 'SPRDACC' AND psParametro IN ('psSpTac','psPtr2P') THEN
            INSERT INTO FWRSIRG
            (FWRSIRG_TERM_CODE)
            SELECT SVRESAS_TERM_CODE
              FROM SVRESAS
             WHERE    (
                           SVRESAS_TSSC_CODE = psFiltro1
                       AND
                           psParametro = 'psSpTac'
                      )
                   OR
                      (
                           SVRESAS_TSSC_CODE = psFiltro2
                       AND SVRESAS_TERM_CODE = psFiltro1
                       AND psParametro = 'psPtr2P'
                      )
             GROUP BY SVRESAS_TERM_CODE;


            IF    psParametro = 'psSpTac' THEN
                  OPEN cuQry FOR
                       SELECT STVTERM_CODE cCode,
                              STVTERM_CODE||csDgl||STVTERM_DESC cDesc,
                              NULL cDsc1,
                              NULL cDsc2,
                              NULL cDsc3,
                              NULL cDsc4
                         FROM STVTERM
                        WHERE STVTERM_CODE IN  (SELECT SSBSECT_TERM_CODE
                                                  FROM SSBSECT INNER JOIN FWRSIRG
                                                       ON SSBSECT_TERM_CODE = FWRSIRG_TERM_CODE
                                                 WHERE SSBSECT_CAMP_CODE = vgsCamp
                                               )
                        ORDER BY STVTERM_CODE DESC;

            ELSIF psParametro = 'psPtr2P' THEN
                  OPEN cuQry FOR
                       SELECT STVPTRM_CODE cCode,
                              STVPTRM_CODE||csDgl||STVPTRM_DESC cDesc,
                              NULL cDsc1,
                              NULL cDsc2,
                              NULL cDsc3,
                              NULL cDsc4
                         FROM STVPTRM
                        WHERE STVPTRM_CODE IN  (SELECT SSBSECT_PTRM_CODE
                                                  FROM SSBSECT INNER JOIN FWRSIRG
                                                       ON SSBSECT_TERM_CODE = FWRSIRG_TERM_CODE
                                                 WHERE SSBSECT_CAMP_CODE = vgsCamp
                                               )
                        ORDER BY STVPTRM_CODE;
            END IF;

      ELSIF psReporte IN ('PWRASEA','PWRMCSA') AND psParametro = 'psSpTCO' THEN
            OPEN cuQry FOR
                 SELECT STVTERM_CODE cCode,
                        STVTERM_CODE||csDgl||STVTERM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVTERM
                  WHERE STVTERM_CODE IN (SELECT SVRCRSV_EFF_TERM
                                           FROM SVRCRSV
                                          WHERE SVRCRSV_TSSC_CODE = psFiltro1
                                        )
                  ORDER BY STVTERM_CODE DESC;

      ELSIF psParametro IN ('psSpTCO','psSprTP') OR (psParametro = 'psSprTD' AND psReporte IN ('PWRCOMG','PWRDFRE','PWRRESM','PWRARCH','PWRCRED') )THEN
            INSERT INTO FWRSIRG
            (FWRSIRG_TERM_CODE)
            SELECT SWBSEPR_TERM_CODE
              FROM SWBSEPR
             WHERE (SWBSEPR_PIDM = pnSiu OR pnSiu IS NULL)
               AND (
                    (SWBSEPR_COLL_CODE IN (SELECT SIRNIST_COLL_CODE
                                             FROM SIRNIST A
                                            WHERE A.SIRNIST_PIDM      = pnDire
                                              AND A.SIRNIST_TERM_CODE = (SELECT MAX(B.SIRNIST_TERM_CODE)
                                                                           FROM SIRNIST B
                                                                          WHERE B.SIRNIST_PIDM = A.SIRNIST_PIDM
                                                                        )
                                          )
                    )
                    OR pnDire IS NULL)
               AND (
                    (SWBSEPR_PIDM IN (SELECT SIRASGN_PIDM
                                        FROM SSBSECT SS,SIRASGN,SCBCRSE A
                                       WHERE SS.SSBSECT_TERM_CODE = SWBSEPR_TERM_CODE
                                         AND SS.SSBSECT_SUBJ_CODE = A.SCBCRSE_SUBJ_CODE
                                         AND SS.SSBSECT_CRSE_NUMB = A.SCBCRSE_CRSE_NUMB
                                         AND A.SCBCRSE_COLL_CODE  = SWBSEPR_COLL_CODE
                                         AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                                       FROM SCBCRSE SC
                                                                      WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                                        AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                                        AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                                                    )
                                         AND (   ((SS.SSBSECT_SUBJ_CODE,SS.SSBSECT_CRSE_NUMB) IN (SELECT SCBSUPP_SUBJ_CODE,SCBSUPP_CRSE_NUMB
                                                                                                   FROM SIRNIST,SCBSUPP A
                                                                                                  WHERE SIRNIST_TERM_CODE   = SS.SSBSECT_TERM_CODE
                                                                                                    AND SIRNIST_PIDM        = pnSicc
                                                                                                    AND SIRNIST_NIST_CODE   = 'SICC'
                                                                                                    AND A.SCBSUPP_TOPS_CODE = SIRNIST_TOPS_CODE
                                                                                                    AND A.SCBSUPP_EFF_TERM  = (SELECT MAX(B.SCBSUPP_EFF_TERM)
                                                                                                                                 FROM SCBSUPP B
                                                                                                                                WHERE B.SCBSUPP_SUBJ_CODE = A.SCBSUPP_SUBJ_CODE
                                                                                                                                  AND B.SCBSUPP_CRSE_NUMB = A.SCBSUPP_CRSE_NUMB
                                                                                                                                  AND B.SCBSUPP_EFF_TERM <= SIRNIST_TERM_CODE
                                                                                                                              )
                                                                                                )
                                                  )
                                              OR (
                                                  (SS.SSBSECT_TERM_CODE,SS.SSBSECT_CRN)       IN (SELECT SSBOVRR_TERM_CODE,SSBOVRR_CRN
                                                                                                   FROM SSBOVRR
                                                                                                  WHERE SSBOVRR_TOPS_CODE IN (SELECT SIRNIST_TOPS_CODE
                                                                                                                                FROM SIRNIST
                                                                                                                               WHERE SIRNIST_TERM_CODE = SS.SSBSECT_TERM_CODE
                                                                                                                                 AND SIRNIST_NIST_CODE = 'SICC'
                                                                                                                                 AND SIRNIST_PIDM      = pnSicc
                                                                                                                             )
                                                                                                )
                                                 )
                                             )
                                         AND SIRASGN_TERM_CODE = SS.SSBSECT_TERM_CODE
                                         AND SIRASGN_CRN       = SS.SSBSECT_CRN
                                     )
                    )
                    OR pnSicc IS NULL)
               AND SWBSEPR_CAMP_CODE = vgsCamp
               AND SWBSEPR_TSSC_CODE = psFiltro1
             GROUP BY SWBSEPR_TERM_CODE;

            OPEN cuQry FOR
                 SELECT STVTERM_CODE cCode,
                              STVTERM_CODE||csDgl||STVTERM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVTERM
                  WHERE STVTERM_CODE IN (SELECT FWRSIRG_TERM_CODE
                                           FROM FWRSIRG
                                        )
                  ORDER BY STVTERM_CODE DESC;


      ELSIF psParametro = 'psPtrmP' AND psReporte IN ('PWRDFRE','PWRPPCD','PWRARCH','PWRCRED','PWRCOMG') THEN
            INSERT INTO FWRSIRG
            (FWRSIRG_TERM_CODE)
            SELECT SWBSEPR_PTRM_CODE
              FROM SWBSEPR
             WHERE (SWBSEPR_PIDM = pnSiu OR pnSiu IS NULL)
               AND (
                    (SWBSEPR_COLL_CODE IN (SELECT SIRNIST_COLL_CODE
                                             FROM SIRNIST A
                                            WHERE A.SIRNIST_PIDM      = pnDire
                                              AND A.SIRNIST_TERM_CODE = (SELECT MAX(B.SIRNIST_TERM_CODE)
                                                                           FROM SIRNIST B
                                                                          WHERE B.SIRNIST_PIDM = A.SIRNIST_PIDM
                                                                        )
                                          )
                    )
                    OR pnDire IS NULL)
               AND (
                    (SWBSEPR_PIDM IN (SELECT SIRASGN_PIDM
                                        FROM SSBSECT SS,SIRASGN,SCBCRSE A
                                       WHERE SS.SSBSECT_TERM_CODE = SWBSEPR_TERM_CODE
                                         AND SS.SSBSECT_SUBJ_CODE = A.SCBCRSE_SUBJ_CODE
                                         AND SS.SSBSECT_CRSE_NUMB = A.SCBCRSE_CRSE_NUMB
                                         AND A.SCBCRSE_COLL_CODE  = SWBSEPR_COLL_CODE
                                         AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                                       FROM SCBCRSE SC
                                                                      WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                                        AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                                        AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                                                    )
                                         AND (   ((SS.SSBSECT_SUBJ_CODE,SS.SSBSECT_CRSE_NUMB) IN (SELECT SCBSUPP_SUBJ_CODE,SCBSUPP_CRSE_NUMB
                                                                                                   FROM SIRNIST,SCBSUPP A
                                                                                                  WHERE SIRNIST_TERM_CODE   = SS.SSBSECT_TERM_CODE
                                                                                                    AND SIRNIST_PIDM        = pnSicc
                                                                                                    AND SIRNIST_NIST_CODE   = 'SICC'
                                                                                                    AND A.SCBSUPP_TOPS_CODE = SIRNIST_TOPS_CODE
                                                                                                    AND A.SCBSUPP_EFF_TERM  = (SELECT MAX(B.SCBSUPP_EFF_TERM)
                                                                                                                                 FROM SCBSUPP B
                                                                                                                                WHERE B.SCBSUPP_SUBJ_CODE = A.SCBSUPP_SUBJ_CODE
                                                                                                                                  AND B.SCBSUPP_CRSE_NUMB = A.SCBSUPP_CRSE_NUMB
                                                                                                                                  AND B.SCBSUPP_EFF_TERM <= SIRNIST_TERM_CODE
                                                                                                                              )
                                                                                                )
                                                  )
                                              OR (
                                                  (SS.SSBSECT_TERM_CODE,SS.SSBSECT_CRN)       IN (SELECT SSBOVRR_TERM_CODE,SSBOVRR_CRN
                                                                                                   FROM SSBOVRR
                                                                                                  WHERE SSBOVRR_TOPS_CODE IN (SELECT SIRNIST_TOPS_CODE
                                                                                                                                FROM SIRNIST
                                                                                                                               WHERE SIRNIST_TERM_CODE = SS.SSBSECT_TERM_CODE
                                                                                                                                 AND SIRNIST_NIST_CODE = 'SICC'
                                                                                                                                 AND SIRNIST_PIDM      = pnSicc
                                                                                                                             )
                                                                                                )
                                                 )
                                             )
                                         AND SIRASGN_TERM_CODE = SS.SSBSECT_TERM_CODE
                                         AND SIRASGN_CRN       = SS.SSBSECT_CRN
                                     )
                    )
                    OR pnSicc IS NULL)
               AND SWBSEPR_CAMP_CODE = vgsCamp
               AND SWBSEPR_TSSC_CODE = psFiltro2
               AND SWBSEPR_TERM_CODE = psFiltro1
             GROUP BY SWBSEPR_PTRM_CODE;

            OPEN cuQry FOR
                 SELECT STVPTRM_CODE cCode,
                              STVPTRM_CODE||csDgl||STVPTRM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVPTRM
                  WHERE STVPTRM_CODE IN (SELECT FWRSIRG_TERM_CODE
                                           FROM FWRSIRG
                                        )
                  ORDER BY STVPTRM_CODE;
      ELSIF  psParametro = 'psSColP' OR (psParametro = 'psSprCD' AND psReporte IN ('PWRDFRE'))
                                     OR (psParametro = 'psSprCo' AND psReporte IN ('PWRRESM'))
                                     OR (psParametro = 'psSprCo' AND psReporte IN ('PWRARCH'))
                                     OR (psParametro = 'psSprCo' AND psReporte IN ('PWRCRED'))
                                     OR (psParametro = 'psSprCo' AND psReporte IN ('PWRCOMG')) THEN
            INSERT INTO FWRSIRG
            (FWRSIRG_TERM_CODE)
            SELECT SWBSEPR_COLL_CODE
              FROM SWBSEPR
             WHERE (SWBSEPR_PIDM = pnSiu OR pnSiu IS NULL)
               AND (
                    (SWBSEPR_COLL_CODE IN (SELECT SIRNIST_COLL_CODE
                                             FROM SIRNIST A
                                            WHERE A.SIRNIST_PIDM      = pnDire
                                              AND A.SIRNIST_TERM_CODE = (SELECT MAX(B.SIRNIST_TERM_CODE)
                                                                           FROM SIRNIST B
                                                                          WHERE B.SIRNIST_PIDM = A.SIRNIST_PIDM
                                                                        )
                                          )
                    )
                    OR pnDire IS NULL)
               AND (
                    (SWBSEPR_PIDM IN (SELECT SIRASGN_PIDM
                                        FROM SSBSECT SS,SIRASGN,SCBCRSE A
                                       WHERE SS.SSBSECT_TERM_CODE = SWBSEPR_TERM_CODE
                                         AND SS.SSBSECT_SUBJ_CODE = A.SCBCRSE_SUBJ_CODE
                                         AND SS.SSBSECT_CRSE_NUMB = A.SCBCRSE_CRSE_NUMB
                                         AND A.SCBCRSE_COLL_CODE  = SWBSEPR_COLL_CODE
                                         AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                                       FROM SCBCRSE SC
                                                                      WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                                        AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                                        AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                                                    )
                                         AND (   ((SS.SSBSECT_SUBJ_CODE,SS.SSBSECT_CRSE_NUMB) IN (SELECT SCBSUPP_SUBJ_CODE,SCBSUPP_CRSE_NUMB
                                                                                                   FROM SIRNIST,SCBSUPP A
                                                                                                  WHERE SIRNIST_TERM_CODE   = SS.SSBSECT_TERM_CODE
                                                                                                    AND SIRNIST_PIDM        = pnSicc
                                                                                                    AND SIRNIST_NIST_CODE   = 'SICC'
                                                                                                    AND A.SCBSUPP_TOPS_CODE = SIRNIST_TOPS_CODE
                                                                                                    AND A.SCBSUPP_EFF_TERM  = (SELECT MAX(B.SCBSUPP_EFF_TERM)
                                                                                                                                 FROM SCBSUPP B
                                                                                                                                WHERE B.SCBSUPP_SUBJ_CODE = A.SCBSUPP_SUBJ_CODE
                                                                                                                                  AND B.SCBSUPP_CRSE_NUMB = A.SCBSUPP_CRSE_NUMB
                                                                                                                                  AND B.SCBSUPP_EFF_TERM <= SIRNIST_TERM_CODE
                                                                                                                              )
                                                                                                )
                                                  )
                                              OR (
                                                  (SS.SSBSECT_TERM_CODE,SS.SSBSECT_CRN)       IN (SELECT SSBOVRR_TERM_CODE,SSBOVRR_CRN
                                                                                                   FROM SSBOVRR
                                                                                                  WHERE SSBOVRR_TOPS_CODE IN (SELECT SIRNIST_TOPS_CODE
                                                                                                                                FROM SIRNIST
                                                                                                                               WHERE SIRNIST_TERM_CODE = SS.SSBSECT_TERM_CODE
                                                                                                                                 AND SIRNIST_NIST_CODE = 'SICC'
                                                                                                                                 AND SIRNIST_PIDM      = pnSicc
                                                                                                                             )
                                                                                                )
                                                 )
                                             )
                                         AND SIRASGN_TERM_CODE = SS.SSBSECT_TERM_CODE
                                         AND SIRASGN_CRN       = SS.SSBSECT_CRN
                                     )
                    )
                    OR pnSicc IS NULL)
               AND SWBSEPR_CAMP_CODE = vgsCamp
               AND (INSTR(csShl||SWBSEPR_PTRM_CODE||csShl,csShl||psFiltro1) > cn0 OR  psFiltro1 = csShl)
               AND SWBSEPR_TSSC_CODE = psFiltro2
               AND SWBSEPR_TERM_CODE = psFiltro3
             GROUP BY SWBSEPR_COLL_CODE;

            OPEN cuQry FOR
                 SELECT STVCOLL_CODE cCode,
                              STVCOLL_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVCOLL
                  WHERE STVCOLL_CODE IN (SELECT FWRSIRG_TERM_CODE
                                           FROM FWRSIRG
                                        )
                  ORDER BY STVCOLL_CODE;

      ELSIF psParametro = 'psSprCH' THEN
            INSERT INTO FWRSIRG
            (FWRSIRG_TERM_CODE)
            SELECT SWBSEPR_COLL_CODE
              FROM SWBSEPR
             WHERE SWBSEPR_CAMP_CODE = vgsCamp
               AND SWBSEPR_TSSC_CODE = psFiltro1
             GROUP BY SWBSEPR_COLL_CODE;

            OPEN cuQry FOR
                 SELECT STVCOLL_CODE cCode,
                              STVCOLL_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVCOLL
                  WHERE STVCOLL_CODE IN (SELECT FWRSIRG_TERM_CODE
                                           FROM FWRSIRG
                                        )
                  ORDER BY STVCOLL_CODE;

      ELSIF psParametro IN ('psSprPi','psSprPd') THEN
            INSERT INTO FWBFLTY
            (FWBFLTY_PIDM,FWBFLTY_LAST_NAME,FWBFLTY_FIRST_NAME)
            SELECT DISTINCT SWBSEPR_PIDM,
                            (SELECT SPRIDEN_LAST_NAME
                               FROM SPRIDEN
                              WHERE SPRIDEN_PIDM = SWBSEPR_PIDM
                                AND SPRIDEN_CHANGE_IND IS NULL
                            ),
                            (SELECT SPRIDEN_FIRST_NAME
                               FROM SPRIDEN
                              WHERE SPRIDEN_PIDM = SWBSEPR_PIDM
                                AND SPRIDEN_CHANGE_IND IS NULL
                            )
              FROM SWBSEPR
             WHERE (SWBSEPR_PIDM = pnSiu OR pnSiu IS NULL)
               AND (
                    (SWBSEPR_COLL_CODE IN (SELECT SIRNIST_COLL_CODE
                                             FROM SIRNIST A
                                            WHERE A.SIRNIST_PIDM      = pnDire
                                              AND A.SIRNIST_TERM_CODE = (SELECT MAX(B.SIRNIST_TERM_CODE)
                                                                           FROM SIRNIST B
                                                                          WHERE B.SIRNIST_PIDM = A.SIRNIST_PIDM
                                                                        )
                                          )
                    )
                    OR pnDire IS NULL)
               AND (
                    (SWBSEPR_PIDM IN (SELECT SIRASGN_PIDM
                                        FROM SSBSECT SS,SIRASGN,SCBCRSE A
                                       WHERE SS.SSBSECT_TERM_CODE = SWBSEPR_TERM_CODE
                                         AND SS.SSBSECT_SUBJ_CODE = A.SCBCRSE_SUBJ_CODE
                                         AND SS.SSBSECT_CRSE_NUMB = A.SCBCRSE_CRSE_NUMB
                                         AND A.SCBCRSE_COLL_CODE  = SWBSEPR_COLL_CODE
                                         AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                                       FROM SCBCRSE SC
                                                                      WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                                                        AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                                                        AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                                                    )
                                         AND (   ((SS.SSBSECT_SUBJ_CODE,SS.SSBSECT_CRSE_NUMB) IN (SELECT SCBSUPP_SUBJ_CODE,SCBSUPP_CRSE_NUMB
                                                                                                   FROM SIRNIST,SCBSUPP A
                                                                                                  WHERE SIRNIST_TERM_CODE   = SS.SSBSECT_TERM_CODE
                                                                                                    AND SIRNIST_PIDM        = pnSicc
                                                                                                    AND SIRNIST_NIST_CODE   = 'SICC'
                                                                                                    AND A.SCBSUPP_TOPS_CODE = SIRNIST_TOPS_CODE
                                                                                                    AND A.SCBSUPP_EFF_TERM  = (SELECT MAX(B.SCBSUPP_EFF_TERM)
                                                                                                                                 FROM SCBSUPP B
                                                                                                                                WHERE B.SCBSUPP_SUBJ_CODE = A.SCBSUPP_SUBJ_CODE
                                                                                                                                  AND B.SCBSUPP_CRSE_NUMB = A.SCBSUPP_CRSE_NUMB
                                                                                                                                  AND B.SCBSUPP_EFF_TERM <= SIRNIST_TERM_CODE
                                                                                                                              )
                                                                                                )
                                                  )
                                              OR (
                                                  (SS.SSBSECT_TERM_CODE,SS.SSBSECT_CRN)       IN (SELECT SSBOVRR_TERM_CODE,SSBOVRR_CRN
                                                                                                   FROM SSBOVRR
                                                                                                  WHERE SSBOVRR_TOPS_CODE IN (SELECT SIRNIST_TOPS_CODE
                                                                                                                                FROM SIRNIST
                                                                                                                               WHERE SIRNIST_TERM_CODE = SS.SSBSECT_TERM_CODE
                                                                                                                                 AND SIRNIST_NIST_CODE = 'SICC'
                                                                                                                                 AND SIRNIST_PIDM      = pnSicc
                                                                                                                             )
                                                                                                )
                                                 )
                                             )
                                         AND SIRASGN_TERM_CODE = SS.SSBSECT_TERM_CODE
                                         AND SIRASGN_CRN       = SS.SSBSECT_CRN
                                     )
                    )
                    OR pnSicc IS NULL)
               AND SWBSEPR_CAMP_CODE = vgsCamp
               AND (INSTR(csShl||SWBSEPR_PTRM_CODE||csShl,csShl||psFiltro4) > cn0 OR  psFiltro4 = csShl OR psFiltro4 IS NULL)
               AND SWBSEPR_TSSC_CODE = psFiltro2
               AND (SWBSEPR_TERM_CODE = psFiltro3 OR psFiltro3 IS NULL)
               AND SWBSEPR_COLL_CODE = psFiltro1;

            OPEN cuQry FOR
                 SELECT FWBFLTY_PIDM cCode,
                        REPLACE(FWBFLTY_LAST_NAME||csEsp||FWBFLTY_FIRST_NAME,csAst,csEsp) cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM FWBFLTY
                  ORDER BY cDesc;

      ELSIF psParametro = 'psSprCr' THEN
            OPEN cuQry FOR
                 SELECT SWRSEPR_TIPO_CRN||csCma||SWRSEPR_CRN AS cCode,
                        DECODE(SWRSEPR_TIPO_CRN,csI,NULL,
                                                csL,SWRSEPR_TIPO_CRN||csDgl||SWRSEPR_GRUPO||csDgl,SWRSEPR_TIPO_CRN||csDgl)||
                        SWRSEPR_CRN||csEsp||SWRSEPR_TITLE    AS cDesc,
                        DECODE(SWRSEPR_TIPO_CRN,csM,cn1,csS,cn2,csL,cn3,csI,cn4) cDsc1,
                        COUNT(1)         AS cDsc2,
                        SWRSEPR_GRUPO    AS cDsc3,
                        SWRSEPR_TIPO_CRN AS cDsc4
                   FROM SWRSEPR
                  WHERE SWRSEPR_CAMP_CODE = vgsCamp
                    AND SWRSEPR_PIDM      = psFiltro1
                    AND SWRSEPR_TEQA_CODE = csPlan
                    AND (INSTR(csShl||SWRSEPR_PTRM_CODE||csShl,csShl||psFiltro5) > cn0 OR  psFiltro5 = csShl)
                    AND SWRSEPR_COLL_CODE = psFiltro4
                    AND SWRSEPR_TERM_CODE = psFiltro3
                    AND SWRSEPR_TSSC_CODE = psFiltro2
                  GROUP BY SWRSEPR_TIPO_CRN||csCma||SWRSEPR_CRN,
                           DECODE(SWRSEPR_TIPO_CRN,csI,NULL,
                                                csL,SWRSEPR_TIPO_CRN||csDgl||SWRSEPR_GRUPO||csDgl,SWRSEPR_TIPO_CRN||csDgl)||
                           SWRSEPR_CRN||csEsp||SWRSEPR_TITLE,
                           DECODE(SWRSEPR_TIPO_CRN,csM,cn1,csS,cn2,csL,cn3,csI,cn4),
                           SWRSEPR_GRUPO,
                           SWRSEPR_TIPO_CRN
                  ORDER BY cDsc1,cDsc3,cDsc4;

      ELSIF psParametro = 'psPtrmP' THEN
            INSERT INTO FWRSIRG
            (FWRSIRG_TERM_CODE)
            SELECT SVRESAS_TERM_CODE
              FROM SVRESAS
             WHERE SVRESAS_TSSC_CODE = psFiltro2
               AND SVRESAS_TERM_CODE = psFiltro1
             GROUP BY SVRESAS_TERM_CODE;

            OPEN cuQry FOR
                 SELECT STVPTRM_CODE cCode,
                        STVPTRM_CODE||csDgl||STVPTRM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM STVPTRM
                  WHERE STVPTRM_CODE IN  (SELECT SSBSECT_PTRM_CODE
                                            FROM SSBSECT INNER JOIN FWRSIRG
                                                 ON SSBSECT_TERM_CODE = FWRSIRG_TERM_CODE
                                           WHERE SSBSECT_CAMP_CODE = vgsCamp
                                         )
                  ORDER BY STVPTRM_CODE;

      ELSIF psParametro = 'psCrn' THEN
            INSERT INTO FWRSIRG(FWRSIRG_CRN)
            SELECT SSBSECT_CRN
              FROM SSBSECT,
                   SVRESAS,
                   (SELECT A.SGBSTDN_PIDM stdnPidm
                      FROM SGBSTDN A
                     WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                        FROM SGBSTDN B
                                                       WHERE B.SGBSTDN_PIDM      = A.SGBSTDN_PIDM
                                                         AND B.SGBSTDN_CAMP_CODE = vgsCamp
                                                     )
                       AND A.SGBSTDN_CAMP_CODE     = vgsCamp
                       AND A.SGBSTDN_COLL_CODE_1   = psFiltro1
                   ) SGBSTD
             WHERE SVRESAS_TERM_CODE   = SSBSECT_TERM_CODE
               AND SVRESAS_CRN         = SSBSECT_CRN
               AND (INSTR(csShl||SSBSECT_PTRM_CODE||csShl,csShl||psFiltro4) > cn0 OR  psFiltro4 = csShl)
               AND SSBSECT_TERM_CODE   = psFiltro3
               AND SVRESAS_TSSC_CODE   = psFiltro2
               AND SVRESAS_PIDM        = SGBSTD.stdnPidm
               AND SSBSECT_CAMP_CODE   = vgsCamp;

            OPEN cuQry FOR
                 SELECT FWRSIRG_CRN cCode,
                        FWRSIRG_CRN cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM FWRSIRG
                  GROUP BY FWRSIRG_CRN
                  ORDER BY FWRSIRG_CRN;

      ELSIF psParametro = 'psSprCo' THEN
            INSERT INTO FWRSIRG
            (FWRSIRG_COLL_CODE,   FWRSIRG_TERM_CODE,FWRSIRG_CRN)
            SELECT
             SGBSTDN_COLL_CODE_1, SVRESAS_TERM_CODE,SVRESAS_CRN
              FROM SVRESAS,
                   SGBSTDN
             WHERE SVRESAS_PIDM      = SGBSTDN_PIDM
               AND SGBSTDN_CAMP_CODE = vgsCamp
               AND SVRESAS_TSSC_CODE = psFiltro2
               AND SVRESAS_TERM_CODE = psFiltro3;

            OPEN cuQry FOR
            SELECT STVCOLL_CODE cCode,
                   STVCOLL_DESC cDesc,
                   NULL cDsc1,
                   NULL cDsc2,
                   NULL cDsc3,
                   NULL cDsc4
              FROM STVCOLL
             WHERE STVCOLL_CODE IN (SELECT FWRSIRG_COLL_CODE
                                      FROM FWRSIRG, SSBSECT
                                     WHERE FWRSIRG_TERM_CODE = SSBSECT_TERM_CODE
                                       AND FWRSIRG_CRN       = SSBSECT_CRN
                                       AND (INSTR(csShl||psFiltro1,csShl||SSBSECT_PTRM_CODE||csShl) > cn0 OR psFiltro1 IS NULL OR psFiltro1='/')
                                       AND SSBSECT_TERM_CODE = psFiltro3
                                       AND SSBSECT_CAMP_CODE = vgsCamp
                                   )
             ORDER BY cCode;

      ELSIF psParametro = 'psHora' AND psReporte IN ('PWRMORO') THEN
            OPEN cuQry FOR
                 SELECT DISTINCT TWRMORO_REPORT_SEQ                    AS cCode,
                                 TO_CHAR(TWRMORO_ACTIVITY_DATE,csHHMI) AS cDesc,
                                 NULL cDsc1,
                                 NULL cDsc2,
                                 NULL cDsc3,
                                 NULL cDsc4
                   FROM TWRMORO
                  WHERE (TWRMORO_DOCU_TERM_CODE <= psFiltro2 OR psFiltro2 IS NULL)
                    AND TRUNC(TWRMORO_RANK_DATE) = TO_DATE(psFiltro3,csDDMMRRRR)
                  ORDER BY cDesc DESC;

      ELSIF psParametro = 'psHora' AND psReporte IN ('PWRMRGL') THEN
            OPEN cuQry FOR
                 SELECT DISTINCT TWRMRDT_REPORT_SEQ                    AS cCode,
                                 TO_CHAR(TWRMRDT_ACTIVITY_DATE,csHHMI) AS cDesc,
                                 NULL cDsc1,
                                 NULL cDsc2,
                                 NULL cDsc3,
                                 NULL cDsc4
                   FROM TWRMRDT
                  WHERE (TWRMRDT_DOCU_TERM_CODE <= psFiltro2 OR psFiltro2 IS NULL)
                    AND TRUNC(TWRMRDT_RANK_DATE) = TO_DATE(psFiltro3,csDDMMRRRR)
                    --AND SUBSTR(TWRMRDT_RANK_DATE,1,10)  = psFiltro3
                  ORDER BY cDesc DESC;
         --vdelacruz 20140630


      ELSIF psParametro = 'psProg1' THEN

      OPEN cuQry FOR
                   SELECT SMRPRLE_PROGRAM      cCode,
                        SMRPRLE_PROGRAM||csDgl||SMRPRLE_PROGRAM_DESC cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM SMRPRLE
                   WHERE (instr('/'||psFiltro1 , '/'||SMRPRLE_LEVL_CODE||'/') > 0 or   psFiltro1 = '/'  OR  psFiltro1 is null);


      ELSE
         OPEN cuQry FOR
                 SELECT NULL AS cCode,
                        NULL AS cDesc,
                        NULL cDsc1,
                        NULL cDsc2,
                        NULL cDsc3,
                        NULL cDsc4
                   FROM DUAL;
      END IF;

      RETURN cuQry;

  END FWASLCT;

  --en el procedimiento se determina que proceso sera ejecutado.
  PROCEDURE Selcct(psParametro VARCHAR2,
                   pnTabIndex  INTEGER,
                   pnSiu       NUMBER   DEFAULT NULL,
                   pnDire      NUMBER   DEFAULT NULL,
                   pnSicc      NUMBER   DEFAULT NULL,
                   psReporte   VARCHAR2 DEFAULT NULL,
                   psCollCode  VARCHAR2 DEFAULT NULL,
                   psTipo      VARCHAR2 DEFAULT NULL,
                   psCondicio1 VARCHAR2 DEFAULT NULL,
                   psCondicio2 VARCHAR2 DEFAULT NULL,
                   psCondicio3 VARCHAR2 DEFAULT NULL,
                   psObjClean  VARCHAR2 DEFAULT NULL,
                   psOptionAll VARCHAR2 DEFAULT NULL,
                   psOptionDfl VARCHAR2 DEFAULT NULL
                  ) IS

  vsSize   VARCHAR2(10) := NULL;
  vsStyle  VARCHAR2(20) := 'class="desAGS"';
  vsOption VARCHAR2(30) := NULL;

  BEGIN
      vgsParametro  := psParametro;
      vgnTabIndex   := pnTabIndex;
      vgsParamCopy1 := psCondicio1;
      vgsParamCopy2 := psCondicio2;
      vgsParamCopy3 := psCondicio3;
      vgsObjcsClean := psObjClean;
      vgnOptionDefl := psOptionDfl;
      vgsOptionAll  := psOptionAll;
      vgsSiu        := pnSiu;
      vgnDire       := pnDire;
      vgnSicc       := pnSicc;
      vgsCollCode   := psCollCode;
      vgsTipo       := psTipo;

      -- si el objeto "select" de html es de tipo multiple
      -- adquiere las siguientes caracteristicas
      IF psTipo = 'MULTIPLE' THEN
         vsSize  := 'size="6"';
         vsStyle := 'style="width:100%"';
      END IF;

      -- si el objeto select tiene la opción para que seleccionen la
      -- opción "todos" (todos los valores) se agrega esta opción
      IF psOptionAll = 'ALL' THEN
         vsOption := '<option value=""></option>';
      END IF;

      --retorna la funcion "f_changecode" para pasar valores a otros objetos
      codigoJavaScript(psReporte);

      htp.p('
      <select name="'||psParametro||'" tabindex="'||pnTabIndex||'" '||vsStyle||' '||psTipo||' '||vsSize||' onChange="f_ChangeCode'||pnTabIndex||'(this.value);">
      '||vsOption
      );

      IF    vgsParametro IN ('psSprUc','psUnive','psSede','psSprUn')  THEN
            PRCCAMP;

      ELSIF vgsParametro = 'psStCur' THEN   --amc
            PWRBJMA;

      ELSIF vgsParametro = 'psCohor' THEN   --amc
            PWRCOHO;

      ELSIF vgsParametro = 'psAsPrU' THEN
            PRCRECR;
            
      ELSIF vgsParametro = 'psAcyr'   THEN
            PWCACYR;

      ELSIF vgsParametro = 'psPrePa' THEN
            PWCSBGI;

      ELSIF vgsParametro = 'psUniDe' THEN
            PWCUNDE;

      ELSIF vgsParametro IN ('psPerio','psPeri2','psPeriM','psTermC','psTerm','psPeri1')  THEN
            PWCTERM;

      ELSIF vgsParametro = 'psPVera' THEN
            PWCTERM('VERANO');

      ELSIF vgsParametro = 'psPuest' THEN
            PWCPTYP;

      ELSIF vgsParametro = 'psNivBa' THEN
            PWCEDLV;

      ELSIF vgsParametro = 'psNivel' THEN
            PWCLEVL;

      ELSIF vgsParametro = 'psNivl1' THEN
            PWCLEVL1;

      ELSIF vgsParametro = 'psNive2' THEN
            PWCLEVL('L');

      ELSIF vgsParametro = 'psTipPr' THEN
            PWCGEOD;

      ELSIF vgsParametro = 'psMajrr' THEN
            PWCMAJR;

      ELSIF vgsParametro = 'psSesio' THEN
            PWCCISE;

      ELSIF vgsParametro = 'psSubjc' THEN
            PWCSUBJ;

      ELSIF vgsParametro IN ('psColl','psEsclR','psEscP','psEsST') THEN
            PWCCOLL;

      ELSIF vgsParametro IN ('psEscu','psFacu') THEN
            PWCCOLL(psCollCode);

      ELSIF vgsParametro = 'psGrado' THEN
            PWCDEGC;

      ELSIF vgsParametro = 'psSubC'  THEN
            PWCCRSE;

      ELSIF vgsParametro = 'psModo'  THEN
            PWCGMOD;

      ELSIF vgsParametro = 'psArea'  THEN
            PWCCUDA;

      ELSIF vgsParametro = 'psAtrib' THEN
            PWCATTR;

      ELSIF vgsParametro = 'psAtbs'  THEN
            PWCFATT;

      ELSIF vgsParametro = 'psCoord' THEN
            PWCTOPS;

      ELSIF vgsParametro = 'psDetP'  THEN
            PWCDETC('P');

      ELSIF vgsParametro = 'psDet'   THEN
            PWCDETC;

      ELSIF vgsParametro IN ('psTipo',  'psTipoC',  'psProfe', 'psTipol',
                             'psBcoTC', 'psAccpr',  'pLisOr3', 'pLisOr2',
                             'pLisOrd', 'pLisEgr',  'pLisEgr', 'pFecEgr',
                             'psNive3', 'psOport',  'psFecha', 'psCupo',
                             'psTipoD', 'psTipoN',  'psTnDoc', 'psTipPa',
                             'psError', 'psUsuObj', 'psOri',   'psEnca',
                             'psSesi',  'psStatb',  'psCapp',  'psSprCn',
                             'psLogo'
                            )   THEN
            PWCTIPO;

      ELSIF vgsParametro = 'psOrige' THEN
            PWCSRCE;

      ELSIF vgsParametro = 'psUsuar' THEN
            PWCBRAU;

      ELSIF vgsParametro = 'psUser'  THEN
            PWCIDEN;

      ELSIF vgsParametro = 'psCate'  THEN
            PWCFCTG;

      ELSIF vgsParametro IN ('psStatu','psStatM')  THEN
            PWCFCST;

      ELSIF vgsParametro = 'psType'  THEN
            PWCFSTP;

      ELSIF vgsParametro = 'psNacio' THEN
            PWCCITZ;

      ELSIF vgsParametro = 'psLista' THEN
            PWCXLST;

      ELSIF vgsParametro = 'psMetod' THEN
            PWCINSM;

      ELSIF vgsParametro = 'psEdifi' THEN
            PWCBLDG;

      ELSIF vgsParametro = 'psDoce'  THEN
            PWCINST;

      ELSIF vgsParametro = 'psDocen' THEN
            PWCASGN;

      ELSIF vgsParametro = 'psStat1' THEN
            PWCSSTS;

      ELSIF vgsParametro = 'psTycon' THEN
            PWCFCNT;

      ELSIF vgsParametro = 'psBlock' THEN
            PWCBLCK;

      ELSIF vgsParametro = 'psFunc'  THEN
            PWCNIST;

      ELSIF vgsParametro = 'psLista' THEN
            PWCGROP;

      ELSIF vgsParametro = 'psSstst' THEN
            PWCSTST;

      ELSIF vgsParametro = 'psSstst' THEN
            PWCSTYP;

      ELSIF vgsParametro = 'psProgr' THEN
            PWCPRLE;

      ELSIF vgsParametro = 'psProEs' THEN
            PWCATTS;

     ELSIF vgsParametro = 'psAttAd' THEN
            PWATTAD;

     ELSIF vgsParametro = 'psIndSe' THEN
            PWATTAD;

      ELSIF vgsParametro = 'psId'    THEN
            PWCRIDN;

      ELSIF vgsParametro = 'psBeca'  THEN
            PWCEXPT;

      ELSIF vgsParametro = 'psSalon' THEN
            PWCRDEF;

      ELSIF vgsParametro = 'psAutor' THEN
            PWCAUTH;

      ELSIF vgsParametro = 'psTipoA' THEN
            PWCADMT;

      ELSIF vgsParametro = 'psClase' THEN
            PWCCLAS;

      ELSIF vgsParametro = 'psStIns' THEN
            PWCESTS;

      ELSIF vgsParametro = 'psObj'   THEN
            PWCOBJS;

      ELSIF vgsParametro = 'psTyAl'  THEN
            PWCSTYP;

      ELSIF vgsParametro = 'psTiPo'  THEN
            PWCTIAN;

      ELSIF vgsParametro = 'psCate2' THEN
            PWCDCAT;

      ELSIF vgsParametro = 'psCate3' THEN
            PWCDCAT('TUIFEE');

      ELSIF vgsParametro = 'psTutor' THEN
            PWCADVR;

      ELSIF vgsParametro = 'psCred'  THEN
            PWCCONT;

      ELSIF vgsParametro = 'psHold'  THEN
            PWCHLDD;

      ELSIF vgsParametro = 'psClas'  THEN
            PWCGCLA;

      ELSIF vgsParametro = 'psSelEn' THEN
            PWCSRVY;

      ELSIF vgsParametro = 'psDepor' THEN
            PWCACTC;

      ELSIF vgsParametro = 'psUsuAl' THEN
            PWCUSRL;

      ELSIF vgsParametro = 'psPtrm'  THEN
            PWCPTRM;

      ELSIF vgsParametro = 'psMcrse' THEN
            PWCSUBJ;

      ELSIF vgsParametro = 'psSessi' THEN
            PWCSESS;

      ELSIF vgsParametro = 'psUserR' THEN
            PWCUSUR;

      ELSIF vgsParametro = 'psModul' THEN
            PWCRECM;

      ELSIF vgsParametro = 'psRepor' THEN
            PWCRECL;

      ELSIF vgsParametro = 'psStand' THEN
            PWCASTD;

      ELSIF vgsParametro = 'psRate'  THEN
            PWCRATE;

      ELSIF vgsParametro = 'psRatS'  THEN
            PWCRATE('JP%');

      ELSIF vgsParametro = 'psModl'  THEN
            PWCMODL;

      ELSIF vgsParametro = 'psApli'  THEN
            PWCSMDL;

      ELSIF vgsParametro = 'psEncst' THEN
            PWCGSRC;

      ELSIF vgsParametro = 'psGchg'  THEN
            PWCGCHG;

      ELSIF vgsParametro = 'psModRC' THEN
            PWCGMOD('Tipos');

      ELSIF vgsParametro = 'psSite'  THEN
            PWCSITE;

      ELSIF vgsParametro IN ('psLevl','psNiveM')  THEN
            PWCLEVL;

      ELSIF psParametro = 'psDept'   THEN
            PWCDEPT;

      ELSIF psParametro = 'psSeprd'  THEN
            PWCTSSC;

      ELSIF psParametro = 'psPago'  THEN
            PWCCDOC;

      ELSIF psParametro = 'psCole'  THEN
            PWCCOLE;

     ELSIF psParametro = 'psVia'  THEN
            PWCMARTYP;

     ELSIF psParametro = 'psViaAd' THEN
        PWCMATRV;

     ELSIF psParametro = 'psAño'  THEN
            PWCMATRA;

     ELSIF psParametro = 'psNueAv'  THEN
            PWCMATRN;

      ELSIF psParametro = 'psCatpr'  THEN
            PRCATPR;

     ELSIF psParametro = 'psCatpr'  THEN
            PWCSTYP;

      ELSIF psParametro = 'psSelCo'  THEN
            PWCCOLL;

      ELSIF psParametro = 'psApdc' THEN
            PWRAPDC;
      ELSIF psParametro = 'psApdd' THEN
            PWRAPDD;

      --gvh: lista de matriculadores con cierre de caja
      ELSIF psParametro = 'psMtUs' THEN
            PWMATUSR;

      --aigui: lista de tipos de cheque
      ELSIF psParametro = 'psTiChe' THEN
            PWTICHE;

      --aigui: lista de estados de documento
      ELSIF psParametro = 'psTaDoc' THEN
            PWSTADO;

      --jccr: lista de trámites de certificados de estudios
      ELSIF psParametro = 'psTraCe' THEN
            PWRTRAE;

      --jccr: lista de trámites de certificados de notas
      ELSIF psParametro = 'psTraNt' THEN
            PWRTRAN;

      -- hmr - 08/06/2011: lista de opción para datos de contacto:
      ELSIF psParametro = 'psDatCo' THEN
            PWCDATC;

      --gvh: lista de resultados de registro
   ELSIF psParametro = 'psRgRes' THEN
         PWCRGRS;

      --gvh: lista de tipos de carga de matricua
   ELSIF psParametro = 'psTcgm' THEN
         PWCTCGM;
   --vdj : lista de meses del año
   ELSIF psParametro = 'psMes' THEN
        PWMONTH;
   --vdj : lista de meses del año
   ELSIF psParametro = 'psTCntr' THEN
        PWTCNTR;
  ELSIF psParametro = 'psPeCFC' THEN
        PWCTERP;
   --vdj: Periodos Postgrado CFC
  ELSIF psParametro ='psPrCFC' THEN
          PWCPRLP;
     --vdj: Programas Postgrado CFC
      END IF;

      htp.p('</select>');

  END Selcct;

  --en el procedimiento se determina que proceso sera ejecutado.
  PROCEDURE Text(psParametro VARCHAR2,
                 pnTabIndex  INTEGER,
                 psReporte   VARCHAR2,
                 psCondicion VARCHAR2
                ) IS
  BEGIN
      vgsParamCopy1 := psCondicion;
      vgsParametro  := psParametro;
      vgnTabIndex   := pnTabIndex;

      --retorna la funcion "f_changecode" para pasar vaslores a otros objetos
      codigoJavaScript(psReporte);

      htp.p('<input name="'||psParametro||'" type="text" tabindex="'||pnTabIndex||'"  class="desAGS" onChange="f_ChangeCode'||pnTabIndex||'(this.value);">');
  END Text;

--Procedimiento hora
  PROCEDURE Hora(psParametro VARCHAR2,
                 pnTabIndex  INTEGER,
                 psReporte   VARCHAR2,
                 psCondicion VARCHAR2
                ) IS
  BEGIN
      vgsParamCopy1 := psCondicion;
      vgsParametro  := psParametro;
      vgnTabIndex   := pnTabIndex;

      --retorna la funcion "f_changecode" para pasar vaslores a otros objetos
      codigoJavaScript(psReporte);

      htp.p('
      <table border="0" cellpadding="1" cellspacing="1" width="100%">
             <tr><td width="70%">
                    <select name="'||psParametro||'" tabindex="'||pnTabIndex||'"  style="width:100%" >
                    </select>
                    </td>
                 <td width="30%">
                    <input type="button" value="Consultar Hora" class="btn01" onClick="f_ChangeCode'||pnTabIndex||'(1);" />
                 </td>
             </tr>
      </table>
      ');
  END Hora;


  --retorna la funcion "f_changecode" para pasar vaslores a otros objetos
  PROCEDURE codigoJavaScript(psReporte VARCHAR2) IS

  vsObjClean VARCHAR2(10)   := NULL;
  vsUrl      VARCHAR2(2000) := NULL;

  procedure concatenar(psVariable varchar2,
                       psObjeto   varchar2
                      ) is

  begin
      htp.p(
      psVariable||' = "";

      for(var vnI = 0; vnI < document.frmDatos.'||psObjeto||'.length; vnI++) {
          if(document.frmDatos.'||psObjeto||'.options[vnI].selected == true) {
            '||psVariable||' = '||psVariable||' + document.frmDatos.'||psObjeto||'.options[vnI].value + "/";
          }
      }'
      );
  end concatenar;

  BEGIN
      htp.p('
      <script type="text/javascript">
      <!--

      ');
      htp.p('function f_ChangeCode'||vgnTabIndex||'(psValue) {
        var vsValue1 = psValue;
        var vsValue2 = "";
        var vsValue3 = "";
        var vsValue4 = "";
        var vsValue5 = "";
        var vsValue6 = "'||vgsCollCode||'";
        var vsValue7 = "";
        var vsValue8 = "";
        var vsValue9 = "";
        var vsValue10 = "";
      ');

      IF    vgsParametro = 'psNmRfE' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psEncst'));

      ELSIF vgsParametro = 'psMcrse' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psTermC'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psFacu'));

      ELSIF vgsParametro ='psDoce' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psPerio'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psFacu'));

      ELSIF vgsParametro = 'psProC' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psPerio'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psEscP'));

      ELSIF vgsParametro = 'psEscP' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psPerio'));

      ELSIF vgsParametro = 'psProfC' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psPerio'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psUnive'));
            htp.p('vsValue4 = '||pk_ObjHTML.selectIndex('frmDatos','psEsclR'));

      ELSIF vgsParametro = 'psEsclR' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psPerio'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psUnive'));

      ELSIF vgsParametro = 'psPtr2P' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psSpTac'));

            concatenar('vsValue1',vgsParametro);

      ELSIF vgsParametro IN ('psSpTac','psSpTCO','psSprTD','psSprTP','psSprCH') THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));

      ELSIF vgsParametro = 'psPtrmP' AND psReporte IN ('PWRDFRE','PWRRESM','PWRARCH','PWRCRED','PWRCOMG') THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psSprTD'));

            concatenar('vsValue1',vgsParametro);

      ELSIF vgsParametro = 'psPtrmP' AND psReporte IN ('PWRPPCD','PWRCOMD') THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psSprTP'));

            concatenar('vsValue1',vgsParametro);

      ELSIF vgsParametro = 'psSprCD' AND psReporte IN ('PWRDFRE') THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psSprTD'));

            concatenar('vsValue4','psPtrmP');

      ELSIF vgsParametro = 'psSprPi' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psSprTD'));
            htp.p('vsValue4 = '||pk_ObjHTML.selectIndex('frmDatos','psSprCD'));

            concatenar('vsValue5','psPtrmP');

      ELSIF vgsParametro = 'psSColP' THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psSprTP'));

            concatenar('vsValue4','psPtrmP');

      ELSIF vgsParametro = 'psSprCo' AND psReporte NOT IN ('PWRCOMG','PWRRESM','PWRARCH','PWRRESM','PWRCRED','PWRCOMG') THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psSeprd'));
            htp.p('vsValue3 = '||pk_ObjHTML.selectIndex('frmDatos','psSpTac'));

            concatenar('vsValue4','psPtr2P');

      ELSIF vgsParametro = 'psHora' AND psReporte IN ('PWRMORO') THEN
            htp.p('vsValue2 = '||pk_ObjHTML.selectIndex('frmDatos','psPerio'));
            htp.p('vsValue3 = document.frmDatos.psFecha.value');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWCLADO') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWMATCO') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRBFIN') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRADCFC') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRCENV') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRCEN2') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRISCR') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRIVIN') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRMNLD3') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRMNLI') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRMNLA') THEN
            concatenar('vsValue1','psNivl1');       
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRMNLD') THEN
            concatenar('vsValue1','psNivl1');       
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWADXCA') THEN
            concatenar('vsValue1','psNivl1'); 
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRSEGP') THEN
            concatenar('vsValue1','psNivl1');       
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRSEGM') THEN
            concatenar('vsValue1','psNivl1');       
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRPOST') THEN
            concatenar('vsValue1','psNivl1');            
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRSEDM') THEN
            concatenar('vsValue1','psNivl1');  
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRCENS') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRCICO') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRTMAI') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRSACD') THEN
            concatenar('vsValue1','psNivl1');
      ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWRSACD') THEN
            concatenar('vsValue1','psNivl1');
        ELSIF vgsParametro = 'psNivl1' AND psReporte IN ('PWLIBVE') THEN
            concatenar('vsValue1','psNivl1');
            --AQUI        
         
         

            
      
                
            
      
      

      END IF;

      --coloca el código javascript para limpiar objetos select de html
      IF vgsObjcsClean IS NOT NULL THEN
         WHILE INSTR(vgsObjcsClean,',') > 0 LOOP
               vsObjClean := SUBSTR(vgsObjcsClean,1, INSTR(vgsObjcsClean,',') - 1);

               pk_ObjHTML.cleanSelect(vsObjClean);

               vgsObjcsClean := SUBSTR(vgsObjcsClean,INSTR(vgsObjcsClean,',') + 1);
         END LOOP;

         vgsObjcsClean := NULL;
         vsObjClean    := NULL;
      END IF;

      IF    (vgsParametro = 'psPtrmP' AND psReporte IN ('PWRCEEF','PWRASEA','PWRMCSA'))
            OR
            (vgsParametro = 'psSprCo' AND psReporte IN ('PWRARCH','PWRRESM','PWRCRED','PWRCOMG'))
            THEN
            NULL;
      ELSIF vgsParametro IN ('psSprCo', 'psSColP', 'psSprTP', 'psSprPi',
                             'psSprCD', 'psPtrmP', 'psSprTD', 'psPtr2P',
                             'psSpTac', 'psSpTCO', 'psSeprd', 'psEncst',
                             'psNmRfE', 'psExped', 'psMcrse', 'psTermC',
                             'psDoce',  'psPeri1', 'psProfC', 'psEsclR',
                             'psEscP',  'psProC',  'psSprCH', 'psHora',
                             'psNivl1'
                            ) THEN

            htp.p('
            var vsURL = "kwaObjPrm.returnValor?psReporte='||psReporte||'&psParametro1='||vgsParamCopy1||'&psParametro2='||vgsParamCopy2||'&psFiltro1="+vsValue1+
            "&psFiltro2="+vsValue2+
            "&psFiltro3="+vsValue3+
            "&psFiltro4="+vsValue4+
            "&psFiltro5="+vsValue5+
            "&psFiltro6="+vsValue6+
            "&psFiltro7="+vsValue7+
            "&psFiltro8="+vsValue8+
            "&psFiltro9="+vsValue9+
            "&psFiltro10="+vsValue10+
            "&psALL=' ||vgsOptionAll||'"+
            "&pnSiu=' ||vgsSiu ||'"+
            "&pnDire='||vgnDire||'"+
            "&pnSicc='||vgnSicc||'";

            frmLOV = open(vsURL, "ventanaReturn", "toolbar=,directories=no,status=no,resizable=yes,location=no,titlebar=no,scrollbars=no");

            if (navigator.appVersion.charAt(0) >=4) {
                frmLOV.resizeTo(10,10);
                frmLOV.moveTo(0,0);
            }
            if (frmLOV.opener == null) {
                frmLOV.opener = self;
            }

            '
            );
      END IF;

      htp.p('}');

      htp.p('
      -->
      </script>
      ');

  END codigoJavaScript;

  --presenta la pagina html para asignar valores a otros objetos
  PROCEDURE returnValor(psReporte    VARCHAR2,
                        psParametro1 VARCHAR2,
                        psParametro2 VARCHAR2 DEFAULT NULL,
                        psFiltro1    VARCHAR2 DEFAULT NULL,
                        psFiltro2    VARCHAR2 DEFAULT NULL,
                        psFiltro3    VARCHAR2 DEFAULT NULL,
                        psFiltro4    VARCHAR2 DEFAULT NULL,
                        psFiltro5    VARCHAR2 DEFAULT NULL,
                        psFiltro6    VARCHAR2 DEFAULT NULL,
                        psFiltro7    VARCHAR2 DEFAULT NULL,
                        psFiltro8    VARCHAR2 DEFAULT NULL,
                        psFiltro9    VARCHAR2 DEFAULT NULL,
                        psFiltro10   VARCHAR2 DEFAULT NULL,
                        psFiltro11   VARCHAR2 DEFAULT NULL,
                        psForma      VARCHAR2 DEFAULT 'frmDatos',
                        psALL        VARCHAR2 DEFAULT NULL,
                        pnSiu        NUMBER   DEFAULT NULL,
                        pnDire       NUMBER   DEFAULT NULL,
                        pnSicc       NUMBER   DEFAULT NULL
                       ) IS

  BEGIN
      IF pnSiu||pnDire||pnSicc IS NULL THEN

         IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
      ELSE
         IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;
      END IF;

      PWASLCT(psReporte, psParametro1, psParametro2,
              psFiltro1, psFiltro2,  psFiltro3,  psFiltro4,
              psFiltro5, psFiltro6,  psFiltro7,  psFiltro8,
              psFiltro9, psFiltro10, psFiltro11,
              psForma,   psALL,      pnSiu,
              pnDire,    pnSicc
             );
  END returnValor;

  --presenta la pagina html para asignar valores a otros objetos
  PROCEDURE PWASLCT(psReporte    VARCHAR2,
                    psParametro1 VARCHAR2,
                    psParametro2 VARCHAR2 DEFAULT NULL,
                    psFiltro1    VARCHAR2 DEFAULT NULL,
                    psFiltro2    VARCHAR2 DEFAULT NULL,
                    psFiltro3    VARCHAR2 DEFAULT NULL,
                    psFiltro4    VARCHAR2 DEFAULT NULL,
                    psFiltro5    VARCHAR2 DEFAULT NULL,
                    psFiltro6    VARCHAR2 DEFAULT NULL,
                    psFiltro7    VARCHAR2 DEFAULT NULL,
                    psFiltro8    VARCHAR2 DEFAULT NULL,
                    psFiltro9    VARCHAR2 DEFAULT NULL,
                    psFiltro10   VARCHAR2 DEFAULT NULL,
                    psFiltro11   VARCHAR2 DEFAULT NULL,
                    psForma      VARCHAR2 DEFAULT 'frmDatos',
                    psALL        VARCHAR2 DEFAULT NULL,
                    pnSiu        NUMBER   DEFAULT NULL,
                    pnDire       NUMBER   DEFAULT NULL,
                    pnSicc       NUMBER   DEFAULT NULL

                   ) IS

  vnLength INTEGER                  := 1;
  vnIndex  INTEGER                  := 0;
  vnRow    INTEGER                  := 1;
  vsBreak  VARCHAR2(5)              := NULL;
  vsALL    SWRRECL.SWRRECL_ALL%TYPE := NULL;

  cuCursor t_Cursor;
  tabDatos t_Table;

  BEGIN
      BEGIN
          SELECT SWRRECL_ALL
            INTO vsALL
            FROM SWRRECL
           WHERE SWRRECL_NOMBRE_PAR = psParametro1
             AND SWRRECL_NOMBRE     = psReporte;
      EXCEPTION
          WHEN OTHERS THEN
               NULL;
      END;

      vsBreak := 'BK000';

      --la consulta se obtiene del valor almacenado en swrrecl_condicion_1
      cuCursor := FWASLCT(psReporte, psParametro1,
                          psFiltro1, psFiltro2,  psFiltro3, psFiltro4,
                          psFiltro5, psFiltro6,  psFiltro7, psFiltro8,
                          psFiltro9, psFiltro10, psFiltro11,
                          pnSiu,     pnDire,     pnSicc
                         );

      vsBreak := 'BK001';
     ----   htp.p('alert("dentro aplicacion 1  >>> '||psFiltro1||''||psFiltro2||''||psFiltro3 ||'" );' );   ---vicc

      LOOP
           EXIT WHEN cuCursor%NOTFOUND;
           FETCH cuCursor INTO tabDatos(vnRow).rCode,
                               tabDatos(vnRow).rDesc,
                               tabDatos(vnRow).rKmp1,
                               tabDatos(vnRow).rKmp2,
                               tabDatos(vnRow).rKmp3,
                               tabDatos(vnRow).rKmp4;
           EXIT WHEN cuCursor%NOTFOUND;

           vnRow := vnRow + 1;

      END LOOP;
      CLOSE cuCursor;

      ROLLBACK;

      vsBreak := 'BK002';

      htp.p('
      <html><head><title>&nbsp;</title>
      <script language="JavaScript"><!--
      function f_Return() {
      ');


     ----   htp.p('alert(" muestra nombre RoA  11 >>> '||pnSiu||''||pnDire||''||pnSicc ||'" );' );   ---vicc
        ---htp.p('alert( muestra nombre RoA  2>>>  );' );   ---vicc
         --coloca una selección en blanco para poder filtrar por todos los datos



      IF psParametro1 = 'psAplic' THEN
         htp.p('
         opener.document.'||psForma||'.'||psParametro1||'.value = "'||tabDatos(1).rDesc||'";
         opener.document.'||psForma||'.'||psParametro2||'.value = "'||tabDatos(1).rKmp1||'";
         ');
           ---------------------------------------------------------------------------------------------------------------
        --------se le agrego el filtro al IF  de psreporte  que es el nombre de la aplicacion de las encuestas. si es esa aplicacion va entrar a esta opcion y si no se salta
        ------- y sigue su proceso normal  pera los demas reportes o aplicaciones   30-may-2014   by glovicx
      ELSIF psParametro1 = 'psNmRfE'   and  psReporte = 'PWRMTRE' and psParametro2  is null THEN
         --coloca una selección en blanco para poder filtrar por todos los datos
         IF vsALL = 'ALL' THEN
            pk_ObjHTML.cleanSelect(psParametro1,psWhere=>'parent.');
         END IF;


         -----  htp.p('alert("dentro aplicacion  >>> '||psParametro2||''||psParametro1||''||vsALL ||'" );' );   ---vicc

        htp.p('parent.document.'||psForma||'.'||psParametro1||'.length=0;');
         FOR vnI IN 1..(vnRow-1) LOOP
             IF vsALL = 'ALL' THEN
                vnLength := vnLength + 1;
                vnIndex  := vnIndex  + 1;
             END IF;

             htp.p('parent.document.'||psForma||'.'||psParametro1||'.length='||vnLength||';');
             htp.p('parent.document.'||psForma||'.'||psParametro1||'['||vnIndex||'].text="' ||tabDatos(vnI).rDesc||'";');
             htp.p('parent.document.'||psForma||'.'||psParametro1||'['||vnIndex||'].value="'||tabDatos(vnI).rCode||'";');


             IF vsALL IS NULL OR vsALL <> 'ALL' THEN
                vnLength := vnLength + 1;
                vnIndex  := vnIndex  + 1;
             END IF;

         END LOOP;

          htp.p('parent.cancelaStatusTiempo();');
--------------------------------------------------

       ELSE
      ------ htp.p('alert("dentro reporte  >>> '||psParametro2||''||psParametro1||''||vsALL ||'" );' );   ---vicc
        ---htp.p('alert( muestra nombre RoA  2>>>  );' );   ---vicc
         --coloca una selección en blanco para poder filtrar por todos los datos
         IF vsALL = 'ALL' THEN
            pk_ObjHTML.cleanSelect(psParametro1,psWhere=>'opener.');
         END IF;

         htp.p('opener.document.'||psForma||'.'||psParametro1||'.length=0;');
         FOR vnI IN 1..(vnRow-1) LOOP
             IF vsALL = 'ALL' THEN
                vnLength := vnLength + 1;
                vnIndex  := vnIndex  + 1;
             END IF;

             htp.p('opener.document.'||psForma||'.'||psParametro1||'.length='||vnLength||';');
             htp.p('opener.document.'||psForma||'.'||psParametro1||'['||vnIndex||'].text="' ||tabDatos(vnI).rDesc||'";');
             htp.p('opener.document.'||psForma||'.'||psParametro1||'['||vnIndex||'].value="'||tabDatos(vnI).rCode||'";');


             IF vsALL IS NULL OR vsALL <> 'ALL' THEN
                vnLength := vnLength + 1;
                vnIndex  := vnIndex  + 1;
             END IF;

         END LOOP;




      END IF;





      htp.p('
      close();
      } //f_Return

      function f_Time() {
        f_Intervalo();

        setTimeout("f_Return()",2000)
      } //f_Time()
      //--></script>
      </head><body style="cursor:wait;margin-left: 0pt; margin-right: 0pt; margin-top: 0pt;margin-bottom: 0pt;" onLoad="f_Time();">
      ');

      --debe hacerce la llama a la función f_intervalo();
      PWAPRSS(0,40);

      htp.p('
      </body></html>
      ');

  EXCEPTION
      WHEN OTHERS THEN
           htp.p(vsBreak||': '||sqlerrm);

  END PWASLCT;

  PROCEDURE PWCLEVL(psOtherLevl VARCHAR2 DEFAULT NULL
                   ) IS

  CURSOR cuQry IS
         SELECT STVLEVL_CODE cCode,
                STVLEVL_DESC cDesc
           FROM STVLEVL
          UNION ALL
         SELECT '00'                             cCode,
                'Licenciatura/Licenciatura Trad' cDesc
           FROM DUAL
          WHERE psOtherLevl IS NOT NULL
          ORDER BY cDesc;



  BEGIN

      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCLEVL;

  --retorna el objeto select con el catalogo de la universidad

    PROCEDURE PWCLEVL1 IS

  CURSOR cuQry IS
         SELECT STVLEVL_CODE cCode,
                STVLEVL_DESC cDesc
           FROM STVLEVL
          UNION ALL
         SELECT '00'                             cCode,
                'Licenciatura/Licenciatura Trad' cDesc
           FROM DUAL
           ORDER BY cDesc;


  BEGIN

      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode ||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCLEVL1;
  PROCEDURE PWCACYR IS

  CURSOR cuQry IS
         SELECT STVACYR_CODE AS cCode,
                STVACYR_DESC AS cDesc
           FROM STVACYR
          WHERE STVACYR_CODE > '2000'
          ORDER BY 1 DESC;
  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCACYR;
  PROCEDURE PRCCAMP IS

  CURSOR cuQry IS
         SELECT STVCAMP_CODE cCode,
                STVCAMP_DESC cDesc
           FROM STVCAMP;
  BEGIN
      FOR regQry IN cuQry LOOP
          IF vgsCamp = regQry.cCode THEN
             htp.p('<option value="'||regQry.cCode||'" SELECTED>'||regQry.cDesc||'</option>');
          ELSE
             htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
          END IF;
      END LOOP;
  END PRCCAMP;
 --retorna el objeto select con el catalogo de categorias de profesor

PROCEDURE PRCATPR IS

  CURSOR cuQry IS

    SELECT     STVFSTP_CODE cCode,
               STVFSTP_DESC cDesc
     FROM STVFSTP
     WHERE STVFSTP_CODE <> '0000';

  BEGIN
      FOR regQry IN cuQry LOOP
          IF vgsCamp = regQry.cCode THEN
             htp.p('<option value="'||regQry.cCode||'" SELECTED>'||regQry.cDesc||'</option>');
          ELSE
             htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
          END IF;
      END LOOP;
  END PRCATPR;

  --retorna el objeto select con el catalogo del asesor universitario
  PROCEDURE PRCRECR IS

  CURSOR cuQry IS
         SELECT STVRECR_CODE cCode,
                STVRECR_DESC cDesc
           FROM STVRECR
          ORDER BY STVRECR_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PRCRECR;

  --retorna el objeto multiple con el status
  PROCEDURE PWCFCST IS

  CURSOR cuQry IS
         SELECT STVFCST_CODE cCode,
                STVFCST_DESC cDesc
           FROM STVFCST
                STVFCST
          ORDER BY STVFCST_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCFCST;

  --retorna el objeto select con las prepas
  PROCEDURE PWCSBGI IS

  CURSOR cuQry IS
         SELECT STVSBGI_CODE cCode,
                STVSBGI_DESC cDesc
           FROM STVSBGI
          ORDER BY STVSBGI_DESC;
  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSBGI;

  --retorna el objeto select con las universidades
  PROCEDURE PWCUNDE IS

  CURSOR cuQry IS
         SELECT STVSBGI_CODE cCode,
                STVSBGI_DESC cDesc
           FROM STVSBGI
           WHERE STVSBGI_TYPE_IND = 'C'
          ORDER BY STVSBGI_DESC;
  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCUNDE;

  --retorna el objeto select con las sesiones
  PROCEDURE PWCCISE IS

  CURSOR cuQry IS
         SELECT DISTINCT DECODE(SWRCISE_SESS_CODE,'"','\a\',SWRCISE_SESS_CODE) cCode,
                SWRCISE_SESS_CODE cDesc
           FROM SWRCISE
          ORDER BY cCode;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCISE;

  --retorna el objeto select con los puestos del asesor
  PROCEDURE PWCPTYP IS

  CURSOR cuQry IS
         SELECT STVPTYP_CODE cCode,
                STVPTYP_DESC cDesc
           FROM STVPTYP
          ORDER BY STVPTYP_DESC;
  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCPTYP;

  --retorna el objeto select con los periodos
  PROCEDURE PWCTERM(psVerano VARCHAR2 DEFAULT NULL) IS

  csVerano CONSTANT VARCHAR2(3) := '%40';

  CURSOR cuQry IS
         SELECT STVTERM_CODE                   cCode,
                REPLACE(STVTERM_DESC,'''',' ') cDesc
           FROM STVTERM
          WHERE STVTERM_TRMT_CODE IS NOT NULL
            AND (
                    psVerano IS NULL
                 OR
                    (
                         STVTERM_CODE LIKE csVerano
                     AND
                         psVerano IS NOT NULL
                    )
                 )
          ORDER BY STVTERM_CODE DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCTERM;

  --retorna el objeto select con el nivel de bachilleres
  PROCEDURE PWCEDLV IS

  CURSOR cuQry IS
         SELECT STVEDLV_CODE cCode,
                STVEDLV_DESC cDesc
           FROM STVEDLV
          ORDER BY STVEDLV_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCEDLV;

  --retorna el objeto select con el tipo de prepa
  PROCEDURE PWCGEOD IS

  CURSOR cuQry IS
         SELECT STVGEOD_CODE cCode,
                STVGEOD_DESC cDesc
           FROM STVGEOD
          ORDER BY STVGEOD_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCGEOD;

  --retorna el objeto select con la carrera
  PROCEDURE PWCMAJR IS

  CURSOR cuQry IS
         SELECT STVMAJR_CODE        cCode,
                LTRIM(STVMAJR_DESC) cDesc
           FROM STVMAJR
          ORDER BY LTRIM(STVMAJR_DESC);
  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCMAJR;

  --retorna el objeto select con la consulta de escuelas
  PROCEDURE PWCCOLL(psCollCode VARCHAR2 DEFAULT NULL,
                    psGnrlEncs VARCHAR2 DEFAULT NULL
                   ) IS

  CURSOR cuQry IS
         SELECT STVCOLL_CODE cCode,
                STVCOLL_DESC cDesc
           FROM STVCOLL
          WHERE (STVCOLL_CODE = psCollCode OR psCollCode IS NULL)
            AND (
                    (
                         psGnrlEncs = csGnrlEncs
                     AND
                         STVCOLL_CODE IN (SELECT A.SGBSTDN_COLL_CODE_1
                                           FROM SGBSTDN A, GOBSRVR
                                          WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                                             FROM SGBSTDN B
                                                                            WHERE B.SGBSTDN_PIDM      = A.SGBSTDN_PIDM
                                                                              AND B.SGBSTDN_STST_CODE = csAS
                                                                          )
                                            AND A.SGBSTDN_STST_CODE     = csAS
                                            AND GOBSRVR_PIDM            = A.SGBSTDN_PIDM
                                        )
                    )
                 OR
                    (
                     psGnrlEncs IS NULL
                    )
                )
          ORDER BY STVCOLL_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCOLL;

  --retorna el objeto select con la consulta de escuelas
  PROCEDURE PWRCOHO IS

  CURSOR cuQry IS
SELECT STVCHRT_CODE cCode,
       STVCHRT_DESC cDesc
  FROM STVCHRT
ORDER BY STVCHRT_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWRCOHO;

  --retorna el objeto select con la consulta de los metodos
  PROCEDURE PWCINSM IS

  CURSOR cuQry IS
         SELECT GTVINSM_CODE cCode,
                GTVINSM_DESC cDesc
           FROM GTVINSM
          ORDER BY GTVINSM_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCINSM;

  --retorna el objeto select con la consulta de areas acad?micas
  PROCEDURE PWCCUDA IS

  CURSOR cuQry IS
         SELECT STVCUDA_CODE cCode,
                STVCUDA_DESC cDesc
           FROM STVCUDA
          ORDER BY STVCUDA_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCUDA;

  --retorna el objeto select con la consulta de atributos
  PROCEDURE PWCATTR IS

  CURSOR cuQry IS
         SELECT STVATTR_CODE cCode,
                STVATTR_DESC cDesc
           FROM STVATTR
          ORDER BY STVATTR_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCATTR;

  --retorna el objeto select con la consulta de los atributos
  PROCEDURE PWCFATT IS

  CURSOR cuQry IS
         SELECT STVFATT_CODE cCode,
                STVFATT_DESC cDesc
           FROM STVFATT
          ORDER BY STVFATT_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCFATT;

  --retorna el objeto select con la consulta de coordinaciones
  PROCEDURE PWCTOPS IS

  CURSOR cuQry IS
         SELECT STVTOPS_CODE cCode,
                STVTOPS_DESC cDesc
           FROM STVTOPS
          ORDER BY STVTOPS_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCTOPS;

  --retorna el objeto select con la consulta de grados
  PROCEDURE PWCDEGC IS

  CURSOR cuQry IS
         SELECT STVDEGC_CODE cCode,
                STVDEGC_DESC cDesc
           FROM STVDEGC
          ORDER BY STVDEGC_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCDEGC;

  --retorna el objeto select con la consulta del subj
  PROCEDURE PWCSUBJ IS

  CURSOR cuQry IS
         SELECT STVSUBJ_CODE cCode,
                STVSUBJ_DESC cDesc
           FROM STVSUBJ
          ORDER BY STVSUBJ_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSUBJ;

  --retorna el objeto select con las materias compuestas de subj,crse y descripcion
  PROCEDURE PWCCRSE IS

  CURSOR cuQry IS
         SELECT SCBCRSE_SUBJ_CODE||
                SCBCRSE_CRSE_NUMB cCode,
                SCBCRSE_TITLE     cDesc
           FROM SCBCRSE
          ORDER BY SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB ;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCRSE;

  --el procedimiento retorna el objeto select con los detail code de pagos
  PROCEDURE PWCDETC(psTypeInd VARCHAR2 DEFAULT NULL
                   ) IS

  CURSOR cuQry IS
         SELECT TBBDETC_DETAIL_CODE cCode,
                TBBDETC_DESC        cDesc
           FROM TBBDETC
          WHERE (TBBDETC_TYPE_IND = psTypeInd OR psTypeInd IS NULL)
          ORDER BY TBBDETC_DETAIL_CODE,
                   TBBDETC_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCDETC;

  PROCEDURE PWCTIPO IS

  csDDMMRRRR CONSTANT VARCHAR2(10) := 'DD/MM/RRRR';
  csFecEgr   CONSTANT VARCHAR2(7)  := 'pFecEgr';
  csd        CONSTANT VARCHAR2(1)  := 'd';
  cs6        CONSTANT VARCHAR2(1)  := '6';
  cn1        CONSTANT NUMBER(1)    := 1;
  cn3        CONSTANT NUMBER(1)    := 3;

  CURSOR cuQry IS
         SELECT GWBTIPO_TYPE    cCode,
                GWBTIPO_DESC    cDesc,
                GWBTIPO_DEFAULT cDefl
           FROM GWBTIPO
          WHERE GWBTIPO_CODE = vgsParametro
          UNION ALL
         SELECT TO_CHAR(DECODE (TO_CHAR(SYSDATE , csd), cs6,  SYSDATE +cn3, SYSDATE + cn1),csDDMMRRRR) cCode,
                TO_CHAR(DECODE (TO_CHAR(SYSDATE , csd), cs6,  SYSDATE +cn3, SYSDATE + cn1),csDDMMRRRR) cDesc,
                NULL cDefl
           FROM DUAL
          WHERE csFecEgr = vgsParametro
          UNION ALL
         SELECT TO_CHAR(SYSDATE,csDDMMRRRR) cCode,
                TO_CHAR(SYSDATE,csDDMMRRRR) cDesc,
                NULL cDefl
           FROM DUAL
          WHERE csFecEgr = vgsParametro;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'" '||regQry.cDefl||'>'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCTIPO;

  --retorna el objeto select con laos usuarios
  PROCEDURE PWCBRAU IS

  CURSOR cuQry IS
         SELECT GURIDEN_USER_ID cCode
           FROM GURIDEN
          UNION ALL
         SELECT GWBTIPO_TYPE
           FROM GWBTIPO
          WHERE GWBTIPO_CODE = vgsParametro;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||'</option>');
      END LOOP;
  END PWCBRAU;

  PROCEDURE PWCSRCE IS

  CURSOR cuQry IS
         SELECT TTVSRCE_CODE cCode,
                TTVSRCE_DESC cDesc
           FROM TTVSRCE
          ORDER BY TTVSRCE_DESC;

  BEGIN
       FOR regQry IN cuQry LOOP
           htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
       END LOOP;
  END PWCSRCE;

  PROCEDURE PWCIDEN IS

  CURSOR cuQry IS
         SELECT GURIDEN_USER_ID cCode,
                GURIDEN_DESC    cDesc
           FROM GURIDEN
          ORDER BY GURIDEN_USER_ID;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCIDEN;

  PROCEDURE PWCRIDN IS

  CURSOR cuQry IS
         SELECT SPRIDEN_ID                                                  cCode,
                SPRIDEN_ID||' - '||SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME cDesc
           FROM SPRIDEN
          WHERE SPRIDEN_CHANGE_IND IS null
          ORDER BY SPRIDEN_ID;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCRIDN;

  --el procedimiento retorna el objeto select con la consulta de categoria
  PROCEDURE PWCFCTG IS

  CURSOR cuQry IS
         SELECT STVFCTG_CODE cCode,
                STVFCTG_DESC cDesc
           FROM STVFCTG
          ORDER BY STVFCTG_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCFCTG;

  --el procedimiento retorna el objeto select con la consulta de staff
  PROCEDURE PWCFSTP IS

  CURSOR cuQry IS
         SELECT STVFSTP_CODE cCode,
                STVFSTP_DESC cDesc
           FROM STVFSTP
          ORDER BY STVFSTP_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCFSTP;

  --retorna el objeto select con la consulta de la nacionalidad
  PROCEDURE PWCCITZ IS

  CURSOR cuQry IS
         SELECT STVCITZ_CODE cCode,
                STVCITZ_DESC cDesc
           FROM STVCITZ
          ORDER BY STVCITZ_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCITZ;

  --retorna el objeto select con la consulta de los edificios
  PROCEDURE PWCBLDG IS

  CURSOR cuQry IS
         SELECT STVBLDG_CODE cCode,
                STVBLDG_DESC cDesc
           FROM STVBLDG
          ORDER BY STVBLDG_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCBLDG;

  --el procedimiento retorna el objeto select con la consulta de los docentes
  PROCEDURE PWCASGN IS

  CURSOR cuQry IS
         SELECT SPRIDEN_ID                                                                   cCode,
                REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME||' '||SPRIDEN_MI,'*',' ') cDesc
           FROM SPRIDEN
          WHERE SPRIDEN_CHANGE_IND IS null
            AND SPRIDEN_PIDM IN (SELECT SIRASGN_PIDM
                                   FROM SIRASGN,SSBSECT
                                  WHERE SIRASGN_CRN       = SSBSECT_CRN
                                    AND SIRASGN_TERM_CODE = SSBSECT_TERM_CODE
                                    AND SSBSECT_CAMP_CODE = vgsCamp
                                )
          ORDER BY cDesc;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCASGN;

  --el procedimiento retorna el objeto select con la consulta del status
  PROCEDURE PWCSSTS IS

  CURSOR cuQry IS
         SELECT STVSSTS_CODE cCode,
                STVSSTS_DESC cDesc
           FROM STVSSTS
          ORDER BY STVSSTS_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSSTS;

  --el procedimiento retorna el objeto select con la consulta del contrato
  PROCEDURE PWCFCNT IS

  CURSOR cuQry IS
         SELECT STVFCNT_CODE cCode,
                STVFCNT_DESC cDesc
           FROM STVFCNT
          ORDER BY STVFCNT_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCFCNT;

  --el procedimiento retorna el objeto select con la consulta del bloque
  PROCEDURE PWCBLCK IS

  CURSOR cuQry IS
         SELECT STVBLCK_CODE cCode,
                STVBLCK_DESC cDesc
           FROM STVBLCK
          ORDER BY STVBLCK_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCBLCK;

  --el procedimiento retorna el objeto select con la consulta de la funcion
  PROCEDURE PWCNIST IS

  CURSOR cuQry IS
         SELECT STVNIST_CODE cCode,
                STVNIST_DESC cDesc
           FROM STVNIST
          ORDER BY STVNIST_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCNIST;

  --retorna el objeto select con el grupo de la lista cruzada
  PROCEDURE PWCGROP IS

  CURSOR cuQry IS
         SELECT SSRXLST_XLST_GROUP cCode,
                NULL               cDesc
           FROM SSRXLST
          WHERE (SSRXLST_CRN,SSRXLST_TERM_CODE) IN (SELECT SSBSECT_CRN,SSBSECT_TERM_CODE
                                                      FROM SSBSECT
                                                     WHERE SSBSECT_CAMP_CODE = vgsCamp
                                                   )
          GROUP BY SSRXLST_XLST_GROUP
          ORDER BY SSRXLST_XLST_GROUP;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||'</option>');
      END LOOP;
  END PWCGROP;

  --retorna el objeto select con la consulta del status stvstst
  PROCEDURE PWCSTST IS

  CURSOR cuQry IS
         SELECT STVSTST_CODE cCode,
                STVSTST_DESC cDesc
           FROM STVSTST
          ORDER BY STVSTST_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSTST;

  --retorna el objeto select con la consulta del programa
  PROCEDURE PWCPRLE IS

  CURSOR cuQry IS
         SELECT SMRPRLE_PROGRAM      cCode,
                SMRPRLE_PROGRAM_DESC cDesc
           FROM SMRPRLE
            WHERE SMRPRLE_PROGRAM LIKE 'LC%'
           OR SMRPRLE_PROGRAM LIKE 'LI%'
          ORDER BY SMRPRLE_PROGRAM;
  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCPRLE;

  --retorna el objeto select con la consulta del programa especial
  PROCEDURE PWCATTS IS

  CURSOR cuQry IS
         SELECT STVATTS_CODE cCode,
                STVATTS_DESC cDesc
           FROM STVATTS
          ORDER BY STVATTS_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCATTS;
--Procedimiento para mostrar atributo primer y segundo semestre de admisión
  PROCEDURE PWATTAD IS

  CURSOR cuQry IS

 SELECT DISTINCT STVATTS_CODE cCode,
                STVATTS_DESC cDesc
           FROM STVATTS, SARAATT
          WHERE SARAATT_ATTS_CODE =  STVATTS_CODE
          ORDER BY STVATTS_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWATTAD;


  --retorna el objeto select con la consulta de las becas
  PROCEDURE PWCEXPT IS

  CURSOR cuQry IS
         SELECT DISTINCT TBBEXPT_EXEMPTION_CODE cCode,
                         TBBEXPT_DESC           cDesc
           FROM TBBEXPT
          ORDER BY TBBEXPT_EXEMPTION_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCEXPT;

  --retorna el objeto select con la consulta de los salones
  PROCEDURE PWCRDEF IS

  CURSOR cuQry IS
         SELECT DISTINCT SLBRDEF_ROOM_NUMBER cCode,
                         SLBRDEF_DESC        cDesc
           FROM SLBRDEF
          ORDER BY SLBRDEF_ROOM_NUMBER;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCRDEF;

  --retorna las autorizaciones
  PROCEDURE PWCAUTH IS

  CURSOR cuQry IS
         SELECT TVVAUTH_TYPE_CODE cCode,
                TVVAUTH_DESC      cDesc
           FROM TVVAUTH
          ORDER BY TVVAUTH_TYPE_CODE;


  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCAUTH;

  --retorna el objeto select de la consulta de tipos de admision
  PROCEDURE PWCADMT IS

  CURSOR cuQry IS
         SELECT STVADMT_CODE cCode,
                STVADMT_DESC cDesc
           FROM STVADMT
          WHERE STVADMT_CODE IS NOT NULL
          ORDER BY STVADMT_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCADMT;

  --retorna el objeto select con la consulta de la clase
  PROCEDURE PWCCLAS IS

  CURSOR cuQry IS
         SELECT STVCLAS_CODE cCode,
                STVCLAS_DESC cDesc
           FROM STVCLAS
          ORDER BY STVCLAS_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCLAS;

  --retorna el objeto select con la consulta de la inscripcion
  PROCEDURE PWCESTS IS

  CURSOR cuQry IS
         SELECT STVESTS_CODE cCode,
                STVESTS_DESC cDesc
           FROM STVESTS
          ORDER BY STVESTS_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCESTS;



  --retorna la seleccion de los objetos por usuario asignado en un campus
  PROCEDURE PWCOBJS IS

  CURSOR cuQry IS
         SELECT GUBOBJS_NAME cCode,
                GUBOBJS_DESC cDesc
           FROM GUBOBJS
          WHERE GUBOBJS_NAME IN (SELECT GURUOBJ_OBJECT
                                   FROM BANSECR.GURUOBJ

                                )
          ORDER BY GUBOBJS_NAME;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode ||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCOBJS;

  --retorna el objeto select con la consulta del tipo de alumno
  PROCEDURE PWCSTYP IS

  CURSOR cuQry IS
         SELECT STVSTYP_CODE cCode,
                STVSTYP_DESC cDesc
           FROM STVSTYP
          ORDER BY STVSTYP_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSTYP;

  --retorna el objeto select con la consulta del tipo de alumno solo a y n
  PROCEDURE PWCTIAN IS

  CURSOR cuQry IS
         SELECT STVSTYP_CODE cCode,
                STVSTYP_DESC cDesc
           FROM STVSTYP
           where STVSTYP_CODE in ('N', 'A')
          ORDER BY STVSTYP_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCTIAN;

  --retorna el objeto select con la consulta de categoria
  PROCEDURE PWCDCAT(psTuiFee VARCHAR2 DEFAULT NULL
                   ) IS

  csFee VARCHAR2(3) := 'FEE';
  csTui VARCHAR2(3) := 'TUI';

  CURSOR cuQry IS
         SELECT TTVDCAT_CODE cCode,
                TTVDCAT_DESC cDesc
           FROM TTVDCAT
          WHERE (   psTuiFee IS NULL
                 OR
                    (    psTuiFee IS NOT NULL
                     AND
                         TTVDCAT_CODE IN (csFee,csTui)
                    )
                )
          ORDER BY TTVDCAT_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCDCAT;

  --el procedimiento retorna el objeto select con la consulta de los tutores
  PROCEDURE PWCADVR IS

  CURSOR cuQry IS
         SELECT SPRIDEN_ID                                                  cCode,
                REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME,'*',' ') cDesc
           FROM SPRIDEN
          WHERE SPRIDEN_PIDM       IN (SELECT SGRADVR_ADVR_PIDM
                                        FROM SGRADVR
                                       WHERE SGRADVR_ADVR_CODE = 'TUTO'
                                     )
            AND SPRIDEN_CHANGE_IND IS null
          ORDER BY SPRIDEN_ID;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCADVR;

  --retorna el objeto select con la consulta de contratos
  PROCEDURE PWCCONT IS

  CURSOR cuQry IS
         SELECT SPRIDEN_PIDM                                                cCode,
                SPRIDEN_ID                                                  cDesc,
                REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME,'*',' ') cDes1
           FROM SPRIDEN
          WHERE SPRIDEN_PIDM IN (SELECT TBBCONT_PIDM
                                   FROM TBBCONT
                                )
          ORDER BY SPRIDEN_ID;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||' - '||regQry.cDes1||'</option>');
      END LOOP;
  END PWCCONT;

  --retorna el nombre del hold
  PROCEDURE PWCHLDD IS

  CURSOR cuQry IS
         SELECT STVHLDD_CODE cCode,
                STVHLDD_DESC cDesc
           FROM STVHLDD
          ORDER BY STVHLDD_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCHLDD;

  --retorna el nombre de la clase
  PROCEDURE PWCGCLA IS

  CURSOR cuQry IS
         SELECT GTVCLAS_CLASS_CODE cCode,
                GTVCLAS_CLASS_CODE cDesc
           FROM BANSECR.GTVCLAS
          ORDER BY 1;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCGCLA;

  --retorna el objeto select con la consulta para consultar la encuesta de alumnos por egresar.
  PROCEDURE PWCSRVY IS

  CURSOR cuQry IS

    SELECT GVRSRVY_GSRC_CODE||'-'||GVRSRVY_SRN cCode,
            GVRSRVY_GSRC_CODE||'-'||GVRSRVY_SRN cDesc,
            '' cDes1
        FROM GVRSRVY;

  BEGIN
       FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'/'||regQry.cDesc||'">'||regQry.cDesc||regQry.cDes1||'</option>');
      END LOOP;
  END PWCSRVY;

  --regresa la lista de las actividades deportivas
  PROCEDURE PWCACTC IS

  CURSOR cuQry IS
         SELECT STVACTC_DESC cCode,
                STVACTC_CODE cDesc
           FROM STVACTC
          ORDER BY STVACTC_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCACTC;

  --retorna a todos los usuarios
  PROCEDURE PWCUSRL IS

  CURSOR cuQry IS
          SELECT GURIDEN_USER_ID cCode,
                 GURIDEN_DESC    cDesc
            FROM GURIDEN
           ORDER BY GURIDEN_USER_ID;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCUSRL;

  --el procedimiento retorna la parte de periodo
  PROCEDURE PWCPTRM IS

  CURSOR cuQry IS
         SELECT STVPTRM_CODE cCode,
                STVPTRM_DESC cDesc
           FROM STVPTRM
          ORDER BY STVPTRM_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          IF regQry.cCode = vgnOptionDefl THEN
             htp.p('<option value="'||regQry.cCode||'" SELECTED>'||regQry.cCode||' - '||regQry.cDesc||'</option>');
          ELSE
             htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
          END IF;
      END LOOP;
  END PWCPTRM;


  --retorna el objeto select con la consulta de la session
  PROCEDURE PWCSESS IS

  CURSOR cuQry IS
         SELECT STVSESS_CODE cCode,
                STVSESS_DESC cDesc
           FROM STVSESS;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSESS;

  --retorna el objeto select con los usuarios que consultan los reportes
  PROCEDURE PWCUSUR IS

  CURSOR cuQry IS
         SELECT SWRUSUR_USUARIO cCode,
                COUNT(1)        cDesc
           FROM SWRUSUR
          GROUP BY SWRUSUR_USUARIO
          ORDER BY SWRUSUR_USUARIO;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||'</option>');
      END LOOP;
  END PWCUSUR;

  --retorna el objeto select con los modulo de los reportes
  PROCEDURE PWCRECM IS

  CURSOR cuQry IS
         SELECT SWBRECM_CODE cCode,
                SWBRECM_DESC cDesc
           FROM SWBRECM
          ORDER BY SWBRECM_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCRECM;

  --retorna el objeto select con los reportes del sistema
  PROCEDURE PWCRECL IS

  CURSOR cuQry IS
         SELECT SWBRECL_NOMBRE                        cCode,
                SWBRECL_DESC||' ('||SWBRECM_DESC||')' cDesc
           FROM SWBRECL,
                SWBRECM
          WHERE SWBRECL_RECMCODE = SWBRECM_CODE
          ORDER BY SWBRECL_RECMCODE,
                   SWBRECL_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCRECL;

  --retorna los bancos utilizados en cargos recurrentes
--  procedure pwcbank is

--  cursor cuqry is
--         select swvbank_code ccode,
--                swvbank_desc cdesc
--           from swvbank
--       order by swvbank_desc;

--  begin
--      for regqry in cuqry loop
--          htp.p('<option value="'||regqry.ccode||'">'||regqry.cdesc||'</option>');
--      end loop;
--  end pwcbank;

  --muestra el catalogo del standar academico
  PROCEDURE PWCASTD IS

  CURSOR cuqRY IS
         SELECT STVASTD_CODE cCode,
                STVASTD_DESC cDesc
           FROM STVASTD;

  BEGIN
      FOR regQry IN cuqRY LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCASTD;

  --muestra el catalogo del rate
  PROCEDURE PWCRATE(psFiltro VARCHAR2 DEFAULT NULL) IS

  CURSOR cuQry IS
         SELECT STVRATE_CODE cCode,
                STVRATE_DESC cDesc
           FROM STVRATE
          WHERE STVRATE_CODE LIKE psFiltro
          UNION ALL
         SELECT GWBTIPO_TYPE    cCode,
                GWBTIPO_DESC    cDesc
           FROM GWBTIPO
          WHERE GWBTIPO_CODE = vgsParametro
          ORDER BY cDesc;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCRATE;

  --muestra los modulos de las aplicaciones
  PROCEDURE PWCMODL IS

  CURSOR cuQry IS
         SELECT SWBMODL_CODE       cCode,
                SWBMODL_DESC_SHORT cDesc
           FROM SWBMODL;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCMODL;

  --muestra los modulos de las aplicaciones
  PROCEDURE PWCSMDL IS

  CURSOR cuQry IS
         SELECT SWRSMDL_MODL_CODE||','||SWRSMDL_CODE cCode,
                SWRSMDL_DESC                         cDesc
           FROM SWRSMDL;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSMDL;



  --el procedimieto devuelve el status
  PROCEDURE PWCSITE IS

  CURSOR cuQry IS
         SELECT STVSITE_CODE cCode,
                STVSITE_DESC cDesc
           FROM STVSITE
          ORDER BY STVSITE_DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCSITE;

  PROCEDURE PWCGMOD(psModoGrade VARCHAR2 DEFAULT NULL
                   ) IS

  CURSOR cuQry IS
         SELECT STVGMOD_CODE cCode,
                DECODE(psModoGrade,NULL,STVGMOD_DESC,
                                        DECODE (STVGMOD_CODE,'N','Ordinario',STVGMOD_DESC)
                      )      cDesc
           FROM STVGMOD
          WHERE (   psModoGrade IS NULL
                 OR
                    (
                         psModoGrade IS NOT NULL
                     AND
                         STVGMOD_CODE IN ('X','S','R','N','E','A')
                    )
                )
          ORDER BY cCode;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCGMOD;

  -- tipo de accesos por programa y por persona
  PROCEDURE PWCGCHG IS

  CURSOR cuQry IS
         SELECT STVGCHG_CODE cCode,
                STVGCHG_DESC cDesc
           FROM STVGCHG
          WHERE STVGCHG_CODE IN ('CA','IN','DO','CO');

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCGCHG;

  --retorna la selecciones de enciesta
  PROCEDURE PWCGSRC IS

  CURSOR cuQry IS
         SELECT GVVGSRC_CODE cCode,
                GVVGSRC_DESC cDesc
           FROM GVVGSRC
          ORDER BY GVVGSRC_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' ('||lower(regQry.cDesc)||')</option>');
      END LOOP;
  END PWCGSRC;

  --retorna los grupos de las listas cruzadas
  PROCEDURE PWCXLST IS

  CURSOR cuQry IS
         SELECT DISTINCT SSBXLST_XLST_GROUP cCode
           FROM SSBXLST
          ORDER BY SSBXLST_XLST_GROUP;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||'</option>');
      END LOOP;
  END PWCXLST;

  --el procedimiento retorna el objeto select con los nrc de los docentes
  PROCEDURE PWCINST IS

  CURSOR cuQry IS
         SELECT SPRIDEN_PIDM             cCode,
                REPLACE(REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME||' '||SPRIDEN_MI,'ñ','&ntilde;'),'*',' ') cDesc
           FROM SIBINST A,
                SPRIDEN S
          WHERE SIBINST_PIDM          = S.SPRIDEN_PIDM
            AND SIBINST_FCST_CODE     = csAC
            AND S.SPRIDEN_CHANGE_IND IS NULL
            AND SIBINST_TERM_CODE_EFF = (SELECT MAX(B.SIBINST_TERM_CODE_EFF)
                                           FROM SIBINST B
                                          WHERE B.SIBINST_PIDM = A.SIBINST_PIDM
                                            AND SIBINST_FCST_CODE = csAC
                                        )
          ORDER BY cDesc;
  BEGIN
       FOR regQry IN cuQry LOOP
            htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
       END LOOP;
  END PWCINST;

  --el procedimiento retorna el catalogo "stvdept"
  PROCEDURE PWCDEPT IS

  CURSOR cuQry IS
         SELECT STVDEPT_CODE cCode,
                STVDEPT_DESC cDesc
           FROM STVDEPT
          ORDER BY cDesc;
  BEGIN
       FOR regQry IN cuQry LOOP
            htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
       END LOOP;
  END PWCDEPT;

  --muestra la encuesta del seprad
  PROCEDURE PWCTSSC IS

  CURSOR cuQry IS
         SELECT SVVTSSC_CODE cCode,
                SVVTSSC_DESC cDesc
           FROM SVVTSSC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCTSSC;

--  begin
--      --inicializa la variable "camp"
--      vgscamp := f_contexto();
  PROCEDURE PWCCDOC IS

  CURSOR cuQry IS
         SELECT TWVPAYM_CODE cCode,
                     TWVPAYM_DESC cDesc
           FROM TWVPAYM;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCDOC;

  PROCEDURE PWCCOLE IS

  CURSOR cuQry IS
         SELECT STVSBGI_CODE cCode,
                     STVSBGI_DESC cDesc
           FROM STVSBGI
         WHERE STVSBGI_TYPE_IND = 'H';

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCCOLE;

  PROCEDURE PWCMATRV IS

  CURSOR cuQry IS
          SELECT DISTINCT SARADAP_ADMT_CODE cCode,
                                     STVADMT_DESC cDesc
                           FROM SARADAP, STVADMT
                         WHERE SARADAP_ADMT_CODE = STVADMT_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCMATRV;

PROCEDURE PWCMARTYP IS

  CURSOR cuQry IS


          SELECT DISTINCT STVRTYP_CODE cCode,
                                     STVRTYP_DESC cDesc
                           FROM STVRTYP
                           WHERE STVRTYP_CODE IN ('AC', 'AE', 'AR');

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCMARTYP;

   PROCEDURE PWCMATRA IS

  CURSOR cuQry IS
         SELECT DISTINCT (SUBSTR (STVTERM_CODE, 1, 4)) cCode
         FROM STVTERM
         ORDER BY SUBSTR (STVTERM_CODE, 1, 4);

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||'</option>');
      END LOOP;
  END PWCMATRA;

  PROCEDURE PWCMATRN IS

  CURSOR cuQry IS

  SELECT DISTINCT SGBSTDN_STYP_CODE cCode,
                             STVSTYP_DESC cDesc
  FROM SGBSTDN, STVSTYP
 WHERE STVSTYP_CODE = SGBSTDN_STYP_CODE AND STVSTYP_CODE IN ('A', 'N');

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCMATRN;

  -- retorna la lista de decisión por admisión
  PROCEDURE PWRAPDD IS

  CURSOR cuQry IS
          SELECT DISTINCT STVAPDC_CODE cCode,
                     STVAPDC_DESC cDesc
                     FROM STVAPDC
                     WHERE STVAPDC_CODE IN ('CO', 'LE', 'C2');

  BEGIN
      FOR regQry IN cuQry LOOP
            htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWRAPDD;

  -- retorna la lista de decisión por admisión
  PROCEDURE PWRAPDC IS

  CURSOR cuQry IS
          SELECT DISTINCT STVAPDC_CODE cCode,
                     STVAPDC_DESC cDesc
             FROM STVAPDC;

  BEGIN
      FOR regQry IN cuQry LOOP
            htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWRAPDC;

  -- gvh: lista de matriculadores con cierre de caja;
  PROCEDURE PWMATUSR IS
    CURSOR cuQry IS
        SELECT UNIQUE
            TWRCCAM_CCAM_USER       cCode
            ,GURIDEN_desc           cDesc
        FROM
            TWRCCAM
            ,GURIDEN
        WHERE
            TWRCCAM_CCAM_USER = GURIDEN_USER_ID(+);

  BEGIN
      FOR regQry IN cuQry LOOP
            htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWMATUSR;

  -- aigui: tipo de cheques
  PROCEDURE PWTICHE IS
    CURSOR cuQry IS
        select twvpaym_code cCode, twvpaym_desc cDesc
        from twvpaym
        where (twvpaym_code in ('CAE', 'CFE', 'CVV') or twvpaym_code like 'CH%')
        order by twvpaym_desc;

  BEGIN
      FOR regQry IN cuQry LOOP
            htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWTICHE;

-- aigui: estado del documento
  PROCEDURE PWSTADO IS
    CURSOR cuQry IS
        select twvdost_status_ind cCode, twvdost_status_desc cDesc
        from twvdost
        order by twvdost_status_ind;

  BEGIN
      FOR regQry IN cuQry LOOP
            htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWSTADO;

  -- jccr: lista de tramites de certificados de estudios -- 27 dic 2010
  PROCEDURE PWRTRAE IS

  CURSOR cuQry IS
         SELECT GWBTIPO_TYPE    cCode,
                GWBTIPO_DESC    cDesc,
                GWBTIPO_DEFAULT cDefl
           FROM GWBTIPO
          WHERE GWBTIPO_CODE = vgsParametro
       ORDER By TO_NUMBER(GWBTIPO_TYPE);


  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'" '||regQry.cDefl||'>'||regQry.cDesc||'</option>');
      END LOOP;
  END PWRTRAE;

  -- jccr: lista de tramites de certificados de notas --  14-ene-2011
  PROCEDURE PWRTRAN IS

  CURSOR cuQry IS
         SELECT GWBTIPO_TYPE    cCode,
                GWBTIPO_DESC    cDesc,
                GWBTIPO_DEFAULT cDefl
           FROM GWBTIPO
          WHERE GWBTIPO_CODE = vgsParametro
       ORDER By TO_NUMBER(GWBTIPO_TYPE);


  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'" '||regQry.cDefl||'>'||regQry.cDesc||'</option>');
      END LOOP;
  END PWRTRAN;


  -- hmr - 08/06/2011: lista de opción para datos de contacto:
  PROCEDURE PWCDATC IS

  CURSOR cuQry IS
         SELECT GWBTIPO_TYPE    cCode,
                GWBTIPO_DESC    cDesc,
                GWBTIPO_DEFAULT cDefl
           FROM GWBTIPO
          WHERE GWBTIPO_CODE = 'psDatCo';

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'" '||regQry.cDefl||'>'||regQry.cDesc||'</option>');
      END LOOP;
  END PWCDATC;


  -- gvh: 20120613: Lista de tipos de resultado de carga de registros (archivo)
  PROCEDURE PWCRGRS IS

  BEGIN

      htp.p('<option value="T">Todos</option>');
      htp.p('<option value="A">Correctos</option>');
      htp.p('<option value="N">No correctos</option>');
      htp.p('<option value="W">Cargados con advertencia</option>');
      htp.p('<option value="R">Rechazados</option>');
      htp.p('<option value="E">Con error</option>');

  END PWCRGRS;

  -- gvh_ 20120711: Lista de tipos de archivos de carga de recaudacion
  PROCEDURE PWCTCGM IS

  BEGIN

      htp.p('<option value="CPEC">Cuponera Santander</option>');
      htp.p('<option value="CBCH">Cuponera Banco Chile</option>');
      htp.p('<option value="CPAC">PAC</option>');
      htp.p('<option value="CPAT">PAT</option>');
      htp.p('<option value="FACT">Factoring Santander</option>');

  END PWCTCGM;
  --el procedimiento retorna el objeto select con la consulta del status
  PROCEDURE PWRBJMA IS

  CURSOR cuQry IS
         SELECT STVRSTS_CODE cCode,
                STVRSTS_DESC cDesc
           FROM STVRSTS
         -- WHERE STVRSTS_CODE = 'psStCur'
          ORDER BY STVRSTS_CODE;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cDesc||'</option>');
      END LOOP;
  END PWRBJMA;


PROCEDURE PWMONTH IS
BEGIN
 htp.p('<option value="01">Enero</option>');
 htp.p('<option value="02">Febrero</option>');
 htp.p('<option value="03">Marzo</option>');
 htp.p('<option value="04">Abril</option>');
 htp.p('<option value="05">Mayo</option>');
 htp.p('<option value="06">Junio</option>');
 htp.p('<option value="07">Julio</option>');
 htp.p('<option value="08">Agosto</option>');
 htp.p('<option value="09">Septiembre</option>');
 htp.p('<option value="10">Octubre</option>');
 htp.p('<option value="11">Noviembre</option>');
 htp.p('<option value="12">Diciembre</option>');

END PWMONTH;

PROCEDURE PWTCNTR IS
BEGIN
 htp.p('<option value="PREGRADO">PREGRADO</option>');
 htp.p('<option value="POSTGRADO">POSTGRADO</option>');
END PWTCNTR;
  --el procedimiento retorna Periodos de Postgrado CFC
PROCEDURE PWCTERP IS

  CURSOR cuQry IS
         SELECT STVTERM_CODE                   cCode,
                REPLACE(STVTERM_DESC,'''',' ') cDesc
           FROM STVTERM
          WHERE STVTERM_TRMT_CODE IS NOT NULL
                AND UPPER(STVTERM_DESC) LIKE 'POST%'
                    AND STVTERM_CODE LIKE '%08' OR STVTERM_CODE LIKE '%04'
          ORDER BY STVTERM_CODE DESC;

  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCTERP;
  --el procedimiento retorna Programas de Postgrado CFC
    PROCEDURE PWCPRLP IS

  CURSOR cuQry IS
         SELECT SMRPRLE_PROGRAM      cCode,
                SMRPRLE_PROGRAM_DESC cDesc
           FROM SMRPRLE
             WHERE SMRPRLE_PROGRAM LIKE 'DI%'
           OR SMRPRLE_PROGRAM LIKE 'MG%'
           OR SMRPRLE_PROGRAM LIKE 'PT%'
          ORDER BY SMRPRLE_PROGRAM;
  BEGIN
      FOR regQry IN cuQry LOOP
          htp.p('<option value="'||regQry.cCode||'">'||regQry.cCode||' - '||regQry.cDesc||'</option>');
      END LOOP;
  END PWCPRLP;
END kwaObjPrm;
/
