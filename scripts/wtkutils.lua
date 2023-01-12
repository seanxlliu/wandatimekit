local debug = true
local supportedLangs = { "en", "zh" }

local function log(message, params, always)
    if params then
        message = message .. " :(" .. type(params) .. ")" .. json.encode(params)
    end

    if not debug and not always then
        return
    end

    print("Wanda Timekit - " .. message)
end

local function GetTime()
    log("GetTimeRealSeconds" .. GetTimeRealSeconds())
end

local function ChooseTranslationTable(tbl, locale)
    tbl["zht"] = tbl["zh"]
    tbl["zhr"] = tbl["zh"]
    return tbl[locale] or tbl[1]
end

local function GetKeyCode(key)
    return _G["KEY_" .. key]
end

local function IsHUD()
    local screen = TheFrontEnd:GetActiveScreen()
    if not screen or not screen.name then
        log("Screen has no name")
        return false
    end
    -- log("Screen name:" .. screen.name)

    return screen.name:find("HUD") ~= nil
end

local function IsWanda(inst)
    local inst = inst or ThePlayer
    return inst
        and inst:IsValid()
        and inst:HasTag("clockmaker")
end

local function IsDead(inst)
    local inst = inst or ThePlayer
    return inst.replica
        and inst.replica.health
        and not inst.replica.health:IsDead()
end

local function FindItem(inst, name, tag)
    local function Find(items)
        if items and type(items) == "table" then
            for k, v in pairs(items) do
                -- log("Checking " .. v.prefab)
                if v.prefab == name and v:HasTag(tag) then
                    log("Found watch with tag:" .. tag)
                    return v
                end
            end
        end
        return nil
    end

    if (inst and inst.replica and inst.replica.inventory) then
        log("Finding " .. name ..  "," .. tag .. " in the inventory")
        local watch = Find(inst.replica.inventory:GetItems())
        if watch then
            return watch
        else
            local containers = inst.replica.inventory:GetOpenContainers()
            if not containers or type(containers) ~= "table" then
                return nil
            end
            for container_inst in pairs(containers) do
                log("Finding item in container:" ..
                    container_inst.prefab .. (container_inst:HasTag("backpack") and "(backpack)" or "(not backpack)"))
                local watch = Find(container_inst.replica.container:GetItems())
                if watch then
                    return watch
                end
            end
        end
    end
    return nil
end

return {
    Log = log,
    GetKeyCode = GetKeyCode,
    IsHUD = IsHUD,
    IsWanda = IsWanda,
    FindItem = FindItem,
}
