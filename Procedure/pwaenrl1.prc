DROP PROCEDURE BANINST1.PWAENRL1;

CREATE OR REPLACE PROCEDURE BANINST1.PWAENRL1(psTerm VARCHAR2
                                             ) IS

  /*
     TAREA: Actualizar la cantidad de inscritos en la programación académica
     FECHA: 17/03/2009
     AUTOR: GEPC
    MODULO: Programación academica

             * Etapas de actualización

               6. UPDATE INCORRECT AVAILABLE SEATS COUNT ON XLISTS SSBXLST

               9. UPDATE INCORRECT AVAILABLE SEATS COUNT ON RESERVED SEATS

  Modificación: 07/04/2011
                GEPC
                * Se quito la tabla SWRERRP que era de auditoria

  */

  csY CONSTANT VARCHAR2(1) := 'Y';
  cn0 CONSTANT NUMBER(1)   := 0;

  BEGIN
      --UPDATE INCORRECT AVAILABLE SEATS COUNT ON XLISTS SSBXLST
      BEGIN
          UPDATE SSBXLST
             SET SSBXLST_SEATS_AVAIL  = (SSBXLST_MAX_ENRL - SSBXLST_ENRL)
           WHERE SSBXLST_SEATS_AVAIL <> (SSBXLST_MAX_ENRL - SSBXLST_ENRL)
             AND SSBXLST_TERM_CODE = psTerm;

      EXCEPTION
          WHEN OTHERS THEN
               NULL;
      END;

      COMMIT;

      --UPDATE INCORRECT  AVAILABLE  SEATS  COUNT ON RESERVED SEATS
      BEGIN
          UPDATE SSRRESV
             SET SSRRESV_SEATS_AVAIL = (SSRRESV_MAX_ENRL - SSRRESV_ENRL) ,
                 SSRRESV_WAIT_AVAIL  = (SSRRESV_WAIT_CAPACITY - SSRRESV_WAIT_COUNT)
           WHERE (
                     SSRRESV_SEATS_AVAIL <> (SSRRESV_MAX_ENRL - SSRRESV_ENRL)
                  OR
                     SSRRESV_WAIT_AVAIL  <> (SSRRESV_WAIT_CAPACITY - SSRRESV_WAIT_COUNT)
                 )
             AND SSRRESV_TERM_CODE = psTerm;

      EXCEPTION
          WHEN OTHERS THEN
               NULL;
      END;

      COMMIT;

  END PWAENRL1;
/
