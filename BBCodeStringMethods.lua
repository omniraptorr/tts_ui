---@param arg tts__Player | tts__Color | tts__ColorShape
function string:addColorTag(arg)
    ---@type tts__Color
    local argColor
    if type(arg) == "table" then
        argColor = Color(--[[---@type tts__Color]] arg)
    elseif type(arg) == "string" then
        argColor = Color.fromString(--[[---@type tts__PlayerColor]] arg)
    elseif type(arg) == "userdata" then
        argColor = Color.fromString((--[[---@type tts__Player]] arg).color)
    end
    return table.concat({ "[", argColor:toHex(false), "]", (--[[---@type string]] self), "[-]" })
end

---@type table<string, true>
local tagLiterals = {
    ["[-]"] = true,
    ["[b]"] = true,
    ["[/b]"] = true,
    ["[i]"] = true,
    ["[/i]"] = true,
    ["[u]"] = true,
    ["[/u]"] = true,
    ["[s]"] = true,
    ["[/s]"] = true,
    ["[sub]"] = true,
    ["[/sub]"] = true,
    ["[sup]"] = true,
    ["[/sup]"] = true,
}

---@param str string
local function checkTag(str)
    if tagLiterals[str] or str:match("%[%x%x%x%x%x%x%]") then
        return ""
    end
end

---@return string
function string:stripBBCode()
    return (self:gsub("%b[]", checkTag)) -- parens are to drop second return val from gsub
end