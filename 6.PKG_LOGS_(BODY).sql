CREATE OR REPLACE PACKAGE BODY PKG_LOGS
AS

FUNCTION GET_RUN_ID RETURN NUMBER
AS
BEGIN
	RETURN LOGS_RUN_SEQ.NEXTVAL;
END GET_RUN_ID;

FUNCTION PREPARE_RUN_ID (RUN_ID IN NUMBER) RETURN NUMBER
AS
	nRUN_ID	NUMBER;
BEGIN
	
	IF RUN_ID IS NULL THEN
		nRUN_ID := GET_RUN_ID;
	ELSE
		nRUN_ID := RUN_ID;
	END IF;

	RETURN nRUN_ID;

END PREPARE_RUN_ID;

PROCEDURE ADD_LOG(DESCR  		IN VARCHAR2,
				LOG_NAME_ID		IN NUMBER,
				LOG_TYPE_ID		IN NUMBER 	DEFAULT NULL,
				RUN_ID 			IN NUMBER 	DEFAULT NULL,
				DESCR_CLOB		IN CLOB 	DEFAULT NULL,
				PROG_NAME		IN VARCHAR2 DEFAULT NULL)
AS
    PRAGMA			autonomous_transaction;
   
	vPROG_NAME 		VARCHAR2(4000);
	nLOG_TYPE_ID	NUMBER;
	nRUN_ID			NUMBER;
	vACTIVE			VARCHAR2(1);
	vDESCR			varchar2(4000);
	cDESCR_CLOB		CLOB;
BEGIN
	
	cDESCR_CLOB:=DESCR_CLOB;
	
	IF LENGTH(DESCR) <= 4000 THEN
		vDESCR:=DESCR;
	ELSE
		vDESCR:='Слишком большой DESCR > 4000. Смотри вывод в DESCR_CLOB';
		cDESCR_CLOB:=DESCR;
	END IF;
	
	BEGIN
		SELECT ACTIVE
			INTO vACTIVE
			FROM APP_LOGS.LOGS_NAME
			WHERE ID = LOG_NAME_ID;
	EXCEPTION WHEN OTHERS THEN
		RETURN;
	END;

	IF vACTIVE = 'N' THEN
		RETURN;
	END IF;
		
	IF LOG_TYPE_ID IS NULL THEN
		nLOG_TYPE_ID := 1;
	ELSE
		nLOG_TYPE_ID := LOG_TYPE_ID;
	END IF;

	nRUN_ID := PREPARE_RUN_ID(RUN_ID);

	IF PROG_NAME IS NULL THEN
		vPROG_NAME := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(2));
	ELSE
		vPROG_NAME := PROG_NAME;
	END IF;

	INSERT INTO LOGS(RUN_ID,
					LOG_TYPE_ID,
					DESCR,
					LOG_NAME_ID,
					PROG_NAME,
					DESCR_CLOB)
		VALUES(nRUN_ID,
				nLOG_TYPE_ID,
				vDESCR,
				LOG_NAME_ID,
				vPROG_NAME,
				cDESCR_CLOB);
	COMMIT;
EXCEPTION WHEN OTHERS THEN
	BEGIN
		INSERT INTO LOGS(RUN_ID,
						LOG_TYPE_ID,
						DESCR,
						LOG_NAME_ID)
			VALUES(nRUN_ID,
					3,
					'Ошибка записи лога',
					LOG_NAME_ID);
	EXCEPTION WHEN OTHERS THEN 
		NULL;
	END;
END ADD_LOG;

PROCEDURE ADD_LOG(DESCR  		IN VARCHAR2,
				vLOG_NAME		IN VARCHAR2,
				vLOG_TYPE		IN VARCHAR2 DEFAULT NULL,
				RUN_ID 			IN NUMBER 	DEFAULT NULL,
				DESCR_CLOB		IN CLOB 	DEFAULT NULL)
AS
	vPROG_NAME	VARCHAR2(4000);
	LOG_NAME_ID NUMBER;
	LOG_TYPE_ID NUMBER;
