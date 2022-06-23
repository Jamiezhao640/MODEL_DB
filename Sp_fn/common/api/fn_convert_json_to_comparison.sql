/*********************************************

declare @comarison_json varchar(max)
set @comarison_json = '{"name":"user_principal_name","value":"support@navidata.ca", "operator":"like"}'

select dbo.fn_convert_json_to_comparison(@comarison_json)

*************************************************/


IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_convert_json_to_comparison')) 
BEGIN 
   DROP FUNCTION dbo.fn_convert_json_to_comparison 
END 
GO
 
CREATE FUNCTION dbo.fn_convert_json_to_comparison(@comparison_json varchar(max))  
RETURNS varchar(max) 

as
begin
	declare @value_type int, @name varchar(64), @value varchar(max), @operator varchar(8), @stt varchar(max)

	select @value_type = [type] from openjson (@comparison_json) where [key] = 'value'
	select @name = [value] from openjson (@comparison_json) where [key] = 'name'
	select @value = [value] from openjson (@comparison_json) where [key] = 'value'
	select @operator = [value] from openjson (@comparison_json) where [key] = 'operator'

	if @value_type = 0
		set @stt = @name + ' IS NULL'
	else if @value_type = 1   -- string
	begin
		if @operator = 'like'
			set @stt = @name  + ' like ''%' + dbo.fn_duplicate_single_quote_in_string (@value) + '%'''
		else 
			set @stt = @name  + ' ' + isnull(@operator, '=') + ' ''' + dbo.fn_duplicate_single_quote_in_string (@value) + ''''
	end
	else if @value_type = 2   -- number
		set @stt = @name + ' ' +  isnull( @operator, '=') + ' ' +  @value
	else if  @value_type = 3   -- boolean
	begin
		set @stt = @name + ' '  + isnull(@operator, '=') + ' ' + case when @value='true' then '1' else '0' end
	end
	else if  @value_type = 4   -- list
	begin
		set @value = replace (@value, '[','(')
		set @value = replace (@value, ']',')')
		set @value = replace (@value, '"','''') 
		set @stt = @name + ' in '  + @value
	end

	return @stt
end

GO

