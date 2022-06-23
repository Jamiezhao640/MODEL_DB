
/***************************************************** A Query:
requirements: 
	1) the specified view must have ID and name column
	2) @filter is the condition, can be any column valid in the specified view
Example:



********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_id_name_list')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_id_name_list
GO

CREATE PROC sp_get_id_name_list
@table_name varchar(64)
, @filter varchar(max) = null
AS

SET nocount ON 
declare @stt varchar(max), @schema_name varchar(64)


begin try
	if ( select count(*) from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @table_name) >1
		throw 100665, 'duplicated view name', 1;

	select @schema_name = TABLE_SCHEMA from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @table_name
 
	set @stt = 'select distinct id, name from [' + @schema_name + '].[' + @table_name + '] ' 

	if @filter is not null
		set @stt = @stt + ' where ' + dbo.fn_convert_json_to_where_clause(@filter)

	set @stt = @stt + ' order by name '

 
	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go

