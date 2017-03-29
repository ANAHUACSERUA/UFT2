CREATE OR REPLACE PACKAGE BANINST1.kwamobil IS

/*
         Tarea: Consultas para las aplicaciones Mobile
         Fecha: 26/06/2012.
         Autor: GEPC

  Modificación: CONSULTE EL "PACKAGE BODY" PARA VER EL DETALLE DE LAS MODIFICACIONES

*/

  TYPE type_cursor IS REF CURSOR;

  --colorCalificacion
  FUNCTION colorCalificacion(pnGrade NUMBER) RETURN VARCHAR2;

  --promedioParcial
  FUNCTION promedioParcial(pnPidm NUMBER,
                           psTerm VARCHAR2,
                           pnCrn  NUMBER,
                           psType VARCHAR2
                          ) RETURN VARCHAR2;

  --ponderacion
  FUNCTION ponderacion(psTerm VARCHAR2,
                       pnCrn  NUMBER,
                       psType VARCHAR2
                      ) RETURN VARCHAR2;

  --getName
  PROCEDURE getName(psId       VARCHAR2,
                    cuName OUT type_cursor
                   );

  --getTerm
  PROCEDURE getTerm(psTypeTerm     VARCHAR2 DEFAULT NULL,
                    cuTerm     OUT type_cursor
                    );

  --getHiAc
  PROCEDURE getHiAc(psId       VARCHAR2,
                    cuHiAc OUT type_cursor
                   );

  --getProm
  PROCEDURE getProm(psId       VARCHAR2,
                    cuProm OUT type_cursor
                   );

  --getParciales
  PROCEDURE getParciales(psId            VARCHAR2,
                         cuParciales OUT type_cursor
                        );

  --getPerfiles
  PROCEDURE getPerfiles(psId            VARCHAR2,
                        cuPerfiles OUT type_cursor
                        );
/** 
  --getEventos
  PROCEDURE getEventos(psId VARCHAR2,
                        cuEventos OUT type_cursor
                        );
**/

--  --getEventoDetalle
--  PROCEDURE getEventoDetalle(psId VARCHAR2,
--                        cuEventos OUT type_cursor
--                        );

  /**
  --getNoticias
  PROCEDURE getNoticias(psId VARCHAR2,
                        cuNoticias OUT type_cursor
                        );
  **/

  --getRetenciones
  PROCEDURE getRetenciones(psId            VARCHAR2,
                        cuRetenciones OUT type_cursor
                        );

  --getCompParciales
  PROCEDURE getCompParciales(psId            VARCHAR2,
                             cuCompParciales OUT type_cursor
                            );

  /**
  --getEstadoCuenta
  PROCEDURE getEstadoCuenta(psId           VARCHAR2,
                            cuEstadoCuenta OUT type_cursor
                           );
  **/

  
  /**
  --getEstadoCuentaVpdi
  PROCEDURE getEstadoCuentaVpdi(psId           VARCHAR2,
                            cuEstadoCuenta OUT type_cursor
                           );
  **/


  /**
  --getAdeudoSiVencido
  PROCEDURE getAdeudoSiVencido(psId               VARCHAR2,
                               --psVpdi             VARCHAR2,
                               cuEstadoCuenta OUT type_cursor
                              );
  **/


  /**
  --getAdeudoNoVencido
  PROCEDURE getAdeudoNoVencido(psId               VARCHAR2,
                               --psVpdi             VARCHAR2,
                               cuEstadoCuenta OUT type_cursor
                              );
  **/


  /**
  --getDetalleCuenta
  PROCEDURE getDetalleCuenta(psId               VARCHAR2,
                             --psVpdi             VARCHAR2,
                             cuEstadoCuenta OUT type_cursor
                            );
  **/


  /**
  --getDetalleCuenta
  PROCEDURE getPagosPorAplicar(psId               VARCHAR2,
                             --psVpdi             VARCHAR2,
                             cuEstadoCuenta OUT type_cursor
                             );
  **/

  --muestra la situacion académica del alumno
  --getSituacion
  PROCEDURE getSituacion(psId            VARCHAR2,
                         cuSituacion OUT type_cursor
                        );
END kwamobil;
/