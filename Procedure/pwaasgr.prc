DROP PROCEDURE BANINST1.PWAASGR;

CREATE OR REPLACE PROCEDURE BANINST1.PWAASGR(psNameNEW   VARCHAR2,
                                             psNameOLD   VARCHAR2,
                                             psDeleteOLD VARCHAR2,
                                             psName      VARCHAR2 DEFAULT NULL,
                                             psSubName   VARCHAR2 DEFAULT NULL,
                                             pnRecmCode  NUMBER   DEFAULT NULL,
                                             psRecmExts  VARCHAR2 DEFAULT 'NEW'
                                            ) IS

/*
    Tarea: Reasigna un reporte a otro
    Fecha: 23/03/2010
    Autor: GEPC
   Modulo: General

           -- psNameNEW   VARCHAR2,               NOMBRE DEL PROCEDIMIENTO (NUEVA CLAVE DEL REPORTE)

           -- psNameOLD   VARCHAR2,               CLAVE DEL REPORTE        (VIEJA CLAVE DEL REPORTE "SWBRECL_NOMBRE")

           -- psDeleteOLD VARCHAR2,               "Y" eliminar la anterior clave del reporte en SWBRECL, SWRRECL y SWRUSUR
                                                  "N" para clonación de reporte (asignarle otras caracterisitricas al reporte clonado)


           -- psName      VARCHAR2 DEFAULT NULL,  Nuevo nombre del reporte (Sustituye el actaul nombre del reporte)

           -- psSubName   VARCHAR2 DEFAULT NULL   Se agrega al actual nombre del reporte ó al "nuevo nombre" del reporte

           -- pnRecmCode  NUMBER   DEFAULT NULL   Reasignar un reporte a otro modulo

           -- psRecmExts  VARCHAR2 DEFAULT 'N'    * "NEW" el reporte se registra en otro modulo y no se asigna a usuarios
                                                  * "OLD" el reporte se registra en otro modulo y se reasigna a usuarios

*/

  vsAccion  VARCHAR2(2)    := NULL;
  vsEtapa   VARCHAR2(100)  := NULL;
  vsError   VARCHAR2(4000) := NULL;
  vsBkpoint VARCHAR2(7)    := 'BK0001 ';

  --Busca el reporte asignado a los usuarios
  CURSOR cuRepUsu IS
         SELECT SWRUSUR_USUARIO   Usee,
                psNameNEW         Rept,
                SWRUSUR_RECMCODE  Recm
           FROM SWRUSUR
          WHERE SWRUSUR_REPORT_NAME = psNameOLD;

  procedure RegistraEtapa is

  begin
      if vsError is not null then
         rollback;

         vsAccion := Null;
      else
         commit;
      end if;

      insert into gwrasgr(gwrasgr_new, gwrasgr_old, gwrasgr_accion, gwrasgr_etapa, gwrasgr_error)
                   values(psNameNEW,   psNameOLD,   vsAccion,       vsEtapa,       vsError);

      commit;

      vsError  := null;
      vsAccion := 'OK';
  end RegistraEtapa;

  BEGIN
      vsEtapa  := 'Registro de reporte';
      vsAccion := 'OK';

      BEGIN
          IF pnRecmCode IS NOT NULL THEN
             INSERT INTO SWBRECL(SWBRECL_NOMBRE,SWBRECL_DESC,                        SWBRECL_PROCESO,SWBRECL_RECMCODE)
                          SELECT psNameNEW,     NVL(psName,SWBRECL_DESC)||psSubName, psNameNEW,      pnRecmCode
                            FROM SWBRECL
                           WHERE SWBRECL_NOMBRE = psNameOLD
                           GROUP BY psNameNEW,NVL(psName,SWBRECL_DESC)||psSubName, psNameNEW;
          ELSE
             INSERT INTO SWBRECL(SWBRECL_NOMBRE,SWBRECL_DESC,                        SWBRECL_PROCESO,SWBRECL_RECMCODE)
                          SELECT psNameNEW,     NVL(psName,SWBRECL_DESC)||psSubName, psNameNEW,      NVL(pnRecmCode,SWBRECL_RECMCODE)
                            FROM SWBRECL
                           WHERE SWBRECL_NOMBRE = psNameOLD;
          END IF;

          IF SQL%ROWCOUNT = 0  THEN
             vsError := vsBkpoint||SQLERRM;
          END IF;

      EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
               vsError := vsBkpoint||SQLERRM;
          WHEN OTHERS THEN
               vsError := vsBkpoint||SQLERRM;
      END;

      vsBkpoint := 'BK0002 ';

      RegistraEtapa;

      vsEtapa  := 'Registro de parametros';

      BEGIN
          INSERT INTO SWRRECL(SWRRECL_NOMBRE,      SWRRECL_NOMBRE_PAR,    SWRRECL_PARAMETRO_DESC,           SWRRECL_PARAMETRO_TIPO,
                              SWRRECL_ORDEN,       SWRRECL_PARAMETRO_REQ, SWRRECL_RECMCODE,                 SWRRECL_PARAM_FILTRO,
                              SWRRECL_CONDICION_1, SWRRECL_CONDICION_2,   SWRRECL_CONDICION_3,              SWRRECL_OBJECT_CLEAN,
                              SWRRECL_ALL,         SWRRECL_DEFAULT
                             )
                       SELECT psNameNEW,           SWRRECL_NOMBRE_PAR,    SWRRECL_PARAMETRO_DESC,           SWRRECL_PARAMETRO_TIPO,
                              SWRRECL_ORDEN,       SWRRECL_PARAMETRO_REQ, NVL(pnRecmCode,SWRRECL_RECMCODE), SWRRECL_PARAM_FILTRO,
                              SWRRECL_CONDICION_1, SWRRECL_CONDICION_2,   SWRRECL_CONDICION_3,              SWRRECL_OBJECT_CLEAN,
                              SWRRECL_ALL,         SWRRECL_DEFAULT
                         FROM SWRRECL
                        WHERE SWRRECL_Nombre = psNameOLD;

          IF SQL%ROWCOUNT = 0  THEN
             vsError := vsBkpoint||SQLERRM;
          END IF;

      EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
               vsError := vsBkpoint||SQLERRM;
          WHEN OTHERS THEN
               vsError := vsBkpoint||SQLERRM;
      END;

      vsBkpoint := 'BK0003 ';

      RegistraEtapa;

      IF pnRecmCode IS NULL OR (pnRecmCode IS NOT NULL AND psRecmExts = 'OLD') THEN
         vsEtapa  := 'Aignar reporte a usuarios';

         FOR regRep IN cuRepUsu LOOP

             --Se asigna el nuevo reporte a los usuarios
             BEGIN
                 INSERT INTO SWRUSUR(SWRUSUR_USUARIO, SWRUSUR_REPORT_NAME, SWRUSUR_RECMCODE)
                              VALUES(regRep.Usee,     regRep.Rept,         NVL(pnRecmCode,regRep.Recm));
             EXCEPTION
                 WHEN DUP_VAL_ON_INDEX THEN
                      vsError := vsBkpoint||SQLERRM;
                 WHEN OTHERS THEN
                      vsError := vsBkpoint||SQLERRM;
             END;

         END LOOP;

         vsBkpoint := 'BK0004 ';

         RegistraEtapa;

         IF psDeleteOLD = 'Y' THEN
            vsEtapa := NULL;

            BEGIN
                BEGIN
                    SELECT SWBRECL_PROCESO
                      INTO vsEtapa
                      FROM SWBRECL
                     WHERE SWBRECL_NOMBRE = psNameOLD
                     GROUP BY SWBRECL_PROCESO;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         vsEtapa := NULL;

                    WHEN OTHERS THEN
                         vsEtapa := NULL;
                END;

                IF vsEtapa IS NOT NULL THEN
                   DELETE FROM TWGBWMNU
                    WHERE TWGBWMNU_NAME = vsEtapa;

                   IF SQL%ROWCOUNT = 0  THEN
                      vsError := vsBkpoint||SQLERRM;
                   END IF;
                END IF;
            END;

            vsBkpoint := 'BK0005 ';

            RegistraEtapa;

            vsEtapa  := 'elimina el reporte anterior al usuario';

            BEGIN
                DELETE FROM SWRUSUR WHERE SWRUSUR_REPORT_NAME = psNameOLD;

                IF SQL%ROWCOUNT = 0  THEN
                   vsError := vsBkpoint||SQLERRM;
                END IF;
            END;

            vsBkpoint := 'BK0006 ';

            RegistraEtapa;

            vsEtapa  := 'elimina los parametros al reprote anterior';

            BEGIN
                DELETE FROM SWRRECL WHERE SWRRECL_NOMBRE = psNameOLD;

                IF SQL%ROWCOUNT = 0  THEN
                   vsError := vsBkpoint||SQLERRM;
                END IF;
            END;

            vsBkpoint := 'BK0007 ';

            RegistraEtapa;

            vsEtapa  := 'elimina el registro del reporte';

            BEGIN
                DELETE FROM SWBRECL WHERE SWBRECL_NOMBRE = psNameOLD;

                IF SQL%ROWCOUNT = 0  THEN
                   vsError := vsBkpoint||SQLERRM;
                END IF;
            END;

            RegistraEtapa;

         END IF;
      END IF;

  END PWAASGR;
/
