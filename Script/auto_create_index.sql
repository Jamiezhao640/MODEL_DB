
declare @table_name varchar(64), @stt varchar(max)
set @table_name = ''

while 1 = 1
begin
	select @table_name = min(t.name) 
	from sys.tables t join sys.schemas s on t.schema_id = s.schema_id
	where s.name = 'lu' and t.name > @table_name

	if (@table_name is null)
		break

	set @stt = 'create unique index IX_UNI_' + @table_name + ' on lu.' + @table_name + '([column_value]); GO'
	print @stt
end


