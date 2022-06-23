
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_add_new_view_column_display_name')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_add_new_view_column_display_name
GO

CREATE PROC sp_add_new_view_column_display_name
AS

insert into tbl_view (view_name)
select distinct TABLE_NAME
from INFORMATION_SCHEMA.COLUMNS
where (TABLE_NAME like 'vw_%' or TABLE_NAME like 'tbl_%')
	and TABLE_NAME not in (select view_name from tbl_view)

insert into tbl_view_column (view_id, column_name)
select v.id, c.COLUMN_NAME
from tbl_view v join INFORMATION_SCHEMA.COLUMNS c on v.view_name = c.TABLE_NAME
where not exists (select * from tbl_view_column where view_id = v.id and column_name = c.COLUMN_NAME)

GO

