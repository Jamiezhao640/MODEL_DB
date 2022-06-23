
-- disable all the trigger first
exec sp_trigger_disabled_by_table


delete from tbl_equipment

-------------------
update tbl_project_room
set estimate_plan_id = null

delete from tbl_estimate_plan

delete from tbl_project_room

------------------------
delete from dbo.tbl_estimate_template_item

delete from tbl_project_item

delete from tbl_item
delete from tbl_specification
delete from tbl_imit_specification

delete from tbl_estimate_template
delete from tbl_estimate_task
delete from tbl_location
delete from tbl_recycle_bin

delete from tbl_permission
delete from tbl_invoice
delete from tbl_po

delete from tbl_requisition_form

delete from tbl_ownership
delete from attm.ownership

delete from lu.project_item_pa_category_future
delete from lu.project_item_pa_category_new
delete from lu.project_item_pa_category_transfer
delete from lu.project_item_tender_package

delete from tbl_report
delete from tbl_report_by_view

delete from tbl_current_requisition_number
delete from tbl_project

delete from tbl_action_log

delete from tbl_copies_of_po_to
delete from tbl_site_contact
delete from tbl_site

delete from tbl_user

delete from tbl_vendor

exec sp_trigger_enabled_by_table