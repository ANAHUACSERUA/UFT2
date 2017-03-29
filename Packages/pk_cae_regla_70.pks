CREATE OR REPLACE PACKAGE BANINST1.pk_Cae_Regla_70 IS
/******************************************************************************
PAQUETE:            BANINST1.pk_Cae_Regla_70
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la aplicacion de diferentes regalas
                    para el proceso de Revoacion del CAE
AUTOR:              Roman Ruiz
FECHA:              25-feb-2014
******************************************************************************/

    /******************************************************************************
    PROCEDIMIENTO:      p_Main
    OBJETIVO:           Evalua los registros validos para las reglas
                           - alumno este activo
                           - Inexistencia de cae años anteriores
                           - 70 %
    PARAMETROS:
*********************************************************************************
-- modificacion :  md-01
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
modificacion :  md-05
objetivo     : se adiciona entradas a TWRCARL.
autor        : Roman Ruiz
fecha        : 04-ago-2014
****************************************
modificacion :  md-06
objetivo     : se cambia el p_main a funcion para regresar detalle y se envia rut en especifico
autor        : Roman Ruiz
fecha        : 21-ago-2014
*********************************************************************************
modificacion :  md-08
objetivo     : la regla del 70 se aplica integra al primera carga  de fuas ,
               todas las demas no se checa la validación de cae en años anteriores(twacral).
autor        : Roman Ruiz
fecha        : 24-sep-2014

 ******************************************************************************/
    

    
Function p_Main (pi_pidm number default null, pi_fuas number default null) return number;

Function F_MainXRut( ps_rut varchar2, ps_error out varchar  ) Return number;


Function F_Evalua70Prcntf ( pi_pidm number ) Return number;


Function F_Evalua70Prcnt ( pi_pidm number, ps_error out varchar  ) Return number;


Function F_EvaluaTieneMatricula ( pi_pidm number ) Return number;



Function F_EvaluaEsEgresado ( pi_pidm number ) Return number;


Function F_EvaluaTieneMatriculaActual ( pi_pidm number ) Return number;

--md-05 start
Function F_AltaTwacral ( pi_pidm number , ps_status varchar , ps_error out varchar  ) Return number;


Function F_AltaTwacralHistorica ( pi_pidm number , ps_error out varchar  ) Return number;


--md-05 end

END pk_Cae_Regla_70;
/