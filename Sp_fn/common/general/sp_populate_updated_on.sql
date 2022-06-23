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