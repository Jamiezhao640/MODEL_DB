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
