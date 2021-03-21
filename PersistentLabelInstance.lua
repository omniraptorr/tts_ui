local Logger = require("ge_tts/Logger")
local TableUtils = require("ge_tts/TableUtils")
local LabelInstance = require("UIUtils/LabelInstance")

---@class PersistentLabelInstance : LabelInstance

---@alias labels table<string, EditLabelParams> -- keys are button indexes. they're strings instead of numbers because TableUtils doesn't like sparse arrays

---@shape PersistentLabelInstance_SavedState : ge_tts__Instance_SavedState
---@field labels labels

-- overloads for how the class will be constructed
---@class static_PersistentLabelInstance : static_LabelInstance
---@overload fun(objOrSavedState: PersistentLabelInstance_SavedState | tts__Object): LabelInstance
---@overload fun(object: tts__Object, nilOrData: labels): LabelInstance
---@overload fun(guid: string, object: tts__Container): LabelInstance
---@overload fun(guid: string, object: tts__Container, nilOrData: nil | labels): LabelInstance
local PersistentLabelInstance = {}

PersistentLabelInstance.INSTANCE_TYPE = "Persistent Labeled Instance"

-- private functions go here as local functions so they won't show up in the return
---@param obj any
local function isContainer(obj)
    return type(obj) == "userdata" and (--[[---@type tts__Object]] obj).tag == "Bag" or (--[[---@type tts__Object]] obj).tag == "Deck"
end

setmetatable(PersistentLabelInstance, TableUtils.merge(LabelInstance, {
    ---@param classTable static_LabelInstance
    ---@param objOrGUIDOrSavedState tts__Object | string | PersistentLabelInstance_SavedState
    ---@param nilOrDataOrContainer nil | labels | tts__Container
    ---@param nilOrData nil | labels
    __call = function(classTable, objOrGUIDOrSavedState, nilOrDataOrContainer, nilOrData)
        ---@type LabelInstance
        local self

        ---@type labels
        local labels = {}

        ---@type nil | labels
        ---temp place to store the label data from constructor
        local nilOrLabelData

        -- handling the various overloads
        if PersistentLabelInstance.isSavedState(objOrGUIDOrSavedState) then
            self = --[[---@type PersistentLabelInstance]] LabelInstance(--[[---@type PersistentLabelInstance_SavedState]] objOrGUIDOrSavedState)
            nilOrLabelData = (--[[---@type PersistentLabelInstance_SavedState]] objOrGUIDOrSavedState).labels
        elseif type(objOrGUIDOrSavedState) == "string" and isContainer(nilOrDataOrContainer) then
            local guid = --[[---@type string]] objOrGUIDOrSavedState
            self = --[[---@type PersistentLabelInstance]] LabelInstance(guid, --[[---@type tts__Container]] nilOrDataOrContainer)
            nilOrLabelData = nilOrData
        elseif type(objOrGUIDOrSavedState) == "userdata" then
            self =  --[[---@type PersistentLabelInstance]] LabelInstance(--[[---@type tts__Object]] objOrGUIDOrSavedState)
            nilOrLabelData = --[[---@not tts__Container]] nilOrDataOrContainer
        else
            error("bad arguments to constructor!")
        end


        local superSetLabel = self.setLabel

        ---@generic P : LabelParams
        ---@overload fun<P : LabelParams>(params: P): EditLabelParams
        ---@param labelParams P
        ---@param nilOrCreate nil | boolean @ whether to actually spawn the label. default true
        ---@return EditLabelParams
        function self.setLabel(labelParams, nilOrCreate)
            local label = superSetLabel(labelParams, nilOrCreate)
            if nilOrCreate == true then
                labels[tostring(label.index)] = label
            end
            self.invalidateSavedState()
            return label
        end

        ---- now we set all the labels we got from constructor
        if nilOrLabelData and next(--[[---@not nil]] nilOrLabelData) then
            local startingLabelData = --[[---@not nil]] nilOrLabelData
            if startingLabelData then
                if self.notInContainer() then -- if obj exists we set the labels right away
                    TableUtils.map(--[[---@not nil]] startingLabelData, function(label)
                        return self.setLabel(label)
                    end)
                else -- else we just store them
                    labels = --[[---@not nil]] startingLabelData
                end
            end
        end

        local superSpawned = self.onSpawned
        function self.onSpawned()
            superSpawned()
            labels = TableUtils.map(labels, function(label)
                return self.setLabel(label)
            end)
        end

        function self.clearLabels()
            local realObj = self.getObject()
            TableUtils.map(labels, function(label)
                return realObj.removeButton(label.index)
            end)
            labels = {}
            self.invalidateSavedState()
        end

        local superSave = self.save
        function self.save()
            return TableUtils.merge(superSave(), {
                labels = labels
            })
        end


        return self
    end,
    __index = LabelInstance,
    -- other metamethods (e.g. arithmetic, pairs, etc) go here too.
}))

return LabelInstance