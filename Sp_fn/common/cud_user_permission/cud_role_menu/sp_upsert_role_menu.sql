/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_upsert_role_menu')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_upsert_role_menu
GO

CREATE PROC sp_upsert_role_menu
@role_id int 
, @menu_name_list varchar(max)
AS

SET nocount ON 
declare @user_id int

begin transaction
begin try

	IF ISJSON(@menu_name_list) != 1 
	begin
		throw 60001 ,'Incorrected JSON format for @permission_list', 1;
	end
	else 
	begin 
		delete from usr.tbl_role_menu where role_id = @role_id
		insert into usr.tbl_role_menu(role_id, menu_name)
		select @role_id, menu_name
		from openjson(@menu_name_list)  WITH (menu_name varchar(256) '$')
	end

end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go
