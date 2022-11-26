local addonName, WrathRandomMounter = ...

SLASH_WRM1 = "/WRM"
SLASH_WRP1 = "/WRP"
local inDebugMode = false

local mounted = IsMounted -- make a local copy of the function and not the result of one execution
local inCombat = InCombatLockdown -- make a local copy of the function and not the result of one execution
local CurrentZoneCategory = 'None'
local ridingSkill = 0

--Variables to store player mounts
local function GenerateBlankMountTable()
  mountTable = {
  ["myGroundMounts"] = {},
  ["mySwiftGroundMounts"] = {},
  ["myFlyingMounts"] = {},
  ["mySwiftFlyingMounts"] = {},
  ["mySuperSwiftFlyingMounts"] = {},
  ["mySwimmingMounts"] = {}
  }
  return mountTable
end
local myMountSets = {
  ["myMounts"] = GenerateBlankMountTable(),
  ["myAQMounts"] = GenerateBlankMountTable()
}
local myCurrentMounts = GenerateBlankMountTable() --Currently active mount set
AllMounts = {}
--SavedMountWeights = {
--  ["Festering Emerald Drake"] = 0,
--  ["Kalu'ak Whalebone Glider"] = 0,
--  ["Reawakened Phase-Hunter"] = 0
--}

--mySuperSwiftFlyingMountsCategories
--Variables to store player mount categories
local function GenerateBlankMountCategoriesTable()
  mountCategoriesTable = {
  ["myGroundMountsCategories"] = {},
  ["mySwiftGroundMountsCategories"] = {},
  ["myFlyingMountsCategories"] = {},
  ["mySwiftFlyingMountsCategories"] = {},
  ["mySuperSwiftFlyingMountsCategories"] = {},
  ["mySwimmingMountsCategories"] = {}
  }
  return mountCategoriesTable
end
local myMountsCategoriesSets = {
  ["myMountsCategories"] = GenerateBlankMountCategoriesTable(),
  ["myAQMountsCategories"] = GenerateBlankMountCategoriesTable()
}
local myCurrentMountsCategories = GenerateBlankMountCategoriesTable() --Categories of mounts in "myCurrentMounts"
AllMountCategories = {}
--SavedMountCategoriesWeights = {
--  ["Glider"] = 0,
--  ["Warp Stalker"] = 0
--}

--Variables to store player pets
local myPets = {}

--Get Localized Mount Names
local function LocalizeMountName()
  for mount in pairs(WrathRandomMounter.itemMounts) do --Loop over all possible mounts from Mounts.lua
    --1:Name, 2:SpellID, 4:MaxSpeed, 5:MinSpeed, 6:SwimSpeed, 7:Category, 9:NormalMount, 10:AQMount
    --ridingSkill 75:0.6, 150:1, 225:1.5, 300:2.8, 375:3.1
    name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(WrathRandomMounter.itemMounts[mount][2])
    WrathRandomMounter.itemMounts[mount][1] = name
  end
end

--Returns the number of elements in a table
local function tablelength(T)
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

--local function PrintMounts()
--  for mountType in pairs (myCurrentMounts) do
--    local mountString = nil
--    for mountCategory in pairs(myCurrentMounts[mountType]) do
--      for mount in pairs(myCurrentMounts[mountType][mountCategory]) do
--        if mountString == nil then
--          mountString = myCurrentMounts[mountType][mountCategory][mount][1]
--        else
--          mountString = mountString .. ", " .. myCurrentMounts[mountType][mountCategory][mount][1]
--        end
--      end
--    end
--    print(mountType .. ": " .. tostring(mountString))
--  end
--end

local function PrintMounts()
  orderedMounts = {}
  for mountName in pairs(AllMounts) do
    table.insert(orderedMounts, mountName)
  end
  table.sort(orderedMounts)

  print("Mounts...")
  for mountOrderID in pairs(orderedMounts) do
    print(orderedMounts[mountOrderID] .. ": " .. tostring(AllMounts[orderedMounts[mountOrderID]]))
  end
