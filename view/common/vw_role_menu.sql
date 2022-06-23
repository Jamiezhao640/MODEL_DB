
 IF EXISTS (
	SELECT
		1
	FROM
		sys.views
	WHERE
		Name = 'vw_role_menu'
) DROP VIEW vw_role_menu
GO
	CREATE VIEW vw_role_menu AS

select r.id
	, r.name
	, isnull (('[' + (select string_agg( '"' +p.menu_name + '"',',') from usr.tbl_role_menu p where r.id=p.role_id ) + ']'),'[]') as menu_json
  from usr.tbl_role r 




GO
