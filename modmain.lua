local utils = require("wtkutils")
local log = utils.Log
local GetKeyCode = utils.GetKeyCode
local MOUSEBUTTON_SIDE1 = 1005
local MOUSEBUTTON_SIDE2 = 1006
local HEALTH_MAX = GLOBAL.TUNING.WANDA_MAX_YEARS_OLD - GLOBAL.TUNING.WANDA_MIN_YEARS_OLD
local HEALTH_OLD = HEALTH_MAX * GLOBAL.TUNING.WANDA_AGE_THRESHOLD_OLD
local HEALTH_YOUNG = HEALTH_MAX * GLOBAL.TUNING.WANDA_AGE_THRESHOLD_YOUNG
local HEALTH_HEAL = GLOBAL.TUNING.POCKETWATCH_HEAL_HEALING * 0.4

local function IsHUD()
    local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
    if not screen or not screen.name then
        log("Screen has no name")
        return
    end
    log("Screen name:" .. screen.name)

    return screen.name:find("HUD") ~= nil
end

local function IsWanda(inst)
    return inst and inst:HasTag("clockmaker") or (GLOBAL.ThePlayer and GLOBAL.ThePlayer:HasTag("clockmaker"))
end

local function FindItem(inst, name, tag)
    log("Finding watch...")
    local function Find(items)
        if items and type(items) == "table" then
            for k, v in pairs(items) do
                log("Checking " .. v.prefab)
                if v.prefab == name and v:HasTag(tag) then
                    log("Found watch with tag:" .. tag)
                    return v
                end
            end
        end
        return nil
    end

    if (inst and inst.replica and inst.replica.inventory) then
        log("Find watch in the inventory")
        local watch = Find(inst.replica.inventory:GetItems())
        if watch then
            return watch
        else
            local containers = inst.replica.inventory:GetOpenContainers()
            if not containers or type(containers) ~= "table" then
                return nil
            end
            for container_inst in pairs(containers) do
                log("Find watch in container:" ..
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

local function UseHealWatch()
    local inst = GLOBAL.ThePlayer
    if not inst or not IsWanda(inst) or not IsHUD() then
        return
    end

    local watch = FindItem(GLOBAL.ThePlayer, "pocketwatch_heal", "pocketwatch_inactive")
    if not watch then
        log("Heal watch is not avaliable.")
        return
    end
    GLOBAL.ThePlayer.replica.inventory:UseItemFromInvTile(watch)
end

local currentMode = nil
local function InitHealMode()
    currentMode = nil
    local stage1 = GetModConfigData("stage1")
    local stage2 = GetModConfigData("stage2")
    if stage1 == 0 and stage2 == 0 then
        return
    end

    local mode = { next = nil, age = 0 }
    local last = mode
    if stage2 > 0 then
        mode = { next = mode, age = stage2 }
        currentMode = mode
    end
    if stage1 > 0 then
        mode = { next = mode, age = stage1 }
        currentMode = mode
    end
    last.next = currentMode
end

local function SwitchHealMode()
    if currentMode and currentMode.next then
        currentMode = currentMode.next
        log("Current maintaining age is switched:" .. currentMode.age)
        GLOBAL.ThePlayer.components.talker:Say("Maintaining age:" .. (currentMode.age == 0 and "Disabled" or currentMode.age))
    end
end

local function GetMaintainedHealth()
    local health = (currentMode and currentMode.age > 0) and GLOBAL.TUNING.WANDA_MAX_YEARS_OLD - currentMode.age or 0
    log("Maintained age is:" .. (currentMode and currentMode.age or 0) .. " health:" .. health)
    return health
end

local function OnHealthDelta(inst, data)
    log("OnHealthDelta", data)

    if not data or type(data) ~= "table" then
        return
    end

    local current = 0
    if inst and inst.replica and inst.replica.health then
        current = inst.replica.health:GetCurrent()
    end

    if current <= 0 then
        return
    end
    log("Current health (age = 80 - current): " .. current)

    local isDamage = data.oldpercent > data.newpercent
    if isDamage and current <= GetMaintainedHealth() then
        UseHealWatch()
    end
end

local function WandaInit(inst)
    inst:ListenForEvent("healthdelta", OnHealthDelta)
end

AddPlayerPostInit(function(inst)
    if IsWanda(inst) then
        WandaInit(inst)
        InitHealMode()
    end
end)


AddSimPostInit(function()
    local KEY_HEAL = GetKeyCode(GetModConfigData("keyheal"))
    local KEY_HEALMODE = GetKeyCode(GetModConfigData("keyhealmode"))
    local MOUSE_HEAL = GetModConfigData("mouseheal")

    GLOBAL.TheInput:AddKeyHandler(function(key, down)
        if not down or key <= 0 then return end

        log("Key hit", { key = key, down = down })

        if key == KEY_HEAL then
            UseHealWatch()
        end

        if key == KEY_HEALMODE then
            SwitchHealMode()
        end
    end)

    GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y)
        if not down or button <= 0 then return end

        log("Mouse key hit", { btn = button, down = down })

        if button == MOUSE_HEAL then
            UseHealWatch()
        end
    end)
end)