end

local function PrintCategories()
  orderedCategories = {}
  for categoryName in pairs(AllMountCategories) do
    table.insert(orderedCategories, categoryName)
  end
  table.sort(orderedCategories)

  print("MountCategories...")
  for categoryorderID in pairs(orderedCategories) do
    print(orderedCategories[categoryorderID] .. ": " .. tostring(AllMountCategories[orderedCategories[categoryorderID]]))
  end
end

local function PrintPets()
  local petString = nil

  for pet in pairs (myPets) do
    petName = myPets[pet]
    if petString == nil then
      petString = tostring(petName)
    else
      petString = petString .. ", " .. tostring(petName)
    end
  end
  print("Pets: " .. tostring(petString))
end

-- Returns a mount string that is of type mountType
local function GetRandomMount(mountType)
  local mount
  local mountTypeCategory = mountType .. "Categories"

  --Randomly pick a mount category
  local numberOfCategories = tablelength(myCurrentMountsCategories[mountTypeCategory])
  if numberOfCategories > 0 then
    local CategoryId = math.random(numberOfCategories)
    local CategoryName = nil

    --Get the category string
    CategoryName = myCurrentMountsCategories[mountTypeCategory][CategoryId]

    mountList = {}
    for mountKey, mount in pairs(myCurrentMounts[mountType][CategoryName]) do
      if AllMounts[mount[1]] == 1 then
        table.insert(mountList, mount[1])
      end
    end

    --Randomly pick a mount from the category
    local numberOfMounts = tablelength(mountList)
    if numberOfMounts > 0 then
      local mountID = math.random(numberOfMounts)
      mount = mountList[mountID]
    end
  end

  return mount
end

-- Returns a pet string
local function GetRandomPet()
  local pet

  --Randomly pick a pet
  local numberOfPets = tablelength(myPets)
  if numberOfPets > 0 then
    local petID = math.random(numberOfPets)
    pet = myPets[petID]
  end

  return pet
end

local function GetRandomMounts()
  local groundMount = GetRandomMount("myGroundMounts")
  local swiftGroundMount = GetRandomMount("mySwiftGroundMounts")
  local flyingMount = GetRandomMount("myFlyingMounts")
  local swiftFlyingMount = GetRandomMount("mySwiftFlyingMounts")
  local superSwiftFlyingMount = GetRandomMount("mySuperSwiftFlyingMounts")
  local swimmingMount = GetRandomMount("mySwimmingMounts")
  
  if superSwiftFlyingMount ~= nil then --replace SwiftFlying mount with SuperSwiftFlying mount if exists
    swiftFlyingMount = superSwiftFlyingMount
  end
  if swiftFlyingMount ~= nil then --replace flyingMount with SwiftFlying mount if exists
    flyingMount = swiftFlyingMount
  end
  if swiftGroundMount ~= nil then --replace groundmount with SwiftGroundMount if exists
    groundMount = swiftGroundMount
  end

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

--Update ingame macro with the new pet
local function UpdatePetMacro(forceUpdate)
  --#showtooltip
  --/cast pet
  --/WRP

  if not inCombat() then
    local pet = GetRandomPet()
    local body = nil
    
    if pet ~= nil then
      body = "#showtooltip " .. "\n/cast " .. pet .. "\n/WRP"
    else
      body = "#showtooltip " .. "\n/WRP"
    end
  
    --Save the macro
    macroIndex = GetMacroIndexByName("Pet")
    if macroIndex == 0 then
      CreateMacro("Pet", "INV_MISC_QUESTIONMARK", body, nil)
    else
      EditMacro("Pet", "Pet", nil, body, 1, 1)
    end
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

--Adds mount into table and creates the category if it does not exist
local function AddMountMyMounts(type, category, mount, mountTable)
  if mountTable[type][category] == nil then
    mountTable[type][category] = {mount}
  else
    table.insert(mountTable[type][category], mount)
  end
end

