local utils = require("wtkutils")
local log = utils.Log
local IsHUD = utils.IsHUD
local IsWanda = utils.IsWanda
local FindItem = utils.FindItem

local POSITION = {
    UNIQUE_ITEM = "u_",
    PLAYER = "p",
    BACKPACK = "b",
    UNIQUE_CONTAINERS = {
        "shadow_container",
        "chester", "hutch",
    }
}

local TRACKING_WATCHES = { "pocketwatch_recall", "pocketwatch_portal" }

local function GetIDByPosition(inst)
    assert(inst and inst.prefab)

    if inst == ThePlayer then
        return POSITION.PLAYER
    end

    if table.contains(POSITION.UNIQUE_CONTAINERS, inst.prefab) then
        return POSITION.UNIQUE_ITEM .. inst.prefab
    end

    -- To check replica.equippable.IsEquipped
    if inst:HasTag("backpack") then
        return POSITION.BACKPACK
    end

    if not inst:IsValid()
        or not inst.Transform
        or inst:HasTag("INLIMBO") then
        log("GetIDByPosition: inst is not valid")
        return false
    end

    assert(inst.replica and inst.replica.container)
    return string.format("c_%2.2f_%2.2f_%2.2f", inst.Transform:GetWorldPosition())
end

WandaTimeKit = Class(function(self, player)
    if not IsWanda(player) then
        self.player = nil
        log("Adding wandatimekit to player who is NOT Wanda!")
        return
    end

    self.player = player or ThePlayer
    self.enableAuto = true
    self.markerOwner = nil
    self.trackingWatchTable = {
        Entity = {}, -- inst.GUID = id
        Marker = {}, -- marker = id
        Position = {}, -- position = id
        Data = {} -- id = { alias }
    }

    self.persistname = "session_" ..
        (TheNet:GetSessionIdentifier() or "INVALID_SESSION") .. "_" .. (TheNet:GetUserID() or "INVALID_USERID") ..
        "_twv2"
    self:OnLoad()

    self.player:ListenForEvent("healthdelta", function(inst, data) self:OnHealthDelta(inst, data) end)
    -- self.player:ListenForEvent("itemget", function (inst, data)
    --     log("itemget:", tostring(inst), data.slot, tostring(data.item), debugstack())
    --     self:TrackWatch(data.item, inst, data.slot)
    -- end)
    self.player:ListenForEvent("itemlose", function(inst, data)
        -- log("itemlose:", tostring(inst), data.slot, tostring(data.item), debugstack())
        self:RemoveTrackingPosition(inst, data.slot)
    end)
    -- self.player:ListenForEvent("newactiveitem", _onnewactiveitem)
    -- self.player:ListenForEvent("equip", function(inst, data) log("equip:" .. strdata(data)) end)
    -- self.player:ListenForEvent("unequip", function(inst, data) log("unequip:" .. strdata(data)) end)
end)

--#region Use health watch

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
    if not self.player or not IsHUD() then
        return
    end

    if self.currentMode and self.currentMode.next then
        self.currentMode = self.currentMode.next
        log("Current maintaining age is switched:" .. self.currentMode.age)
        self.player.components.talker:Say("Maintaining age:" ..
            (self.currentMode.age == 0 and "Disabled" or self.currentMode.age))
    end
end

function WandaTimeKit:OnHealthDelta(inst, data)
    log("OnHealthDelta", data)
    -- log("Inst is player? " .. tostring(inst == self.player))

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

-- function WandaTimeKit:OnMarker(marker, watch, position)
--     -- about to mark with watch, use player position
--     if not marker and watch and position and self.player then
--         local x, y, z = self.player.Transform:GetWorldPosition()
--         local wid = TheShard:GetShardId()
--         local mid = string.format("w:%s_x:%f_y:%f_z:%f")
--         if not self.recallMap.Watch[watch.GUID] then
--             local id = #self.recallMap.Map
--         end
--     end
-- end

--#endregion

function WandaTimeKit:InitInvSlot(slot)
    local _self = self

    local _SetTile = slot._base.SetTile
    function slot:SetTile(tile)
        local inst = tile and tile.item or nil
        if inst and table.contains(TRACKING_WATCHES, inst.prefab) then
            -- log("Slot item:", (inst or "nil"), debugstack())
            _self:TrackWatch(inst, slot.container.inst, slot.num)
        end
        _SetTile(slot, tile)
    end

    local _OnControl = slot.OnControl
    function slot:OnControl(control, down)
        if down and control == CONTROL_SECONDARY
            and slot.tile and slot.tile.item and slot.tile.item.prefab
            and table.contains(TRACKING_WATCHES, slot.tile.item.prefab)
            and TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) then
            _self:NameWatch(slot)
            return true
        end

        return _OnControl(slot, control, down)
    end
end

--#region Name recall pocketwatch
-- Since all pocketwatch identical data are only stored on the server, we can only identify them in following ways
-- 1. When watch is in the inventory or backpack
-- 2. When watch is in the chest
-- 3. (TODO) Tracking the recallmark

function WandaTimeKit:NameWatch(slot)
    local config = {
        animbank = "ui_board_5x3",
        animbuild = "ui_board_5x3",
        menuoffset = Vector3(6, -70, 0),
        cancelbtn = {
            text = STRINGS.UI.TRADESCREEN.CANCEL,
            cb = function(_, _, w)
                -- log("cancelbtn!")
            end,
            control = CONTROL_CANCEL
        },
        acceptbtn = {
            text = STRINGS.UI.TRADESCREEN.ACCEPT,
            cb = function(_, _, w)
                local msg = TrimString(w:GetText())
                self:TrackWatch(slot.tile.item, slot.container.inst, slot.num, msg)
            end,
            control = CONTROL_ACCEPT
        }
    }

    ThePlayer:DoTaskInTime(0.5, function()
        ThePlayer.HUD:ShowWriteableWidget({ replica = {} }, config)
    end)
