local TableUtils = require("ge_tts/TableUtils")
local vec2 = require("ge_tts/Vector2")
local LoggerStatic = require("ge_tts/Logger")
local Logger = LoggerStatic()
Logger.setFilterLevel(LoggerStatic.DEBUG)
local getTransformScale = require("ge_tts/ObjectUtils").getTransformScale
require("UIUtils/BBCodeStringMethods")

local original_gmatch = string.gmatch
---@param pattern string
---@return fun():string
function string:gmatch(pattern)
    return --[[---@type fun():string]] original_gmatch(--[[---@type string]] self, pattern)
end

-- ripped from https://stackoverflow.com/a/19329565/592606
---@param s string
local function magicLines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

-- ripped from https://gist.github.com/tjakubo2/7b6248e765163ffcf9963ab1f59f3e18
---@type table<string, number>
local charWidthTable = {
    ['`'] = 2381, ['~'] = 2381, ['1'] = 1724, ['!'] = 1493, ['2'] = 2381,
    ['@'] = 4348, ['3'] = 2381, ['#'] = 3030, ['4'] = 2564, ['$'] = 2381,
    ['5'] = 2381, ['%'] = 3846, ['6'] = 2564, ['^'] = 2564, ['7'] = 2174,
    ['&'] = 2777, ['8'] = 2564, ['*'] = 2174, ['9'] = 2564, ['('] = 1724,
    ['0'] = 2564, [')'] = 1724, ['-'] = 1724, ['_'] = 2381, ['='] = 2381,
    ['+'] = 2381, ['q'] = 2564, ['Q'] = 3226, ['w'] = 3704, ['W'] = 4167,
    ['e'] = 2174, ['E'] = 2381, ['r'] = 1724, ['R'] = 2777, ['t'] = 1724,
    ['T'] = 2381, ['y'] = 2564, ['Y'] = 2564, ['u'] = 2564, ['U'] = 3030,
    ['i'] = 1282, ['I'] = 1282, ['o'] = 2381, ['O'] = 3226, ['p'] = 2564,
    ['P'] = 2564, ['['] = 1724, ['{'] = 1724, [']'] = 1724, ['}'] = 1724,
    ['|'] = 1493, ['\\'] = 1923, ['a'] = 2564, ['A'] = 2777, ['s'] = 1923,
    ['S'] = 2381, ['d'] = 2564, ['D'] = 3030, ['f'] = 1724, ['F'] = 2381,
    ['g'] = 2564, ['G'] = 2777, ['h'] = 2564, ['H'] = 3030, ['j'] = 1075,
    ['J'] = 1282, ['k'] = 2381, ['K'] = 2777, ['l'] = 1282, ['L'] = 2174,
    [';'] = 1282, [':'] = 1282, ['\''] = 855, ['"'] = 1724, ['z'] = 1923,
    ['Z'] = 2564, ['x'] = 2381, ['X'] = 2777, ['c'] = 1923, ['C'] = 2564,
    ['v'] = 2564, ['V'] = 2777, ['b'] = 2564, ['B'] = 2564, ['n'] = 2564,
    ['N'] = 3226, ['m'] = 3846, ['M'] = 3846, [','] = 1282, ['<'] = 2174,
    ['.'] = 1282, ['>'] = 2174, ['/'] = 1923, ['?'] = 2174, [' '] = 1282,
    ['avg'] = 2500
}

---@param str string
local function calcButtonSize(str) -- todo: improve precision etc
    str = str:stripBBCode()
    local len, height = 0, 0
    for line in magicLines(str) do
        height = height + 1
        local l = --[[---@type string]] line -- for luanalysis :|
        local newLen = 0
        for i = 1, #l do
            local c = l:sub(i,i)
            if charWidthTable[c] ~= nil then
                newLen = newLen + charWidthTable[c]
            else
                newLen = newLen + charWidthTable.avg
            end
        end
        if l:len() < 4 then -- extra padding for short labels
            newLen = newLen * 1.15
        end

        len = math.max(len, newLen)
    end

    return len / 5, height
end

-- some custom objects have the image flipped so it's actually upside down in local coords
-- since we care about alignment relative to the image we need to correct this
-- todo: add names into here as they come up
---@type table<string, boolean>
local invertedImgNames = {
    Card = true,
    Deck = true,
    Custom_Model_Bag = true,
    Custom_Model = true,
    Custom_Token = true,
}
local invertedImgVec = Vector(-1, 1, -1)

local buttonScale = 0.002 -- this is for converting button width to local coords
local fontSize = 1000
local baseLineHeight = 800
local baseScale = Vector(0.1, 0.1, 0.1)
--baseScale = Vector(1,1,1) -- for debug

local funcCount = 0
local funcPrefix = "__alignedButtonCallback_";
(--[[---@type table<string, any>]] _G)[funcPrefix] = function() end

