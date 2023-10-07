local addonName, WrathRandomMounter = ...

SLASH_WRM1 = "/WRM"
local inDebugMode = false
local defaultCategoryWeight = 100
local defaultMountWeight = 100

local mounted = IsMounted -- make a local copy of the function and not the result of one execution
local inCombat = InCombatLockdown -- make a local copy of the function and not the result of one execution
local ridingSkill = 0
local flyable = IsFlyableArea -- make a local copy of the function and not the result of one execution
local indoors = IsIndoors -- make a local copy of the function and not the result of one execution
local currentlyFlyable = flyable()
local CurrentlyIndoors = indoors()
englishFaction, localizedFaction = UnitFactionGroup("player")
playerFaction = englishFaction

--Variables to store player mounts {{creatureSpellID, name, mountID, isGroundMount, isFlyingMount, isSwimmingMount}, ...}
local myMounts = {
  ["UsableMounts"] = {},
  ["KnownMounts"] = {}
}

--Variables to store player mount categories
local myMountsCategories = {
  ["UsableMountsCategories"] = {},
  ["KnownMountsCategories"] = {}
}

--Variables to store mounts by category {{creatureSpellID, name, mountID, isGroundMount, isFlyingMount, isSwimmingMount}, ...}
currentMounts = {
  ["myMountsGround"] = {},
  ["myMountsFlying"] = {},
  ["myMountsSwimming"] = {}
}

local function LocalizeMountName() --Get Localized Mount Names
  for mount in pairs(WrathRandomMounter.itemMounts) do --Loop over all possible mounts from Mounts.lua
    --1:Name, 2:SpellID, 4:MaxSpeed, 5:MinSpeed, 6:SwimSpeed, 7:Category, 9:NormalMount, 10:AQMount
    --ridingSkill 75:0.6, 150:1, 225:1.5, 300:2.8, 375:3.1
    name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(WrathRandomMounter.itemMounts[mount][2])
    WrathRandomMounter.itemMounts[mount][1] = name
  end
end

local function tablelength(T) --Returns the number of elements in a table
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end


local function GetRidingSkill()
  --ridingSkill 75:0.6, 150:1, 225:1.5, 300:2.8, 375:3.1
  if IsPlayerSpell(33388, false) then--75
    ridingSkill = 75
  end
  if IsPlayerSpell(33391, false) then--150
    ridingSkill = 150
  end
  if IsPlayerSpell(34090, false) then--225
    ridingSkill = 225
  end
  if IsPlayerSpell(34091, false) then--300
    ridingSkill = 300
  end

  if inDebugMode then
    print("RidingSkill: " .. tostring(ridingSkill))
  end
end

--Create delay function
local waitTable = {};
local waitFrame = nil;

function wrm_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

local function PrintMountTypeID(name)
  name = string.lower(name)
  mountFound = false
  for mountmyMoutsID in pairs(myMounts["KnownMounts"]) do
    mountName = myMounts["KnownMounts"][mountmyMoutsID][2]
    mountNameLower = string.lower(mountName)
    if mountNameLower == name then
      creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(myMounts["KnownMounts"][mountmyMoutsID][3])
      mountFound = true
      print(name .. ": " .. tostring(mountTypeID))
    end
  end

  if mountFound == false then
    print (name .. ": was not found")
  end
end

local function PrintMounts(mountList)
  orderedMounts = {}
  for myMountsID in pairs(mountList) do
    table.insert(orderedMounts, mountList[myMountsID][2])
  end
  table.sort(orderedMounts)

  print("Mounts...")
  for mountOrderID in pairs(orderedMounts) do
    weight = SavedMountWeights[orderedMounts[mountOrderID]]
    if weight == nil then
      weight = defaultMountWeight
    end
    print(orderedMounts[mountOrderID] .. ": " .. tostring(weight))
  end
  print(tablelength(orderedMounts) .. " Mounts Total")
end

local function PrintCategories()
  categories = {}

  -- get categoryies
  for i, mount in ipairs(myMounts["KnownMounts"]) do
    categorieName = mount[7]
    categorieWeight = SavedMountCategoriesWeights[categorieName]
    if categorieWeight == nil then
      categorieWeight = defaultCategoryWeight
    end
    categories[tostring(categorieName)] = categorieWeight
  end

  orderedCategories = {}
  for categoryName in pairs(categories) do
    table.insert(orderedCategories, categoryName)
  end
  table.sort(orderedCategories)

  print("MountCategories...")
  for categoryorderID in pairs(orderedCategories) do
    print(orderedCategories[categoryorderID] .. ": " .. tostring(categories[orderedCategories[categoryorderID]]))
  end
