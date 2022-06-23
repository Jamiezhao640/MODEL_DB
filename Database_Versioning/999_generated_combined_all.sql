------------Merging Date and Time: 06/23/2022 09:01:23 --------------------




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\View\common\vw_lookup_table.sql --------------------
IF EXISTS (
		SELECT 1
		FROM sys.VIEWS
		WHERE Name = 'vw_lookup_table'
		)
	DROP VIEW vw_lookup_table
GO


create view vw_lookup_table
as
SELECT table_name, 
	case when exists(select * from INFORMATION_SCHEMA.COLUMNS 
						where table_schema = 'lu' 
							and 
							  COLUMN_NAME='project_id'
							and
							  TABLE_NAME=m.TABLE_NAME)
		then 'project'
		when exists(select * from INFORMATION_SCHEMA.COLUMNS 
						where table_schema = 'lu' 
							and 
							  COLUMN_NAME='site_id'
							and
							  TABLE_NAME=m.TABLE_NAME)
		 then 'location'
		 else 'general'
	end as [type]
FROM INFORMATION_SCHEMA.TABLES m
where table_schema = 'lu' and table_name not like 'vw_%'


GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\View\common\vw_permission_json.sql --------------------

IF EXISTS (
		SELECT 1
		FROM sys.VIEWS
		WHERE Name = 'vw_permission_json'
		)
	DROP VIEW vw_permission_json
GO

CREATE VIEW vw_permission_json
AS
select u.id, u.given_name, u.surname, u.user_principal_name, u.default_project_id,u.[nickname], u.[avatar], u.is_active, 
	(
		select p.id, p.name, 
			(
				select r.id, r.name as name,
					(
						select  menu_name as name
						from usr.tbl_role_menu rp
						where rp.role_id = r.id
						for JSON PATH
					)   as menu_json
				from vw_user_project_role_ln upr join usr.tbl_role r on upr.role_id = r.id
				where upr.project_id = p.id and upr.user_id = u.id
				for JSON PATH
			) as role_json
		from vw_user_project_ln up join tbl_project p on up.project_id = p.id
		where up.user_id = u.id
		FOR JSON PATH
	) as project_json
from vw_user u

GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\View\common\vw_role.sql --------------------
IF EXISTS (
		SELECT 1
		FROM sys.VIEWS
		WHERE Name = 'vw_role'
		)
	DROP VIEW vw_role
GO

CREATE VIEW vw_role
AS
select * from usr.tbl_role

GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\View\common\vw_role_menu.sql --------------------

 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_role_menu'
) DROP VIEW vw_role_menu
GO
	CREATE VIEW vw_role_menu AS

select r.id
	, r.name
	, isnull (('[' + (select string_agg( '"' +p.menu_name + '"',',') from usr.tbl_role_menu p where r.id=p.role_id ) + ']'),'[]') as menu_json
  from usr.tbl_role r 




GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\View\common\vw_user.sql --------------------

 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_user'
) DROP VIEW vw_user
GO
	CREATE VIEW vw_user AS

select u.*, user_principal_name as name
	 , convert(varchar, created_on, 23) as createdOn
     , convert(varchar, updated_on, 23) as updatedOn
	,case when is_active=1 then 'Yes' else 'No' end AS isActive
	,case when is_email_sent =1 then 'Yes' else 'No' end AS isEmailSent 


  from usr.tbl_user u 

where u.id>0

GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\View\common\vw_user_project_ln.sql --------------------

-- if a user is granted role_id=1 and project_id = -1, there this user is admin on all the projects
 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_user_project_ln'
) DROP VIEW vw_user_project_ln
GO
	CREATE VIEW vw_user_project_ln AS

SELECT distinct [user_id] ,[project_id] FROM vw_user_project_role_ln


GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\View\common\vw_user_project_role_ln.sql --------------------

-- if a user is granted role_id=1 and project_id = -1, there this user is admin on all the projects
 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_user_project_role_ln'
) DROP VIEW vw_user_project_role_ln
GO
	CREATE VIEW vw_user_project_role_ln AS

SELECT [user_id]
      ,[role_id]
      ,[updated_on]
      ,[project_id]
  FROM usr.[tbl_permission]
  where project_id > 0
union
select user_id,1 as role_id, getdate() as updated_on, tbl_project.id as project_id
from usr.tbl_permission, tbl_project
where usr.tbl_permission.project_id = -1 and tbl_project.id > 0


GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\action_log_utility\fn_tbl_action_log_changed_value.sql --------------------
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




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\action_log_utility\fn_tbl_deleted_record.sql --------------------
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




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\action_log_utility\fn_tbl_record_first_last_change.sql --------------------
IF EXISTS ( SELECT  * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_tbl_record_first_last_change') 
				) 
BEGIN 
	DROP FUNCTION dbo.fn_tbl_record_first_last_change 
END 
GO

CREATE FUNCTION dbo.fn_tbl_record_first_last_change (@table_name varchar(64),@id int) 
RETURNS @first_last_log table 
	(first_by_whom varchar(64), first_operation varchar(8), first_created_on datetime,
	 last_by_whom varchar(64), last_operation varchar(8), last_created_on datetime ) 
as
begin
	if (@table_name != 'tbl_equipment'
		or (select estimate_plan_id from tbl_equipment where id=@id) is null)
	begin
		insert into @first_last_log (first_by_whom, first_operation,first_created_on,
									last_by_whom, last_operation,last_created_on)
		select f.by_whom_id, f.operation, f.created_on, l.by_whom_id, l.operation, l.created_on
		from tbl_action_log f , tbl_action_log l
		where f.id = (select min(id) from tbl_action_log where on_table=@table_name and record_id=id)
			and l.id = (select max(id) from tbl_action_log where on_table=@table_name and record_id=id)
	end
	else
	begin
		insert into @first_last_log (first_by_whom, first_operation,first_created_on,
									last_by_whom, last_operation,last_created_on)
		select f.by_whom_id, f.operation, f.created_on, l.by_whom_id, l.operation, l.created_on
		from tbl_action_log f , tbl_action_log l
		where f.id = (select max(id) from tbl_action_log 
					  where on_table='#estimate-task'
						and record_id = 
							(select task_id 
							from tbl_estimate_plan ep 
								join tbl_equipment e on e.estimate_plan_id = ep.id
							where e.id=@id)
					 )
			and l.id = (select max(id) from tbl_action_log where on_table=@table_name and record_id=id)
	end
	return;
