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


