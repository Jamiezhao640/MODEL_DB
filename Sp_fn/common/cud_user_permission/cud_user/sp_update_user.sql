
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_user')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_user
GO

CREATE PROC sp_update_user
@id int
, @user_principal_name varchar(128) = null
, @surname varchar(64) = null
, @given_name varchar(64) = null
, @sam_account_name varchar(64) = null
, @is_email_sent bit = 0
, @default_project_id  int  = null
, @nickname varchar(64) = null
, @avatar varchar(64) = null
, @is_active bit = null
AS

SET nocount ON 

begin try

	update usr.tbl_user
	set  user_principal_name = case when @user_principal_name is null then user_principal_name else @user_principal_name end
		, surname = case when @surname is null then surname else @surname end
		, given_name = case when @given_name is null then given_name else @given_name end
		, sam_account_name = case when @sam_account_name is null then sam_account_name else @sam_account_name end
		, is_email_sent = case when @is_email_sent is null then is_email_sent else @is_email_sent end
		, default_project_id = case when @default_project_id is null then default_project_id else @default_project_id end
		, nickname = case when @nickname is null then nickname else @nickname end
		, avatar = case when @avatar is null then avatar else @avatar end
		, is_active = case when @is_active is null then is_active else @is_active end
	where id = @id

end try

BEGIN CATCH  
	throw
END CATCH  

select id , user_principal_name from usr.tbl_user where id = @id

go

