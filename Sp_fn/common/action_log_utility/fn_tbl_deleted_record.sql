IF EXISTS ( SELECT  * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_tbl_deleted_record') 
				) 
BEGIN 
	DROP FUNCTION dbo.fn_tbl_deleted_record 
END 
GO

CREATE FUNCTION dbo.fn_tbl_deleted_record (@id int) 
RETURNS @key_value table 
	(column_name varchar(128), column_value varchar(512)) 
as
begin
	declare @json nvarchar(max), @operation varchar(16)
	select @json = json_content , @operation = operation
	from tbl_action_log where id = @id;

	insert into @key_value (column_name, column_value)
		SELECT [key], [value]
		FROM OPENJSON(@json,N'$.log[0]')
		where [key]  not in ('operation', 'on_table')
	return;
end
go
