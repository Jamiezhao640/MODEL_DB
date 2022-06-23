/****** Script for SelectTopNRows command from SSMS  ******/
USE [FH_HEPS_DEV]
GO


exec sp_set_context_info_with_id 1

INSERT INTO [dbo].[tbl_item]
           ([item]
           ,[description]
           ,[maint_resp_id]
           ,[type_id]
           ,[default_unit_cost]
           ,[is_active])

SELECT [Item]
      ,[Description]
	  , (select id from [lu].[item_maintenance_representative] where name = [Maintenance Department]) maint_resp_id
	  , (select id from [lu].[item_type] where name = [Equipment Type]) type_id
      ,[Default Unit Cost]
	  , 1
 
 FROM [temp].[Catalog$]