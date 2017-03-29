CREATE OR REPLACE PACKAGE BANINST1.kwacrev IS
/*
           Tarea: Registro de criterios de evaluación
           Fecha: 25/10/2006.
           Autor: GEPC
        Objetivo: Asignar los criterios de evaluación alos cursos y alumnos inscritos a ellos

    Modificación: El historico de modificaciones consultarlo en el PACKAGE BODY


*/

  --EL PROCEDIMEITO GENERA LOS FRAIMS DE LA APLICACIÓN
  PROCEDURE Criterios(psPrograma VARCHAR2 DEFAULT NULL);

  --PRESENTA EL LISTADO DE COMPONENTES
  PROCEDURE Componentes(psTerm  VARCHAR2 DEFAULT NULL,
                        psCrn   VARCHAR2 DEFAULT NULL
                       );

  --EL PROCEDIMIENTO GUARDA LOS componenteS
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
                             psMust VARCHAR2
                            );

  --ES ELIMINADO EL COMPONENTE
  PROCEDURE eliminaComponente(psTerm VARCHAR2,
                              psCrn  VARCHAR2,
								                      pnIddi NUMBER
                             );

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
                           );

  PROCEDURE P_CssTabs;

END kwacrev;
/