local utils = require("wtkutils")
-- local log = utils.Log
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

AddPlayerPostInit(function(player)
    if IsWanda(player) then
        player:AddComponent("wandatimekit")
        player.components.wandatimekit:SetStages(stages)
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
