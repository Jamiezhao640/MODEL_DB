
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_duplicate_single_quote_in_string')) 
BEGIN 
   DROP FUNCTION dbo.fn_duplicate_single_quote_in_string 
END 
GO
 
CREATE FUNCTION dbo.fn_duplicate_single_quote_in_string(@string varchar(max))  
RETURNS varchar(max) 
AS 
begin
	declare @duplicating_single_quote varchar(max)
	set @duplicating_single_quote =  (  SELECT STRING_AGG (value, '''''') FROM STRING_SPLIT(@string, '''')  ) 
	return @duplicating_single_quote
end
   
GO