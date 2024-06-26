CREATE TABLE LOGS_THEMES
(ID 		NUMBER(38,0), 
THEME_NAME 	VARCHAR2(4000) NOT NULL, 
ACTIVE 		VARCHAR2(1) DEFAULT 'Y' NOT NULL,
CLEAR_TIME_TYPE	NUMBER(38,0) NOT NULL, 
DAYS_CNT	NUMBER(38,0), 
MONTHS_CNT	NUMBER(38,0),
DESCR 		VARCHAR2(4000),
CONSTRAINT LOG_NAME_PK PRIMARY KEY (ID), 
CONSTRAINT LOG_NAME_UN UNIQUE (NAME),
CONSTRAINT LOGS_NAME_CHECK_DAYS_MONTHS CHECK ("CLEAR_TIME_TYPE"=1 AND "DAYS_CNT" IS NOT NULL AND "MONTHS_CNT" IS NULL OR "CLEAR_TIME_TYPE"=2 AND "DAYS_CNT" IS NULL AND "MONTHS_CNT" IS NOT NULL), 
CONSTRAINT LOGS_NAME_CHECK_ACTIVE CHECK (ACTIVE IN ('Y', 'N'))
);

CREATE SEQUENCE LOGS_THEMES_SEQ
	START WITH 1
	INCREMENT BY 1
	CACHE 20
	NOCYCLE;

CREATE OR REPLACE TRIGGER LOGS_THEMES_I 
	BEFORE INSERT
		ON LOGS_THEMES
	FOR EACH ROW
DECLARE
BEGIN
	:NEW.ID := LOGS_THEMES_SEQ.nextval;
END LOGS_THEMES_I;

COMMENT ON TABLE LOGS_THEMES IS 'Темы лога';
COMMENT ON COLUMN LOGS_THEMES.ID IS 'Первичный ключ';
COMMENT ON COLUMN LOGS_THEMES.THEME_NAME IS 'Наименование темы';
COMMENT ON COLUMN LOGS_THEMES.ACTIVE IS 'Собирать логи';
COMMENT ON COLUMN LOGS_THEMES.CLEAR_TIME_TYPE IS '1-хранить логи в днях; 2- хранить логи в месяцах';
COMMENT ON COLUMN LOGS_THEMES.DAYS_CNT IS 'Сколько хранить логи в днях';
COMMENT ON COLUMN LOGS_THEMES.MONTHS_CNT IS 'Сколько хранить логи в месяцах';
COMMENT ON COLUMN LOGS_THEMES.DESCR IS 'Описание';

INSERT INTO LOGS_THEMES(THEME_NAME, ACTIVE, CLEAR_TIME_TYPE, DAYS_CNT, DESCR)
VALUES('DEBUG', 'Y' , 1, 1, 'Основная тема для DEBUG');

INSERT INTO LOGS_THEMES(THEME_NAME, ACTIVE, CLEAR_TIME_TYPE, DAYS_CNT, DESCR)
VALUES('EXAMPLE', 'Y' , 1, 1, 'Тестовая тема');