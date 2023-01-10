local utils = require("wtkutils")
local log = utils.Log
local IsHUD = utils.IsHUD
local IsWanda = utils.IsWanda
local FindItem = utils.FindItem

local function OnHealthDelta(inst, data)
    inst.components.wandatimekit:OnHealthDelta(inst, data)
end

WandaTimeKit = Class(function(self, player)
    if not IsWanda(player) then
        self.player = nil
        log("Adding wandatimekit to player who is NOT Wanda!")
        return
    end

    self.player = player or ThePlayer
    self.enableAuto = true
    self.player:ListenForEvent("healthdelta", OnHealthDelta)
end)

function WandaTimeKit:OnRemoveFromEntity()
    self.player:RemoveEventCallback("healthdelta", OnHealthDelta)
end

function WandaTimeKit:SetStages(stages)
    -- linked list to store avaliable modes
    self.currentMode = nil
    local mode = { next = nil, age = 0 }
    local tail = mode

    if self.enableAuto then
        for i = #stages, 1, -1 do
            if stages[i] > 0 then
                mode = { next = mode, age = stages[i] }
            end
        end
    end

    if mode.next == nil then
        self.enableAuto = false
        self.currentMode = nil
    else
        tail.next = mode
        self.currentMode = mode
    end
end

function WandaTimeKit:UseHealWatch()
    if not self.player or not IsHUD() then
        return
    end

    local watch = FindItem(self.player, "pocketwatch_heal", "pocketwatch_inactive")
    if not watch then
        self.player.components.talker:Say("Heal watch is not avaliable.")
        return
    end

    if self.player.replica and self.player.replica.inventory then
        self.player.replica.inventory:UseItemFromInvTile(watch)
    else
        log("Cannot UseItemFromInvTile")
    end
end

function WandaTimeKit:SwitchHealMode()
    if self.currentMode and self.currentMode.next then
        self.currentMode = self.currentMode.next
        log("Current maintaining age is switched:" .. self.currentMode.age)
        self.player.components.talker:Say("Maintaining age:" ..
            (self.currentMode.age == 0 and "Disabled" or self.currentMode.age))
    end
end

function WandaTimeKit:OnHealthDelta(inst, data)
    log("OnHealthDelta", data)
    log("Inst is player? " .. tostring(inst == self.player))

    if not data or type(data) ~= "table" then
        return
    end

    if self.enableAuto and self.currentMode -- enabled auto heal
        and data.oldpercent > data.newpercent -- is damaging
        and inst
        and inst.replica
        and inst.replica.health
        and not inst.replica.health:IsDead() then

        local current = inst.replica.health:GetCurrent()
        local maintaining = (self.currentMode and self.currentMode.age > 0) and
            TUNING.WANDA_MAX_YEARS_OLD - self.currentMode.age or 0
        log("Current health (age = 80 - current): " ..
            current .. ", Maintained age is:" .. self.currentMode.age .. " maintaining:" .. maintaining)
        if (current <= maintaining) then
            self:UseHealWatch()
        end
    end
end

return WandaTimeKit
