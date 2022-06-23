IF EXISTS (
		SELECT 1
		FROM sys.VIEWS
		WHERE Name = 'vw_lookup_table'
		)
	DROP VIEW vw_lookup_table
GO


create view vw_lookup_table
as
SELECT table_name, 
	case when exists(select * from INFORMATION_SCHEMA.COLUMNS 
						where table_schema = 'lu' 
							and 
							  COLUMN_NAME='project_id'
							and
							  TABLE_NAME=m.TABLE_NAME)
		then 'project'
		when exists(select * from INFORMATION_SCHEMA.COLUMNS 
						where table_schema = 'lu' 
							and 
							  COLUMN_NAME='site_id'
							and
							  TABLE_NAME=m.TABLE_NAME)
		 then 'location'
		 else 'general'
	end as [type]
FROM INFORMATION_SCHEMA.TABLES m
where table_schema = 'lu' and table_name not like 'vw_%'


GO

