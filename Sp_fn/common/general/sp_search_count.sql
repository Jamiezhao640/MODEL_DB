
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_search_count')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_search_count
GO

CREATE PROC sp_search_count @view_name varchar(128), @where_clause varchar(max) = null

AS

declare @stt varchar(max)

set @stt = 'select * from ' + @view_name 
if @where_clause is not null
	set @stt = @stt + ' where ' + @where_clause
exec (@stt)

set @stt = 'select count(*) from ' + @view_name 
if @where_clause is not null
	set @stt = @stt + ' where ' + @where_clause

exec (@stt)


GO





