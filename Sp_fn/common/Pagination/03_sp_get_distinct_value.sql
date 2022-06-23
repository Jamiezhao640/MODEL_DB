
/******************************************************



***************************************************************/


if exists (select * from dbo.sysobjects where id = object_id(N'sp_get_distinct_value') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_get_distinct_value
GO

create   proc sp_get_distinct_value
@view_name varchar(128) 
, @column_name varchar(512)
, @filter_json varchar(max) = null

as

declare @stt nvarchar(max), @where_clause varchar(max)

set @where_clause = dbo.fn_convert_json_to_where_clause(@filter_json)

set @stt = 'select distinct ' + @column_name + ' from ' +  @view_name + case when @where_clause !='' then ' where ' + @where_clause else @where_clause end
    + ' order by ' + @column_name

begin try
    print @stt
    exec (@stt)
end try
BEGIN CATCH  
    throw
END CATCH;  

go
GO