local function GetAllMounts(mountTable, mountList)
  for mountType in pairs(myCurrentMounts) do
    for category in pairs(myCurrentMounts[mountType]) do
      for mount in pairs(myCurrentMounts[mountType][category]) do
        mountName = myCurrentMounts[mountType][category][mount][1]
        if mountList[mountName] == nil then
          if SavedMountWeights[mountName] == nil then
            mountList[mountName] = 1
          else
            mountList[mountName] = SavedMountWeights[mountName]
          end
        end
      end
    end
  end
end

local function GetAllMountCategories(mountTable, categoryList)
  for mountType in pairs(myCurrentMounts) do
    for category in pairs(myCurrentMounts[mountType]) do
      if categoryList[category] == nil then
        if SavedMountCategoriesWeights[category] == nil then
          categoryList[category] = 1
        else
          categoryList[category] = SavedMountCategoriesWeights[category]
        end
      end
    end
  end
end

local function RecordMountCategories(mountTable, categoryTable)
    --Put Categories into categoryTable
    for mountCategory, mounts in pairs(mountTable["myGroundMounts"]) do
      if AllMountCategories[mountCategory] ~= 0 then
        table.insert(categoryTable["myGroundMountsCategories"], mountCategory)
      end
    end
    for mountCategory, mounts in pairs(mountTable["mySwiftGroundMounts"]) do
      if AllMountCategories[mountCategory] ~= 0 then
        table.insert(categoryTable["mySwiftGroundMountsCategories"], mountCategory)
      end
    end
    for mountCategory, mounts in pairs(mountTable["myFlyingMounts"]) do
      if AllMountCategories[mountCategory] ~= 0 then
        table.insert(categoryTable["myFlyingMountsCategories"], mountCategory)
      end
    end
    for mountCategory, mounts in pairs(mountTable["mySwiftFlyingMounts"]) do
      if AllMountCategories[mountCategory] ~= 0 then
        table.insert(categoryTable["mySwiftFlyingMountsCategories"], mountCategory)
      end
    end
    for mountCategory, mounts in pairs(mountTable["mySuperSwiftFlyingMounts"]) do
      if AllMountCategories[mountCategory] ~= 0 then
        table.insert(categoryTable["mySuperSwiftFlyingMountsCategories"], mountCategory)
      end
    end
    for mountCategory, mounts in pairs(mountTable["mySwimmingMounts"]) do
      if AllMountCategories[mountCategory] ~= 0 then
        table.insert(categoryTable["mySwimmingMountsCategories"], mountCategory)
      end
    end
end

--Updates the pet tables based on the companion API
local function UpdateMyPets()
  myPets = {}

  -- Get pets from the companion API
  PetsKnown = {} --Stores the API pets
  CompanionType = "CRITTER"
  numPets = GetNumCompanions(CompanionType) --total number of API pets
  petCounter = 1 --loop counter
  while petCounter <= numPets do
    creatureID, creatureName, creatureSpellID, icon, issummoned, petType = GetCompanionInfo(CompanionType, petCounter)
    if inDebugMode then
      --print("PetSpellID: " .. creatureSpellID)
      --print("PetName: " .. creatureName)
    end
    table.insert(PetsKnown, {creatureSpellID, creatureName})
    petCounter = petCounter + 1
  end

  -- Get additional pet data from Pets.lua
  for pet in pairs(PetsKnown) do --Loop over all possible pets from Pets.lua
    --1:PetName, 2:PetCategory
    Pet = WrathRandomMounter.itemPets[tostring(PetsKnown[pet][1])] --Table off all the pet data
    if inDebugMode then
      print("Pet: " .. tostring(PetsKnown[pet][1] .. ", " .. tostring(PetsKnown[pet][2])))
      print("Pet Table: " .. tostring(Pet))
    end

    
    SpellID = nil
    PetName = nil
    PetCategory = nil
    if Pet ~= nil then
      SpellID = pet
      PetName = Pet[1]
      PetCategory = Pet[2]
    else
      SpellID = PetsKnown[pet][1]
      PetName = PetsKnown[pet][2]
      PetCategory = "None"
    end
    
    if inDebugMode then
      print("Petnaem: " .. tostring(PetName))
    end

    table.insert(myPets, PetName)
  end

  if inDebugMode then
    PrintPets()
  end
