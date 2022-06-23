
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_parse_sp_parameter')) 
BEGIN 
   DROP FUNCTION dbo.fn_parse_sp_parameter 
END 
GO
 
CREATE FUNCTION dbo.fn_parse_sp_parameter (@string varchar(max))  
RETURNS varchar(max) 
AS 
begin
	declare @parameter_name varchar(128), @parameter_value varchar(max), @parameter_type int
	declare @stt varchar(max)

	declare db_cursor cursor for select [key], [value],[type] from openjson(@string)
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @parameter_name, @parameter_value, @parameter_type  
	set @stt = ''

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
-- print @stt
		if @parameter_value is not null
		begin
			if @parameter_type = 2
				set @stt = @stt + ' @' + @parameter_name + ' = ' + @parameter_value + ','
			else 
				set @stt = @stt + ' @' + @parameter_name + ' = ''' + dbo.fn_duplicate_single_quote_in_string(@parameter_value) + ''' ,'
		end 
		FETCH NEXT FROM db_cursor INTO  @parameter_name, @parameter_value, @parameter_type  
	END 
	set @stt = substring (@stt,1,len(@stt)-1) 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 

	return @stt
end
   
GO