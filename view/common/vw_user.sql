
 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_user'
) DROP VIEW vw_user
GO
	CREATE VIEW vw_user AS

select u.*, user_principal_name as name
	 , convert(varchar, created_on, 23) as createdOn
     , convert(varchar, updated_on, 23) as updatedOn
	,case when is_active=1 then 'Yes' else 'No' end AS isActive
	,case when is_email_sent =1 then 'Yes' else 'No' end AS isEmailSent 


  from usr.tbl_user u 

where u.id>0

GO