end
go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\action_log_utility\sp_restore_from_action_log.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_restore_from_action_log') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_restore_from_action_log
GO

create   proc sp_restore_from_action_log
@id int
as 


DECLARE @operation varchar(20), @json NVARCHAR(4000), @field_list varchar(4000), @value_list varchar(4000), @table_name varchar(256)
declare @stt nvarchar(MAX)
select @json = json_content
    , @operation = operation
    , @table_name = on_table 
from tbl_action_log where id = @id


begin try
    if @json is null
        throw 60100, 'the action log id is invalid', 1;
    
    if @operation != 'Delete'
        throw 60200, 'The to-be-restored action log is not a delete operation', 1;

    SELECT @field_list = string_agg([key] ,',')
		    , @value_list = string_agg (case when [type] = 1 then '''' + [value] + '''' 
										     when [type] = 2 then [value] 
										     when [type] = 3 then case when [value]='true' then '1' else '0' end
										     else null end ,',')
    FROM OPENJSON(@json	, N'$.log[0]') 
    where [key] not in ('operation','on_table','updated_on')

    set @stt = 'SET IDENTITY_INSERT ' + @table_name + ' ON; 
    ' +'insert into ' + @table_name + '(' + @field_list + ') values (' + @value_list + ') 
    ' + 'SET IDENTITY_INSERT ' + @table_name + ' OFF;'

    print @stt
    exec (@stt)

end try

BEGIN CATCH  
    throw
END CATCH;  


Go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\fn_convert_json_to_comparison.sql --------------------
/*********************************************

declare @comarison_json varchar(max)
set @comarison_json = '{"name":"user_principal_name","value":"support@navidata.ca", "operator":"like"}'

select dbo.fn_convert_json_to_comparison(@comarison_json)

*************************************************/


IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_convert_json_to_comparison')) 
BEGIN 
   DROP FUNCTION dbo.fn_convert_json_to_comparison 
END 
GO
 
CREATE FUNCTION dbo.fn_convert_json_to_comparison(@comparison_json varchar(max))  
RETURNS varchar(max) 

as
begin
	declare @value_type int, @name varchar(64), @value varchar(max), @operator varchar(8), @stt varchar(max)

	select @value_type = [type] from openjson (@comparison_json) where [key] = 'value'
	select @name = [value] from openjson (@comparison_json) where [key] = 'name'
	select @value = [value] from openjson (@comparison_json) where [key] = 'value'
	select @operator = [value] from openjson (@comparison_json) where [key] = 'operator'

	if @value_type = 0
		set @stt = @name + ' IS NULL'
	else if @value_type = 1   -- string
	begin
		if @operator = 'like'
			set @stt = @name  + ' like ''%' + dbo.fn_duplicate_single_quote_in_string (@value) + '%'''
		else 
			set @stt = @name  + ' ' + isnull(@operator, '=') + ' ''' + dbo.fn_duplicate_single_quote_in_string (@value) + ''''
	end
	else if @value_type = 2   -- number
		set @stt = @name + ' ' +  isnull( @operator, '=') + ' ' +  @value
	else if  @value_type = 3   -- boolean
	begin
		set @stt = @name + ' '  + isnull(@operator, '=') + ' ' + case when @value='true' then '1' else '0' end
	end
	else if  @value_type = 4   -- list
	begin
		set @value = replace (@value, '[','(')
		set @value = replace (@value, ']',')')
		set @value = replace (@value, '"','''') 
		set @stt = @name + ' in '  + @value
	end

	return @stt
end

GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\fn_convert_json_to_where_clause.sql --------------------

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





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\fn_duplicate_single_quote_in_string.sql --------------------

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




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\sp_api_parse_resource.sql --------------------

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





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\sp_api_stored_procedure.sql --------------------
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





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\sp_api_table_delete.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_table_delete') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_table_delete
GO

create   proc sp_api_table_delete
@schema_name varchar(64)
,@view_name varchar(64)
,@data_json varchar(max)
as



declare @stt varchar(max), @filter_json varchar(max), @where_clause varchar(max)

BEGIN TRY
	select @filter_json = [value] from OPENJSON(@data_json) where [key] = 'filter'

	set @where_clause = dbo.fn_convert_json_to_where_clause(@filter_json)
	select @stt = 'delete from ' + @schema_name + '.' + @view_name + case when @where_clause !='' then ' where ' + @where_clause else @where_clause end 

	print @stt
	exec (@stt)
END TRY

BEGIN CATCH
	throw
END CATCH;


GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\sp_api_table_insert.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_table_insert') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_table_insert
GO

create   proc sp_api_table_insert
@schema_name varchar(64)
,@view_name varchar(64)
,@data_json varchar(max)
as


declare @column_name varchar(128), @column_value varchar(128), @column_type int
declare @stt varchar(max)

declare @resource_value varchar(128)

