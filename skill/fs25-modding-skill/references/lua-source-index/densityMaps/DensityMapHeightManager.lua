






















































---
local DensityMapHeightManager_mt = Class(DensityMapHeightManager, AbstractManager)




























































---Load data on map load
-- @return boolean true if loading was successful else false
function DensityMapHeightManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    DensityMapHeightManager:superClass().loadMapData(self)

    if g_addCheatCommands then
        -- server only cheats
        if g_server ~= nil then
            addConsoleCommand("gsTipCollisionsShow", "Shows the collisions for tipping on the ground", "consoleCommandShowTipCollisions", self)
            addConsoleCommand("gsTipCollisionsUpdate", "Updates the collisions for tipping on the ground around the current camera", "consoleCommandUpdateTipCollisions", self)
            addConsoleCommand("gsTipAnywhereAdd", "Tips a fillType", "consoleCommandTipAnywhereAdd", self, "fillTypeName; amount; [length]; [rows]; [spacing]")
            addConsoleCommand("gsTipAnywhereAddAll", "Tips a heap of every fill type that can be tipped", "consoleCommandTipAnywhereAddAll", self)
            addConsoleCommand("gsTipAnywhereClear", "Clears tip area", "consoleCommandTipAnywhereClear", self)
        end

        addConsoleCommand("gsDensityMapToggleDebug", "Toggles debug mode", "consoleCommandToggleDebug", self)
        addConsoleCommand("gsPlacementCollisionsShow", "Shows the collisions for placement and terraforming", "consoleCommandShowPlacementCollisions", self)
    end

    self:loadDefaultTypes(missionInfo, baseDirectory)
    local success = XMLUtil.loadDataFromMapXML(xmlFile, "densityMapHeightTypes", baseDirectory, self, self.loadDensityMapHeightTypes, missionInfo, baseDirectory)

    for i=#self.modDensityHeightMapTypeFilenames, 1, -1 do
        local filename = self.modDensityHeightMapTypeFilenames[i]

        local heightTypesXmlFile = loadXMLFile("heightTypes", filename)
        self:loadDensityMapHeightTypes(heightTypesXmlFile, missionInfo, baseDirectory, false)
        delete(heightTypesXmlFile)

        self.modDensityHeightMapTypeFilenames[i] = nil
    end

    return success
end
