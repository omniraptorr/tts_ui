local serpent = require "IO/serpent-git/src/serpent"

---@type table<string, number>
local xml_order = {tag = 1, attributes = 2, value = 3, children = 4}
local function compareKeys(k1, k2)
	local v1 = xml_order[k1]
	local v2 = xml_order[k2]
	if not v1 or not v2 then
		return k1 < k2
	end
	return v1 < v2
end

---@param k string[]
local function mySort(k, o) -- k=keys, o=original table
	 table.sort(k, compareKeys)
end

---@param arg tts__UIElement[] | tts__Object
---@return string
local function out(arg)
	local XMLTable ---@type tts__UIElement[]
	local argType = type(arg)
	if argType == "userdata" then
		XMLTable = (--[[---@type tts__Object]] arg).UI.getXmlTable()
	elseif argType == "table" then
		XMLTable = --[[---@type tts__UIElement[] ]] arg
	else
		XMLTable = Global.UI.getXmlTable()
	end
	return serpent.block(XMLTable, { sortkeys = mySort, comment = false})
end

return out