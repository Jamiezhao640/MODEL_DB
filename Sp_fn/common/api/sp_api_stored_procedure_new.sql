if exists (select * from dbo.sysobjects where id = object_id(N'sp_api_stored_procedure') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_api_stored_procedure
GO

create   proc sp_api_stored_procedure
@sp_name varchar(128)
, @data_json varchar(max)
as

declare @parameter_name varchar(128), @parameter_value varchar(max), @parameter_type int
declare @stt varchar(max)

BEGIN TRY
	set @stt = @sp_name + ' '  + 
	(select STRING_AGG (PARAMETER_NAME + 
		case when [type] = 0 then ' = NULL'
			when [type] in (1,4,5) then ' = ''' + dbo.fn_duplicate_single_quote_in_string([value]) + ''''
			when  [type] = 2 then ' = ' + [value]
			when  [type] = 3 then ' = ' + case when [value] ='true' then '1' else '0' end 
		end, ', ')
	from openjson(@data_json) dj join INFORMATION_SCHEMA.PARAMETERS para on '@'+ [key] = PARAMETER_NAME collate SQL_Latin1_General_CP1_CI_AS
	where SPECIFIC_NAME=@sp_name )

	print @stt
	exec (@stt)

END TRY

BEGIN CATCH
	throw
END CATCH;

GO

