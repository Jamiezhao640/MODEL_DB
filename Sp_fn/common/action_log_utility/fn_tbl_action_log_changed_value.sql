IF EXISTS ( SELECT  * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_tbl_action_log_changed_value') 
				) 
BEGIN 
	DROP FUNCTION dbo.fn_tbl_action_log_changed_value 
END 
GO

CREATE FUNCTION dbo.fn_tbl_action_log_changed_value (@id int) 
RETURNS @key_value table 
	(column_name varchar(128), old_value varchar(512), new_value varchar(512)) 
as
begin
	declare @json nvarchar(max), @operation varchar(16)
	select @json = json_content , @operation = operation
	from tbl_action_log where id = @id;
	if @operation = 'update'
		insert into @key_value (column_name, old_value, new_value)
		SELECT case when v1.[key] is null then v2.[key] else v1.[key] end as [field_name]
				, v1.[value] as old_value
				, v2.[value] as new_value
		FROM OPENJSON(@json,N'$.log[0]') v1
			full join OPENJSON(@json,N'$.log[1]') v2 on v1.[key] = v2.[key] 
		where (v1.[value]!=v2.[value] 
				or v1.[value] is null 
				or v2.[value] is null
				)
			and 
			(case when v1.[key] is null then v2.[key] else v1.[key] end) not in ('operation', 'on_table')
	else if @operation = 'insert'
 		insert into @key_value (column_name, old_value, new_value)
		SELECT [key], null, [value] 
		FROM OPENJSON(@json,N'$.log[0]')
		where [key]  not in ('operation', 'on_table')
	else  
 		insert into @key_value (column_name, old_value, new_value)
		SELECT [key], [value] , null
		FROM OPENJSON(@json,N'$.log[0]')
		where [key]  not in ('operation', 'on_table')
	return;
end
go
