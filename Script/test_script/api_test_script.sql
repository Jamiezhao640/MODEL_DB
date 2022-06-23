declare @api_json varchar(max)

set @api_json = '
{  "resource": "user",
  "action": "get",
  "by_whom_id": -1,
    "data": { "user_principal_name": "support@navidata.ca" }
  }
'

exec sp_api_parse_resource @api_json = @api_json

/**************************

key	value	type
String_value	John	1
DoublePrecisionFloatingPoint_value	45	2
DoublePrecisionFloatingPoint_value	2.3456	2
BooleanTrue_value	true	3
BooleanFalse_value	false	3
Null_value	NULL	0
Array_value	["a","r","r","a","y"]	4
Object_value	{"obj":"ect"}	5

******************************/