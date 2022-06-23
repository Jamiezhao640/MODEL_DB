
declare myCur cursor for 
select s.name [schema_name], t.name [table_name] 
	from [sys].[tables] t join sys.schemas s on t.schema_id=s.schema_id 
	where s.name in ( 'attm','dbo')
		and not exists (select * from internal.trigger_excluded where schema_name = s.name and table_name = t.name )
	order by s.name, t.name


declare @schema_name varchar(64), @tablename  varchar(64), @stt nvarchar(max)
open myCur
Fetch next from myCur into @schema_name, @tablename

while @@fetch_status = 0
begin
	set @stt = 'drop trigger if exists ' + @schema_name + '.tri_' + @tablename
	-- print @stt
	exec(@stt)

	set @stt = ' 
create TRIGGER tri_'   + @tablename +
' 
ON ' + @schema_name + '.' + @tablename +
case when @tablename='tbl_equipment_status_tracking' then
		'
AFTER delete
		'
	else
		'
AFTER insert , update, delete
		'
end
+
'
AS 
BEGIN
	SET NOCOUNT ON;
	declare @table_name varchar(128)
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N''tempdb.[dbo].#temp'') and xtype=''U'')
		drop table #temp

	select @table_name =  SCHEMA_NAME(schema_id) + ''.'' + OBJECT_NAME(parent_object_id)
         FROM sys.objects 
         WHERE sys.objects.name = OBJECT_NAME(@@PROCID)
            AND SCHEMA_NAME(sys.objects.schema_id) = OBJECT_SCHEMA_NAME(@@PROCID)

	select * into #temp from ( select ''deleted'' as operation , @table_name as on_table, * from deleted  
								union 
							   select ''inserted'' as operation, @table_name as on_table, * from inserted 
							) v

	exec sp_log_operation @table_name
	
	if exists (select * from inserted)
		update '   + @schema_name + '.' + @tablename + '  
		set updated_on = [dbo].[fn_convert_utc_to_local_time](getdate())
		where id in (select id from inserted)


END


'
	-- print(@stt)
	exec( @stt)
	
	Fetch next from myCur into  @schema_name, @tablename
end
close myCur
deallocate myCur

GO