begin try

	select @stt = 'insert into ' + @schema_name + '.' + @view_name
	select @stt = @stt + '( ' + STRING_AGG([key],',') + ' ) values ('
	from openjson(@data_json)
	where exists ( select * from sys.tables t join sys.all_columns c on t.object_id=c.object_id 
															join sys.schemas s on s.schema_id = t.schema_id
										where t.name= @view_name and s.name = @schema_name
												and c.name = [key] collate SQL_Latin1_General_CP1_CI_AS
											)
		and [key]!='id'   -- Column name is valid and is not ID

	select @stt = @stt + STRING_AGG ( case when [type] = 0 then ' NULL' when [type] = 1 then ' ''' + [value] + '''' when [type] = 2 then ' ' + [value] else '' end , ',') + ' )'
	from openjson(@data_json)
	where exists ( select * from sys.tables t 
								join sys.all_columns c on t.object_id=c.object_id 
								join sys.schemas s on s.schema_id = t.schema_id
					where t.name= @view_name 
							and s.name = @schema_name
							and c.name = [key] collate SQL_Latin1_General_CP1_CI_AS
				)
			and [key]!='id'    
    print @stt
	exec (@stt)

END TRY

BEGIN CATCH
	throw
END CATCH;

GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\sp_api_table_select.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_table_select') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_table_select
GO

create   proc sp_api_table_select
@schema_name varchar(64)
,@view_name varchar(64)
,@data_json varchar(max)
as

declare @stt varchar(max), @filter_json varchar(max), @where_clause varchar(max)


print 'sp_api_table_select: ' + @data_json

BEGIN TRY
	select @filter_json = [value] from OPENJSON(@data_json) where [key] = 'filter'
	set @where_clause = dbo.fn_convert_json_to_where_clause(@filter_json)
	select @stt = 'select * from ' + @schema_name + '.' + @view_name + case when @where_clause !='' then ' where ' + @where_clause else @where_clause end 

	print @stt
	exec (@stt)
END TRY

BEGIN CATCH
	throw
END CATCH;

GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\api\sp_api_table_update.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_table_update') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_table_update
GO

create   proc sp_api_table_update
@schema_name varchar(64)
,@view_name varchar(64)
,@data_json varchar(max)
as

declare @stt nvarchar(max)

declare @filter_json varchar(max), @where_clause varchar(max)



-- print 'entry sp_api_table_update'
BEGIN TRY
	select @filter_json = [value] from OPENJSON(@data_json) where [key] = 'filter'


	select @stt = 'update ' + @schema_name + '.' + @view_name + ' set '
			+ STRING_AGG ( case when [type] = 0 then [key] + ' = ' + ' NULL' 
								when [type] = 1 then [key] + ' = ' + ' ''' + [value] + '''' 
								when [type] = 2 then [key] + ' = ' + ' ' + [value] 
												else [key] + ' = ' + '' end , ',')
	from openjson(@data_json)
	where exists ( select * from sys.tables t 
								join sys.all_columns c on t.object_id=c.object_id 
								join sys.schemas s on s.schema_id = t.schema_id
					where t.name= @view_name 
							and s.name = @schema_name
							and c.name = [key] collate SQL_Latin1_General_CP1_CI_AS
				)
			and [key]!='id'    

	set @where_clause = dbo.fn_convert_json_to_where_clause(@filter_json)
	select @stt = @stt + case when @where_clause !='' then ' where ' + @where_clause else @where_clause end 

	print @stt
	exec (@stt)

END TRY

BEGIN CATCH
	throw
END CATCH;

GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_cfg_resource_config\sp_create_default_resource_config.sql --------------------
/*******************************************************

Insert a PO

*************************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_default_resource_config')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_default_resource_config
GO

CREATE PROC sp_create_default_resource_config
@resource varchar(64)
AS
SET NOCOUNT ON

INSERT INTO [cfg].[resource_config]
           ([resource]
           ,[action]
           ,[object_type]
           ,[sp_name]
           ,[schema_name]
           ,[view_name])
     VALUES (@resource, 'create', 'sp', 'sp_create_'+@resource, 'dbo',null)
			, (@resource, 'update', 'sp', 'sp_update_'+@resource, 'dbo',null)
			, (@resource, 'delete', 'sp', 'sp_delete_'+@resource, 'dbo',null)
			, (@resource, 'get', 'vw', null, 'dbo','vw_'+@resource)
GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_cfg_table_column\sp_create_table_column.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_table_column
GO

CREATE PROC sp_create_table_column
@page_id int
, @user_id int = NULL
, @index int
, @control_type_id int = NULL
, @name varchar(64) = NULL
, @label varchar(64) = NULL
, @field varchar(64) = NULL
, @align varchar(32) = NULL
, @is_lockable bit = NULL
, @is_visiable_on_create bit = NULL
, @is_visiable_on_update bit = NULL
, @is_readonly bit = NULL
, @is_visiable_on_table bit = NULL
, @is_mandatory bit = NULL
, @is_bulk bit = NULL
, @sortable bit = NULL
AS

SET nocount ON 

begin transaction
begin try
	insert into cfg.[page_table_column] (
		page_id
		, [user_id]
		, [index]
		, control_type_id
		, [name]
		, [label]
		, field
		, align
		, is_lockable
		, is_visiable_on_create
		, is_visiable_on_update
		, is_readonly
		, is_visiable_on_table
		, is_mandatory
		, is_bulk
		, sortable
		)
	values (
		@page_id
		, @user_id
		, @index
		, @control_type_id
		, @name
		, @label
		, @field
		, @align
		, @is_lockable
		, @is_visiable_on_create
		, @is_visiable_on_update
		, @is_readonly
		, @is_visiable_on_table
		, @is_mandatory
		, @is_bulk
		, @sortable
		)
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  

	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go






---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_cfg_table_column\sp_delete_table_column.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_delete_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_delete_table_column
GO

CREATE PROC sp_delete_table_column
@id int
AS

SET nocount ON 

begin try
	delete from cfg.[page_table_column] where id = @id
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_cfg_table_column\sp_get_table_column.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_get_table_column') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_get_table_column
GO

create   proc sp_get_table_column
@page_name varchar(64) = null

as
	select page_name
        , [index]
      ,ptc.[name]
      ,[label]
	  ,[field]
      ,ct.[name] as control_type
      ,[is_lockable]
      ,[is_visiable_on_create]
      ,[is_visiable_on_update]
      ,[is_readonly]
      ,[is_visiable_on_table]
      ,[is_mandatory]
      ,[is_bulk] 
      , sortable
	  , align
	from cfg.page p join cfg.page_table_column ptc on p.id = ptc.page_id 
		join cfg.page_control_type ct on ct.id = ptc.control_type_id
	where page_name = @page_name or @page_name is null

GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_cfg_table_column\sp_update_table_column.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_table_column
GO

CREATE PROC sp_update_table_column
@id int
, @page_id int = NULL
, @user_id int = NULL
, @index int = NULL
, @control_type_id int = NULL
, @name varchar(64) = NULL
, @label varchar(64) = NULL
, @field varchar(64) = NULL
, @align varchar(32) = NULL
, @is_lockable bit = NULL
, @is_visiable_on_create bit = NULL
, @is_visiable_on_update bit = NULL
, @is_readonly bit = NULL
, @is_visiable_on_table bit = NULL
, @is_mandatory bit = NULL
, @is_bulk bit = NULL
, @sortable bit = NULL
AS

SET nocount ON 

begin try
	update tbl_page_table_column
	set page_id = case when @page_id is null then page_id else @page_id end
		, user_id = case when @user_id is null then user_id else @user_id end
		, [index] = case when @index is null then [index] else @index end
		, control_type_id = case when @control_type_id is null then control_type_id else @control_type_id end
		, name = case when @name is null then name else @name end
		, label = case when @label is null then label else @label end
		, field = case when @field is null then field else @field end
		, align = case when @align is null then align else @align end
		, is_lockable = case when @is_lockable is null then is_lockable else @is_lockable end
		, is_visiable_on_create = case when @is_visiable_on_create is null then is_visiable_on_create else @is_visiable_on_create end
		, is_visiable_on_update = case when @is_visiable_on_update is null then is_visiable_on_update else @is_visiable_on_update end
		, is_readonly = case when @is_readonly is null then is_readonly else @is_readonly end
		, is_visiable_on_table = case when @is_visiable_on_table is null then is_visiable_on_table else @is_visiable_on_table end
		, is_mandatory = case when @is_mandatory is null then is_mandatory else @is_mandatory end
		, is_bulk = case when @is_bulk is null then is_bulk else @is_bulk end
		, sortable = case when @sortable is null then sortable else @sortable end
	where id = @id
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_cfg_table_column\sp_upsert_table_column.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_upsert_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_upsert_table_column
GO

CREATE PROC sp_upsert_table_column
@page_id int
, @user_id int = NULL
, @index int
, @control_type_id int = NULL
, @name varchar(64) = NULL
, @label varchar(64) = NULL
, @field varchar(64) = NULL
, @align varchar(32) = NULL
, @is_lockable bit = NULL
, @is_visiable_on_create bit = NULL
, @is_visiable_on_update bit = NULL
, @is_readonly bit = NULL
, @is_visiable_on_table bit = NULL
, @is_mandatory bit = NULL
, @is_bulk bit = NULL
, @sortable bit = NULL
AS

SET nocount ON 

declare @id int
select @id = id from cfg.page_table_column 
			where page_id = @page_id and (([user_id] is null and @user_id is null) or [user_id] = @user_id) and [index] = @index 
if @id is null
	exec sp_create_table_column
				@page_id = @page_id
				, @user_id = @user_id
				, @index = @index
				, @control_type_id = @control_type_id
				, @name = @name
				, @label = @label
				, @field = @field
				, @align = @align
				, @is_lockable = @is_lockable
				, @is_visiable_on_create = @is_visiable_on_create
				, @is_visiable_on_update = @is_visiable_on_update
				, @is_readonly = @is_readonly
				, @is_visiable_on_table = @is_visiable_on_table
				, @is_mandatory = @is_mandatory
				, @is_bulk = @is_bulk
				, @sortable = @sortable
else 
	exec sp_update_table_column
				@id = @id
				, @page_id = @page_id
				, @user_id = @user_id
				, @index = @index
				, @control_type_id = @control_type_id
				, @name = @name
				, @label = @label
				, @field = @field
				, @align = @align
				, @is_lockable = @is_lockable
				, @is_visiable_on_create = @is_visiable_on_create
				, @is_visiable_on_update = @is_visiable_on_update
				, @is_readonly = @is_readonly
				, @is_visiable_on_table = @is_visiable_on_table
				, @is_mandatory = @is_mandatory
				, @is_bulk = @is_bulk
				, @sortable = @sortable	


go






---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\sp_create_lookup_table.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_lookup_table
GO

CREATE PROC sp_create_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @name varchar(128)
AS

SET nocount ON 
declare @stt varchar(max)

begin transaction
begin try
	set @stt = 'insert into [' + @schema_name + '].[' + @table_name  + '] (name) values (''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''')'
	print @stt
	exec (@stt)

	set @stt = 'select max(id) as [id] from ['+ @schema_name + '].[' + @table_name  + ']'
	exec (@stt)
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\sp_get_lookup_table.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_lookup_table
GO

