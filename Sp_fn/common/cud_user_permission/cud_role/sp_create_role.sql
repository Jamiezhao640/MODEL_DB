/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_role')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_role
GO

CREATE PROC sp_create_role
@name varchar(128)
AS

SET nocount ON 
declare @role_id int

begin transaction
begin try
	insert into usr.tbl_role (
			name
			)
		values (
			@name
			)
		select max(id) as role_id from usr.tbl_role
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go
