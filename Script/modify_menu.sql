
exec sp_set_context_info_with_id 1
begin tran
update tbl_menu
set name = replace(name, 'project_equipment','equipment')
where name like '%project_equipment%'

commit tran