---@param obj tts__Object
---@return fun(params: LabelParams): tts__ButtonParameters
local function labelFactory(obj)
    local objTransformScale = Vector(getTransformScale(obj))

    local halfSize = obj.getBoundsNormalized().size
        :scale(objTransformScale)
        :scale(Vector(-0.5, 0.5, 0.5)) -- for some reason button coords have the x inverted, we just sneak that in here.

    local baseRotation = 180

    if invertedImgNames[obj.name] then
        halfSize:scale(invertedImgVec)
        baseRotation = 0
    end

    local originalOffset = obj.getBounds().offset:scale(objTransformScale) -- the offset changes as you add buttons that extend the bounds, so we have to get it in advance.

    -- todo: add support for axis aligned rotation at least.
    ---@shape LabelParams : tts__ButtonParameters
    ---@field click_function nil | string | fun() | fun(obj: tts__Object) | fun(obj: tts__Object, player: tts__PlayerHandColor) | fun(obj: tts__Object, player: tts__PlayerHandColor, alt_click: boolean)
    ---@field label string
    ---@field click_function nil | string
    ---@field position nil | ge_tts__Vector2 | ge_tts__Vec2Shape @ scaled by the object's xz size. default {0,0}
    ---@field rotation nil | number | tts__VectorShape @ y axis rotation
    ---@field align nil | ge_tts__Vector2 | ge_tts__Vec2Shape @ scaled by the object's button size. default {0,0}
    ---@field y nil | number @ scaled by the object's y size. default 1
    ---@field height nil | number @ defaults to 900 (since font size is 1000)
    ---@field width  nil | number @ defaults to a length based on the label length
    ---@field scale nil | number | tts__VectorShape

    ---@overload fun(params: LabelParams): tts__ButtonParameters
    ---@param params LabelParams
    ---@param nilOrCreate nil | boolean @ whether to actually spawn the label. default true
    ---@return tts__ButtonParameters
    local function out(params, nilOrCreate)
        local create = nilOrCreate == nil and true or false

        local computedWidth, numLines = 0, 1
        if params.label then
            computedWidth, numLines = calcButtonSize(params.label)
        end
        local buttonHeight = params.height or numLines * baseLineHeight
        local buttonWidth = params.width or computedWidth

        local finalScale = baseScale:copy()
        if type(params.scale) == "number" then
            finalScale:scale(--[[---@type number]] params.scale)
        elseif type(params.scale) == "table" then
            finalScale:scale(Vector(--[[---@type tts__VectorShape]] params.scale))
        end

        local rotation = baseRotation
        local realButtonHeight, realButtonWidth = buttonHeight, buttonWidth
        if params.rotation then
            local rotParam = --[[---@not nil]] params.rotation
            if type(rotParam) == "table" then
                rotation = rotation + (--[[---@type tts__NumVectorShape]] rotParam)[2]
            else -- it's a number
                rotation = rotation + --[[---@type number]] rotParam
            end
            -- reference https://i.imgur.com/WKTTzSt.png
            local cos = math.abs(math.cos(math.rad(rotation)))
            local sin = math.abs(math.sin(math.rad(rotation)))
            realButtonHeight = buttonHeight * cos + buttonWidth * sin
            realButtonWidth = buttonWidth * cos + buttonHeight * sin
        end

        ---@type string
        local funcName = funcPrefix
        if type(params.click_function) == "function" then
            funcCount = funcCount + 1
            funcName = funcPrefix .. tostring(funcCount);
            (--[[---@type table<string, any>]] _G)[funcName] = params.click_function
        elseif type(params.click_function) == "string" then
            funcName = --[[---@type string]] params.click_function
        end

        local localObjPos = Vector(0, 1.01, 0)
        if params.position then
            local relativePos = vec2(--[[---@not nil]] params.position)
            localObjPos.x = relativePos.x
            localObjPos.z = relativePos.y
        end

        if params.y then
            localObjPos.y = --[[---@not nil]] params.y
        end
        if math.abs(localObjPos.y) == 1 then
            localObjPos.y = localObjPos.y * 1.01 -- dirty fix to prevent z fighting
        end

        localObjPos:scale(halfSize):sub(originalOffset)

        Logger.log("transform scale is " .. tostring(objTransformScale))
        Logger.log("offset is " .. tostring(originalOffset))
        if params.align then
            local align = vec2(--[[---@not nil]] params.align)
            -- todo: can't get them to line up :(
            localObjPos.x = localObjPos.x + align.x * realButtonWidth / 2 * buttonScale * finalScale.x / objTransformScale.x
            localObjPos.z = localObjPos.z + align.y * realButtonHeight / 2 * buttonScale * finalScale.z / objTransformScale.z
        end

        local finalRotation = Vector(0, rotation, 0)
        if obj.is_face_down then
            localObjPos.x = -localObjPos.x
            localObjPos.y = -localObjPos.y
            finalRotation.z = 180
        end

        local finalParams = TableUtils.merge(params, {
            click_function = funcName,
            position = localObjPos,
            width = buttonWidth,
            font_size = fontSize,
            height = buttonHeight,
            scale = finalScale,
            rotation = finalRotation,
        })

        if create then
            obj.createButton(--[[---@type tts__ButtonParameters]] finalParams)
        end

        return --[[---@type tts__ButtonParameters]] finalParams
    end

    return out
end

return labelFactory