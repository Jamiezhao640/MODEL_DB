if exists (select * from dbo.sysobjects where id = object_id(N'sp_get_table_column') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_get_table_column
GO

create   proc sp_get_table_column
@page_name varchar(64) = null

as
	select page_name
        , [index]
      ,ptc.[name]
      ,[label]
	  ,[field]
      ,ct.[name] as control_type
      ,[is_lockable]
      ,[is_visiable_on_create]
      ,[is_visiable_on_update]
      ,[is_readonly]
      ,[is_visiable_on_table]
      ,[is_mandatory]
      ,[is_bulk] 
      , sortable
	  , align
	from cfg.page p join cfg.page_table_column ptc on p.id = ptc.page_id 
		join cfg.page_control_type ct on ct.id = ptc.control_type_id
	where page_name = @page_name or @page_name is null

GO