end

--Updates the mount tables based on the companion API
local function UpdateMyMounts()
  myMountSets["myMounts"] = GenerateBlankMountTable()
  myMountSets["myAQMounts"] = GenerateBlankMountTable()
  myMountsCategoriesSets["myMountsCategories"] = GenerateBlankMountCategoriesTable()
  myMountsCategoriesSets["myAQMountsCategories"] = GenerateBlankMountCategoriesTable()

  -- Get mounts from the companion API
  MountsKnown = {} --Stores the API mounts
  CompanionType = "MOUNT"
  numMounts = GetNumCompanions(CompanionType) --total number of API mounts
  mountCounter = 1 --loop counter
  while mountCounter <= numMounts do
    creatureID, creatureName, creatureSpellID, icon, issummoned, mountType = GetCompanionInfo(CompanionType, mountCounter)
    table.insert(MountsKnown, creatureSpellID)
    mountCounter = mountCounter + 1
  end

  -- Get additional mount data from Mounts.lua and put into myCurrentMounts
  for mount in pairs(WrathRandomMounter.itemMounts) do --Loop over all possible mounts from Mounts.lua
    --2:SpellID, 4:MaxSpeed, 5:MinSpeed, 6:SwimSpeed, 7:Category, 9:NormalMount, 10:AQMount
    --ridingSkill 75:0.6, 150:1, 225:1.5, 300:2.8, 375:3.1
    Mount = WrathRandomMounter.itemMounts[mount] --Table off all the mount data
    SpellID = Mount[2]
    MaxSpeed = Mount[4]
    MinSpeed = Mount[5]
    SwimSpeed = Mount[6]
    Category = Mount[7]
    NormalMount = Mount[9]
    AQMount = Mount[10]
    
    if tableContains(MountsKnown, SpellID) then --Check if player has mount
      --print("SpellID: " .. SpellID)
      --print("RidingSkill: " .. ridingSkill)
      if MinSpeed <= 1 and ridingSkill >= 75 then --Ground Mount
        AddMountMyMounts("myGroundMounts", Category, Mount, myCurrentMounts)
      end
      if (MinSpeed <= 1 and MaxSpeed >=1) and ridingSkill >= 150 then --SwiftGround Mount
        AddMountMyMounts("mySwiftGroundMounts", Category, Mount, myCurrentMounts)
      end
      if MaxSpeed > 1 and ridingSkill >= 225 then --Flying Mount
        AddMountMyMounts("myFlyingMounts", Category, Mount, myCurrentMounts)
      end
      if (MinSpeed <= 2.8 and MaxSpeed >= 2.8) and ridingSkill >= 300 then --Swift Flying Mount
        AddMountMyMounts("mySwiftFlyingMounts", Category, Mount, myCurrentMounts)
      end
      if MaxSpeed >= 2.8 and ridingSkill >= 300 then --Super Swift Flying Mount
        AddMountMyMounts("mySuperSwiftFlyingMounts", Category, Mount, myCurrentMounts)
      end
      if SwimSpeed > 0 then -- Swimming Mount
        AddMountMyMounts("mySwimmingMounts", Category, Mount, myCurrentMounts)
      end
    end
  end
  
  GetAllMounts(myCurrentMounts, AllMounts)
  --Move Mounts from myCurrentMounts to separate Mount set
  for MountType in pairs(myCurrentMounts) do
    for Category in pairs(myCurrentMounts[MountType]) do
      for mount in pairs(myCurrentMounts[MountType][Category]) do
        Mount = myCurrentMounts[MountType][Category][mount]
        SpellID = Mount[2]
        NormalMount = Mount[9]
        AQMount = Mount[10]
        
        if NormalMount == 1 then
          AddMountMyMounts(MountType, Category, Mount, myMountSets["myMounts"])
        end
        if AQMount == 1 then
          AddMountMyMounts(MountType, Category, Mount, myMountSets["myAQMounts"])
        end
      end
    end
  end

  --Put Categories into myCurrentMountsCategories
  GetAllMountCategories(myCurrentMounts, AllMountCategories)
  RecordMountCategories(myMountSets["myMounts"], myMountsCategoriesSets["myMountsCategories"])
  RecordMountCategories(myMountSets["myAQMounts"], myMountsCategoriesSets["myAQMountsCategories"])

  --Update Current tables
  if CurrentZoneCategory == "Ahn'Qiraj" then
    myCurrentMounts = myMountSets["myAQMounts"]
    myCurrentMountsCategories = myMountsCategoriesSets["myAQMountsCategories"]
  else
    myCurrentMounts = myMountSets["myMounts"]
    myCurrentMountsCategories = myMountsCategoriesSets["myMountsCategories"]
  end

  if inDebugMode then
    PrintMounts()
  end
