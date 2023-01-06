local Utils = {}
local debug = true

function Utils.Log(message, params, always)
    if params then
        message = message .. " :(" .. type(params) .. ")" .. json.encode(params)
    end

    if not debug and not always then
        return
    end

    print("Wanda Timekit - " .. message)
end

return Utils
