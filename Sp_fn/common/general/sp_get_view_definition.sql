
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_view_definition')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_view_definition
GO

CREATE PROC sp_get_view_definition @view_name varchar(128)
AS

select	COLUMN_NAME as [text],
		COLUMN_NAME as [value],
		case when DATA_TYPE in ('bigint','float','int','decimal') then 'numeric'
			when DATA_TYPE in ('money') then 'currency'
			when DATA_TYPE in ('nvarchar','text','varchar','varbinary') then 'text'
			when DATA_TYPE in ('bit') then 'bool'
			when DATA_TYPE in ('date','datetime','datetime2','smalldatetime') then 'datetime'
			else 'UNKNOWN'
		end [type]				
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = @view_name


GO





