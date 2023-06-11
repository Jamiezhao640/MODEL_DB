
select * from tbl_api_log
where ISJSON(api_json) =1 and exists (select * from openjson (api_json) where [key] = 'resource_name' and [value] = 'sp_new_po')

test-git
git