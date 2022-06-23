declare @api_json varchar(max)

set @api_json = '
{
    "resource": "user_role_permission",
    "action": "get/create/update/delete",
    "by_whom_id": 1,
    "data": {
      "filter": [
        {
          "name": "user",
          "value": [ "1", "2", "3", "4" ]
        },
        {
          "name": "name",
          "value": [ 1, 2, 3, 4 ]
        },
        {
          "name": "string",
          "value": "test_string"
        },
        {
          "name": "number",
          "value": 1245
        },
        {
          "name": "is_active",
          "value": false
        }
      ]
    }
  }
'

declare @filter_json varchar(max)

select @filter_json = [value] from openjson (@api_json,'$.data') where [key] = 'filter'

select dbo.fn_convert_json_to_where_clause(@filter_json)
