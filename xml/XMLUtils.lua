---@shape ColorBlockTable
---@field normal nil | tts__Color | tts__PlayerHandColor
---@field highlight nil | tts__Color | tts__PlayerHandColor
---@field pressed nil | tts__Color | tts__PlayerHandColor
---@field disabled nil | tts__Color | tts__PlayerHandColor

local colorBlockFields = {"normal", "highlight", "pressed", "disabled"}
---@param values ColorBlockTable
---@return tts__UIElement_ColorBlock
local function makeColorBlock(values)
	---@type string[]
	local out = {}
	for _,name in ipairs(colorBlockFields) do
		local value = values[name]
		if type(value) == string then
			table.insert(out, --[[---@type tts__PlayerHandColor]] value)
		elseif type(value) == table then
			table.insert(out, (--[[---@type tts__Color]] value):toHex())
		else
			table.insert(out, "")
		end
	end
	return table.concat(out, "|")
end

--example usage
--makeColorBlock({
--	pressed = Color(1, 1, 1),
--	disabled = "Blue",
--})

-- ripped from https://github.com/ccxvii/snippets/blob/master/xml.lua
-- could come in useful for storing arbitrary strings (such as json) in xml attributes. thanks eldin for the tip
local sbyte, schar = string.byte, string.char
local function sub_hex_ent(s) return sbyte(tonumber(s, 16)) end
local function sub_dec_ent(s) return schar(tonumber(s)) end
local gsub = string.gsub

---@param s string
---@return string
local function unescape(s)
	s = gsub(s, "&lt;", "<")
	s = gsub(s, "&gt;", ">")
	s = gsub(s, "&apos;", "'")
	s = gsub(s, "&quot;", '"')
	s = gsub(s, "&#x(%x+);", sub_hex_ent)
	s = gsub(s, "&#(%d+);", sub_dec_ent)
	s = gsub(s, "&amp;", "&")
	return s
end

---@param s string
---@return string
local function escape(s)
	s = gsub(s, "&", "&amp;")
	s = gsub(s, "<", "&lt;")
	s = gsub(s, ">", "&gt;")
	s = gsub(s, "'", "&apos;")
	s = gsub(s, '"', "&quot;")
	return s
end


return {
	makeColorBlock = makeColorBlock,
	escape = escape,
	unescape = unescape,
}
