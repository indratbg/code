create or replace FUNCTION terbilang (
   v_number   IN   NUMBER
)
   RETURN VARCHAR2
AS
   TYPE myArray IS TABLE OF VARCHAR2 (255);
   str_array    myArray
      := myArray ('',
                  'thousand ',
                  ' million ',
                  ' billion ',
                  ' trillion ',
                  ' quadrillion ',
                  ' quintillion ',
                  ' sextillion ',
                  'septillion ',
                  ' octillion ',
                  ' nonillion ',
                  ' decillion ',
                  ' undecillion ',
                  ' duodecillion '
                 );
   str_number   VARCHAR2 (50);
   l_return     VARCHAR2 (4000);
   trans1       VARCHAR2 (4000);
   trans2       VARCHAR2 (4000);
BEGIN
   str_number := TRUNC (ABS (v_number));
   FOR i IN 1 .. str_array.COUNT
   LOOP
      EXIT WHEN str_number IS NULL;
      IF (SUBSTR (str_number, LENGTH (str_number) - 2, 3) <> 0)
      THEN
         trans1 :=
               TO_CHAR (TO_DATE (SUBSTR (str_number, LENGTH (str_number) - 2,
                                         3),
                                 'J'
                                ),
                        'Jsp'
                       )
            || str_array (i)
            || trans1;
      END IF;
      str_number := SUBSTR (str_number, 1, LENGTH (str_number) - 3);
   END LOOP;
   l_return := trans1;
   IF TO_CHAR (v_number) LIKE '%.%'
   THEN
      str_number :=
           (ABS (v_number) - TRUNC (ABS (v_number)))
         * (TO_NUMBER (RPAD ('1',
                             (LENGTH ((ABS (v_number) - TRUNC (ABS (v_number))
                                      )
                                     )
                             ),
                             RPAD ('0', 50, '0')
                            )
                      )
           );
      FOR i IN 1 .. str_array.COUNT
      LOOP
         EXIT WHEN str_number IS NULL;
         IF (SUBSTR (str_number, LENGTH (str_number) - 2, 3) <> 0)
         THEN
            trans2 :=
                  TO_CHAR (TO_DATE (SUBSTR (str_number,
                                            LENGTH (str_number) - 2,
                                            3
                                           ),
                                    'J'
                                   ),
                           'Jsp'
                          )
               || str_array (i)
               || trans2;
         END IF;
         str_number := SUBSTR (str_number, 1, LENGTH (str_number) - 3);
      END LOOP;
      l_return := trans1 || ' point ' || trans2;
   END IF;
   RETURN l_return;
END terbilang;