end

-- Returns a mount string that is of type mountType
local function GetRandomMount(mountArray)
  local mount
  mountList = mountArray

  if RandomMode == "Category" then
    categories = {}
    categorie = nil
    mounts = {}
    mount = nil

    -- get categoryies
    for i, mount in ipairs(mountList) do
      categorieName = mount[7]
      categorieWeight = SavedMountCategoriesWeights[categorieName]
      if categorieWeight == nil then
        categorieWeight = defaultCategoryWeight
      end
      categories[tostring(categorieName)] = categorieWeight
    end
    
    -- get rollRange for each category
    maxRollRange = 0
    categorieRollRange = {}
    for categorieName, categorieRange in pairs(categories) do
      categorieRollRange[categorieName] = {maxRollRange, maxRollRange + categorieRange}
      maxRollRange = maxRollRange + categorieRange
    end

    -- roll category
    if maxRollRange > 0 then
      local categoryRoll = math.random(maxRollRange)
      for categorieName, categorieRollRange in pairs(categorieRollRange) do
        if categoryRoll > categorieRollRange[1] and categoryRoll <= categorieRollRange[2] then
          categorie = categorieName
        end
      end
    end

    -- get mounts
    for i, mount in ipairs(mountList) do
      mountName = mount[2]
      categorieName = mount[7]
      if categorieName == categorie then
        mountWeight = SavedMountWeights[mountName]
        if mountWeight == nil then
          mountWeight = defaultMountWeight
        end
        mounts[tostring(mountName)] = mountWeight
      end
    end

    -- get rollRange for each mount
    maxRollRange = 0
    mountsRollRange = {}
    for mountName, mountRange in pairs(mounts) do
      mountsRollRange[mountName] = {maxRollRange, maxRollRange + mountRange}
      maxRollRange = maxRollRange + mountRange
    end

    -- roll mount
    if maxRollRange > 0 then
      local mountRoll = math.random(maxRollRange)
      for mountName, mountRollRange in pairs(mountsRollRange) do
        if mountRoll > mountRollRange[1] and mountRoll <= mountRollRange[2] then
          mount = mountName
        end
      end
    end
  end

  return mount
end

local function GetRandomMounts()
  local groundMount = GetRandomMount(currentMounts["myMountsGround"])
  local flyingMount = GetRandomMount(currentMounts["myMountsFlying"])
  local swimmingMount = GetRandomMount(currentMounts["myMountsSwimming"])

  return groundMount, flyingMount, swimmingMount
end

--Update ingame macro with the new groundMount, flyingMount, swimmingMount
local function UpdateMacro(groundMount, flyingMount, swimmingMount)
    --#showtooltip
    --/stopcasting
    --/cast [nomounted,mod:alt] GroundMount
    --/cast [nomounted,swimming] SwimmingMount
    --/cast [nomounted,flyable] FlyingMount
    --/cast [nomounted] GroundMount
    --/WRM
    --/dismount

    local groundMountString = ""
    local groundMountString2 = ""
    local flyingMountString = ""
    local swimmingMountString = ""
    local tooltip = ""

    --Get the correct string for the different lines of the macro
    if groundMount ~= nil then
      groundMountString = "\n/cast [nomounted,mod:alt] " .. tostring(groundMount)
      groundMountString2 = "\n/cast [nomounted] " .. tostring(groundMount)
      tooltip = tostring(groundMount)
    end
    if flyingMount ~= nil then
      flyingMountString = "\n/cast [nomounted,flyable] " .. tostring(flyingMount)
      if 	IsFlyableArea() then
        tooltip = tostring(flyingMount)
      end
    end
    if swimmingMount ~= nil then
      swimmingMountString = "\n/cast [swimming] " .. tostring(swimmingMount)
    end

    --Join all the lines of the macro together
    --tooltip can be added after '#showtooltip' was removed due to consern about macro length exceeding 255 chars
    local body = "#showtooltip " .. "\n/stopcasting" .. groundMountString .. swimmingMountString .. flyingMountString .. groundMountString2 .. "\n/WRM" .. "\n/dismount"

    --Save the macro
    macroIndex = GetMacroIndexByName("Mount")
    if macroIndex == 0 then
      CreateMacro("Mount", "INV_MISC_QUESTIONMARK", body, nil)
    else
      EditMacro("Mount", "Mount", nil, body, 1, 1)
    end
