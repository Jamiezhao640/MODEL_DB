
-- if a user is granted role_id=1 and project_id = -1, there this user is admin on all the projects
 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_user_project_role_ln'
) DROP VIEW vw_user_project_role_ln
GO
	CREATE VIEW vw_user_project_role_ln AS

SELECT [user_id]
      ,[role_id]
      ,[updated_on]
      ,[project_id]
  FROM usr.[tbl_permission]
  where project_id > 0
union
select user_id,1 as role_id, getdate() as updated_on, tbl_project.id as project_id
from usr.tbl_permission, tbl_project
where usr.tbl_permission.project_id = -1 and tbl_project.id > 0


GO
