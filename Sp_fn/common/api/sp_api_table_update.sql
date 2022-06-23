if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_table_update') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_table_update
GO

create   proc sp_api_table_update
@schema_name varchar(64)
,@view_name varchar(64)
,@data_json varchar(max)
as

declare @stt nvarchar(max)

declare @filter_json varchar(max), @where_clause varchar(max)



-- print 'entry sp_api_table_update'
BEGIN TRY
	select @filter_json = [value] from OPENJSON(@data_json) where [key] = 'filter'


	select @stt = 'update ' + @schema_name + '.' + @view_name + ' set '
			+ STRING_AGG ( case when [type] = 0 then [key] + ' = ' + ' NULL' 
								when [type] = 1 then [key] + ' = ' + ' ''' + [value] + '''' 
								when [type] = 2 then [key] + ' = ' + ' ' + [value] 
												else [key] + ' = ' + '' end , ',')
	from openjson(@data_json)
	where exists ( select * from sys.tables t 
								join sys.all_columns c on t.object_id=c.object_id 
								join sys.schemas s on s.schema_id = t.schema_id
					where t.name= @view_name 
							and s.name = @schema_name
							and c.name = [key] collate SQL_Latin1_General_CP1_CI_AS
				)
			and [key]!='id'    

	set @where_clause = dbo.fn_convert_json_to_where_clause(@filter_json)
	select @stt = @stt + case when @where_clause !='' then ' where ' + @where_clause else @where_clause end 

	print @stt
	exec (@stt)

END TRY

BEGIN CATCH
	throw
END CATCH;

GO
