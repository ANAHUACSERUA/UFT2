CREATE OR REPLACE PACKAGE baninst1.kwasmrbcmp is

  PROCEDURE Inicio(psParametro VARCHAR2 DEFAULT NULL,
                   pnBusca     NUMBER   DEFAULT 0
                  );

  --CÓDIGO JavaScript
  PROCEDURE JS;

  PROCEDURE Verifica(psOneu   VARCHAR2,
                     psUser   VARCHAR2,
                     psDate   VARCHAR2,
                     pnAudSid NUMBER
                    );

END kwasmrbcmp;
/
