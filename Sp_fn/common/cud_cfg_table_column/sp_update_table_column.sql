/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_table_column
GO

CREATE PROC sp_update_table_column
@id int
, @page_id int = NULL
, @user_id int = NULL
, @index int = NULL
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

begin try
	update tbl_page_table_column
	set page_id = case when @page_id is null then page_id else @page_id end
		, user_id = case when @user_id is null then user_id else @user_id end
		, [index] = case when @index is null then [index] else @index end
		, control_type_id = case when @control_type_id is null then control_type_id else @control_type_id end
		, name = case when @name is null then name else @name end
		, label = case when @label is null then label else @label end
		, field = case when @field is null then field else @field end
		, align = case when @align is null then align else @align end
		, is_lockable = case when @is_lockable is null then is_lockable else @is_lockable end
		, is_visiable_on_create = case when @is_visiable_on_create is null then is_visiable_on_create else @is_visiable_on_create end
		, is_visiable_on_update = case when @is_visiable_on_update is null then is_visiable_on_update else @is_visiable_on_update end
		, is_readonly = case when @is_readonly is null then is_readonly else @is_readonly end
		, is_visiable_on_table = case when @is_visiable_on_table is null then is_visiable_on_table else @is_visiable_on_table end
		, is_mandatory = case when @is_mandatory is null then is_mandatory else @is_mandatory end
		, is_bulk = case when @is_bulk is null then is_bulk else @is_bulk end
		, sortable = case when @sortable is null then sortable else @sortable end
	where id = @id
end try

BEGIN CATCH  
	throw
END CATCH  

go

