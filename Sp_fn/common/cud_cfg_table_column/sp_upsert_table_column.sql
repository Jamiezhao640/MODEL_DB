/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_upsert_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_upsert_table_column
GO

CREATE PROC sp_upsert_table_column
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

declare @id int
select @id = id from cfg.page_table_column 
			where page_id = @page_id and (([user_id] is null and @user_id is null) or [user_id] = @user_id) and [index] = @index 
if @id is null
	exec sp_create_table_column
				@page_id = @page_id
				, @user_id = @user_id
				, @index = @index
				, @control_type_id = @control_type_id
				, @name = @name
				, @label = @label
				, @field = @field
				, @align = @align
				, @is_lockable = @is_lockable
				, @is_visiable_on_create = @is_visiable_on_create
				, @is_visiable_on_update = @is_visiable_on_update
				, @is_readonly = @is_readonly
				, @is_visiable_on_table = @is_visiable_on_table
				, @is_mandatory = @is_mandatory
				, @is_bulk = @is_bulk
				, @sortable = @sortable
else 
	exec sp_update_table_column
				@id = @id
				, @page_id = @page_id
				, @user_id = @user_id
				, @index = @index
				, @control_type_id = @control_type_id
				, @name = @name
				, @label = @label
				, @field = @field
				, @align = @align
				, @is_lockable = @is_lockable
				, @is_visiable_on_create = @is_visiable_on_create
				, @is_visiable_on_update = @is_visiable_on_update
				, @is_readonly = @is_readonly
				, @is_visiable_on_table = @is_visiable_on_table
				, @is_mandatory = @is_mandatory
				, @is_bulk = @is_bulk
				, @sortable = @sortable	


go