end

--Check if table contains element
local function tableContains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

--Updates the mount tables based on the companion API
local function UpdateMyMounts()

  myMounts["UsableMounts"] = {}
  myMounts["KnownMounts"] = {}
  currentMounts = {
    ["myMountsGround"] = {},
    ["myMountsFlying"] = {},
    ["myMountsSwimming"] = {}
  }
  
  mountIDs = C_MountJournal.GetMountIDs() --List of all avalible MountIDs
  mountCounter = 1 --loop counter
  while mountCounter <= #mountIDs do
    name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountIDs[mountCounter])
    creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)


    --1:Name, 2:SpellID, 4:MaxSpeed, 5:MinSpeed, 6:SwimSpeed, 7:Category, 9:NormalMount, 10:AQMount
    if spellID ~= nil and name ~= nil then
      category = nil
      localMount = WrathRandomMounter.itemMounts[tostring(spellID)]

      if localMount ~= nil then
        category = WrathRandomMounter.itemMounts[tostring(spellID)][7]
      else
        --print("the mount with spellID " .. tostring(spellID) .. "was not found")
      end
    end
    
    --print details to check them
    if name == "Felsteed" and debug then
      print(name .. " isActive: " .. tostring(isActive))
      print(name .. " isUsable: " .. tostring(isUsable))
      print(name .. " sourceType: " .. tostring(sourceType))
      print(name .. " shouldHideOnChar: " .. tostring(shouldHideOnChar))
      print(name .. " isCollected: " .. tostring(isCollected))
      print(name .. " mountID: " .. tostring(mountID))
    end

    --convert to the old variables
    creatureID = nil
    creatureName = name
    creatureSpellID = spellID
    icon = icon
    issummoned = isActive
    moutType = nil

    isGroundMount = false
    isFlyingMount = false
    IsSwimmingMount = false

    if mountTypeID == 230 then
      isGroundMount = true
    elseif mountTypeID == 231 then
      isSimmingMount = true
    elseif mountTypeID == 232 then
      isSimmingMount = true
    elseif mountTypeID == 241 then
      isGroundMount = true
    elseif mountTypeID == 247 then
      isFlyingMount = true
    elseif mountTypeID == 248 then
      isFlyingMount = true
    elseif mountTypeID == 254 then
      isSimmingMount = true
    elseif mountTypeID == 269 then
      isGroundMount = true
    elseif mountTypeID == 284 then
      isGroundMount = true
    elseif mountTypeID == 398 then
      isFlyingMount = true
    elseif mountTypeID == 402 then
      isFlyingMount = true
    elseif mountTypeID == 408 then
      isFlyingMount = true
    elseif mountTypeID == 412 then
      isFlyingMount = true
    elseif mountTypeID == 424 then
      isFlyingMount = true
    end

    if (playerFaction == "Alliance" and (faction == nil or faction == 1)) or (playerFaction == "Horde" and (faction == nil or faction == 0)) then --Correct Faction
      if isCollected and not shouldHideOnChar then --Have mount and usable on character
        mount = {creatureSpellID, name, mountID, isGroundMount, isFlyingMount, isSwimmingMount, category}
        table.insert(myMounts["KnownMounts"], mount)
        if isUsable then --Usable in current zone
          table.insert(myMounts["UsableMounts"], mount)

          if isGroundMount then
            table.insert(currentMounts["myMountsGround"], mount)
          end
          if isFlyingMount then
            table.insert(currentMounts["myMountsFlying"], mount)
          end
          if isSwimmingMount then
            table.insert(currentMounts["myMountsSwimming"], mount)
          end

        end
      end
    end
    mountCounter = mountCounter + 1
  end

  if inDebugMode then
    PrintMounts(myMounts["KnownMounts"])
    PrintMounts(myMounts["UsableMounts"])
  end
end

