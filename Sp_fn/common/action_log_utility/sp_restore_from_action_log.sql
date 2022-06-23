if exists (select * from dbo.sysobjects where id = object_id(N'sp_restore_from_action_log') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_restore_from_action_log
GO

create   proc sp_restore_from_action_log
@id int
as 


DECLARE @operation varchar(20), @json NVARCHAR(4000), @field_list varchar(4000), @value_list varchar(4000), @table_name varchar(256)
declare @stt nvarchar(MAX)
select @json = json_content
    , @operation = operation
    , @table_name = on_table 
from tbl_action_log where id = @id


begin try
    if @json is null
        throw 60100, 'the action log id is invalid', 1;
    
    if @operation != 'Delete'
        throw 60200, 'The to-be-restored action log is not a delete operation', 1;

    SELECT @field_list = string_agg([key] ,',')
		    , @value_list = string_agg (case when [type] = 1 then '''' + [value] + '''' 
										     when [type] = 2 then [value] 
										     when [type] = 3 then case when [value]='true' then '1' else '0' end
										     else null end ,',')
    FROM OPENJSON(@json	, N'$.log[0]') 
    where [key] not in ('operation','on_table','updated_on')

    set @stt = 'SET IDENTITY_INSERT ' + @table_name + ' ON; 
    ' +'insert into ' + @table_name + '(' + @field_list + ') values (' + @value_list + ') 
    ' + 'SET IDENTITY_INSERT ' + @table_name + ' OFF;'

    print @stt
    exec (@stt)

end try

BEGIN CATCH  
    throw
END CATCH;  


Go

