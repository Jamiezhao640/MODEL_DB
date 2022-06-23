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
