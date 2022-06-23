
insert tbl_menu_leaf_permission values ('CREATE'), ('READ'), ('UPDATE'), ('DELETE'), ('HISTORY'), ('FINANCE'), ('ATTACHMENT')



insert into tbl_menu(name)
select leaf_permission
from 
(
select m.name+ '_' + mp.permission as leaf_permission
from [dbo].[tbl_menu] m , tbl_menu_leaf_permission mp 
where m.is_leaf = 1
) v 
where leaf_permission not in (select name from tbl_menu)

