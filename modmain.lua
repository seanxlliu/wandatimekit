local utils = require("wtkutils")
local log = utils.Log
local GetKeyCode = utils.GetKeyCode
local IsWanda = utils.IsWanda
local MOUSEBUTTON_SIDE1 = 1005
local MOUSEBUTTON_SIDE2 = 1006
local HEALTH_MAX = GLOBAL.TUNING.WANDA_MAX_YEARS_OLD - GLOBAL.TUNING.WANDA_MIN_YEARS_OLD
local HEALTH_OLD = HEALTH_MAX * GLOBAL.TUNING.WANDA_AGE_THRESHOLD_OLD
local HEALTH_YOUNG = HEALTH_MAX * GLOBAL.TUNING.WANDA_AGE_THRESHOLD_YOUNG
local HEALTH_HEAL = GLOBAL.TUNING.POCKETWATCH_HEAL_HEALING * 0.4

local stages = {
    GetModConfigData("stage1"),
    GetModConfigData("stage2"),
}
local containers = require("containers")

AddPlayerPostInit(function(player)
    if IsWanda(player) and GLOBAL.TheWorld and not GLOBAL.TheWorld.ismastersim then
        player:AddComponent("wandatimekit")
        player.components.wandatimekit:SetStages(stages)
        print("Player component registered")
    end
end)

AddSimPostInit(function()
    local KEY_HEAL = GetKeyCode(GetModConfigData("keyheal"))
    local KEY_HEALMODE = GetKeyCode(GetModConfigData("keyhealmode"))
    local MOUSE_HEAL = GetModConfigData("mouseheal")

    GLOBAL.TheInput:AddKeyHandler(function(key, down)
        if not down or key <= 0 then return end

        -- log("Key hit", { key = key, down = down })
        if GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.wandatimekit then
            if key == KEY_HEAL then
                GLOBAL.ThePlayer.components.wandatimekit:UseHealWatch()
            end

            if key == KEY_HEALMODE then
                GLOBAL.ThePlayer.components.wandatimekit:SwitchHealMode()
            end
        end
    end)

    GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y)
        if not down or button <= 0 then return end

        -- log("Mouse key hit", { btn = button, down = down })

        if GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.wandatimekit then
            if button == MOUSE_HEAL then
                GLOBAL.ThePlayer.components.wandatimekit:UseHealWatch()
            end
        end
    end)
end)

AddClassPostConstruct("widgets/invslot", function(self)
    if (GLOBAL.ThePlayer and GLOBAL.ThePlayer.components and GLOBAL.ThePlayer.components.wandatimekit) then
        GLOBAL.ThePlayer.components.wandatimekit:InitInvSlot(self)
    end
end)

GLOBAL.ACTIONS.CAST_POCKETWATCH.stroverridefn = function(act, ...)
    if (GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_ATTACK)) then
        -- log("CONTROL_FORCE_ATTACK pressed strfn")
        return GLOBAL.STRINGS.SIGNS.MENU.ACCEPT
    end
    -- log("hooked strfn")
    return GLOBAL.STRINGS.ACTIONS.CAST_POCKETWATCH[GLOBAL.ACTIONS.CAST_POCKETWATCH.strfn(act, ...)]
        or GLOBAL.STRINGS.ACTIONS.CAST_POCKETWATCH.GENERIC
end

AddPrefabPostInitAny(function(inst)
    local type = containers.params[inst.prefab] and containers.params[inst.prefab].type or nil
    if type and table.contains({ "pack", "chest" }, type) then
        log("AddPrefabPostInitAny ListenForEvent:", type, tostring(inst))
        -- inst:ListenForEvent("itemget", function(container, data)
        --     log("itemget:", tostring(container), data.slot, tostring(data.item), GLOBAL.debugstack())
        --     GLOBAL.ThePlayer.components.wandatimekit:TrackWatch(data.item, container, data.slot)
        -- end)
        inst:ListenForEvent("itemlose", function(container, data)
            -- log("itemlose:", tostring(container), data.slot, tostring(data.item), GLOBAL.debugstack())
            local kit = GLOBAL.ThePlayer and GLOBAL.ThePlayer.components
                and GLOBAL.ThePlayer.components.wandatimekit or nil
            if kit then
                kit:RemoveTrackingPosition(container, data.slot)
            end
        end)
    end
end)



AddPrefabPostInit("pocketwatch_recall_marker", function(inst)
    log("pocketwatch_recall_marker spawned, is master:" .. tostring(GLOBAL.TheWorld.ismastersim))

    -- inst:DoPeriodicTask(1, function(inst)
    --     if inst and inst.Transform and inst.Transform.GetWorldPosition then
    --         local x, y, z = inst.Transform:GetWorldPosition()
    --         print(x, y, z)
    --     end
    -- end)
end)
