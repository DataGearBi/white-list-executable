USE [ecm71]
GO
/****** Object:  StoredProcedure [casemgmt].[CREATEWHITELIST]    Script Date: 9/12/2019 1:45:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Hanash Yaslem
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [casemgmt].[CREATEWHITELIST]
	@ORIGINAL_CASE_RK_STR nvarchar(100),
	@ENTITY_NAME nvarchar(1000),
	@ORIGINAL_INCIDENT_ID nvarchar(100),
	@MAX_RANK_STR nvarchar(10),
	@WHIETLIST_INITIATOR nvarchar(100),
	@ISCREATED numeric(10) output
AS DECLARE
	@ORIGINAL_CASE_DESC nvarchar(100),
	@ORIGINAL_VALID_DTTM_LGCHR  DATETIME,
	@ORIGINAL_VALID_DTTM  DATETIME,
	@ORIGINAL_CASE_RK numeric(10),
	@MAX_RANK numeric(10),
	@ROW_ID numeric(10),
	@ROW_ID1 numeric(10),
	@WHITELIST_CASE_RK numeric(10),
	@WHITELIST_CASE_ID nvarchar (100),
	@WHITELIST_PRIORITY_CD  nvarchar (1000),
	@WHITELIST_VALID_FROM_DTTM DATETIME,
	@WHIETLIST_INCIDENT_ID nvarchar(100),
	@IS_CREATED_BEFORE numeric(10)
BEGIN
	set @ISCREATED = 0;

	SET @ORIGINAL_CASE_RK = CAST(@ORIGINAL_CASE_RK_STR AS INT);
	SET @MAX_RANK = CAST(@MAX_RANK_STR AS INT); 
  
	select  @IS_CREATED_BEFORE = count(*) from CASEMGMT.SWIFT_STP 
		where STPName='SWIFT_SP' and ENTITY_NAME= LTRIM(RTRIM(@ENTITY_NAME)) and ID=LTRIM(RTRIM(@ORIGINAL_INCIDENT_ID)) and MAX_RANK=MAX_RANK;
  

	IF @IS_CREATED_BEFORE=0
	BEGIN
		EXEC [casemgmt].[case_rk_seq_next] @retval = @WHITELIST_CASE_RK OUTPUT
		PRINT @WHITELIST_CASE_RK;
		set @WHITELIST_CASE_ID = CONCAT( 'WL-', @WHITELIST_CASE_RK);
		set @ROW_ID = 0;
		set @ROW_ID1 = @ROW_ID+1;
		
		
		select @WHITELIST_PRIORITY_CD = PRIORITY_CD  from casemgmt.case_live where CASE_RK=@ORIGINAL_CASE_RK;
		if @@rowcount = 0
		BEGIN
			SET @WHITELIST_PRIORITY_CD = '';
		end

		SET @WHITELIST_VALID_FROM_DTTM = getDate();

		Insert into CASEMGMT.CASE_LIVE (CASE_RK,CASE_ID,VALID_FROM_DTTM,SOURCE_SYSTEM_CD , REGULATORY_RPT_RQD_FLG
		,CREATE_DTTM, VERSION_NO,DELETE_FLG, UI_DEF_FILE_NM,CREATE_USER_ID, CASE_LINK_SK
		,CASE_TYPE_CD,CASE_DESC,UPDATE_USER_ID,PRIORITY_CD,CASE_STATUS_CD) 
		values (@WHITELIST_CASE_RK,@WHITELIST_CASE_ID, @WHITELIST_VALID_FROM_DTTM,'SASECM','0'
		, @WHITELIST_VALID_FROM_DTTM,1,'0','case-whitelist.xml',@WHIETLIST_INITIATOR, 
		@original_case_rk,'WHITELIST','whitelist',@WHIETLIST_INITIATOR,@WHITELIST_PRIORITY_CD,'SN');


		insert into casemgmt.CASE_VERSION select * from casemgmt.CASE_LIVE where case_rk=@WHITELIST_CASE_RK;
		insert into casemgmt.case_x_user_group VALUES (@WHITELIST_CASE_RK,'AML Analysts');
		insert into casemgmt.case_x_user_group VALUES (@WHITELIST_CASE_RK,'Ent Case Mgmt Users');
		insert into casemgmt.case_x_user_group VALUES (@WHITELIST_CASE_RK,'CDD Analysts');

		update casemgmt.case_live set CASE_LINK_SK=@ORIGINAL_CASE_RK where case_rk=@ORIGINAL_CASE_RK;
		select @ORIGINAL_VALID_DTTM = MAX(VALID_FROM_DTTM)  from casemgmt.CASE_UDF_CHAR_VALUE where CASE_RK=@ORIGINAL_CASE_RK;
		select @ORIGINAL_VALID_DTTM_LGCHR = MAX(VALID_FROM_DTTM) from casemgmt.CASE_UDF_LGCHR_VALUE where CASE_RK=@ORIGINAL_CASE_RK;
    
		
		insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
			select @WHITELIST_CASE_RK,@WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, 1 ,UDF_VALUE
			from casemgmt.case_udf_char_value 
			where case_rk=@ORIGINAL_CASE_RK and valid_from_dttm=@ORIGINAL_VALID_DTTM
			AND ROW_NO = @ROW_ID1
			AND udf_table_nm ='X_ENTITY_LIST1';

		SET @WHIETLIST_INCIDENT_ID = @ORIGINAL_INCIDENT_ID + '0';

		update casemgmt.case_udf_char_value set UDF_VALUE= @WHIETLIST_INCIDENT_ID
		where case_rk= @WHITELIST_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST1' and UDF_NM='X_INCIDENT_ID';
     

		insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
		  select @WHITELIST_CASE_RK,@WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE
		  from casemgmt.case_udf_char_value 
		  where case_rk=@ORIGINAL_CASE_RK and valid_from_dttm=@ORIGINAL_VALID_DTTM AND udf_table_nm ='X_ENTITY_LIST'
		  AND ROW_NO in (select row_no from casemgmt.case_udf_char_value where 
		  UDF_TABLE_NM='X_ENTITY_LIST' and UDF_NM='ROWNO' AND UDF_VALUE=@row_id 
		  and VALID_FROM_DTTM=@ORIGINAL_VALID_DTTM);
      
		insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
			select @WHITELIST_CASE_RK, @WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE
			from casemgmt.case_udf_char_value
			where case_rk=@ORIGINAL_CASE_RK and valid_from_dttm=@ORIGINAL_VALID_DTTM_LGCHR AND UDF_NM = 'X_REMARKS' 
			AND ROW_NO in (select row_no from casemgmt.case_udf_char_value where 
			UDF_TABLE_NM='X_ENTITY_LIST' and UDF_NM='ROWNO' 
			and VALID_FROM_DTTM=@ORIGINAL_VALID_DTTM);
    
		insert into casemgmt.case_udf_char_value (CASE_RK, VALID_FROM_DTTM, UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE)
			select @WHITELIST_CASE_RK,@WHITELIST_VALID_FROM_DTTM,UDF_TABLE_NM, UDF_NM, ROW_NO, UDF_VALUE
			from casemgmt.case_udf_char_value 
			where case_rk=@ORIGINAL_CASE_RK and valid_from_dttm=@ORIGINAL_VALID_DTTM
			AND ( udf_nm='X_IDENTITY_NUM' OR udf_nm= 'X_CLIENT_NAME' )
			AND udf_table_nm ='CASE';

			
		
		insert into casemgmt.SWIFT_STP (STPName,ENTITY_NAME,ID,MAX_RANK) values ('SWIFT_SP' , @ENTITY_NAME, @ORIGINAL_INCIDENT_ID, @MAX_RANK);
    
		SET @ISCREATED = 1;
		
	END
END