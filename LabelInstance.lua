local Logger = require("ge_tts/Logger")
local Instance = require("ge_tts/Instance")
local TableUtils = require("ge_tts/TableUtils")
local setLabelFactory = require("UIUtils/LabelFactory")

---@class LabelInstance : ge_tts__Instance

-- overloads for how the class will be constructed
---@class static_LabelInstance : ge_tts__static_Instance
---@overload fun(objectOrSavedState: tts__Object | ge_tts__Instance_SavedState): LabelInstance
---@overload fun(guid: string, container: tts__Container): LabelInstance
local LabelInstance = {}

LabelInstance.INSTANCE_TYPE = "Labeled Instance"

-- private functions go here as local functions so they won't show up in the return
---@param obj any
local function isContainer(obj)
    return type(obj) == "userdata" and (--[[---@type tts__Object]] obj).tag == "Bag" or (--[[---@type tts__Object]] obj).tag == "Deck"
end

setmetatable(LabelInstance, TableUtils.merge(Instance, {
    ---@param classTable static_LabelInstance
    ---@param objOrGUIDOrSavedState tts__Object | string | ge_tts__Instance_SavedState
    ---@param nilOrDataOrContainer nil | tts__Container
    __call = function(classTable, objOrGUIDOrSavedState, nilOrDataOrContainer)
        ---@type LabelInstance
        local self

        -- handling the various overloads
        if LabelInstance.isSavedState(objOrGUIDOrSavedState) then
            self = --[[---@type LabelInstance]] Instance(--[[---@type ge_tts__Instance_SavedState]] objOrGUIDOrSavedState)
        elseif type(objOrGUIDOrSavedState) == "string" and isContainer(nilOrDataOrContainer) then
            local guid = --[[---@type string]] objOrGUIDOrSavedState
            self = --[[---@type LabelInstance]] Instance(guid, --[[---@type tts__Container]] nilOrDataOrContainer)
            Logger.assert(self.getContainerPosition(), "Instance(): guid " .. guid .. " doesn't exist in container!") -- todo: move this check to Instance and make it optional
        elseif type(objOrGUIDOrSavedState) == "userdata" then
            self =  --[[---@type LabelInstance]] Instance(--[[---@type tts__Object]] objOrGUIDOrSavedState)
        else
            error("bad arguments to constructor!")
        end

        function self.notInContainer() -- technically an object could contain an object with guid same as itself but meh. won't fix
            return self.getInstanceGuid() == self.getObject().getGUID()
        end

        local setLabel = setLabelFactory(self.getObject())

        ---@generic P : LabelParams
        ---@overload fun<P : LabelParams>(params: P): EditLabelParams
        ---@param labelParams P
        ---@param nilOrCreate nil | boolean @ whether to actually spawn the label. default true
        ---@return EditLabelParams
        function self.setLabel(labelParams, nilOrCreate)
            Logger.assert(self.notInContainer(), "error: tried to set label while inside container!")
            return setLabel(labelParams, nilOrCreate == nil and true or false)
        end

        return self
    end,
    __index = Instance,
    -- other metamethods (e.g. arithmetic, pairs, etc) go here too.
}))

return LabelInstance