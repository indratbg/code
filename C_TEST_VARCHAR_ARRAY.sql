CREATE PROCEDURE C_TEST_VARCHAR_ARRAY(
P_XN_DOC_NUM OUT VARCHAR_ARRAY_LIST)
IS
BEGIN

SELECT DOC_NUM INTO P_XN_DOC_NUM FROM T_CLIENT_DEPOSIT;

END C_TEST_VARCHAR_ARRAY;
