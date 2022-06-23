
-- if a user is granted role_id=1 and project_id = -1, there this user is admin on all the projects
 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_user_project_ln'
) DROP VIEW vw_user_project_ln
GO
	CREATE VIEW vw_user_project_ln AS

SELECT distinct [user_id] ,[project_id] FROM vw_user_project_role_ln


GO
