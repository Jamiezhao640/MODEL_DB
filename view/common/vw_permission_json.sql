
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