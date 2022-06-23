if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_stored_procedure') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_stored_procedure
GO

create   proc sp_api_stored_procedure
@sp_name varchar(64)
, @data_json varchar(max)
as

declare @parameter_name varchar(128), @parameter_value varchar(max), @parameter_type int
declare @stt varchar(max)

BEGIN TRY
	set @stt = @sp_name

	declare db_cursor cursor for select [key], [value],[type] from openjson(@data_json)
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @parameter_name, @parameter_value, @parameter_type  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
-- print @stt
		if @parameter_type = 0
			set @stt = @stt + ' @' + @parameter_name + ' = NULL, '
		else if @parameter_type in ( 1,4,5)
				set @stt = @stt + ' @' + @parameter_name + ' = ''' + dbo.fn_duplicate_single_quote_in_string(@parameter_value) + ''' ,'
		else if @parameter_type = 2
			set @stt = @stt + ' @' + @parameter_name + ' = ' + @parameter_value + ','
		else if @parameter_type = 3
			set @stt = @stt + ' @' + @parameter_name + ' = ' + case when @parameter_value ='true' then '1' else '0' end  + ','
		else
			set @stt = @stt + ' unexpected parameter type '

		FETCH NEXT FROM db_cursor INTO  @parameter_name, @parameter_value, @parameter_type  
	END 
	set @stt = substring (@stt,1,len(@stt)-1) 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 

	print @stt
	exec (@stt)

END TRY

BEGIN CATCH
	throw
END CATCH;

GO

