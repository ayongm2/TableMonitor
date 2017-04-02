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