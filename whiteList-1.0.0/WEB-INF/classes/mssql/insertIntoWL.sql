USE [ecm71]
GO
/****** Object:  StoredProcedure [casemgmt].[INSERTINTOWL]    Script Date: 9/12/2019 1:46:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Hanash Yaslem
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [casemgmt].[INSERTINTOWL]
	@WHITELIST_CASE_RK numeric(10),
	@ISINSERTED numeric(10) output
AS DECLARE
	@MIN_ROW_NO numeric(10),
	@MAX_ROW_NO numeric(10),
	@WHITELIST_UID nvarchar(1000),
	@WHITELIST_VALID_FROM_DTTM datetime,
	@NATIONALITY nvarchar(1000),
	@RESIDENCY nvarchar(1000),
	@INCIDENT_NAME nvarchar(1000),
	@WHITE_LIST_MODULE nvarchar(1000),
	@MATCH_ENTITY_NAME nvarchar(1000),
	@MATCH_ENTITY_NATIONALITY nvarchar(1000),
	@MATCH_ENTITY_RESIDENCY nvarchar(1000),
	@IS_CREADTED_BEFORE numeric(10)
BEGIN
	set @ISINSERTED = 0;

	select @IS_CREADTED_BEFORE = count(*)  from casemgmt.STPLog 
		where STPName='insertIntoWhiteList' and caseRK=@WHITELIST_CASE_RK;
	IF @IS_CREADTED_BEFORE=0 
	BEGIN 
		select @WHITELIST_VALID_FROM_DTTM = max(VALID_FROM_DTTM) from casemgmt.CASE_LIVE  where case_rk=@WHITELIST_CASE_RK;
		
		select @MIN_ROW_NO = min(row_no) from casemgmt.CASE_UDF_CHAR_VALUE
			 where case_rk=@WHITELIST_CASE_RK AND VALID_FROM_DTTM=@WHITELIST_VALID_FROM_DTTM
			 and UDF_NM in ('ENTITY_NAME','FULL_ADDRESS','PLACE_OF_BIRTH','X_YEAR_OF_BIRTH','X_BIRTH_DT');

		select @MAX_ROW_NO = max(row_no) from casemgmt.CASE_UDF_CHAR_VALUE
			where case_rk=@WHITELIST_CASE_RK AND VALID_FROM_DTTM=@WHITELIST_VALID_FROM_DTTM
			and UDF_NM in ('ENTITY_NAME','FULL_ADDRESS','PLACE_OF_BIRTH','X_YEAR_OF_BIRTH','X_BIRTH_DT');

		select @INCIDENT_NAME = UDF_VALUE  from casemgmt.case_udf_char_value 
			where case_rk=@WHITELIST_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST1' AND udf_nm='X_SOURCE_NAME'  
			AND VALID_FROM_DTTM=@WHITELIST_VALID_FROM_DTTM;

		select @NATIONALITY = UDF_VALUE  from casemgmt.case_udf_char_value 
			where case_rk=@WHITELIST_CASE_RK
			and UDF_NM='X_SOURCE_NATIONALITY';

		select @RESIDENCY = UDF_VALUE  from casemgmt.case_udf_char_value 
			where case_rk=@WHITELIST_CASE_RK
			and UDF_NM='X_SOURCE_RESIDENCY';

		select @WHITE_LIST_MODULE = CASE_TYPE_CD  from casemgmt.case_live 
			where case_rk=(select CASE_LINK_SK from casemgmt.case_live where case_rk=@WHITELIST_CASE_RK);

		insert into DG_WL_LOGS.dbo.WHITE_LIST_QNB([ENTITY_NAME],[NATIONALITY],[RESIDENCY],[MODULE]) 
			values(@INCIDENT_NAME,@NATIONALITY,@RESIDENCY,@WHITE_LIST_MODULE);
		
-------------------------------
		select @WHITELIST_UID = max(WHITE_LIST_UID) from DG_WL_LOGS.dbo.WHITE_LIST_QNB;
-------------------------------


	WHILE @MIN_ROW_NO <= @MAX_ROW_NO
	BEGIN 
		select @MATCH_ENTITY_NAME = UDF_VALUE from casemgmt.case_udf_char_value where case_rk=@WHITELIST_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST' AND udf_nm='ENTITY_NAME'  AND VALID_FROM_DTTM=@WHITELIST_VALID_FROM_DTTM and row_no=@MIN_ROW_NO;
		select @MATCH_ENTITY_NATIONALITY = UDF_VALUE from casemgmt.case_udf_char_value where case_rk=@WHITELIST_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST' AND udf_nm='NATIONALITY_COUNTRY_NAME'  AND VALID_FROM_DTTM=@WHITELIST_VALID_FROM_DTTM and row_no=@MIN_ROW_NO;
		if @@rowcount = 0
		BEGIN
			SET @MATCH_ENTITY_NATIONALITY = '';
		end

		select @MATCH_ENTITY_RESIDENCY = UDF_VALUE from casemgmt.case_udf_char_value where case_rk=@WHITELIST_CASE_RK and UDF_TABLE_NM='X_ENTITY_LIST' AND udf_nm='CITIZENSHIP_COUNTRY_NAME'  AND VALID_FROM_DTTM=@WHITELIST_VALID_FROM_DTTM and row_no=@MIN_ROW_NO;
		if @@rowcount = 0
		BEGIN
			SET @MATCH_ENTITY_RESIDENCY = '';
		end

		insert into DG_WL_LOGS.dbo.WHITE_LIST_MATCHES_QNB(WHITE_LIST_UID,MATCH_ENTITY_NAME,MATCH_ENTITY_NATIONALITY ,MATCH_ENTITY_RESIDENCY) 
			values(@WHITELIST_UID,@MATCH_ENTITY_NAME,@MATCH_ENTITY_NATIONALITY,@MATCH_ENTITY_RESIDENCY);

		SET @MIN_ROW_NO = @MIN_ROW_NO + 1 ;
	END

	insert into casemgmt.STPLog (STPName,CASERK,CreateDate) 
		values ('insertIntoWhiteList' , @WHITELIST_CASE_RK, getDate());
		
	SET @ISINSERTED = 1;

	END
END