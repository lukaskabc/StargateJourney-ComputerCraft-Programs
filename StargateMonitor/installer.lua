--        part of
--   Stargate Monitor
-- created by lukaskabc
--

local GITHUB_URL = "https://raw.githubusercontent.com/lukaskabc/StargateJourney-ComputerCraft-Programs/main/StargateMonitor/"

print("This installer will donwload all files for gate monitor")
printError("HTTP API has to be enabled in server config!")
print("There are two options, files can be downloaded from github or pastebin")
print("Download from github will always give you the newest code version available, but may require updating computercraft server config")
print("Pastebin download may give outdated versions")
print("GitHub requires allowed domain raw.githubusercontent.com")
print("Pastebin requires allowed domain pastebin.com")
print("")
print("1. GitHub")
print("2. Pastebin")

local option = read()
local usePastebin = false

if option == "1" or option == "Github" or option == "GitHub" or option == "github" then 
    usePastebin = false
elseif option == "2" or option == "Pastebin" or option == "pastebin" then 
    usePastebin = true
else
    error("Unknwon input: "..option)
end


local files = {
    {name = "1_cartouche.lua",      pastebin = "Bf4z6jFV"},
    {name = "dial.lua",             pastebin = "xdSLhDzR"},
    {name = "history.lua",          pastebin = "J7wuG3Zy"},
    {name = "chevrons.lua",         pastebin = "qfgpdbGb"},
    {name = "main.lua",             pastebin = "X8YYkSG2"},
    {name = "menu.lua",             pastebin = "B6VkyCDt"},
    {name = "status.lua",           pastebin = "WZiv6VV2"},
    {name = "universal_dialer.lua", pastebin = "yRMjjjn3"},
    {name = "utils.lua",            pastebin = "Bf4z6jFV"},


    -- FILES with content
    {name = "history.data", data={"{}"}},
    {name = "stargate.nfp", data={
        "ffffffffffff77777ffffffffffff",
        "fffffff777777111777777fffffff",
        "fffff7177777771777777717fffff",
        "ffff771177fffffffff771177ffff",
        "fff77777fffffffffffff77777fff",
        "ff77777fffffffffffffff77777ff",
        "f7177fffffffffffffffffff7717f",
        "f711fffffffffffffffffffff117f",
        "f777fffffffffffffffffffff777f",
        "7777fffffffffffffffffffff7777",
        "7777fffffffffffffffffffff7777",
        "7777fffffffffffffffffffff7777",
        "f777fffffffffffffffffffff777f",
        "f711fffffffffffffffffffff117f",
        "f7177fffffffffffffffffff7717f",
        "ff77777fffffffffffffff77777ff",
        "fff77777fffffffffffff77777fff",
        "ffff771177fffffffff771177ffff",
        "fffff7177777777777777717fffff",
        "fffffff777777777777777fffffff",
        "ffffffffffff77777ffffffffffff"
    }},
    {name = "wormhole.nfp", data={
        "ffffffffffff77777ffffffffffff",
        "fffffff777777111777777fffffff",
        "fffff7177777771777777717fffff",
        "ffff771177bbbbbbbbb771177ffff",
        "fff77777bbbbbbbbbbbbb77777fff",
        "ff77777bbbbbbbbbbbbbbb77777ff",
        "f7177bbbbbbbbbbbbbbbbbbb7717f",
        "f711bbbbbbbbbbbbbbbbbbbbb117f",
        "f777bbbbbbbbbbbbbbbbbbbbb777f",
        "7777bbbbbbbbbbbbbbbbbbbbb7777",
        "7777bbbbbbbbbbbbbbbbbbbbb7777",
        "7777bbbbbbbbbbbbbbbbbbbbb7777",
        "f777bbbbbbbbbbbbbbbbbbbbb777f",
        "f711bbbbbbbbbbbbbbbbbbbbb117f",
        "f7177bbbbbbbbbbbbbbbbbbb7717f",
        "ff77777bbbbbbbbbbbbbbb77777ff",
        "fff77777bbbbbbbbbbbbb77777fff",
        "ffff771177bbbbbbbbb771177ffff",
        "fffff7177777777777777717fffff",
        "fffffff777777777777777fffffff",
        "ffffffffffff77777ffffffffffff"
    }}
}

local function saveFile(filename, text)
    local f = io.open(filename, "w")
    f:write(text)
    f:flush()
    f:close()
end


for i, f in pairs(files) do
    print("Downloading " .. i .. " / " .. #files)

    if f.data ~= nil then
        saveFile(f.name, table.concat(f.data, "\n"))
    elseif usePastebin then
        shell.run("pastebin", "get", f.pastebin, f.name)
    else -- use github
        shell.run("wget", GITHUB_URL .. f.name, f.name)
    end

end


print("")
print("")
print("All files were downloaded")
print("Would you like to setup startup file which will automatically run StargateMonitor on computer startup ?")
print("yes/no")

local response = read()

if response == "yes" and not fs.exists("startup.lua") then
    saveFile("startup.lua", "shell.run(\"main.lua\")")
    print("File startup.lua created")
else
    if fs.exists("startup.lua") then
        printError("File startup.lua already exists")
    end
    print("Skipping autostart setup")
    print("Execute main.lua for start")
end


print("Installation finished")