IF EXISTS (
		SELECT 1
		FROM sys.VIEWS
		WHERE Name = 'vw_role'
		)
	DROP VIEW vw_role
GO

CREATE VIEW vw_role
AS
select * from usr.tbl_role

GO