local function UpdateMountMacro(forceUpdate)
  local groundMount, flyingMount, swimmingMount = GetRandomMounts()
  if (not IsMounted() or forceUpdate) and not inCombat() then --Only update macro if player is not mounted and delay by 0.1s so macro is not being updated while it is being run.
    UpdateMacro(groundMount, flyingMount, swimmingMount)
  end
end

--Gets mounts and updates macro when addon is loaded.
local function InitialStartup(self, event, ...)
  GetRidingSkill()
  LocalizeMountName()
  UpdateMyMounts() --Update mount table with current mounts
  UpdateMountMacro(true)
end

local function updateSavedWeightTo100()
  for mountName, weight in pairs(SavedMountWeights) do
    SavedMountWeights[mountName] = 100 * weight
  end
  print("Mount weights have been updated")

  for categorieName, weight in pairs(SavedMountCategoriesWeights) do
    SavedMountCategoriesWeights[categorieName] = 100 * weight
  end
  print("Mount category weights have been updated")
end

--Changes saved variables from nil to empty lists
local function InitialStartupOfSavedVariables()
  if SavedMountWeights == nil then
    SavedMountWeights = {}
  end
  if SavedMountCategoriesWeights == nil then
    SavedMountCategoriesWeights = {}
  end
  if RandomMode == nil then
    RandomMode = "Category" --Category, Mount
  end
  if SettingsVersion == nil then
    SettingsVersion = 0
  end

  if SettingsVersion < 1 then
    updateSavedWeightTo100()
    SettingsVersion = 1
  end
end

--Handles the entering world event
local function InitialStartupHandler(self, event, ...)
  InitialStartupOfSavedVariables()
  InitialStartup(self, event, ...) --Gets the addon into a usable state
  wrm_wait(10, InitialStartup, self, event, ...) --Reruns startup incase parts of the API had not started yet (Updating Macros can fail if called too early)
end

local function stringStarts(String,Start) -- Check if string starts with the given string
  return string.sub(String,1,string.len(Start))==Start
end

local function splitString(stringToSplit)
  sep = "%s"
  local t={}
  for str in string.gmatch(stringToSplit, "([^"..sep.."]+)") do
          table.insert(t, str)
  end
  return t
end

local function SaveCategory(categoryName, categoryValue)
  print("set category: " .. categoryName .. ", " .. categoryValue)
  mountCategoryFound = false
  for mountIndex, mount in ipairs(myMounts["KnownMounts"]) do
    if string.lower(categoryName) == string.lower(tostring(mount[7])) then
      mountCategoryFound = true
      categoryName = mount[7]
    end
  end

  if mountCategoryFound then
    if tonumber(categoryValue) ~= nil then
      SavedMountCategoriesWeights[categoryName] = tonumber(categoryValue)
    else
      print("Needs to be an integer, current default is: " .. tostring(defaultCategoryWeight))
    end
  else
    print("Category \"" .. categoryName .. "\" could not be found")
  end
  InitialStartup()
end

local function SaveMount(mountName, mountValue)
  print("set mount: " .. mountName .. ", " .. mountValue)
  mountFound = false
  for mountIndex, mount in ipairs(myMounts["KnownMounts"]) do
    if string.lower(mountName) == string.lower(mount[2]) then
      mountFound = true
      mountName = mount[2]
    end
  end
  if mountFound then
    if tonumber(mountValue) ~= nil then
      SavedMountWeights[mountName] = tonumber(mountValue)
    else
      print("Needs to be an integer, current default is: " .. tostring(defaultMountWeight))
    end
  else
    print("Mount \"" .. mountName .. "\" could not be found")
  end
  InitialStartup()
end

--Captures console commands that are entered
--/wrm Set Category Glider 0

local function DumpMounts()
  DumpAllMounts = {}

  mountIDs = C_MountJournal.GetMountIDs() --List of all avalible MountIDs
  mountCounter = 1 --loop counter
  while mountCounter <= #mountIDs do
    name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountIDs[mountCounter])
    creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)
    

    if name ~= nil then
      if mountCounter == 1 then
        print(name)
      end
      DumpAllMounts[name] = {mountID, name, spellID, mountTypeID}
    end
    
    mountCounter = mountCounter + 1
  end
  print("List of mounts was Saved")
end

