create or replace 
PROCEDURE INSERTINTOWL 
(
  ORIGINAL_CASE_RK IN NUMBER  
, ISINSERTED OUT NUMBER  
) AS 
	MIN_ROW_NO NUMBER(10,0);
	MAX_ROW_NO NUMBER(10,0);
	WHITELIST_UID VARCHAR2(100 CHAR);
	WHITELIST_VALID_FROM_DTTM VARCHAR2(100 CHAR);
	NATIONALITY VARCHAR2(100 CHAR);
	RESIDENCY VARCHAR2(100 CHAR);
	INCIDENT_NAME VARCHAR2(100 CHAR);
	WHITE_LIST_MODULE NUMBER(10,0);
	MATCH_ENTITY_NAME VARCHAR2(100 CHAR);
	MATCH_ENTITY_NATIONALITY VARCHAR2(100 CHAR);
	MATCH_ENTITY_RESIDENCY VARCHAR2(100 CHAR);
	VALID_DATE VARCHAR2(100 CHAR);
	IS_CREADTED_BEFORE NUMBER(10,0);
BEGIN
	ISINSERTED:=0;
	select count(*) into IS_CREADTED_BEFORE from casemgmt.STPLog 
		where STPName='insertIntoWhiteList' and caseRK=ORIGINAL_CASE_RK;
	IF IS_CREADTED_BEFORE=0 THEN
			
		select max(VALID_FROM_DTTM) into WHITELIST_VALID_FROM_DTTM from casemgmt.CASE_LIVE  where case_rk=ORIGINAL_CASE_RK;
		
		select min(row_no) into MIN_ROW_NO from casemgmt.CASE_UDF_CHAR_VALUE
			 where case_rk=ORIGINAL_CASE_RK AND VALID_FROM_DTTM=WHITELIST_VALID_FROM_DTTM
			 and UDF_NM in ('ENTITY_NAME','FULL_ADDRESS','PLACE_OF_BIRTH','X_YEAR_OF_BIRTH','X_BIRTH_DT');

		select max(row_no) into MAX_ROW_NO from casemgmt.CASE_UDF_CHAR_VALUE
			where case_rk=ORIGINAL_CASE_RK AND VALID_FROM_DTTM=WHITELIST_VALID_FROM_DTTM
			and UDF_NM in ('ENTITY_NAME','FULL_ADDRESS','PLACE_OF_BIRTH','X_YEAR_OF_BIRTH','X_BIRTH_DT');

		select UDF_VALUE into INCIDENT_NAME from casemgmt.case_udf_char_value 
			where case_rk=ORIGINAL_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST1' AND udf_nm='X_SOURCE_NAME'  
			AND VALID_FROM_DTTM=WHITELIST_VALID_FROM_DTTM;
		
		select UDF_VALUE into NATIONALITY from casemgmt.case_udf_char_value 
			where case_rk=ORIGINAL_CASE_RK
			and UDF_NM='X_SOURCE_NATIONALITY';
			
		select UDF_VALUE into RESIDENCY from casemgmt.case_udf_char_value 
			where case_rk=ORIGINAL_CASE_RK
			and UDF_NM='X_SOURCE_RESIDENCY';
		
		select CASE_TYPE_CD into WHITE_LIST_MODULE from casemgmt.case_live 
			where case_rk=(select CASE_LINK_SK from casemgmt.case_live where case_rk=ORIGINAL_CASE_RK);

		insert into DG_WL_LOGS.WHITE_LIST_QNB(ENTITY_NAME,NATIONALITY,RESIDENCY,MODULE) 
			values(INCIDENT_NAME,NATIONALITY,RESIDENCY,WHITE_LIST_MODULE);
		
		select max(WHITE_LIST_UID) into WHITELIST_UID from DG_WL_LOGS.WHITE_LIST_QNB;

		
		FOR loop_counter IN MIN_ROW_NO..MAX_ROW_NO
		LOOP
			select UDF_VALUE into MATCH_ENTITY_NAME from casemgmt.case_udf_char_value where case_rk=ORIGINAL_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST' AND udf_nm='ENTITY_NAME'  AND VALID_FROM_DTTM=WHITELIST_VALID_FROM_DTTM and row_no=loop_counter;
			
			select UDF_VALUE into MATCH_ENTITY_NATIONALITY from casemgmt.case_udf_char_value where case_rk=ORIGINAL_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST' AND udf_nm='NATIONALITY_COUNTRY_NAME'  AND VALID_FROM_DTTM=WHITELIST_VALID_FROM_DTTM and row_no=loop_counter;
			
			select UDF_VALUE into MATCH_ENTITY_RESIDENCY from casemgmt.case_udf_char_value where case_rk=ORIGINAL_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST' AND udf_nm='CITIZENSHIP_COUNTRY_NAME'  AND VALID_FROM_DTTM=WHITELIST_VALID_FROM_DTTM and row_no=loop_counter;
			
			insert into DG_WL_LOGS.WHITE_LIST_MATCHES_QNB(WHITE_LIST_UID,MATCH_ENTITY_NAME,MATCH_ENTITY_NATIONALITY ,MATCH_ENTITY_RESIDENCY) 
				values(WHITELIST_UID,MATCH_ENTITY_NAME,MATCH_ENTITY_NATIONALITY,MATCH_ENTITY_RESIDENCY);
		END LOOP;
			
		
		--10NOV2005:03:49:19.0  ... SAS Format datetime20 , to aviod any possible compatibility issues. 
		VALID_DATE := to_char(sysdate,'DDMONYYYY:HH24:MI:SS');

		insert into casemgmt.STPLog (STPName,CASERK,CreateDate) 
				values ('insertIntoWhiteList' , ORIGINAL_CASE_RK, VALID_DATE);
		commit;
		ISINSERTED:=1;
	END IF;
END INSERTINTOWL;