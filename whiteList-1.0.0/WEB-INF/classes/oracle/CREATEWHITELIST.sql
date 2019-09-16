create or replace 
PROCEDURE CREATEWHITELIST 
(
  ORIGINAL_CASE_RK_STR IN VARCHAR2  
, CASE_TYPE IN VARCHAR2  
, ENTITY_NAME IN VARCHAR2  
, ORIGINAL_CASE_ID IN VARCHAR2  
, MAX_RANK_STR IN VARCHAR2  
, WHIETLIST_INITIATOR IN VARCHAR2
,ISCREATED OUT NUMBER  
) AS 
  ORIGINAL_CASE_DESC VARCHAR2(100 CHAR);
  ORIGINAL_VALID_DTTM_LGCHR  TIMESTAMP(6);
  ORIGINAL_VALID_DTTM  TIMESTAMP(6);
  ORIGINAL_CASE_RK NUMBER(10,0);
  MAX_RANK NUMBER(10,0);
  ROW_ID NUMBER(10,0);
  ROW_ID1 NUMBER(10,0);
  WHITELIST_CASE_RK NUMBER(10,0);
  WHITELIST_CASE_ID  VARCHAR2(100 CHAR) ;
  WHITELIST_PRIORITY_CD  VARCHAR2(100 CHAR) ;
  WHITELIST_VALID_FROM_DTTM TIMESTAMP(6);
  WHIETLIST_INCIDENT_ID VARCHAR2(100 CHAR);
  IS_CREADTED_BEFORE NUMBER(10,0);
BEGIN
  ISCREATED:=0;
  
  ORIGINAL_CASE_RK:= TO_NUMBER(ORIGINAL_CASE_RK_STR);
  MAX_RANK:= TO_NUMBER(MAX_RANK_STR);  
  
  select count(*) into IS_CREADTED_BEFORE from CASEMGMT.SWIFT_STP 
  where STPName='SWIFT_SP' and ENTITY_NAME= TRIM(ENTITY_NAME) and ID=TRIM(ORIGINAL_CASE_ID) and MAX_RANK=MAX_RANK;
  
  IF IS_CREADTED_BEFORE=0 THEN
  
  select CASEMGMT.case_rk_seq.nextval into WHITELIST_CASE_RK from dual;
  WHITELIST_CASE_ID := 'WL-'|| WHITELIST_CASE_RK;
  ROW_ID := 0;
  ROW_ID1 := ROW_ID+1;
  
  select PRIORITY_CD into WHITELIST_PRIORITY_CD from casemgmt.case_live where CASE_RK=original_case_rk;
  select sysdate into WHITELIST_VALID_FROM_DTTM from dual;

    Insert into CASEMGMT.CASE_LIVE (CASE_RK,CASE_ID,VALID_FROM_DTTM,SOURCE_SYSTEM_CD , REGULATORY_RPT_RQD_FLG
        ,CREATE_DTTM, VERSION_NO,DELETE_FLG, UI_DEF_FILE_NM,CREATE_USER_ID, CASE_LINK_SK
        ,CASE_TYPE_CD,CASE_DESC,UPDATE_USER_ID,PRIORITY_CD,CASE_STATUS_CD) 
        values (WHITELIST_CASE_RK,WHITELIST_CASE_ID, WHITELIST_VALID_FROM_DTTM,'SASECM','0'
        , WHITELIST_VALID_FROM_DTTM,1,'0','case-whitelist.xml',WHIETLIST_INITIATOR, 
        original_case_rk,'WHITELIST','whitelist','ECM',WHITELIST_PRIORITY_CD,'SN');
        
    insert into casemgmt.CASE_VERSION select * from casemgmt.CASE_LIVE where case_rk=WHITELIST_CASE_RK;
    insert into casemgmt.case_x_user_group VALUES (WHITELIST_CASE_RK,'AML Analysts');
    insert into casemgmt.case_x_user_group VALUES (WHITELIST_CASE_RK,'Ent Case Mgmt Users');
    insert into casemgmt.case_x_user_group VALUES (WHITELIST_CASE_RK,'CDD Analysts');
    
    update casemgmt.case_live set CASE_LINK_SK=ORIGINAL_CASE_RK where case_rk=ORIGINAL_CASE_RK;
    select VALID_FROM_DTTM into WHITELIST_VALID_FROM_DTTM from casemgmt.case_live where CASE_RK=WHITELIST_CASE_RK;
    select MAX(VALID_FROM_DTTM) into ORIGINAL_VALID_DTTM from casemgmt.CASE_UDF_CHAR_VALUE where CASE_RK=ORIGINAL_CASE_RK;
    select MAX(VALID_FROM_DTTM) into ORIGINAL_VALID_DTTM_LGCHR from casemgmt.CASE_UDF_LGCHR_VALUE where CASE_RK=ORIGINAL_CASE_RK;
    
    select VALID_FROM_DTTM into WHITELIST_VALID_FROM_DTTM from casemgmt.case_live where case_rk=WHITELIST_CASE_RK;
        
    insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
      select WHITELIST_CASE_RK,WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, ROW_NO,UDF_VALUE
      from casemgmt.case_udf_char_value 
      where case_rk=ORIGINAL_CASE_RK and valid_from_dttm=ORIGINAL_VALID_DTTM
      AND ROW_NO = ROW_ID1
      AND udf_table_nm ='X_ENTITY_LIST1';
    
    
    insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
      select WHITELIST_CASE_RK,WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE
      from casemgmt.case_udf_char_value 
      where case_rk=ORIGINAL_CASE_RK and valid_from_dttm=ORIGINAL_VALID_DTTM AND udf_table_nm ='X_ENTITY_LIST'
      AND ROW_NO in (select row_no from casemgmt.case_udf_char_value where 
      UDF_TABLE_NM='X_ENTITY_LIST' and UDF_NM='ROWNO' AND UDF_VALUE=row_id 
      and VALID_FROM_DTTM=ORIGINAL_VALID_DTTM);
      
    insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
      select WHITELIST_CASE_RK,WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE
      from casemgmt.case_udf_char_value
      where case_rk=ORIGINAL_CASE_RK and valid_from_dttm=ORIGINAL_VALID_DTTM_LGCHR AND UDF_NM = 'X_REMARKS' 
      AND ROW_NO in (select row_no from casemgmt.case_udf_char_value where 
      UDF_TABLE_NM='X_ENTITY_LIST' and UDF_NM='ROWNO' 
      and VALID_FROM_DTTM=ORIGINAL_VALID_DTTM);
    
    insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
      select WHITELIST_CASE_RK,WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE
      from casemgmt.case_udf_char_value 
      where case_rk=ORIGINAL_CASE_RK and valid_from_dttm=ORIGINAL_VALID_DTTM
        AND ( udf_nm='X_IDENTITY_NUM' OR udf_nm= 'X_CLIENT_NAME' )
        AND udf_table_nm ='CASE';
    
    update casemgmt.case_udf_char_value  set row_no=1
        where case_rk=WHITELIST_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST1';
        
    WHIETLIST_INCIDENT_ID := ORIGINAL_CASE_ID || 0;
    update casemgmt.case_udf_char_value set UDF_VALUE=WHIETLIST_INCIDENT_ID
        where case_rk=WHITELIST_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST1' and UDF_NM='X_INCIDENT_ID';
     
    insert into casemgmt.SWIFT_STP (STPName,ENTITY_NAME,ID,MAX_RANK) values ('SWIFT_SP' , ENTITY_NAME, ORIGINAL_CASE_ID, MAX_RANK);
    
    commit;
     ISCREATED:=1;
  END IF;
 
END CREATEWHITELIST;