end

function WandaTimeKit:RemoveTrackingWatch(watch, removePosition)
    assert(watch)
    local dataid = self.trackingWatchTable.Entity[watch.GUID]
    if dataid then
        log("Remove watch:" .. watch.name .. " removePosition:" .. tostring(removePosition))
        if removePosition then
            table.removetablevalue(self.trackingWatchTable.Position, dataid)
        else
            self.trackingWatchTable.Entity[watch.GUID] = nil
        end
        if not table.contains(self.trackingWatchTable.Position, dataid) and
            self.trackingWatchTable.Entity[watch.GUID] == nil then
            self.trackingWatchTable.Data[dataid] = nil
        end
    end
end

function WandaTimeKit:RemoveTrackingPosition(container, slot)
    assert(container and slot > 0)
    local posid = GetIDByPosition(container)
    if posid then
        posid = posid .. "_" .. slot
        local dataid = self.trackingWatchTable.Position[posid]
        if dataid then
            log("Remove position:", container, slot)
            self.trackingWatchTable.Position[posid] = nil
            if not table.contains(self.trackingWatchTable.Entity, dataid) then
                self.trackingWatchTable.Data[dataid] = nil
            end
        end
    end
end

function WandaTimeKit:SetWatchAlias(watch, alias)
    if not alias then return end
    watch.name = STRINGS.NAMES[string.upper(watch.prefab)] .. "[" .. alias .. "]"
end

-- function WandaTimeKit:OnSlotRemove(watch, slot)
--     if not watch or not table.contains(TRACKING_WATCHES, watch.prefab) then
--         return
--     end

--     if slot and slot.container and slot.container.inst and slot.container.inst.replica then
--         if slot.container.inst:HasTag("backpack")
--             and not slot.container.inst.replica.equippable:IsEquipped() then
--             log(slot.container.inst.name .. " is unequipped")
--             self:RemoveTrackingWatch(watch, true)

--             -- if watch.oncontainerclose == nil then
--             --     watch.oncontainerclose = watch:DoTaskInTime(1, function(inst)
--             --         self:RemoveTrackingWatch(watch, true)
--             --         watch.oncontainerclose = nil
--             --     end)
--             -- end
--         end
--     end
-- end

function WandaTimeKit:TrackWatch(watch, container, slot, alias)
    if not watch or not container or not slot or not table.contains(TRACKING_WATCHES, watch.prefab) then
        return
    end

    -- if alias then
    --     alias = string.gsub(alias, '(\\[|\\])', '')
    -- end

    local posid = GetIDByPosition(container)
    if not posid then
        return
    end
    posid = posid .. "_" .. slot
    log("posid: " .. posid)

    local dataid = self.trackingWatchTable.Entity[watch.GUID]
    if dataid then
        log("update position")
        table.removetablevalue(self.trackingWatchTable.Position, dataid)
        self.trackingWatchTable.Position[posid] = dataid
    else
        dataid = self.trackingWatchTable.Position[posid]
        if dataid then
            log("recover tracking by position")
            self.trackingWatchTable.Entity[watch.GUID] = dataid
            assert(self.trackingWatchTable.Data[dataid])
            if not alias and self.trackingWatchTable.Data[dataid].alias then
                self:SetWatchAlias(watch, self.trackingWatchTable.Data[dataid].alias)
            end
        else
            log("new tracking watch")
            dataid = #self.trackingWatchTable.Data + 1
            self.trackingWatchTable.Entity[watch.GUID] = dataid
            self.trackingWatchTable.Position[posid] = dataid
            self.trackingWatchTable.Data[dataid] = {
                alias = alias or nil
            }
            watch:ListenForEvent("onremove", function(watch)
                -- log("on remove event")
                self:RemoveTrackingWatch(watch)
            end)
        end
    end

    assert(dataid)
    if alias then
        log("update alias")
        self.trackingWatchTable.Data[dataid].alias = alias
        self:SetWatchAlias(watch, alias)
    end
end

function WandaTimeKit:GetSaveNamingData()
    local data = {}

    data.Data = {}
    data.Position = {}

    for posid, dataid in pairs(self.trackingWatchTable.Position) do
        local d = self.trackingWatchTable.Data[dataid]
        if d and d.alias ~= nil and d.alias ~= "" then
            local i = #data.Data + 1
            data.Data[i] = d
            data.Position[posid] = i
        end
    end
    return data
end

function WandaTimeKit:LoadNamingData(data)
    if not data then return end
    self.trackingWatchTable.Position = data.Position or {}
    self.trackingWatchTable.Data = data.Data or {}
end

--#endregion

function WandaTimeKit:OnSave()
    if TheNet:GetIsClient() then

        local data = self:GetSaveNamingData()
        local str = json.encode(data)
        log("Saving data:\n" .. str)
        TheSim:SetPersistentString(self.persistname, str, true)

    end
    return {}
end

function WandaTimeKit:OnLoad()
    if TheNet:GetIsClient() then
        local data = {}
        TheSim:GetPersistentString(self.persistname, function(success, strdata)
            if success then
                log("Data is loaded:\n" .. strdata)
                data = json.decode(strdata)
            end
        end)
        self:LoadNamingData(data)
    end
    return {}
end

return WandaTimeKit
