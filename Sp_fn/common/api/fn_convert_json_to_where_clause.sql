
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_convert_json_to_where_clause')) 
BEGIN 
   DROP FUNCTION dbo.fn_convert_json_to_where_clause 
END 
GO
 
CREATE FUNCTION dbo.fn_convert_json_to_where_clause(@filter_json varchar(max))  
RETURNS varchar(max) 

as
begin

	declare @key int = 0, @comparison_json varchar(max), @where_clause varchar(max)

	set @where_clause = ''
	while exists (select * from openjson (@filter_json) where [key] = @key )
	begin
		select @comparison_json = [value] from openjson (@filter_json) where [key] = @key
		if @key = 0
			set @where_clause = dbo.fn_convert_json_to_comparison(@comparison_json)
		else
			set @where_clause = @where_clause + ' and ' + dbo.fn_convert_json_to_comparison(@comparison_json)
		set @key = @key + 1
	end
	return @where_clause

end

GO