local function WRMHandler(parameter)
  if(string.len(parameter) > 0) then --If a parameter was supplied
    parameterLower = string.lower(parameter)
    if parameterLower == "list" then
      PrintMounts(myMounts["KnownMounts"]) --Prints players mounts to console
    elseif parameterLower == "list usable" then
        PrintMounts(myMounts["UsableMounts"]) --Prints players mounts to console
    elseif parameterLower == "list ground" then
        PrintMounts(currentMounts["myMountsGround"]) --Prints players mounts to console
    elseif parameterLower == "list flying" then
        PrintMounts(currentMounts["myMountsFlying"]) --Prints players mounts to console
    elseif parameterLower == "listcategories" then
      PrintCategories()
    elseif parameterLower == "update" then
      InitialStartup() --Rerun Startup to capture new mounts
    elseif parameterLower == "debug" then
      inDebugMode = not inDebugMode --Change the debug state of the addon
      print('DebugMode Changed to: ' .. tostring(inDebugMode))
    elseif stringStarts(parameterLower, "mounttype") then
      splitParameter = splitString(parameter)
      mountName = string.sub(parameter, 11, string.len(parameter)) --"mounttype"
      PrintMountTypeID(mountName)
    elseif parameterLower == "settings" then
      print("Current Settings Version: " .. tostring(SettingsVersion))
    elseif stringStarts(parameterLower, "set") then
      splitParameter = splitString(parameter)
      if string.lower(splitParameter[2]) == "category" then
        setType = string.sub(parameter, 13, string.len(parameter)) --"Set Category"
        setType = string.gsub(setType, splitParameter[tablelength(splitParameter)], "")
        setType = string.gsub(setType, '^%s*(.-)%s*$', '%1')

        SaveCategory(setType, splitParameter[tablelength(splitParameter)])
      elseif string.lower(splitParameter[2]) == "mount" then
        setType = string.sub(parameter, 10, string.len(parameter)) --"Set Mount"
        setType = string.gsub(setType, splitParameter[tablelength(splitParameter)], "")
        setType = string.gsub(setType, '^%s*(.-)%s*$', '%1')

        SaveMount(setType, splitParameter[tablelength(splitParameter)])
      else
        print('Accepted Parameters are: "Set Mount [MountName] [Weight]", "Set Category [CategoryName] [Weight]"')
      end
    elseif parameterLower == "dump mounts" then
      DumpMounts()
    else
      print('Parameter was: ' .. parameter) --Print a list of valid command to the console
      print('Accepted Parameters are: "list", "list usable", "list ground", "list flying", "listCategories", "update", "debug", "zone", "Set Mount [MountName] [Weight]", "Set Category [CategoryName] [Weight]", "MountType [Mount Name]", "Settings", "Dump Mounts"')
    end
  else --If no parameter was supplied update macro with new random mounts
    wrm_wait(0.1, UpdateMountMacro, false)
  end

  if inDebugMode then
      print("WRM was called with parameter: " .. parameter)
  end
end

--Handles the changing zone event
local function ZoneChangeHandler(self, event, ...)
  
  UpdateMyMounts()--Update mount table with current mounts
  UpdateMountMacro(true)
  
  if inDebugMode then
    print("Zone Changed")
  end
end


-- Initilize addon when entering world
local EnterWorldFrame = CreateFrame("Frame")
EnterWorldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EnterWorldFrame:SetScript("OnEvent", InitialStartupHandler)

-- Update player zone
local ChangeZoneFrame = CreateFrame("Frame")
ChangeZoneFrame:RegisterEvent("ZONE_CHANGED")
ChangeZoneFrame:SetScript("OnEvent", ZoneChangeHandler)


-- Register slash commands
SlashCmdList["WRM"] = WRMHandler;

--local flyable = IsFlyableArea -- make a local copy of the function and not the result of one execution
--local indoors = isIndoors -- make a local copy of the function and not the result of one execution
--local currentlyFlyable = flyable()
--local CurrentlyIndoors = indoors()

-- New API Commands
--CallCompanion(Type, ID) - uses companion
--DismissCompanion(Type) - dismisses compaion
--GetCompanionCooldown(Type, ID) - (startTime, duration, isEnabled)
--GetCompanionInfo - (creatureID, creatureName, creatureSpellID, icon, issummoned)
--GetNumCompanions(Type) - (NumberOfCompanions)
--PickupCompanion(Type, ID)