BEGIN
	
	vPROG_NAME := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(2));
	
	BEGIN
		SELECT ID
			INTO LOG_NAME_ID
			FROM LOGS_NAME
			WHERE UPPER(NAME) = UPPER(vLOG_NAME);
	EXCEPTION WHEN OTHERS THEN
		LOG_NAME_ID:= NULL;
	END;

	BEGIN
		SELECT ID
			INTO LOG_TYPE_ID
			FROM LOGS_TYPE
			WHERE UPPER(LOG_TYPE) = UPPER(vLOG_TYPE);
	EXCEPTION WHEN OTHERS THEN
		LOG_TYPE_ID:= NULL;
	END;

	ADD_LOG(DESCR 			=> DESCR,
			LOG_NAME_ID		=> LOG_NAME_ID,
			LOG_TYPE_ID		=> LOG_TYPE_ID,
			RUN_ID 			=> RUN_ID,
			DESCR_CLOB		=> DESCR_CLOB,
			PROG_NAME		=> vPROG_NAME);
EXCEPTION WHEN OTHERS THEN
	NULL;
END ADD_LOG;

PROCEDURE ADD_LOG_CLOB(DESCR_CLOB  	IN CLOB,
					LOG_NAME_ID		IN NUMBER,
					LOG_TYPE_ID		IN NUMBER DEFAULT NULL,
					RUN_ID 			IN NUMBER DEFAULT NULL)
AS
	vPROG_NAME 	VARCHAR2 (4000);
BEGIN
	
	vPROG_NAME := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(2));

	ADD_LOG(DESCR  			=> NULL,
			LOG_NAME_ID		=> LOG_NAME_ID,
			LOG_TYPE_ID		=> LOG_TYPE_ID,
			RUN_ID 			=> RUN_ID,
			DESCR_CLOB		=> DESCR_CLOB,
			PROG_NAME		=> vPROG_NAME);
EXCEPTION WHEN OTHERS THEN
	NULL;
END ADD_LOG_CLOB;

PROCEDURE DEB(DESCR IN VARCHAR2)
AS
	vPROG_NAME	VARCHAR2 (4000);
BEGIN
	
	vPROG_NAME := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(2));

	ADD_LOG(DESCR  			=> DESCR,
			LOG_NAME_ID		=> 1, --DEBUG
			LOG_TYPE_ID		=> 4, --DEBUG
			RUN_ID 			=> NULL,
			DESCR_CLOB		=> NULL,
			PROG_NAME		=> vPROG_NAME);
EXCEPTION WHEN OTHERS THEN
	NULL;
END DEB;

PROCEDURE DEBC(DESCR_CLOB IN CLOB)
AS
	vPROG_NAME	VARCHAR2 (4000);
BEGIN
	
	vPROG_NAME := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(2));

	ADD_LOG(DESCR  			=> NULL,
			LOG_NAME_ID		=> 1, --DEBUG
			LOG_TYPE_ID		=> 4, --DEBUG
			RUN_ID 			=> NULL,
			DESCR_CLOB		=> DESCR_CLOB,
			PROG_NAME		=> vPROG_NAME);
EXCEPTION WHEN OTHERS THEN
	NULL;
END DEBC;

PROCEDURE CLEAR_LOGS_JOB
AS
BEGIN
	FOR c IN (SELECT ID,
					CLEAR_TIME_TYPE,
					DAYS_CNT,
					MONTHS_CNT
				FROM LOGS_NAME)
	LOOP
		IF c.CLEAR_TIME_TYPE = 1 THEN
			DELETE FROM LOGS 
				WHERE LOG_NAME_ID = c.ID 
					AND TRUNC(CREATE_DATE) <= SYSDATE - c.DAYS_CNT;
		ELSIF c.CLEAR_TIME_TYPE = 2 THEN
			DELETE FROM LOGS 
				WHERE LOG_NAME_ID = c.ID 
					AND TRUNC(CREATE_DATE) <= ADD_MONTHS(SYSDATE, -c.MONTHS_CNT);
		END IF;
			
	END LOOP;
	
END;

PROCEDURE CLEAR_LOGS(nLOG_NAME_ID IN NUMBER)
AS
BEGIN
	DELETE 
		FROM LOGS 
		WHERE LOG_NAME_ID = nLOG_NAME_ID;
END CLEAR_LOGS;

END PKG_LOGS;