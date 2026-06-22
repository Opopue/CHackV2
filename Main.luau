local function load(url)
    local success, err = pcall(function()
        local code = game:HttpGet(url, true)
        local fn, loadErr = loadstring(code)
        if fn then fn()
        else warn("Syntax Fehler: " .. tostring(loadErr)) end
    end)
    if not success then
        warn("Fehler: " .. url .. " - " .. tostring(err))
    end
end

local base = "https://raw.githubusercontent.com/Opopue/CHackV2/main/"

load(base .. "CHackV2_Core.luau")
task.wait(0.2)
load(base .. "CHackV2_Logic.luau")

print("CHack loaded! RShift to open.")
