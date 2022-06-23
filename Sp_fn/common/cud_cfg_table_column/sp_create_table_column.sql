/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_table_column
GO

CREATE PROC sp_create_table_column
@page_id int
, @user_id int = NULL
, @index int
, @control_type_id int = NULL
, @name varchar(64) = NULL
, @label varchar(64) = NULL
, @field varchar(64) = NULL
, @align varchar(32) = NULL
, @is_lockable bit = NULL
, @is_visiable_on_create bit = NULL
, @is_visiable_on_update bit = NULL
, @is_readonly bit = NULL
, @is_visiable_on_table bit = NULL
, @is_mandatory bit = NULL
, @is_bulk bit = NULL
, @sortable bit = NULL
AS

SET nocount ON 

begin transaction
begin try
	insert into cfg.[page_table_column] (
		page_id
		, [user_id]
		, [index]
		, control_type_id
		, [name]
		, [label]
		, field
		, align
		, is_lockable
		, is_visiable_on_create
		, is_visiable_on_update
		, is_readonly
		, is_visiable_on_table
		, is_mandatory
		, is_bulk
		, sortable
		)
	values (
		@page_id
		, @user_id
		, @index
		, @control_type_id
		, @name
		, @label
		, @field
		, @align
		, @is_lockable
		, @is_visiable_on_create
		, @is_visiable_on_update
		, @is_readonly
		, @is_visiable_on_table
		, @is_mandatory
		, @is_bulk
		, @sortable
		)
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  

	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go


