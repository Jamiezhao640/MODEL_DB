/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_user')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_user
GO

CREATE PROC sp_create_user
@user_principal_name varchar(128)
, @surname varchar(64)  = null
, @given_name varchar(64) = null
, @default_project_id  int = null
, @nickname varchar(64) =null
, @avatar varchar(64) = null
, @is_active bit = null

AS

SET nocount ON 
declare @user_id int

begin transaction
begin try
		-- if the ad user doesn't exist, create it first
		if not exists (select * from usr.tbl_user where user_principal_name = @user_principal_name)  
			insert into usr.tbl_user (
				user_principal_name
				, surname
				, given_name
				, [default_project_id]
				, [nickname]
				, [avatar]
				, is_active
				)
			values (
				@user_principal_name
				, @surname
				, @given_name
				, @default_project_id
				, @nickname 
				, @avatar
				, @is_active
				)
		select @user_id = id from usr.tbl_user where user_principal_name=@user_principal_name


end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

select @user_id as [id], @user_principal_name as user_principal_name

go
