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
