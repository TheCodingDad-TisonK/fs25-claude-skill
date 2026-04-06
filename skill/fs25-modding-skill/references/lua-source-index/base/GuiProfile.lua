









---GUI element display profile.
-- Holds GuiElement property data for re-use similar to a HTML/CSS definition.
local GuiProfile_mt = Class(GuiProfile)


---Create a new GuiProfile.
-- @param table profiles Reference to loaded profiles table for inheritance checking.
-- @param table traits Reference to loaded traits table for inheritance checking.
-- @return New GuiProfile instance
function GuiProfile.new(profiles, traits)
    local self = setmetatable({}, GuiProfile_mt)

    self.values = {}
    self.name = ""
    self.profiles = profiles
    self.traits = traits
    self.parent = nil

    return self
end


---Load profile data from XML.
-- @param entityId xmlFile XML file handle
-- @param string key Profile XML element node path
-- @param table presets Table of presets for symbol resolution, {preset name=preset value}
-- @param boolean? isTrait Whether this profile is a trait
-- @param boolean? isVariant
-- @return boolean success True if profile values could be loaded, false otherwise.
function GuiProfile:loadFromXML(xmlFile, key, presets, isTrait, isVariant)
    local name = getXMLString(xmlFile, key .. "#name")
    if name == nil then
        Logging.xmlWarning(xmlFile, "Missing name for a profile in XML file %s at path %s", getXMLFilename(xmlFile), key)
        return false
    end

    self.name = name
    self.isTrait = isTrait or false
    self.parent = getXMLString(xmlFile, key .. "#extends")
    self.isVariant = isVariant

    if self.parent == self.name then
        error("Profile " .. name .. " extends itself")
    end

    -- If this is not a trait, resolve traits
    if not isTrait then
        local traitsStr = getXMLString(xmlFile, key .. "#with")
        if traitsStr ~= nil then
            local traitNames = traitsStr:trim():split(" ")

            -- Copy all values, overwriting previous ones.
            -- This is resolving of the traits.
            for i, traitName in ipairs(traitNames) do
                local trait = self.traits[traitName]

                if trait ~= nil then
                    for traitValueName, value in pairs(trait.values) do
                        self.values[traitValueName] = value
                    end
                else
                    Logging.xmlWarning(xmlFile, "Trait-profile '%s' not found for trait '%s' at '%s'", traitName, self.name, key)
                end
            end
        end
    end

    local numElements = getXMLNumOfChildren(xmlFile, key)
    local oldFormatCount = 0
    for i = 0, numElements - 1 do
        local valueName = getXMLElementName(xmlFile, string.format("%s.*(%i)", key, i))
        local valueKey = key .. string.format(".%s(0)#value", valueName)

        --if old format is still used, we throw a warning
        if valueName == "Value" then
            valueName = getXMLString(xmlFile, key .. string.format(".Value(%i)#name", oldFormatCount))
            valueKey = key .. string.format(".Value(%i)#value", oldFormatCount)
            oldFormatCount = oldFormatCount + 1

            Logging.xmlWarning(xmlFile, "Gui profile '%s' still uses old format, please convert it to the new one", valueName)
        end

        local value = getXMLString(xmlFile, valueKey)
        if valueName == nil or value == nil or valueName == "Variant" then
            break
        end

        if value:startsWith("$preset_") then
            local preset = string.gsub(value, "$preset_", "")
            if presets[preset] ~= nil then
                value = presets[preset]
            else
                Logging.xmlWarning(xmlFile, "Preset '%s' it profile '%s' at '%s' is not defined", preset, name, valueKey)
            end
        end

        self.values[valueName] = value
    end

    return true
end


---Get a string value from this profile (and its ancestors) by name.
-- @param string name Name of attribute value to retrieve
-- @param string default Default value to use if the attribute is not defined.
-- @return string value
function GuiProfile:getValue(name, default)
    local ret = default

    -- Try a special case
    if self.values[name .. g_baseUIPostfix] ~= nil and self.values[name .. g_baseUIPostfix] ~= "nil" then
        ret = self.values[name .. g_baseUIPostfix]

    -- Try definition in the profile
    elseif self.values[name] ~= nil and self.values[name] ~= "nil" then
        ret = self.values[name]

    -- Try the profile itself
    else
        if self.parent ~= nil then
            -- Try parent
            local parentProfile
            if self.isVariant then
                parentProfile = self.profiles[self.parent]
            else
                -- Follow the path of special variants so top-level variants update all children
                parentProfile = g_gui:getProfile(self.parent)
            end

            if parentProfile ~= nil and parentProfile ~= "nil" then
                ret = parentProfile:getValue(name, default)
            else
                Logging.warning("Parent-profile '%s' not found for profile '%s'", self.parent, self.name)
            end
        end
    end

    return ret
end


---Get a boolean value from this profile (and its ancestors) by name.
-- @param string name Name of attribute value to retrieve
-- @param boolean default Default value to use if the attribute is not defined.
-- @return boolean bool
function GuiProfile:getBool(name, default)
    local value = self:getValue(name)
    local ret = default
    if value ~= nil and value ~= "nil" then
--#debug         Assert.assert(value:lower() == "true" or value:lower() == "false", "Invalid boolean", "Value %q for key %q is not a valid boolean string", value, name)
        ret = (value:lower() == "true")
    end

    return ret
end


---Get a number value from this profile (and its ancestors) by name.
-- @param string name Name of attribute value to retrieve
-- @param float default Default value to use if the attribute is not defined.
-- @return float number value of attribute if set, given 'default' otherwise
function GuiProfile:getNumber(name, default)
    local value = self:getValue(name)
    local ret = default
    if value ~= nil and value ~= "nil" then
        ret = tonumber(value)
--#debug         Assert.isNotNil(ret)
    end

    return ret
end
