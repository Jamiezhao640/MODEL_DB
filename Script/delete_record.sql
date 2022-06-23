
exec sp_trigger_disabled_by_table
delete from tbl_equipment

delete from tbl_po

delete from tbl_estimate_template_item

update tbl_estimate_plan
set referenced_project_room_id = null

delete from tbl_project_item

delete from tbl_project_room
delete from tbl_estimate_plan

truncate table tbl_action_log

truncate table tbl_uri

exec sp_trigger_enabled_by_table


