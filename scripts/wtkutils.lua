local Utils = {}
local debug = true
local supportedLangs = {"en", "zh"}

function Utils.Log(message, params, always)
    if params then
        message = message .. " :(" .. type(params) .. ")" .. json.encode(params)
    end

    if not debug and not always then
        return
    end

    print("Wanda Timekit - " .. message)
end

function Utils.GetTime()
    Utils.Log("GetTimeRealSeconds" .. GetTimeRealSeconds())
end

function Utils.ChooseTranslationTable(tbl, locale)
    tbl["zht"] = tbl["zh"]
    tbl["zhr"] = tbl["zh"]
    return tbl[locale] or tbl[1]
end

function Utils.GetKeyCode(key)
    return _G["KEY_" .. key]
end

return Utils
