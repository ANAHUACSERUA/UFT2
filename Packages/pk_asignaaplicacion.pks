DROP PACKAGE BANINST1.PK_ASIGNAAPLICACION;

CREATE OR REPLACE PACKAGE BANINST1.pk_AsignaAplicacion IS
/*
  Objetivo              : Aplicaci�n para asiganar escuelas y periodos a modificar
  Fecha de creaci�n     : 10/05/2006
  Autor                 : GEPC

  �ltima modificaci�n:
*/
  --EL PROCEDIMEITO GENERA LOS FRAIMS DE LA APLICACI�N
  PROCEDURE P_Aplicacion(psParametro VARCHAR2 DEFAULT NULL);


  --GENERA LAPAGINA HTML EN LA APLICACION QUE ASIGNA LA APLICACION
  PROCEDURE p_AsignandoModulo(psMsg    VARCHAR2,
                              pbAccion BOOLEAN,
                              psAccion VARCHAR2,
                              pnModulo NUMBER DEFAULT NULL);

  --PAGINA PREVIA PARA PRESENTAR LA ASIGNACION DE APLICACIONES
  PROCEDURE p_AplicacionAsignada(psUsuario VARCHAR2,
                                 psModulo  VARCHAR2);

  --PRESENTA EL LISTADO DE APLICACIONES
  PROCEDURE p_AplicacionAsignada(psUsuario    VARCHAR2,
                                 psModulo     VARCHAR2,
                                 psAplicacion VARCHAR2);

  --REGISTRA LA APLICACI�N AL USUARIO
  PROCEDURE p_AsignandoAplicacion(psUsuario    VARCHAR2,
                                  pnModulo     NUMBER,
                                  pnAplicacion NUMBER,
                                  psAccion     VARCHAR2);

  -- JS
  PROCEDURE js;

END pk_AsignaAplicacion;
/


DROP PUBLIC SYNONYM PK_ASIGNAAPLICACION;

CREATE PUBLIC SYNONYM PK_ASIGNAAPLICACION FOR BANINST1.PK_ASIGNAAPLICACION;


GRANT EXECUTE ON BANINST1.PK_ASIGNAAPLICACION TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ASIGNAAPLICACION TO WWW2_USER;