end

local function GetCurrentZoneCategory()
  local zoneText = GetZoneText()
  local zoneCategory = WrathRandomMounter.itemZones[zoneText]
  if zoneCategory == nil then
    zoneCategory = 'None'
  end
  
  if inDebugMode then
    print("Current Zone: " .. zoneText)
    print("Current Zone Category: " .. zoneCategory)
  end
  
  return zoneCategory
end

local function UpdateMountMacro(forceUpdate)
  local groundMount, flyingMount, swimmingMount = GetRandomMounts()
  if (not IsMounted() or forceUpdate) and not inCombat() then --Only update macro if player is not mounted and delay by 0.1s so macro is not being updated while it is being run.
    UpdateMacro(groundMount, flyingMount, swimmingMount)
  end
end

--Gets mounts and updates macro when addon is loaded.
local function InitialStartup(self, event, ...)
  CurrentZoneCategory = GetCurrentZoneCategory()
  GetRidingSkill()
  LocalizeMountName()
  UpdateMyMounts() --Update mount table with current mounts
  UpdateMountMacro(true)
  UpdateMyPets()
  UpdatePetMacro(true)
end

--Changes saved variables from nil to empty lists
local function InitialStartupOfSavedVariables()
  if SavedMountWeights == nil then
    SavedMountWeights = {}
  end
  if SavedMountCategoriesWeights == nil then
    SavedMountCategoriesWeights = {}
  end
end

--Handles the entering world event
local function InitialStartupHandler(self, event, ...)
  InitialStartupOfSavedVariables()
  InitialStartup(self, event, ...) --Gets the addon into a usable state
  wrm_wait(10, InitialStartup, self, event, ...) --Reruns startup incase parts of the API had not started yet (Updating Macros can fail if called too early)
end

local function stringStarts(String,Start)
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
  for allMountCategory in pairs(AllMountCategories) do
    if string.lower(categoryName) == string.lower(allMountCategory) then
      mountCategoryFound = true
      categoryName = allMountCategory
    end
  end
  if mountCategoryFound then
    if categoryValue == "0" or categoryValue == "1" then
      SavedMountCategoriesWeights[categoryName] = tonumber(categoryValue)
      AllMountCategories[categoryName] = tonumber(categoryValue)
    else
      print("Currently only weights of 1 and 0 are accepted")
    end
  else
    print("Category \"" .. categoryName .. "\" could not be found")
  end
  InitialStartup()
end

local function SaveMount(mountName, mountValue)
  print("set mount: " .. mountName .. ", " .. mountValue)
  mountFound = false
  for allMount in pairs(AllMounts) do
    if string.lower(mountName) == string.lower(allMount) then
      mountFound = true
      mountName = allMount
    end
  end
  if mountFound then
    if mountValue == "0" or mountValue == "1" then
      SavedMountWeights[mountName] = tonumber(mountValue)
      AllMounts[mountName] = tonumber(mountValue)
    else
      print("Currently only weights of 1 and 0 are accepted")
    end
  else
    print("Mount \"" .. mountName .. "\" could not be found")
  end
  InitialStartup()