CREATE PROC sp_get_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	set @stt = 'select id, name from [' + @schema_name + '].[' + @table_name + ']'

	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\sp_update_lookup_table.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_lookup_table
GO

CREATE PROC sp_update_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @id int
, @name varchar(128)
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set name = ''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''' where id = ' + convert(varchar(10), @id)

	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\cud_location_lookup_table\sp_create_location_lookup_table.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_location_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_location_lookup_table
GO

CREATE PROC sp_create_location_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @name varchar(128)
, @site_id int
AS

SET nocount ON 
declare @stt varchar(max)

begin transaction
begin try
	if (@schema_name != 'lu' or @table_name not in ('location_component', 'location_sub_component','location_sub_area','location_cluster'))
		throw 16009, '@table_name is not a location list', 1

	set @stt = 'insert into [' + @schema_name + '].[' + @table_name  + '] (name, site_id) values (''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''', ' 
			+ convert(char(10), @site_id) + ')'
	print @stt
	exec (@stt)

	set @stt = 'select max(id) as [id] from ['+ @schema_name + '].[' + @table_name  + ']'
	exec (@stt)
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\cud_location_lookup_table\sp_get_location_lookup_table.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_location_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_location_lookup_table
GO

CREATE PROC sp_get_location_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @site_id int
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	set @stt = 'select id, name from [' + @schema_name + '].[' + @table_name + '] where site_id = ' + convert(varchar(10), @site_id)

	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\cud_location_lookup_table\sp_update_location_lookup_table.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_location_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_location_lookup_table
