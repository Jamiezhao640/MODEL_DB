/******************************************************

exec sp_paginate_view 
@view_name = 'vw_pg_estimate'
, @page_size = 20
, @page_number = 1

***************************************************************/


if exists (select * from dbo.sysobjects where id = object_id(N'sp_paginate_view') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_paginate_view
GO

create   proc sp_paginate_view
@schema_name sysname = 'dbo'  -- by default, the schema is dbo
, @view_name varchar(128) 
, @filter varchar(max) = null  -- by default, there is no where clause
, @search_string varchar(64) = null  -- by default, there is no string to search
, @order_by varchar(512) = '1'  -- by default, the results are sorted by the first column
, @page_number int = 1 -- page number starting from 1, it is the default value
, @page_size int = 5 --default page size is 12

as

declare @stt nvarchar(max), @sql_filter nvarchar(max), @search_condition nvarchar(max) = ''

-- generate search condition
if @search_string is not null
begin
	SELECT @search_condition = @search_condition + '[' + COLUMN_NAME + '] LIKE ''%' + @search_string + '%'' OR '
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_SCHEMA = @schema_name
		AND TABLE_NAME = @view_name 
		AND DATA_TYPE IN ('char','nchar','ntext','nvarchar','text','varchar')
	SET @search_condition = left(@search_condition,len(@search_condition)-3)
end

-- generate Where clause in a SELECT statement
if @filter is null and @search_string is null
	set @sql_filter = ''
else if @filter is null and @search_string is not null
	set @sql_filter = ' where ' + @search_condition
else if @filter is not null and @search_string is null
	set @sql_filter = ' where ' + dbo.fn_convert_json_to_where_clause(@filter)
else if @filter is not null and @search_string is not null
	set @sql_filter = ' where ' + '( ' + dbo.fn_convert_json_to_where_clause(@filter) + ' ) and ( ' + @search_condition + ' )'


begin try
	-- Paginated Records
	if @view_name = 'vw_equipment'
	begin
		set @stt = 'select * from vw_equipment where id in ( select id from vw_equipment ' + @sql_filter + ' )' 
	end
	else
	begin
		set @stt = 'select * from [' + @schema_name + '].[' + @view_name + '] ' + @sql_filter
	end
	set @stt = @stt + ' order by ' + @order_by  + ' offset ' + convert (varchar(20), (@page_number-1)*@page_size ) + ' rows fetch next ' + convert(varchar(20), @page_size) + ' row only'

	print @stt
	exec (@stt)

	-- Total Record Count
	set @stt = 'select count(*) as total_size from [' + @schema_name + '].[' + @view_name + '] ' + @sql_filter
	-- print @stt
	exec sp_executesql @stt
end try
BEGIN CATCH  
    throw  
END CATCH;  

GO



