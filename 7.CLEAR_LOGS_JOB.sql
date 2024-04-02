BEGIN
	DBMS_SCHEDULER.CREATE_JOB(job_name 	=> CLEAR_LOGS',
							job_type 	=> 'PLSQL_BLOCK',
							job_action 	=> 'BEGIN PKG_LOGS.CLEAR_LOGS_JOB; END;',
							start_date 	=> TO_TIMESTAMP_TZ('2024-01-01 00:00:00.0 +3:00', 'yyyy-mm-dd hh24:mi:ss.ff tzr'),
							repeat_interval => 'FREQ=DAILY;BYHOUR=7;BYMINUTE=0;BYSECOND=0',
							comments 	=> 'Clear Logs',
							enabled 	=> TRUE);
END;