GO

CREATE PROC sp_update_location_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @id int
, @name varchar(128) = null
, @site_id int = null
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	if (@schema_name != 'lu' or @table_name not in ('location_component', 'location_sub_component','location_sub_area','location_cluster'))
		throw 16009, '@table_name is not a location list', 1

	if @name is not null
	begin
		set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set name = ''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''' where id = ' + convert(varchar(10), @id)
		--print @stt
		exec (@stt)
	end	
	if @site_id is not null
	begin
		set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set site_id = ' + convert(varchar(10),@site_id) + ' where id = ' + convert(varchar(10), @id)
		--print @stt
		exec (@stt)
	end
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\cud_project_lookup_table\sp_create_project_lookup_table.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_project_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_project_lookup_table
GO

CREATE PROC sp_create_project_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @name varchar(128)
, @project_id int
AS

SET nocount ON 
declare @stt varchar(max)

begin transaction
begin try
	if (@schema_name != 'lu' or @table_name not in ('project_item_pa_category_future','project_item_pa_category_new','project_item_pa_category_transfer','project_item_tender_package'))
		throw 16009, '@table_name is not a project list', 1

	set @stt = 'insert into [' + @schema_name + '].[' + @table_name  + '] (name, project_id) values (''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''', ' 
			+ convert(char(10), @project_id) + ')'
	print @stt
	exec (@stt)

	set @stt = 'select max(id) as [id] from ['+ @schema_name + '].[' + @table_name  + ']'
	exec (@stt)
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\cud_project_lookup_table\sp_get_project_lookup_table.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_project_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_project_lookup_table
GO

CREATE PROC sp_get_project_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @project_id int
, @search_string varchar(128) = null
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	set @stt = 'select id, name from [' + @schema_name + '].[' + @table_name + '] where project_id = ' + convert(varchar(10), @project_id) 
			+ ' and name like ''%' + @search_string + '%'''

	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_lookup_table\cud_project_lookup_table\sp_update_project_lookup_table.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_project_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_project_lookup_table
GO

