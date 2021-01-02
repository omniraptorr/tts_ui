---@param guid string
local function naive_getObject(guid)
    return --[[---@not nil]] getObjectFromGUID(guid)
end

local lf = require("UIUtils/LabelFactory")
local vec2 = require("ge_tts/Vector2")

function onLoad()
  local bag = naive_getObject("222a81")
  local card = naive_getObject("4ea443")
  local deck = naive_getObject("6e575e")
  local tile = naive_getObject("0b75fa")
  local cube = naive_getObject("635247")
  local marble = naive_getObject("17c103")
  local board = naive_getObject("077ca6")

  local testObjs = {
    -- card,
    -- deck,
    tile,
    board,
    -- bag,
    -- cube,
  }

  for _, obj in ipairs(testObjs) do
    local width = 1000
    print(obj.name)
    local objCreateButton =  lf(--[[---@type tts__Object]] obj)
    objCreateButton({
        color = "Red",
        label = "at\nsmaller\nwidths\nit\nis\nless\nnoticeable",
        position = vec2{1,1},
        align = vec2{-1, 0},
    })
    objCreateButton({
        color = "Red",
        label = "but this longer one one overlaps a bit",
        position = vec2{1,0},
        align = vec2{-1, 0},
    })
  end
end