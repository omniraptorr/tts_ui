local Logger = require("ge_tts/Logger")
local Instance = require("ge_tts/Instance")
local TableUtils = require("ge_tts/TableUtils")
local setLabelFactory = require("UIUtils/LabelFactory")

---@class LabelInstance : ge_tts__Instance

---@alias labels EditLabelParams[]

---@shape LabelInstance_SavedState : ge_tts__Instance_SavedState
---@field labels nil | labels

-- overloads for how the class will be constructed
---@class static_LabelInstance : ge_tts__static_Instance
---@overload fun(savedState: LabelInstance_SavedState): LabelInstance
---@overload fun(object: tts__Object): LabelInstance
---@overload fun(object: tts__Object, nilOrData: nil | labels,): LabelInstance
---@overload fun(guid: string, object: tts__Container): LabelInstance
---@overload fun(guid: string, object: tts__Container, nilOrData: nil | labels): LabelInstance
local LabelInstance = {}

LabelInstance.INSTANCE_TYPE = "Labeled Instance"

-- private functions go here as local functions so they won't show up in the return
---@param obj any
local function isContainer(obj)
    return type(obj) == "userdata" and (--[[---@type tts__Object]] obj).tag == "Bag" or (--[[---@type tts__Object]] obj).tag == "Deck"
end

setmetatable(LabelInstance, TableUtils.merge((Instance), {
    ---@param objOrGUIDOrSavedState tts__Object | string | LabelInstance_SavedState
    ---@param nilOrLabelsOrContainer nil | labels | tts__Container
    ---@param nilOrLabels nil | labels
    __call = function(_, objOrGUIDOrSavedState, nilOrLabelsOrContainer, nilOrLabels)
        ---@type LabelInstance
        local self

        ---@type labels
        local labels = {}

        -- handling the various overloads
        if LabelInstance.isSavedState(objOrGUIDOrSavedState) then
            local savedState = --[[---@type LabelInstance_SavedState]] objOrGUIDOrSavedState
            self = --[[---@type LabelInstance]] Instance(savedState)
            if savedState.labels then
                labels = --[[---@type labels]] savedState.labels
            end
        elseif type(objOrGUIDOrSavedState) == "string" and isContainer(nilOrLabelsOrContainer) then
            local guid = --[[---@type string]] objOrGUIDOrSavedState
            self = --[[---@type LabelInstance]] Instance(guid, --[[---@type tts__Container]] nilOrLabelsOrContainer)
            Logger.assert(self.getContainerPosition(), "Instance(): guid " .. guid .. " doesn't exist in container!") -- todo: move this check to Instance and make it optional
            if nilOrLabels then
                labels = --[[---@type labels]] nilOrLabels
            end
        elseif type(objOrGUIDOrSavedState) == "userdata" then
            self =  --[[---@type LabelInstance]] Instance(--[[---@type tts__Object]] objOrGUIDOrSavedState)
            if nilOrLabelsOrContainer then
                labels = --[[---@type labels]] nilOrLabelsOrContainer
            end
        else
            error("bad arguments to constructor!")
        end

        function self.notInContainer() -- technically an object could contain an object with guid same as itself but meh
            return self.getInstanceGuid() == self.getObject().getGUID()
        end

        local setLabel = setLabelFactory(self.getObject())

        -- now we create any labels we got from the constructor
        if self.notInContainer() then
            labels = TableUtils.map(labels, function(label)
                return setLabel(label)
            end)
        end

        ---@generic P : LabelParams
        ---@overload fun<P : LabelParams>(params: P): EditLabelParams
        ---@param labelParams P
        ---@param nilOrCreate nil | boolean @ whether to actually spawn the label. default true
        ---@return EditLabelParams
        function self.setLabel(labelParams, nilOrCreate)
            Logger.assert(self.notInContainer(), "tried to make label while inside container")
            local label = setLabel(labelParams, nilOrCreate)
            labels[label.index] = label
            return label
        end

        function self.onSpawned()
            setLabel = setLabelFactory(self.getObject())
            labels = TableUtils.map(labels, function(label)
                return setLabel(label)
            end)
        end

        function self.clearLabels()
            local realObj = self.getObject()
            TableUtils.map(labels, function(label)
                return realObj.removeButton(label.index)
            end)
            labels = {}
        end

        local superSave = self.save
        function self.save()
            if next(labels) then
                return TableUtils.merge(superSave(), {
                    labels = labels,
                })
            else
                return superSave()
            end
        end

        return self
    end,
    __index = Instance,
    -- other metamethods (e.g. arithmetic, pairs, etc) go here too.
}))

return LabelInstance