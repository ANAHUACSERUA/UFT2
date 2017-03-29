CREATE OR REPLACE FUNCTION BANINST1.FWAURLL(psTipo VARCHAR2) RETURN VARCHAR2 IS

/*

   TAREA: Retorna la liga para cargar archivos (DESTINO)
          Retorna la liga desde donde se ejecuta el proseso (ORIGEN)
   FECHA: 14/06/2010
   AUTOR: GEPC

*/

  csRuta CONSTANT VARCHAR2(300) := FWALINK; --Retorna el URL que le corresponde al Campus
  
  vsLiga VARCHAR2(300) := NULL;

  BEGIN

      IF    psTipo = 'ORIGEN' THEN
            vsLiga := csRuta;
      ELSIF psTipo = 'DESTINO' THEN
            vsLiga := csRuta||'archivo.guardaFoto';
      END IF;

      RETURN vsLiga;

  END FWAURLL;
/
