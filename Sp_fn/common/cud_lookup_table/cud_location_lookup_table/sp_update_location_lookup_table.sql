
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_location_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_location_lookup_table
GO

CREATE PROC sp_update_location_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @id int
, @name varchar(128) = null
, @site_id int = null
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	if (@schema_name != 'lu' or @table_name not in ('location_component', 'location_sub_component','location_sub_area','location_cluster'))
		throw 16009, '@table_name is not a location list', 1

	if @name is not null
	begin
		set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set name = ''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''' where id = ' + convert(varchar(10), @id)
		--print @stt
		exec (@stt)
	end	
	if @site_id is not null
	begin
		set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set site_id = ' + convert(varchar(10),@site_id) + ' where id = ' + convert(varchar(10), @id)
		--print @stt
		exec (@stt)
	end
end try

BEGIN CATCH  
	throw
END CATCH  

go

