/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_upsert_permission')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_upsert_permission
GO

CREATE PROC sp_upsert_permission
@project_id_list varchar(max)
, @user_id_list varchar(max)
, @role_id_list varchar(max) 
AS

SET nocount ON 
declare @user_id int

begin transaction
begin try

	IF ISJSON(@project_id_list) != 1 
		throw 60001 ,'Incorrected JSON format for @project_id_list', 1;

	IF ISJSON(@user_id_list) != 1 
		throw 60001 ,'Incorrected JSON format for @user_id_list', 1;

	IF ISJSON(@role_id_list) != 1 
		throw 60001 ,'Incorrected JSON format for @role_id_list', 1;

	delete from usr.tbl_permission
		where user_id in (select id from openjson(@user_id_list)  WITH (id INT '$'))
			and project_id in (select id from openjson(@project_id_list)  WITH (id INT '$'))

	if @role_id_list is not null
		insert into usr.tbl_permission(user_id, project_id, role_id)
		select user_id, project_id, role_id
		from openjson(@user_id_list)  WITH (user_id INT '$')
			, openjson(@project_id_list)  WITH (project_id INT '$')
			, openjson(@role_id_list)  WITH (role_id INT '$')

	update usr.tbl_user
	set default_project_id = (select top 1 project_id from openjson(@project_id_list)  WITH (project_id INT '$'))
	where id in (select user_id from openjson(@user_id_list)  WITH (user_id INT '$'))

end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go
