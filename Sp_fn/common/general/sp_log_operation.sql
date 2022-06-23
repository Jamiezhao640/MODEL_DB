if exists (select * from dbo.sysobjects where id = object_id(N'sp_log_operation') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_log_operation
GO

create   proc [dbo].sp_log_operation
@table_name varchar(64)
as
	BEGIN
	SET NOCOUNT ON;
	
	declare @operation varchar(8), @by_whom_id int , @id int
	set @id = 0
	-- set @by_whom = convert(varchar(64), CONTEXT_INFO())
	-- set @by_whom = substring (@by_whom, 1, CHARINDEX(char(0),@by_whom)-1)
	set @by_whom_id =  cast (substring(CONTEXT_INFO(),1,4) as int)
	
	while 1 =1
	begin
		select @id = min(id) from #temp where id > @id
		if @id is null
			break
		
		if not exists (select * from #temp where id=@id and operation = 'deleted') 
			set @operation = 'Insert'
		else if not exists (select * from #temp where  id=@id and operation = 'inserted')
			set @operation = 'Delete'
		else
			set @operation = 'Update'

		-- select @by_whom, @table_name, @operation, (select * from  #temp  where id=@id order by operation for json path, root ('log')) as json_content
		insert into tbl_action_log (by_whom_id, on_table, operation, record_id)
		values (@by_whom_id, @table_name, @operation, @id)

		update tbl_action_log
		set json_content = ( select * from  #temp  where id=@id order by operation for json path, root ('log') )
		where id = @@IDENTITY
		
	end
	
END

GO

