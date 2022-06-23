declare @stt varchar(max)
select @stt = STRING_AGG ('drop view ' + name, ';'+char(10)) from sys.views where schema_id = 1
print @stt
exec (@stt)

