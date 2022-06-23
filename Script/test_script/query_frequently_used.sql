select * from [cfg].[resource_config]

exec sp_get_table_column

select * from [dbo].[tbl_api_log] order by id desc


-----------------------------------


select * from tbl_api_log
where ISJSON(api_json) =1 and exists (select * from openjson (api_json) where [key] = 'action' and [value] = 'create')
order by id desc






-- check the foreign key
select * from openjson (@api_json, N'$.data.menu_name_list') v
where v.value not in (select name from tbl_menu)

