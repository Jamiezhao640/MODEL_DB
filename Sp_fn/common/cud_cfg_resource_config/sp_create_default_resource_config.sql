/*******************************************************

Insert a PO

*************************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_default_resource_config')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_default_resource_config
GO

CREATE PROC sp_create_default_resource_config
@resource varchar(64)
AS
SET NOCOUNT ON

INSERT INTO [cfg].[resource_config]
           ([resource]
           ,[action]
           ,[object_type]
           ,[sp_name]
           ,[schema_name]
           ,[view_name])
     VALUES (@resource, 'create', 'sp', 'sp_create_'+@resource, 'dbo',null)
			, (@resource, 'update', 'sp', 'sp_update_'+@resource, 'dbo',null)
			, (@resource, 'delete', 'sp', 'sp_delete_'+@resource, 'dbo',null)
			, (@resource, 'get', 'vw', null, 'dbo','vw_'+@resource)
GO