/******************************************************



***************************************************************/


if exists (select * from dbo.sysobjects where id = object_id(N'sp_distinct_value') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_distinct_value
GO

create   proc sp_distinct_value
@view_name varchar(128) 
, @column_name varchar(512)
, @where_clause varchar(max) = null

as

declare @stt nvarchar(max)
declare @blank_filter nvarchar(512)
declare @null_condition nvarchar(512)


if exists ( SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = @view_name and COLUMN_NAME = @column_name
		AND DATA_TYPE IN ('char','nchar','ntext','nvarchar','text','varchar'))
begin
	set @blank_filter = @column_name + ' is not null and ' + @column_name + ' != '''''
    set @null_condition = @column_name + ' is null or ' + @column_name + ' = '''''
end
else
begin
	set @blank_filter = @column_name + ' is not null '
	set @null_condition = @column_name + ' is null '
end 

set @stt = 'select ' + @column_name + ' from 
( '
	+ 'select distinct ' + @column_name + ' from ' +  @view_name 
    + case when @where_clause is not null 
            then  ' where (' + @where_clause + ') and (' + @blank_filter + ')'
            else  ' where ' + @blank_filter
      end
	+ ' union select null as ' + @column_name + ' from '  +  @view_name  + 
                + case when @where_clause is not null 
                    then  ' where (' + @where_clause + ') and (' + @null_condition + ')'
            else  ' where ' + @null_condition
      end  + 
    ') v '
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



