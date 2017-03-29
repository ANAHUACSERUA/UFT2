CREATE OR REPLACE PACKAGE BANINST1.kwaciti IS

/*
         Tarea: Consulta de citas para la inscripción de los alumnos de  - RUA -
         Fecha: 03 DIC 2014
         Autor: MAC

*/

  type type_cursor IS REF CURSOR;

  csAS          CONSTANT VARCHAR2(2)  := 'AS';
  csLC          CONSTANT VARCHAR2(2)  := 'LC';
  csLT          CONSTANT VARCHAR2(2)  := 'LT';
  csLV          CONSTANT VARCHAR2(2)  := 'LV';
  csLI          CONSTANT VARCHAR2(2)  := 'LI';
  csST          CONSTANT VARCHAR2(2)  := 'ST';
  csYYYYMMDD    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
  csDDMMYYYY    CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
  csYYYYMMDDH24 CONSTANT VARCHAR2(14) := 'YYYYMMDDHH24MI';
  cs999999      CONSTANT VARCHAR2(6)  := '999999';
  cn0           CONSTANT NUMBER(1)    := 0;
  cn1           CONSTANT NUMBER(1)    := 1;
  cn2           CONSTANT NUMBER(1)    := 2;
  cn3           CONSTANT NUMBER(1)    := 3;
  cn4           CONSTANT NUMBER(1)    := 4;
  vsCamp        CONSTANT VARCHAR2(11) := F_CONTEXT;

  --CODIGO JAVA SCRIPT
  PROCEDURE JS;

  --EL PROCEDIMEITO GENERA LOS FRAIMS DE LA APLICACIÓN
  PROCEDURE Cita;

  --EL PROCEDIMIENTO PRESENTA EL PERIODO DE INSCRIPCIÓN
  PROCEDURE Mensaje(psTerm VARCHAR2);

  -- Obtiene los Datos de la Cita
  PROCEDURE DatosCita(psTerm    VARCHAR2,
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
                     );

  --Retorna las citas de inscripción para el mobil
  --getCitas
  PROCEDURE getCitas(psID    IN SPRIDEN.SPRIDEN_ID%TYPE,
                     cuCita OUT type_cursor
                    );

END kwaciti;
/