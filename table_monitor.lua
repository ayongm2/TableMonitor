local stirng_find = string.find
local string_match = string.match
local string_sub = string.sub
local table_insert = table.insert
local table_remove = table.remove
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local getmetatable = getmetatable
local string_split = string.split or function (input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string_find(input, delimiter, pos, true) end do
        table_insert(arr, string_sub(input, pos, st - 1))
        pos = sp + 1
    end
    table_insert(arr, string_sub(input, pos))
    return arr
end
local table_removebyvalue = table.removebyvalue or function (array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table_remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end
--[[--

    根据路径取得table中的特定项的值

    @param table t 
    @param string path

    @return table中的特定项的值

    e.g.
    local a = {a1 = 1, a2 = "b", a3 = {a31 = 3, a32 = {a321 = "c"}}}
    table.getByPath(a, "a3.a32.a321") --> "c"
--]]
function table.getByPath( t, path )
    if not path then 
        return t
    elseif string_find(path, "%.") then 
        local paths = string_split(path, ".")
        local cur = t
        local hasN = string_find(path, "%[") ~= nil
        for i, keyname in ipairs(paths) do
            local v 
            if hasN then
                local n = tonumber(string_match(keyname, "^%[(.+)%]$"))
                if n then v = cur[n] end 
            end 
            if not v then v = cur[keyname] end
            if v then cur = v else return nil end
        end
        return cur
    else
        return t[path]
    end
end
--[[--

    根据路径设定table中的特定项的值,期间不存在的项自动创建{}

    @param table t 
    @param string path
    @param * value

    e.g.
    local a = {a1 = 1, a2 = "b", a3 = {a31 = 3, a32 = {a321 = "c"}}}
    table.setByPath(a, "a3.a32.a321", "d")
    table.getByPath(a, "a3.a32.a321") --> "d"
--]]
function table.setByPath( t, path, value )
    if not path then 
        t = value
    elseif string_find(path, "%.") then 
        local paths = string_split(path, ".")
        local cur = t
        local count = #paths
        local hasN = string_find(path, "%[") ~= nil
        for i = 1, count - 1 do
            local keyname = paths[i]
            local v
            if hasN then
                local n = tonumber(string_match(keyname, "^%[(.+)%]$"))
                if n then 
                    v = cur[n]
                    keyname = n 
                end 
            end 
            if not v then v = cur[keyname] end
            if v then 
                cur = v
            else
                cur[keyname] = {}
                cur = cur[keyname]
            end
        end
        local lastKeyname = paths[count]
        if hasN then 
            lastKeyname = tonumber(string_match(lastKeyname, "^%[(.+)%]$")) or lastKeyname
        end
        cur[lastKeyname] = value
    else
        t[path] = value
    end 
    return t
end
--[[--

    创建带监控的table

    @param table tb 源table
    @param fun(path,value,oldValue) callback 值改变时的回调
    @param string path 上级路径,不用理会此参数,仅为内部使用

    @return 带监控的table
--]]
local table_monitor_
function table_monitor_(tb, callback, path)
    local data = tb or {}
    local subpath = path
    local function createKey( key )
        if "number" == type(key) then 
            return "[" .. key .. "]"
        else
            return key
        end
    end
    local mt = {
        __index = function ( t, k )
            local v = rawget(t, k)
            if v then 
                return v
            else
                if "__ismonitor__" == k then
                    return true
                end
                local result = data[k]
                if type(result) == "table" then 
                    local newMonitor = table_monitor_(result, callback
                        , subpath and subpath .. "." .. createKey(k) or createKey(k))
                    rawset(t, k, newMonitor)
                    return newMonitor
                else
                    return result
                end
            end
        end,
        __newindex = function ( t, k, v )
            local oldValue = data[k]
            if oldValue ~= v then 
                data[k] = v
                if callback then 
                    if type(v) ~= "table" then 
                        callback(subpath and subpath .. "." .. createKey(k) or createKey(k)
                            , v, oldValue)
                    end
                end
            end
        end,
        __call = function ( t, k, v )
            if "[path]" == k then 
                return subpath
            elseif "string" == type(k) then
                if v then 
                    table.setByPath(t, k, v)
                else
                    return table.getByPath(t, k)
                end
            else
                return data
            end
        end,
    }
    return setmetatable({}, mt)
end
--[[--

    创建带监控的table

    @param table tb 源table
    @param fun(path,value,oldValue) callback 值改变时的回调

    @return 带监控的table

    e.g
    local a = {"a", "b", c = {"c1", "c2"}}
    local ta = table.monitor(a, function ( path, value, oldValue )
        print(path, value, oldValue)
    end)
    ta.c[2] = "c3"
--]]
function table.monitor( tb, callback )
    local callbacks = {}
    if callback then 
        callbacks[#callbacks + 1] = callback
    end
    local addCallback = function ( self, cb )
        callbacks[#callbacks + 1] = cb
    end
    local removeCallback = function ( self, cb )
        table_removebyvalue(callbacks, cb, true)
    end
    local cb = function ( path, value, oldValue )
        for k, listener in pairs(callbacks) do
            listener(path, value, oldValue)
        end
    end
    local result = table_monitor_(tb, cb)

    local mt = getmetatable(result)
    local index_fn = mt.__index
    mt.__index = function ( t, k )
        if k == "addCallback" then 
            return addCallback
        elseif k == "removeCallback" then
            return removeCallback
        else
            return index_fn(t, k)
        end
    end
    setmetatable(result, mt)
    return result
end




