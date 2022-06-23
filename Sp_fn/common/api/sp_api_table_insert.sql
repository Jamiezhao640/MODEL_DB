if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_table_insert') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_table_insert
GO

create   proc sp_api_table_insert
@schema_name varchar(64)
,@view_name varchar(64)
,@data_json varchar(max)
as


declare @column_name varchar(128), @column_value varchar(128), @column_type int
declare @stt varchar(max)

declare @resource_value varchar(128)

begin try

	select @stt = 'insert into ' + @schema_name + '.' + @view_name
	select @stt = @stt + '( ' + STRING_AGG([key],',') + ' ) values ('
	from openjson(@data_json)
	where exists ( select * from sys.tables t join sys.all_columns c on t.object_id=c.object_id 
															join sys.schemas s on s.schema_id = t.schema_id
										where t.name= @view_name and s.name = @schema_name
												and c.name = [key] collate SQL_Latin1_General_CP1_CI_AS
											)
		and [key]!='id'   -- Column name is valid and is not ID

	select @stt = @stt + STRING_AGG ( case when [type] = 0 then ' NULL' when [type] = 1 then ' ''' + [value] + '''' when [type] = 2 then ' ' + [value] else '' end , ',') + ' )'
	from openjson(@data_json)
	where exists ( select * from sys.tables t 
								join sys.all_columns c on t.object_id=c.object_id 
								join sys.schemas s on s.schema_id = t.schema_id
					where t.name= @view_name 
							and s.name = @schema_name
							and c.name = [key] collate SQL_Latin1_General_CP1_CI_AS
				)
			and [key]!='id'    
    print @stt
	exec (@stt)

END TRY

BEGIN CATCH
	throw
END CATCH;

GO

