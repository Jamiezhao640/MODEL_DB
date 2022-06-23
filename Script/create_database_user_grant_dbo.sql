/****** Object:  User [FHA_HEPS]    Script Date: 4/29/2022 6:01:34 AM ******/
CREATE USER [FHA_HEPS] for login [FHA_HEPS]
GO

exec sp_addrolemember 'db_owner', 'FHA_HEPS'
go


-------------------------------------------------------

CREATE USER [FHA_HEPS_PROD] for login [FHA_HEPS_PROD]
GO

exec sp_addrolemember 'db_owner', 'FHA_HEPS_PROD'
go


 ----------------------------------------------------------
 /****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [id]
      ,[given_name]
      ,[surname]
      ,[sam_account_name]
      ,[user_principal_name]
      ,[created_on]
      ,[updated_on]
      ,[is_email_sent]
      ,[default_project_id]
      ,[nickname]
      ,[avatar]
  FROM [dbo].[tbl_user]

  select * from tbl_permission


  exec sp_set_context_info_with_id 1
  insert into tbl_user (given_name, surname, user_principal_name) values ('Chris', 'Wang', 'cw_1703@healthbc.org')

  insert into tbl_permission (user_id, role_id, project_id) values (29, 1, -1), (31,1,-1)


