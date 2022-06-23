
if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_parse_resource') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_parse_resource
GO

create   proc sp_api_parse_resource
@api_json varchar(max)
as

declare @resource varchar(64), @action varchar(64), @object_type char(4), @schema_name varchar(64), @view_name varchar(64), @sp_name varchar(64), @data_json varchar(max)
declare @by_whom_id int, @err_msg varchar(128)

BEGIN TRY
	insert into tbl_api_log (api_json) values (@api_json)
	IF ISJSON(@api_json) != 1 throw 60001
			,'Incorrected JSON format for ID list'
			,1
	If not exists (select * from OPENJSON(@api_json) where [key] = 'by_whom_id')
		throw 600200, 'by_whom_id is missing', 1

	select @by_whom_id =  convert(int,[value] )
	from OPENJSON(@api_json)
	where [key] = 'by_whom_id'
	IF not exists (select * from usr.tbl_user where id=@by_whom_id) 
	begin 
		set @err_msg = 'The by_whom_id, ' + convert(varchar(20), @by_whom_id) +  ', does not exist';
		throw 600100
			,@err_msg
			,1
	end 

	exec sp_set_context_info_with_id @current_user_id = @by_whom_id

	-- from @api_json
	select @resource = [value] from openjson (@api_json) where [key] = 'resource'
	select @action = [value] from openjson (@api_json) where [key] = 'action'
	select @data_json = [value] from openjson (@api_json) where [key] = 'data'

	-- from tbl_resource_config
	select @object_type = object_type,  @schema_name = [schema_name], @view_name = view_name, @sp_name = sp_name
	from cfg.resource_config
	where [resource] = @resource
		and [action] = @action

print '@object_type = ' + @object_type
print '@action = ' + @action
print '@view_name = ' + @view_name
print '@sp_name = ' + @sp_name

	if @object_type = 'vw'
	begin
		if @action = 'create'
			exec sp_api_table_insert @schema_name = @schema_name, @view_name = @view_name, @data_json = @data_json
		else if @action = 'update'
			exec sp_api_table_update @schema_name = @schema_name, @view_name = @view_name, @data_json = @data_json
		else if @action = 'delete'
			exec sp_api_table_delete @schema_name = @schema_name, @view_name = @view_name, @data_json = @data_json
		else if @action = 'get'
			exec sp_api_table_select @schema_name = @schema_name, @view_name = @view_name, @data_json = @data_json
	end
	else
		exec sp_api_stored_procedure @sp_name = @sp_name, @data_json = @data_json
END TRY

BEGIN CATCH
	throw
END CATCH;





GO

