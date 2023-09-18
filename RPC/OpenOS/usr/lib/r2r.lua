r2r = {}
r2r.buffer = {}
r2r.chunksize = 1000
r2r.initalized = false
r2r.fn = {}

local rpc = require("rpc")
local serial = require "serialization"
local component = require("component")

function r2r.fn.list()
    local rt = {}
    for k,v in pairs(r2r.fn) do
        rt[#rt + 1] = k
    end
    return rt
end

function r2r.fn.listcomponents()
    return component.list()
end

function r2r.init()
    rpc.register("createendpoint", function()
        local key = require("uuid").next()
        r2r.buffer[key] = {}
        return key
    end)

    rpc.register("record", function(data, key)
        r2r.buffer[key][#r2r.buffer[key] + 1] = data
        return true
    end)
    
    rpc.register("call", function(function_name, key)
        local data = ""
        for i = 1, #r2r.buffer[key] do
            data = data .. r2r.buffer[key][i]
        end
        local deserialized = serial.unserialize(data)
        local result = r2r.fn[function_name](table.unpack(deserialized))
        local serialized_result = serial.serialize({result})
        local chunk_count = #serialized_result // r2r.chunksize
        if #serialized_result % r2r.chunksize ~= 0 then
            chunk_count = chunk_count + 1
        end
        r2r.buffer[key]["result"] = {}
        for i = 1, chunk_count do
            r2r.buffer[key]["result"][i] = serialized_result:sub((i - 1) * r2r.chunksize + 1, i * r2r.chunksize)
        end
        return true
    end)

    rpc.register("getresultpart", function(key, id)
        return r2r.buffer[key]["result"][id]
    end)

    rpc.register("getchunkcount", function(key)
        return #r2r.buffer[key]["result"]
    end)

    rpc.register("removeendpoint", function(key)
        r2r.buffer[key] = nil
    end)

    r2r.initalized = true
end 

function r2r.call(host,function_name, ...)
    local key = rpc.call(host,"createendpoint")
    local serialized_args = serial.serialize({...})
    local chunk_count = #serialized_args // r2r.chunksize
    if #serialized_args % r2r.chunksize ~= 0 then
        chunk_count = chunk_count + 1
    end
    for i = 1, chunk_count do
        local chunk = serialized_args:sub((i - 1) * r2r.chunksize + 1, i * r2r.chunksize)
        rpc.call(host,"record", chunk, key)
    end
    rpc.call(host,"call", function_name, key)
    local result_chunk_count = rpc.call(host,"getchunkcount", key)
    local result = ""
    for i = 1, result_chunk_count do
        result = result .. rpc.call(host,"getresultpart", key, i)
    end
    rpc.call(host,"removeendpoint", key)
    return table.unpack(serial.unserialize(result))
end


function r2r.proxy(hostname,filter)
    filter=(filter or "").."(.+)"
    local fnames = r2r.call(hostname,"list")
    if not fnames then return false end
    local rt = {}
    for k,v in pairs(fnames) do
        fv = v:match(filter)
        if fv then
            rt[fv] = function(...)
                return r2r.call(hostname,v,...)
            end
        end
    end
    return rt
end


function r2r.register(name,fn)
    if not r2r.initalized then
        r2r.init()
    end
    r2r.fn[name] = fn
end

return r2r