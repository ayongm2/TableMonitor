# Table Monitor

简单的Lua table监视器,被监视的table发生改变时都会进行回调.
其基本形态就如lua教程中关于metatable的例子,单层table监控.

使用的场景是基本固定结构的table中经常发生数值变化的情况,现已扩展成能处理任何变化,可将服务端数据本地存储后主动发起通知回调,也可用于扩展RxLua对table中数值变化的处理.

具体使用可参看例子
```
require("table_monitor")
local a = {
    a1 = 1,
    a2 = { 1, 2, 3},
    a3 = {
        a31 = "a",
        a32 = {
            "b"
        },
    },
}

local ta = table.monitor(a, function ( path, value, oldValue )
    print(string.format("table change at %s from ", path), oldValue, "to ", value)
end)

print("start~~~")
print(ta.a3.a32[1])
ta.a3.a32[2] = 2
ta.a3.a32 = {"c"}
ta.a3.a32.a = 3
ta.a3.a32 = 33
print("~~~", ta.a3.a32)
print(ta.a2[3])
ta.a3.a32 = {33}
print(ta.a3.a32[1])
ta.a3.a32 = nil
ta.a3.a32 = {5}
print(ta.a3.a32)
print("over~~~")

--[[
start~~~
b
table change at a3.a32.[2] from     nil to  2
table change at a3.a32 from     table: 0x7faf8bc068e0   to  table: 0x7faf8bc07ae0
table change at a3.a32.a from   nil to  3
table change at a3.a32 from     table: 0x7faf8bc07790   to  33
~~~ 33
3
table change at a3.a32 from     33  to  table: 0x7faf8bc08450
33
table change at a3.a32 from     table: 0x7faf8bc08120   to  nil
table change at a3.a32 from     nil to  table: 0x7faf8bc088b0
table: 0x7faf8bc088b0
over~~~
--]]

```