end

--Captures console commands that are entered
--/wrm Set Category Glider 0
local function WRMHandler(parameter)
  if(string.len(parameter) > 0) then --If a parameter was supplied
    parameterLower = string.lower(parameter)
    if parameterLower == "list" then
      PrintMounts() --Prints players mounts to console
    elseif parameterLower == "listcategories" then
      PrintCategories()
    elseif parameterLower == "update" then
      InitialStartup() --Rerun Startup to capture new mounts
    elseif parameterLower == "debug" then
      inDebugMode = not inDebugMode --Change the debug state of the addon
      print('DebugMode Changed to: ' .. tostring(inDebugMode))
    elseif parameterLower == "zone" then
      print('Current Zone Category: ' .. CurrentZoneCategory)
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
        print("Set funtion needs to in format" .. '"Set Mount [MountName] [Weight]", "Set Category [CategoryName] [Weight]"')
      end
    else
      print('Parameter was: ' .. parameter) --Print a list of valid command to the console
      print('Accepted Parameters are: "list", "listCategories", "update", "debug", "zone", "Set Mount [MountName] [Weight]", "Set Category [CategoryName] [Weight]"')
    end
  else --If no parameter was supplied update macro with new random mounts
    wrm_wait(0.1, UpdateMountMacro, false)
  end

  if inDebugMode then
      print("WRM was called with parameter: " .. parameter)
  end
end

local function WRPHandler(parameter)
    
  if(string.len(parameter) > 0) then --If a parameter was supplied
    if parameter == "list" then
      PrintPets() --Prints players mounts to console
    elseif parameter == "update" then
      UpdateMyPets() --Rerun Startup to capture new pets
    elseif parameter == "debug" then
      inDebugMode = not inDebugMode --Change the debug state of the addon
      print('DebugMode Changed to: ' .. tostring(inDebugMode))
    else
      print('Parameter was: ' .. parameter) --Print a list of valid command to the console
      print('Accepted Parameters are: "list", "update", "debug"')
    end
  else --If no parameter was supplied update macro with new random pets
    wrm_wait(0.1, UpdatePetMacro, false)
  end

  if inDebugMode then
      print("WRP was called with parameter: " .. parameter)
  end
end

--Handles the changing zone event
local function ZoneChangeHandler(self, event, ...)
  local zoneCategory = GetCurrentZoneCategory()
  
  if CurrentZoneCategory ~= zoneCategory then
    CurrentZoneCategory = zoneCategory
    print("Updating for Zone Change")
    if CurrentZoneCategory == "Ahn'Qiraj" then
      myCurrentMounts = myMountSets["myAQMounts"]
      myCurrentMountsCategories = myMountsCategoriesSets["myAQMountsCategories"]
    else
      myCurrentMounts = myMountSets["myMounts"]
      myCurrentMountsCategories = myMountsCategoriesSets["myMountsCategories"]
    end
    UpdateMountMacro(false)
  end
  
  if inDebugMode then
    print("Zone Category Now: " .. zoneCategory)
  end
end


-- Initilize addon when entering world
local EnterWorldFrame = CreateFrame("Frame")
EnterWorldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EnterWorldFrame:SetScript("OnEvent", InitialStartupHandler)

-- Update player zone
local ChangeZoneFrame = CreateFrame("Frame")
ChangeZoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ChangeZoneFrame:SetScript("OnEvent", ZoneChangeHandler)


-- Register slash commands
SlashCmdList["WRM"] = WRMHandler;
SlashCmdList["WRP"] = WRPHandler;



-- New API Commands
--CallCompanion(Type, ID) - uses companion
--DismissCompanion(Type) - dismisses compaion
--GetCompanionCooldown(Type, ID) - (startTime, duration, isEnabled)
--GetCompanionInfo - (creatureID, creatureName, creatureSpellID, icon, issummoned)
--GetNumCompanions(Type) - (NumberOfCompanions)
--PickupCompanion(Type, ID)
