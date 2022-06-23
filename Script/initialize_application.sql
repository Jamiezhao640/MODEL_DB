

exec sp_set_context_info_with_id 1

SET IDENTITY_INSERT tbl_site on
insert into tbl_site (id,name) values (-1, 'Virtual')
SET IDENTITY_INSERT tbl_site off

SET IDENTITY_INSERT tbl_project on
insert into tbl_project(id,name,site_id,ha_id) values (-1, 'Super Project', -1, 1)
SET IDENTITY_INSERT tbl_project off

insert into [dbo].[tbl_permission] (user_id, role_id, project_id) values (1,1,-1)

select * from vw_pg_user_project_role_permission

