version = "0.3.0" -- This is the version of the template. Change it to your own number.

description = [[
    Wanda's full function toolkit to well manage her time ;) 󰀫
    
    1. This mod will maintain 2 Wanda's age stages automatically. You may switch between them or turn off.
    2. Press mouse side key or the configurable hot key to use the Ageless Watch in the inventory or the backpack.
    3. When a recall watch is put in your inventory or a chest, you can ctrl + right-click to name it.

    ]]
    
description = description .. "󰀍 V " .. version

author = "Sean Xiaolu"

-- This is the URL name of the mod's thread on the forum; the part after the ? and before the first & in the url
forumthread = ""

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

-- Compatible with Don't Starve Together
dst_compatible = true

-- Not compatible with Don't Starve
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- Character mods are required by all clients
all_clients_require_mod = false

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- The mod's tags displayed on the server list
server_filter_tags = {}

-- This information tells other players more about the mod
local stringtbl = {
    {
        name = "Wanda Timekit",
        options = {
            titles = {
                heal = "Ageless Watch",
                backstep = "Backstep Watch"
            },
            stage1 = {
                label = "Stage 1",
                hover = "Age stage 1 to maintain can be swtiched between stage 1/2 and disable"
            },
            stage2 = {
                label = "Stage 2",
                hover = "Age stage 2 to maintain can be swtiched between stage 1/2 and disable"
            },
            keyhealmode = {
                label = "Age Stage Switch Key",
                hover = "Switch key to change different age stage",
            },
            keyheal = {
                label = "Ageless Watch Hot Key",
                hover = "Hot key to use Ageless Watch",
            },
            mouseheal = {
                label = "Ageless Watch Mouse Button",
                hover = "Mouse side button to use Ageless Watch. If your mouse only have one side button, don't change this"
            }
        },
        MOUSE_SIDEBUTTON = "Side Button",
        DISABLE = "Disable",
        ENABLE = "Enable"
    },
    ["zh"] = {
        name = "旺达辅助工具箱",
        options = {
            titles = {
                heal = "不老表",
                backstep = "倒走表"
            },
            stage1 = {
                label = "阶段1",
                hover = "保持年龄的配置，可以在阶段1/2和禁用之间切换"
            },
            stage2 = {
                label = "阶段2",
                hover = "保持年龄的配置，可以在阶段1/2和禁用之间切换"
            },
            keyhealmode = {
                label = "年龄模式热键",
                hover = "在不同年龄模式间切换",
            },
            keyheal = {
                label = "不老表的热键",
                hover = "",
            },
            mouseheal = {
                label = "不老表的鼠标侧键",
                hover = "如果只有一个鼠标侧边键，不要更改"
            }
        },
        MOUSE_SIDEBUTTON = "鼠标侧边键",
        DISABLE = "关闭",
        ENABLE = "打开"
    }
}

stringtbl["zht"] = stringtbl["zh"]
stringtbl["zhr"] = stringtbl["zh"]
local STRINGS = ChooseTranslationTable(stringtbl)

name = STRINGS.name

local function Title(title)
    local title = STRINGS.options.titles[name]
    return {
        name = name,
        label = title,
        options = {
            { description = "", data = false }
        },
        default = false,
    }
end

local function Option(name, optiontype, default)
    local option = STRINGS.options[name]
    option["name"] = name
    option["default"] = default
    local options = {}
    if optiontype == "key" then
        local keys = { "B", "C", "G", "H", "J", "K", "L", "N", "O", "P", "R", "T", "V", "X", "Z", "F1", "F2", "F3", "F4",
            "F5", "F6", "F7", "F8", "F9", "F10", "F11", "LSHIFT", "RSHIFT", "LCTRL", "RCTRL", "LALT", "RALT", "ALT",
            "CTRL", "SHIFT", "SPACE", "ENTER", "ESCAPE", "MINUS", "EQUALS", "BACKSPACE", "PERIOD", "SLASH", "LEFTBRACKET",
            "BACKSLASH", "RIGHTBRACKET", "TILDE", "PRINT", "SCROLLOCK", "PAUSE", "INSERT", "HOME", "DELETE", "END",
            "PAGEUP", "PAGEDOWN", "UP", "DOWN", "LEFT", "RIGHT", "KP_DIVIDE", "KP_MULTIPLY", "KP_PLUS", "KP_MINUS",
            "KP_ENTER", "KP_PERIOD", "KP_EQUALS" }
        for i = 1, #keys do
            options[i] = { description = keys[i], data = keys[i] }
        end
        option["options"] = options
    elseif optiontype == "mousesidebtn" then
        options = {
            {
                description = STRINGS.MOUSE_SIDEBUTTON .. " 1",
                data = 1005
            },
            {
                description = STRINGS.MOUSE_SIDEBUTTON .. " 2",
                data = 1006
            }
        }
    elseif optiontype == "age" then
        options[1] = { description = STRINGS.DISABLE, data = 0 }
        for i = 20, 79 do
            options[i - 18] = { description = "" .. i, data = i }
        end
    else
        options = {
            {
                description = STRINGS.ENABLE,
                data = true
            },
            {
                description = STRINGS.DISABLE,
                data = false
            }
        }
    end
    option["options"] = options
    return option
end

configuration_options = {
    Title(STRINGS.options.titles["heal"]),
    Option("stage1", "age", 73),
    Option("stage2", "age", 43),
    Option("keyhealmode", "key", "N"),
    Option("keyheal", "key", "X"),
    Option("mouseheal", "mousesidebtn", 1005)
}

-- mod_dependencies