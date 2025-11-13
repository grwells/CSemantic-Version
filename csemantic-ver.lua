#!/usr/bin/lua

local json = require("dkjson")
local argparse = require("argparse")

-- ANSI shadow from https://patorjk.com/software/taag/
-- All parser arguments specified at bottom of file 
-- after API
local parser = argparse():name("semantic version"):add_complete():description(
[[
███████╗███████╗███╗   ███╗ █████╗ ███╗   ██╗████████╗██╗ ██████╗    ██╗   ██╗███████╗██████╗ 
██╔════╝██╔════╝████╗ ████║██╔══██╗████╗  ██║╚══██╔══╝██║██╔════╝    ██║   ██║██╔════╝██╔══██╗
███████╗█████╗  ██╔████╔██║███████║██╔██╗ ██║   ██║   ██║██║         ██║   ██║█████╗  ██████╔╝
╚════██║██╔══╝  ██║╚██╔╝██║██╔══██║██║╚██╗██║   ██║   ██║██║         ╚██╗ ██╔╝██╔══╝  ██╔══██╗
███████║███████╗██║ ╚═╝ ██║██║  ██║██║ ╚████║   ██║   ██║╚██████╗     ╚████╔╝ ███████╗██║  ██║
╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝      ╚═══╝  ╚══════╝╚═╝  ╚═╝
]]
)

local vM = 0
local vm = 0
local vp = 0

local json_meta = nil
local json_saved = false

local function get_gversion()
    return string.format('version: v%u.%02u.%03u', vM, vm, vp)
end

-- returns true if file exists
function file_exists(file)
    local f = io.open(file, "rb")

    if f then f:close() end
    return f ~= nil
end

-- reads file into a string and returns
local function read_file(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read "*a" -- read whole file
    file:close()
    return content
end

local function get_version()
    local json_str = read_file("metadata.json")
    local obj, pos, err = json.decode(json_str, 1, nil)

    if err then
        print ("Error:", err)
        return nil
    else
        json_meta = obj -- store object
        vM = obj.version.major
        vm = obj.version.minor
        vp = obj.version.patch
        print (get_gversion())
        return ver
    end
end

local function increment_major()
    vM = vM + 1
    return vm
end

local function increment_minor()
    vm = vm + 1
    if vm > 99 then 
        vm = 0
        vp = 0 -- reset patch on rollover
        increment_major()
    end
    return vm
end


local function increment_patch()
    vp = vp + 1
    if vp > 999 then 
        vp = 0
        increment_minor()
    end
    return vp
end

local function save_meta(jsonobj)
    local json_str = json.encode(jsonobj, {indent = true})
    print("json:", json_str)
    local file = io.open("metadata.json", "w")
    if file then 
        file:write(json_str)
        file:close()
    else
        print("error opening metadata.json")
    end

end

parser
    :flag("-p --patch")
    :description("increment patch version")
    :action(increment_patch)

parser
    :flag("-m --minor")
    :description("increment minor version")
    :action(increment_minor)

parser
    :flag("-M --major")
    :description("increment major version")
    :action(increment_major)

parser
    :flag("--print")
    :description("print current version")
    :action(function() print(get_gversion()) end)

parser
    :flag("-s --save")
    :description("save current version to metadata.json")
    :action(
        function()
            if json_meta then
                json_meta.version.patch = vp
                json_meta.version.minor = vm
                json_meta.version.major = vM
                save_meta(json_meta)
                json_saved = true
            else
                print("error json_meta is nil")
            end
        end
    )

-- default: attempt to load version from file
get_version()
print("[DEBUG] start", get_gversion())
print("[DEBUG] executing args")
local args = parser:parse()

if json_saved then 
    print ("[EXIT] json saved to file")
else
    print("[EXIT] json not saved")
end
