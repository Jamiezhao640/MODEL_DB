if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_table_select') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_table_select
GO

create   proc sp_api_table_select
@schema_name varchar(64)
,@view_name varchar(64)
,@data_json varchar(max)
as

declare @stt varchar(max), @filter_json varchar(max), @where_clause varchar(max)


print 'sp_api_table_select: ' + @data_json

BEGIN TRY
	select @filter_json = [value] from OPENJSON(@data_json) where [key] = 'filter'
	set @where_clause = dbo.fn_convert_json_to_where_clause(@filter_json)
	select @stt = 'select * from ' + @schema_name + '.' + @view_name + case when @where_clause !='' then ' where ' + @where_clause else @where_clause end 

	print @stt
	exec (@stt)
END TRY

BEGIN CATCH
	throw
END CATCH;

GO

