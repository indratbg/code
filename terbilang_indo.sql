create or replace FUNCTION terbilang_indo(v_number IN NUMBER) RETURN VARCHAR2 AS
BEGIN
    RETURN      REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE( REPLACE(
             REPLACE(REPLACE( REPLACE( REPLACE(
             LOWER( TERBILANG(v_number))
             , 'trillion'    , 'Trilyun')
             , 'billion'    , 'Milyar')
             , 'million'    , 'Juta')
             , 'onethousand'    , 'Seribu')
             , 'thousand'    , ' Ribu')
             , 'nine hundred'    , 'Sembilan Ratus')
             , 'eigth hundred'    , 'Delapan Ratus')
             , 'seven hundred'    , 'Tujuh Ratus')
             , 'six hundred'    , 'Enam Ratus')
             , 'five hundred'    , 'Lima Ratus')
             , 'four hundred'    , 'Empat Ratus')
             , 'three hundred'    , 'Tiga Ratus')
             , 'two hundred'    , 'Dua Ratus')
             , 'one hundred'    , 'Seratus')
             , 'hundred'    , 'Ratus')
             , 'ninety'        , 'Sembilan Puluh')
             , 'eighty'        , 'Delapan Puluh')
             , 'seventy'    , 'Tujuh Puluh')
             , 'sixty'        , 'Enam Puluh')
             , 'fifty'        , 'Lima Puluh')
             , 'forty'        , 'Empat Puluh')
             , 'thirty'        , 'Tiga Puluh')
             , 'twenty'        , 'Dua Puluh')
             , 'nineteen'    , 'Sembilan  Belas')
             , 'eighteen'    , 'Delapan Belas')
             , 'seventeen'    , 'Tujuh Belas')
             , 'sixteen'    , 'Enam  Belas')
             , 'fifteen'    , 'Lima  Belas')
             , 'fourteen'    , 'Empat  Belas')
             , 'thirteen'    , 'Tiga  Belas')
             , 'twelve'        , 'Dua  Belas')
             , 'eleven'        , 'Se Belas')
             , 'ten'        , 'Sepuluh')
             , 'nine'        , 'Sembilan')
             , 'eight'        , 'Delapan')
             , 'seven'        , 'Tujuh')
             , 'six'        , 'Enam')
             , 'five'        , 'Lima')
             , 'four'       , 'Empat')
             , 'three'        , 'Tiga')
             , 'two'        , 'Dua')
             , 'one'        , 'Satu')
             , 'point'        , 'koma')
             , '','')||' Rupiah';
END terbilang_indo;