CREATE PROC sp_update_project_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @id int
, @name varchar(128) = null
, @project_id int = null
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	if (@schema_name != 'lu' or @table_name not in ('project_item_pa_category_future','project_item_pa_category_new','project_item_pa_category_transfer','project_item_tender_package'))
		throw 16009, '@table_name is not a project list', 1

	if @name is not null
	begin
		set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set name = ''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''' where id = ' + convert(varchar(10), @id)
		--print @stt
		exec (@stt)
	end	
	if @project_id is not null
	begin
		set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set project_id = ' + convert(varchar(10),@project_id) + ' where id = ' + convert(varchar(10), @id)
		--print @stt
		exec (@stt)
	end
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_role\sp_create_role.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_role')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_role
GO

CREATE PROC sp_create_role
@name varchar(128)
AS

SET nocount ON 
declare @role_id int

begin transaction
begin try
	insert into usr.tbl_role (
			name
			)
		values (
			@name
			)
		select max(id) as role_id from usr.tbl_role
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_role\sp_delete_role.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_delete_role')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_delete_role
GO

CREATE PROC sp_delete_role
@id int
AS

SET nocount ON 

begin try
	delete from usr.tbl_role_menu where role_id = @id
	delete from usr.tbl_role where id = @id
end try

BEGIN CATCH  
	throw
END CATCH  

go






---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_role\sp_update_role.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_role')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_role
GO

CREATE PROC sp_update_role
@id int, 
@name varchar(128)
AS

SET nocount ON 

begin try
	update usr.tbl_role
	set  name = case when @name is null then name else @name end
	where id = @id

end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_role_menu\sp_upsert_role_menu.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_upsert_role_menu')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_upsert_role_menu
GO

CREATE PROC sp_upsert_role_menu
@role_id int 
, @menu_name_list varchar(max)
AS

SET nocount ON 
declare @user_id int

begin transaction
begin try

	IF ISJSON(@menu_name_list) != 1 
	begin
		throw 60001 ,'Incorrected JSON format for @permission_list', 1;
	end
	else 
	begin 
		delete from usr.tbl_role_menu where role_id = @role_id
		insert into usr.tbl_role_menu(role_id, menu_name)
		select @role_id, menu_name
		from openjson(@menu_name_list)  WITH (menu_name varchar(256) '$')
	end

end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_user\sp_create_user.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_user')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_user
GO

CREATE PROC sp_create_user
@user_principal_name varchar(128)
, @surname varchar(64)  = null
, @given_name varchar(64) = null
, @default_project_id  int = null
, @nickname varchar(64) =null
, @avatar varchar(64) = null
, @is_active bit = null

AS

SET nocount ON 
declare @user_id int

begin transaction
begin try
		-- if the ad user doesn't exist, create it first
		if not exists (select * from usr.tbl_user where user_principal_name = @user_principal_name)  
			insert into usr.tbl_user (
				user_principal_name
				, surname
				, given_name
				, [default_project_id]
				, [nickname]
				, [avatar]
				, is_active
				)
			values (
				@user_principal_name
				, @surname
				, @given_name
				, @default_project_id
				, @nickname 
				, @avatar
				, @is_active
				)
		select @user_id = id from usr.tbl_user where user_principal_name=@user_principal_name


end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

select @user_id as [id], @user_principal_name as user_principal_name

go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_user\sp_delete_user.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_delete_user')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_delete_user
GO

CREATE PROC sp_delete_user
@id int
AS

SET nocount ON 

begin transaction
begin try
	delete from usr.tbl_permission where user_id = @id
	delete from usr.tbl_user where id = @id
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH  

IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go






---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_user\sp_update_user.sql --------------------

/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_user')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_user
GO

CREATE PROC sp_update_user
@id int
, @user_principal_name varchar(128) = null
, @surname varchar(64) = null
, @given_name varchar(64) = null
, @sam_account_name varchar(64) = null
, @is_email_sent bit = 0
, @default_project_id  int  = null
, @nickname varchar(64) = null
, @avatar varchar(64) = null
, @is_active bit = null
AS

SET nocount ON 

begin try

	update usr.tbl_user
	set  user_principal_name = case when @user_principal_name is null then user_principal_name else @user_principal_name end
		, surname = case when @surname is null then surname else @surname end
		, given_name = case when @given_name is null then given_name else @given_name end
		, sam_account_name = case when @sam_account_name is null then sam_account_name else @sam_account_name end
		, is_email_sent = case when @is_email_sent is null then is_email_sent else @is_email_sent end
		, default_project_id = case when @default_project_id is null then default_project_id else @default_project_id end
		, nickname = case when @nickname is null then nickname else @nickname end
		, avatar = case when @avatar is null then avatar else @avatar end
		, is_active = case when @is_active is null then is_active else @is_active end
	where id = @id

end try

BEGIN CATCH  
	throw
END CATCH  

select id , user_principal_name from usr.tbl_user where id = @id

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\cud_user_permission\cud_user_project_role (permission)\sp_upsert_permission.sql --------------------
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_upsert_permission')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_upsert_permission
GO

CREATE PROC sp_upsert_permission
@project_id_list varchar(max)
, @user_id_list varchar(max)
, @role_id_list varchar(max) 
AS

SET nocount ON 
declare @user_id int

begin transaction
begin try

	IF ISJSON(@project_id_list) != 1 
		throw 60001 ,'Incorrected JSON format for @project_id_list', 1;

	IF ISJSON(@user_id_list) != 1 
		throw 60001 ,'Incorrected JSON format for @user_id_list', 1;

	IF ISJSON(@role_id_list) != 1 
		throw 60001 ,'Incorrected JSON format for @role_id_list', 1;

	delete from usr.tbl_permission
		where user_id in (select id from openjson(@user_id_list)  WITH (id INT '$'))
			and project_id in (select id from openjson(@project_id_list)  WITH (id INT '$'))

	if @role_id_list is not null
		insert into usr.tbl_permission(user_id, project_id, role_id)
		select user_id, project_id, role_id
		from openjson(@user_id_list)  WITH (user_id INT '$')
			, openjson(@project_id_list)  WITH (project_id INT '$')
			, openjson(@role_id_list)  WITH (role_id INT '$')

	update usr.tbl_user
	set default_project_id = (select top 1 project_id from openjson(@project_id_list)  WITH (project_id INT '$'))
	where id in (select user_id from openjson(@user_id_list)  WITH (user_id INT '$'))

end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\fn_parse_sp_parameter.sql --------------------

IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'fn_parse_sp_parameter')) 
BEGIN 
   DROP FUNCTION dbo.fn_parse_sp_parameter 
END 
GO
 
CREATE FUNCTION dbo.fn_parse_sp_parameter (@string varchar(max))  
RETURNS varchar(max) 
AS 
begin
	declare @parameter_name varchar(128), @parameter_value varchar(max), @parameter_type int
	declare @stt varchar(max)

	declare db_cursor cursor for select [key], [value],[type] from openjson(@string)
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @parameter_name, @parameter_value, @parameter_type  
	set @stt = ''

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
-- print @stt
		if @parameter_value is not null
		begin
			if @parameter_type = 2
				set @stt = @stt + ' @' + @parameter_name + ' = ' + @parameter_value + ','
			else 
				set @stt = @stt + ' @' + @parameter_name + ' = ''' + dbo.fn_duplicate_single_quote_in_string(@parameter_value) + ''' ,'
		end 
		FETCH NEXT FROM db_cursor INTO  @parameter_name, @parameter_value, @parameter_type  
	END 
	set @stt = substring (@stt,1,len(@stt)-1) 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 

	return @stt
end
   
GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\fn_to_raw_json.sql --------------------
DROP FUNCTION IF EXISTS dbo.fn_to_raw_json_array
GO
CREATE FUNCTION
[dbo].[fn_to_raw_json_array](@json nvarchar(max), @key nvarchar(400)) returns nvarchar(max)
AS BEGIN
       declare @new nvarchar(max) = replace(@json, CONCAT('},{"', @key,'":'),',')
       return '[' + substring(@new, 1 + (LEN(@key)+5), LEN(@new) -2 - (LEN(@key)+5)) + ']'
END

GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_add_new_view_column_display_name.sql --------------------

IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_add_new_view_column_display_name')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_add_new_view_column_display_name
GO

CREATE PROC sp_add_new_view_column_display_name
AS

insert into tbl_view (view_name)
select distinct TABLE_NAME
from INFORMATION_SCHEMA.COLUMNS
where (TABLE_NAME like 'vw_%' or TABLE_NAME like 'tbl_%')
	and TABLE_NAME not in (select view_name from tbl_view)

insert into tbl_view_column (view_id, column_name)
select v.id, c.COLUMN_NAME
from tbl_view v join INFORMATION_SCHEMA.COLUMNS c on v.view_name = c.TABLE_NAME
where not exists (select * from tbl_view_column where view_id = v.id and column_name = c.COLUMN_NAME)

GO





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_change_history.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_change_history') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_change_history
GO

create   proc [dbo].sp_change_history
@on_table varchar(64) = null ,
@id int = null
as
select on_table, record_id as id, by_whom_id, operation, json_content, created_on
from [dbo].[tbl_action_log]
where (on_table =@on_table or @on_table is null)
	and (record_id = @id or @id is null)
--	and (JSON_value(json_content,'$.log[0].id') = @id or @id is null)

GO






---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_find_string_in_table.sql --------------------
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_find_string_in_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_find_string_in_table
GO

CREATE PROCEDURE dbo.sp_find_string_in_table
@string_to_find VARCHAR(max)
, @schema sysname = 'dbo'
, @view_name sysname 
AS

BEGIN TRY
   DECLARE @sqlCommand varchar(max) = 'SELECT * FROM [' + @schema + '].[' + @view_name + '] WHERE ' 
	   
   SELECT @sqlCommand = @sqlCommand + '[' + COLUMN_NAME + '] LIKE ''' + @string_to_find + ''' OR '
   FROM INFORMATION_SCHEMA.COLUMNS 
   WHERE TABLE_SCHEMA = @schema
   AND TABLE_NAME = @view_name 
   AND DATA_TYPE IN ('char','nchar','ntext','nvarchar','text','varchar')

   SET @sqlCommand = left(@sqlCommand,len(@sqlCommand)-3)
   EXEC (@sqlCommand)
   PRINT @sqlCommand
END TRY

BEGIN CATCH 
	throw
END CATCH 

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_get_id_name_list.sql --------------------

/***************************************************** A Query:
requirements: 
	1) the specified view must have ID and name column
	2) @filter is the condition, can be any column valid in the specified view
Example:



********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_id_name_list')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_id_name_list
GO

CREATE PROC sp_get_id_name_list
@table_name varchar(64)
, @filter varchar(max) = null
AS

SET nocount ON 
declare @stt varchar(max), @schema_name varchar(64)


begin try
	if ( select count(*) from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @table_name) >1
		throw 100665, 'duplicated view name', 1;

	select @schema_name = TABLE_SCHEMA from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @table_name
 
	set @stt = 'select distinct id, name from [' + @schema_name + '].[' + @table_name + '] ' 

	if @filter is not null
		set @stt = @stt + ' where ' + dbo.fn_convert_json_to_where_clause(@filter)

	set @stt = @stt + ' order by name '

 
	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_get_view_definition.sql --------------------

IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_view_definition')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_view_definition
GO

CREATE PROC sp_get_view_definition @view_name varchar(128)
AS

select	COLUMN_NAME as [text],
		COLUMN_NAME as [value],
		case when DATA_TYPE in ('bigint','float','int','decimal') then 'numeric'
			when DATA_TYPE in ('money') then 'currency'
			when DATA_TYPE in ('nvarchar','text','varchar','varbinary') then 'text'
			when DATA_TYPE in ('bit') then 'bool'
			when DATA_TYPE in ('date','datetime','datetime2','smalldatetime') then 'datetime'
			else 'UNKNOWN'
		end [type]				
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = @view_name


GO









---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_log_operation.sql --------------------
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





---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_populate_updated_on.sql --------------------
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_populate_updated_on')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_populate_updated_on
GO

CREATE PROCEDURE sp_populate_updated_on
@table_name varchar(64)
as 
declare @stt varchar(max)

set @stt = '
update ' + @table_name + '
set updated_on = a.created_on
from ' + @table_name + ' e join
(
select e.id, v.action_log_id 
from ' + @table_name + ' e 
	join 
	(select record_id, max(id) as action_log_id
	from tbl_action_log 
	where on_table=''' + @table_name + '''
	group by record_id)  v on e.id=v.record_id
	) v1 on e.id=v1.id
	join tbl_action_log a on a.id = v1.action_log_id;


update ' + @table_name + '
set updated_on = created_on
where updated_on is null;

'
--print @stt
exec (@stt)

GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_search_count.sql --------------------

IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_search_count')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_search_count
GO

CREATE PROC sp_search_count @view_name varchar(128), @where_clause varchar(max) = null

AS

declare @stt varchar(max)

set @stt = 'select * from ' + @view_name 
if @where_clause is not null
	set @stt = @stt + ' where ' + @where_clause
exec (@stt)

set @stt = 'select count(*) from ' + @view_name 
if @where_clause is not null
	set @stt = @stt + ' where ' + @where_clause

exec (@stt)


GO









---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_set_content_info.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_set_context_info') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_set_context_info
GO

create   proc [dbo].sp_set_context_info
@current_user varchar(64)
as

	declare @user_name_binary varbinary(128)
	set @user_name_binary = convert(varbinary(128),@current_user)
	set context_info @user_name_binary

GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\general\sp_set_content_info_with_id.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_set_context_info_with_id') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_set_context_info_with_id
GO

create   proc sp_set_context_info_with_id
@current_user_id int
as

	declare @user_name_binary varbinary(128)
	set @user_name_binary = convert(varbinary(128),@current_user_id)
	set context_info @user_name_binary

	-- get the current_user_id
	-- select cast (substring(CONTEXT_INFO(),1,4) as int)
GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\Pagination\01_sp_paginate_view.sql --------------------
/******************************************************

exec sp_paginate_view 
@view_name = 'vw_pg_estimate'
, @page_size = 20
, @page_number = 1

***************************************************************/


if exists (select * from dbo.sysobjects where id = object_id(N'sp_paginate_view') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_paginate_view
GO

create   proc sp_paginate_view
@schema_name sysname = 'dbo'  -- by default, the schema is dbo
, @view_name varchar(128) 
, @filter varchar(max) = null  -- by default, there is no where clause
, @search_string varchar(64) = null  -- by default, there is no string to search
, @order_by varchar(512) = '1'  -- by default, the results are sorted by the first column
, @page_number int = 1 -- page number starting from 1, it is the default value
, @page_size int = 5 --default page size is 12

as

declare @stt nvarchar(max), @sql_filter nvarchar(max), @search_condition nvarchar(max) = ''

-- generate search condition
if @search_string is not null
begin
	SELECT @search_condition = @search_condition + '[' + COLUMN_NAME + '] LIKE ''%' + @search_string + '%'' OR '
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_SCHEMA = @schema_name
		AND TABLE_NAME = @view_name 
		AND DATA_TYPE IN ('char','nchar','ntext','nvarchar','text','varchar')
	SET @search_condition = left(@search_condition,len(@search_condition)-3)
end

-- generate Where clause in a SELECT statement
if @filter is null and @search_string is null
	set @sql_filter = ''
else if @filter is null and @search_string is not null
	set @sql_filter = ' where ' + @search_condition
else if @filter is not null and @search_string is null
	set @sql_filter = ' where ' + dbo.fn_convert_json_to_where_clause(@filter)
else if @filter is not null and @search_string is not null
	set @sql_filter = ' where ' + '( ' + dbo.fn_convert_json_to_where_clause(@filter) + ' ) and ( ' + @search_condition + ' )'


begin try
	-- Paginated Records
	if @view_name = 'vw_equipment'
	begin
		set @stt = 'select * from vw_equipment where id in ( select id from vw_equipment ' + @sql_filter + ' )' 
	end
	else
	begin
		set @stt = 'select * from [' + @schema_name + '].[' + @view_name + '] ' + @sql_filter
	end
	set @stt = @stt + ' order by ' + @order_by  + ' offset ' + convert (varchar(20), (@page_number-1)*@page_size ) + ' rows fetch next ' + convert(varchar(20), @page_size) + ' row only'

	print @stt
	exec (@stt)

	-- Total Record Count
	set @stt = 'select count(*) as total_size from [' + @schema_name + '].[' + @view_name + '] ' + @sql_filter
	-- print @stt
	exec sp_executesql @stt
end try
BEGIN CATCH  
    throw  
END CATCH;  

GO







---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\Pagination\02_sp_distinct_value.sql --------------------
/******************************************************



***************************************************************/


if exists (select * from dbo.sysobjects where id = object_id(N'sp_distinct_value') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_distinct_value
GO

create   proc sp_distinct_value
@view_name varchar(128) 
, @column_name varchar(512)
, @where_clause varchar(max) = null

as

declare @stt nvarchar(max)
declare @blank_filter nvarchar(512)
declare @null_condition nvarchar(512)


if exists ( SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = @view_name and COLUMN_NAME = @column_name
		AND DATA_TYPE IN ('char','nchar','ntext','nvarchar','text','varchar'))
begin
	set @blank_filter = @column_name + ' is not null and ' + @column_name + ' != '''''
    set @null_condition = @column_name + ' is null or ' + @column_name + ' = '''''
end
else
begin
	set @blank_filter = @column_name + ' is not null '
	set @null_condition = @column_name + ' is null '
end 

set @stt = 'select ' + @column_name + ' from 
( '
	+ 'select distinct ' + @column_name + ' from ' +  @view_name 
    + case when @where_clause is not null 
            then  ' where (' + @where_clause + ') and (' + @blank_filter + ')'
            else  ' where ' + @blank_filter
      end
	+ ' union select null as ' + @column_name + ' from '  +  @view_name  + 
                + case when @where_clause is not null 
                    then  ' where (' + @where_clause + ') and (' + @null_condition + ')'
            else  ' where ' + @null_condition
      end  + 
    ') v '
    + ' order by ' + @column_name

begin try
    print @stt
    exec (@stt)
end try
BEGIN CATCH  
    throw
END CATCH;  

go
GO







---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\Pagination\03_sp_get_distinct_value.sql --------------------

/******************************************************



***************************************************************/


if exists (select * from dbo.sysobjects where id = object_id(N'sp_get_distinct_value') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_get_distinct_value
GO

create   proc sp_get_distinct_value
@view_name varchar(128) 
, @column_name varchar(512)
, @filter_json varchar(max) = null

as

declare @stt nvarchar(max), @where_clause varchar(max)

set @where_clause = dbo.fn_convert_json_to_where_clause(@filter_json)

set @stt = 'select distinct ' + @column_name + ' from ' +  @view_name + case when @where_clause !='' then ' where ' + @where_clause else @where_clause end
    + ' order by ' + @column_name

begin try
    print @stt
    exec (@stt)
end try
BEGIN CATCH  
    throw
END CATCH;  

go
GO









---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\trigger\01_sp_trigger_enabled_by_table.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_trigger_enabled_by_table') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_trigger_enabled_by_table
GO

create   proc sp_trigger_enabled_by_table
@table_name varchar(256) = null
as
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += 
    N'ENABLE TRIGGER ' + 
    QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) 
    + ' on ' + QUOTENAME(OBJECT_SCHEMA_NAME(tbl.object_id))  + N'.' + QUOTENAME(tbl.name) 
    + N'; ' + NCHAR(13)
FROM sys.triggers AS t join sys.tables tbl on t.parent_id=tbl.object_id
WHERE tbl.name = @table_name or @table_name is null

-- PRINT @sql;
exec (@sql);


GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\trigger\02_sp_trigger_disabled_by_table.sql --------------------
if exists (select * from dbo.sysobjects where id = object_id(N'sp_trigger_disabled_by_table') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_trigger_disabled_by_table
GO

create   proc sp_trigger_disabled_by_table
@table_name varchar(256) = null
as
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += 
    N'DISABLE TRIGGER ' + 
    QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) 
    + ' on ' + QUOTENAME(OBJECT_SCHEMA_NAME(tbl.object_id))  + N'.' + QUOTENAME(tbl.name) 
    + N'; ' + NCHAR(13)
FROM sys.triggers AS t join sys.tables tbl on t.parent_id=tbl.object_id
WHERE tbl.name = @table_name or @table_name is null

-- PRINT @sql;
exec (@sql);


GO




---------------------------- C:\Users\jamie\source\repos\navidatainc\MODEL_DB\Sp_fn\common\trigger\10_create_common_trigger.sql --------------------

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

