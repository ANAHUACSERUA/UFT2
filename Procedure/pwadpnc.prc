DROP PROCEDURE BANINST1.PWADPNC;

CREATE OR REPLACE PROCEDURE BANINST1.PWADPNC(psObject VARCHAR2) IS

/*
          TAREA: Script para generar el archivo que compilara los respaldos
          FECHA: 08/03/2010
          AUTOR: GEPC
         MODULO: General
  OBSERVACIONES:
                 * "A" identifica la apertura del spool para obtener la bitacora de instalación (SPOOL RUTA\)
                   "Z" identifica el cierre del archivo de bitacora (SPOOL OFF)
                   "E" sentencias "SET" para definir las "Caracteristicas de compilación"
                   "Y" sentencia "SET FEEDBACK ON" para compilar las dependencias y poder observar posibles errores
                   "I" identifica la instrucción para compilar el respaldo
                   "D" identifica las dependencias de los respaldos para ser compilados.
                   "W" identifica los objetos de pendientes de las dependencias de los respaldos.
                   "X" sentencias "SET" para el fin del script "compilador de respaldos"

                 * En el script "install.sql" agregar la instrucción "@generaCompilador.SQL &&RUTA"
                   despues de haber realizado el respaldo de objetos.

                 * En el script "respaldo.sql" agregar las instrucciónes
                      -- BEGIN
                      -- PWADPNC('&2');
                      -- END;
                      -- /
                   despues de la sentencia "SPOOL OFF;"


   Modificacion: 17/03/2010
                 GEPC
                 * Se agrego la columna "GWBDPNC_ORDEN" para establecer el orden de ejecución de los procesos

   Modificacion: 18/03/2010
                 GEPC
                 * Se establece un orden para la sección "X" que corresponde al fin del script
                 * Se agrega el filtro 'INVALID' en la obtención de las dependencias, para que solo
                   se compilen la dependencias invalidas.

   Modificacion: 26/11/2012
                 GVH
                 * Se cambian los separadores de directorios a diagonales normales para que se soporte la ejecucion en UNIX
                 * Se cambian los saltos de linea al estandar UNIX lf \n CHR(10) en lugar de CR \r CHR(13)



*/

  vsProceso VARCHAR2(100) := NULL;
  vnOrden   INTEGER       := NULL;

  CURSOR cuDependencia IS
         SELECT GWBDPNC_DEPENDENCIA Depend
           FROM GWBDPNC
          WHERE GWBDPNC_TIPO = 'D';

  BEGIN
      SELECT UPPER(SUBSTR(psObject,1,DECODE(INSTR(psObject,'.')-1,-1,LENGTH(psObject),INSTR(psObject,'.')-1)))
        INTO vsProceso
        FROM DUAL;

      SELECT NVL(MAX(GWBDPNC_ORDEN),0)+1
        INTO vnOrden
        FROM GWBDPNC;

      ------OBTENER LA SALIDA AL RESTITUIR LA COMPILACION
      INSERT INTO GWBDPNC(GWBDPNC_OBJECT,GWBDPNC_TIPO)
      SELECT spoo.Code1, spoo.Code2
        FROM (SELECT 'SPOOL RUTA/Respaldo'||TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')||'.txt' Code1,'A' Code2
                FROM DUAL
               UNION ALL
              SELECT 'SPOOL OFF','Z'
                FROM DUAL
             ) spoo
       WHERE NOT EXISTS (SELECT NULL
                          FROM GWBDPNC
                         WHERE GWBDPNC_TIPO = spoo.Code2
                       );

      ------CARACTERISTICAS DE LA COMPILACION
      INSERT INTO GWBDPNC(GWBDPNC_OBJECT,GWBDPNC_TIPO)
      SELECT setss.Code1,setss.Code2
        FROM (SELECT 'SET ECHO          OFF' Code1,'E' Code2 FROM DUAL UNION ALL
              SELECT 'SET FEEDBACK      OFF'      ,'E' FROM DUAL UNION ALL
              SELECT 'SET VERIFY        OFF'      ,'E' FROM DUAL UNION ALL
              SELECT 'SET SHOWMODE      OFF'      ,'E' FROM DUAL UNION ALL
              SELECT 'SET PAGESIZE      0'        ,'E' FROM DUAL UNION ALL
              SELECT 'SET LINESIZE      1000'     ,'E' FROM DUAL UNION ALL
              SELECT 'SET LONG          900000'   ,'E' FROM DUAL UNION ALL
              SELECT 'SET LONGCHUNKSIZE 900000'   ,'E' FROM DUAL UNION ALL
              SELECT 'SET TRIMSPOOL     ON'       ,'E' FROM DUAL UNION ALL
              SELECT 'SET DEFINE        OFF'      ,'E' FROM DUAL
             ) setss
       WHERE NOT EXISTS (SELECT NULL
                           FROM GWBDPNC
                          WHERE GWBDPNC_TIPO = setss.Code2
                        );

      ------CARACTERISTICAS DE LA DEPENDENCIA
      INSERT INTO GWBDPNC(GWBDPNC_OBJECT,GWBDPNC_TIPO)
      SELECT setss.Code1,setss.Code2
        FROM (SELECT CHR(10)||'SET FEEDBACK ON'||CHR(10) Code1,'Y' Code2 FROM DUAL
             ) setss
       WHERE NOT EXISTS (SELECT NULL
                           FROM GWBDPNC
                          WHERE GWBDPNC_TIPO = setss.Code2
                        );

      ------OBJETOS A COMPILAR
      INSERT INTO GWBDPNC(GWBDPNC_OBJECT,GWBDPNC_TIPO,GWBDPNC_ORDEN)
      VALUES('PROMPT ***Restaurando '||psObject||CHR(10)||'@'||psObject||CHR(10)||'@propiedades.sql'||CHR(10),'I',vnOrden);

      ------OBJETOS DEPENDIENTES AL RESTAURAR COMPILACION
      INSERT INTO GWBDPNC(GWBDPNC_OBJECT,GWBDPNC_TIPO,GWBDPNC_DEPENDENCIA,GWBDPNC_TYPE_OBJECT)
      SELECT dependenc.Comp,
             'D',
             dependenc.Obje,
             dependenc.Typp
         FROM (SELECT CHR(10)||
                      'PROMPT ***DEPENDENCIA '||OBJECT_NAME||CHR(10)||
                      'ALTER '||REPLACE(OBJECT_TYPE,' BODY')||' '||
                      OWNER||'.'||OBJECT_NAME||' COMPILE;' Comp,
                      OBJECT_NAME                          Obje,
                      OBJECT_TYPE                          Typp
                 FROM PUBLIC_DEPENDENCY A,
                      ALL_OBJECTS       B
                WHERE REFERENCED_OBJECT_ID = (SELECT OBJECT_ID
                                                FROM ALL_OBJECTS
                                               WHERE OWNER        = 'BANINST1'
                                                 AND OBJECT_TYPE IN ('FUNCTION','PACKAGE','PROCEDURE','TRIGGER')
                                                 AND OBJECT_NAME  = vsProceso
                                             )
                  AND B.OBJECT_NAME       <> vsProceso
                  AND A.OBJECT_ID          = B.OBJECT_ID
                  AND B.STATUS             = 'INVALID'
                  AND NOT EXISTS (SELECT NULL
                                    FROM GWBDPNC
                                   WHERE GWBDPNC_DEPENDENCIA = B.OBJECT_NAME
                                     AND GWBDPNC_TIPO        = 'D'
                                 )
              ) dependenc;

      COMMIT;

      ------OBJETOS dependencias de los DEPENDIENTES AL RESTAURAR COMPILACION
      FOR regDep IN cuDependencia LOOP
          vsProceso := regDep.Depend;

          INSERT INTO GWBDPNC(GWBDPNC_OBJECT,GWBDPNC_TIPO,GWBDPNC_DEPENDENCIA,GWBDPNC_TYPE_OBJECT)
          SELECT dependenc.Comp,
                 'W',
                 dependenc.Obje,
                 dependenc.Typp
            FROM (SELECT CHR(10)||
                         'PROMPT ***DEPENDENCIA '||OBJECT_NAME||CHR(10)||
                         'ALTER '||REPLACE(OBJECT_TYPE,' BODY')||' '||
                         OWNER||'.'||OBJECT_NAME||' COMPILE;' Comp,
                         OBJECT_NAME                          Obje,
                         OBJECT_TYPE                          Typp
                    FROM PUBLIC_DEPENDENCY A,
                         ALL_OBJECTS       B
                   WHERE REFERENCED_OBJECT_ID = (SELECT OBJECT_ID
                                                   FROM ALL_OBJECTS
                                                  WHERE OWNER        = 'BANINST1'
                                                    AND OBJECT_TYPE IN ('FUNCTION','PACKAGE','PROCEDURE','TRIGGER')
                                                    AND OBJECT_NAME  = vsProceso
                                                )
                     AND B.OBJECT_NAME       <> vsProceso
                     AND A.OBJECT_ID          = B.OBJECT_ID
                     AND B.STATUS             = 'INVALID'
                     AND NOT EXISTS (SELECT NULL
                                       FROM GWBDPNC
                                      WHERE GWBDPNC_DEPENDENCIA = B.OBJECT_NAME
                                        AND GWBDPNC_TIPO        = 'W'
                                    )
                     AND NOT EXISTS (SELECT NULL
                                       FROM GWBDPNC
                                      WHERE GWBDPNC_DEPENDENCIA = B.OBJECT_NAME
                                        AND GWBDPNC_TIPO        = 'D'
                                    )
                 ) dependenc;

          COMMIT;
      END LOOP;

      ------SALIDA DEL ARCHIVO
      INSERT INTO GWBDPNC(GWBDPNC_OBJECT,GWBDPNC_TIPO,GWBDPNC_ORDEN)
      SELECT exits.Code1, exits.Code2, exits.Orden
        FROM (SELECT 'SET DEFINE ON' Code1,                    'X' Code2, 80 Orden FROM DUAL UNION ALL
              SELECT 'PROMPT',                                 'X', 81 FROM DUAL UNION ALL
              SELECT 'PROMPT GRACIAS :)',                      'X', 82 FROM DUAL UNION ALL
              SELECT 'PROMPT',                                 'X', 83 FROM DUAL UNION ALL
              SELECT 'PROMPT',                                 'X', 84 FROM DUAL UNION ALL
              SELECT 'PROMPT [ oprime ENTER para continuar ]', 'X', 85 FROM DUAL UNION ALL
              SELECT 'ACCEPT RESPALDO CHAR;',                  'X', 86 FROM DUAL UNION ALL
              SELECT 'PROMPT',                                 'X', 87 FROM DUAL UNION ALL
              SELECT 'SET TERM OFF',                           'X', 88 FROM DUAL UNION ALL
              SELECT 'DISCONNECT',                             'X', 89 FROM DUAL UNION ALL
              SELECT 'EXIT;',                                  'X', 90 FROM DUAL
             ) exits
       WHERE NOT EXISTS (SELECT NULL
                           FROM GWBDPNC
                          WHERE GWBDPNC_TIPO = exits.Code2
                        );

       COMMIT;

  END PWADPNC;
/


DROP PUBLIC SYNONYM PWADPNC;

CREATE PUBLIC SYNONYM PWADPNC FOR BANINST1.PWADPNC;


GRANT EXECUTE ON BANINST1.PWADPNC TO BANSECR;
