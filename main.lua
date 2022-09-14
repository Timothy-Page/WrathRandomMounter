local addonName, WrathRandomMounter = ...

SLASH_WRM1 = "/WRM"
SLASH_WRP1 = "/WRP"
local inDebugMode = false

local mounted = IsMounted()
local inCombat = InCombatLockdown()
local CurrentZoneCategory = 'None'

local myMounts = {
  ["myGroundMounts"] = {},
  ["mySwiftGroundMounts"] = {},
  ["myFlyingMounts"] = {},
  ["mySwiftFlyingMounts"] = {},
  ["mySuperSwiftFlyingMounts"] = {},
  ["mySwimmingMounts"] = {}
}
local myAQMounts = {
  ["myGroundMounts"] = {},
  ["mySwiftGroundMounts"] = {},
  ["myFlyingMounts"] = {},
  ["mySwiftFlyingMounts"] = {},
  ["mySuperSwiftFlyingMounts"] = {},
  ["mySwimmingMounts"] = {}
}
local myCurrentMounts = {
  ["myGroundMounts"] = {},
  ["mySwiftGroundMounts"] = {},
  ["myFlyingMounts"] = {},
  ["mySwiftFlyingMounts"] = {},
  ["mySuperSwiftFlyingMounts"] = {},
  ["mySwimmingMounts"] = {}
}

local myMountsCategories = {
  ["myGroundMountsCategories"] = {},
  ["mySwiftGroundMountsCategories"] = {},
  ["myFlyingMountsCategories"] = {},
  ["mySwiftFlyingMountsCategories"] = {},
  ["mySuperSwiftFlyingMountsCategories"] = {},
  ["mySwimmingMountsCategories"] = {}
}
local myAQMountsCategories = {
  ["myGroundMountsCategories"] = {},
  ["mySwiftGroundMountsCategories"] = {},
  ["myFlyingMountsCategories"] = {},
  ["mySwiftFlyingMountsCategories"] = {},
  ["mySuperSwiftFlyingMountsCategories"] = {},
  ["mySwimmingMountsCategories"] = {}
}
local myCurrentMountsCategories = {
  ["myGroundMountsCategories"] = {},
  ["mySwiftGroundMountsCategories"] = {},
  ["myFlyingMountsCategories"] = {},
  ["mySwiftFlyingMountsCategories"] = {},
  ["mySuperSwiftFlyingMountsCategories"] = {},
  ["mySwimmingMountsCategories"] = {}
}

--Returns the number of elements in a table
local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
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

local function PrintMounts()
  for mountType in pairs (myCurrentMounts) do
    local mountString = nil
    for mountCategory in pairs(myCurrentMounts[mountType]) do
      for mount in pairs(myCurrentMounts[mountType][mountCategory]) do
        if mountString == nil then
          mountString = myCurrentMounts[mountType][mountCategory][mount][1]
        else
          mountString = mountString .. ", " .. myCurrentMounts[mountType][mountCategory][mount][1]
        end
      end
    end
    print(mountType .. ": " .. tostring(mountString))
  end
end

-- Returns a mount string that is of type mountType
local function GetRandomMount(mountType)
  local mount
  local mountTypeCategory = mountType .. "Categories"

  --Randomly pick a mount category
  local numberOfCategories = tablelength(myCurrentMounts[mountType])
  if numberOfCategories > 0 then
    local CategoryId = math.random(numberOfCategories)
    local CategoryName = nil

    --Get the category string
    CategoryName = myCurrentMountsCategories[mountTypeCategory][CategoryId]
    
    --Randomly pick a mount from the category
    local numberOfMounts = tablelength(myCurrentMounts[mountType][CategoryName])
    if numberOfMounts > 0 then
      local mountID = math.random(numberOfMounts)
      mount = myCurrentMounts[mountType][CategoryName][mountID][1]
    end
  end

  return mount
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

--Used to reset mount table when updating mounts
local function BlankMountTable()
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

--Used to reset mount category table when updating mounts
local function BlankMountCategoryTable()
  mountCategoryTable = {
    ["myGroundMountsCategories"] = {},
    ["mySwiftGroundMountsCategories"] = {},
    ["myFlyingMountsCategories"] = {},
    ["mySwiftFlyingMountsCategories"] = {},
    ["mySuperSwiftFlyingMountsCategories"] = {},
    ["mySwimmingMountsCategories"] = {}
  }

  return mountCategoryTable
end

local function RecordMountCategories(mountTable, categoryTable)
    --Put Categories into categoryTable
    for mountCategory, mounts in pairs(mountTable["myGroundMounts"]) do
      table.insert(categoryTable["myGroundMountsCategories"], mountCategory)
    end
    for mountCategory, mounts in pairs(mountTable["mySwiftGroundMounts"]) do
      table.insert(categoryTable["mySwiftGroundMountsCategories"], mountCategory)
    end
    for mountCategory, mounts in pairs(mountTable["myFlyingMounts"]) do
      table.insert(categoryTable["myFlyingMountsCategories"], mountCategory)
    end
    for mountCategory, mounts in pairs(mountTable["mySwiftFlyingMounts"]) do
      table.insert(categoryTable["mySwiftFlyingMountsCategories"], mountCategory)
    end
    for mountCategory, mounts in pairs(mountTable["mySuperSwiftFlyingMounts"]) do
      table.insert(categoryTable["mySuperSwiftFlyingMountsCategories"], mountCategory)
    end
    for mountCategory, mounts in pairs(mountTable["mySwimmingMounts"]) do
      table.insert(categoryTable["mySwimmingMountsCategories"], mountCategory)
    end
end

--Updates the mount tables based on the companion API
local function UpdateMyMounts()
  myMounts = BlankMountTable()
  myAQMounts = BlankMountTable()
  myMountsCategories = BlankMountCategoryTable()
  myAQMountsCategories = BlankMountCategoryTable()

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

  -- Get additional mount data from Mounts.lua
  for mount in pairs(WrathRandomMounter.itemMounts) do --Loop over all possible mounts from Mounts.lua
    --2:SpellID, 4:MaxSpeed, 5:MinSpeed, 6:SwimSpeed, 7:Category, 9:NormalMount, 10:AQMount
    Mount = WrathRandomMounter.itemMounts[mount] --Table off all the mount data
    SpellID = Mount[2]
    MaxSpeed = Mount[4]
    MinSpeed = Mount[5]
    SwimSpeed = Mount[6]
    Category = Mount[7]
    NormalMount = Mount[9]
    AQMount = Mount[10]

    if tableContains(MountsKnown, SpellID) then --Check if player has mount
      if MinSpeed <= 1 then --Ground Mount
        if NormalMount == 1 then
          AddMountMyMounts("myGroundMounts", Category, Mount, myMounts)
        end
        if AQMount == 1 then
          AddMountMyMounts("myGroundMounts", Category, Mount, myAQMounts)
        end
      end
      if MinSpeed <= 1 and MaxSpeed >=1 then --SwiftGround Mount
        if NormalMount == 1 then
          AddMountMyMounts("mySwiftGroundMounts", Category, Mount, myMounts)
        end
        if AQMount == 1 then
          AddMountMyMounts("mySwiftGroundMounts", Category, Mount, myAQMounts)
        end
      end
      if MaxSpeed > 1 then --Flying Mount
        if NormalMount == 1 then
          AddMountMyMounts("myFlyingMounts", Category, Mount, myMounts)
        end
        if AQMount == 1 then
          AddMountMyMounts("myFlyingMounts", Category, Mount, myAQMounts)
        end
      end
      if MinSpeed <= 2.8 and MaxSpeed >= 2.8 then --Swift Flying Mount
        if NormalMount == 1 then
          AddMountMyMounts("mySwiftFlyingMounts", Category, Mount, myMounts)
        end
        if AQMount == 1 then
          AddMountMyMounts("mySwiftFlyingMounts", Category, Mount, myAQMounts)
        end
      end
      if MaxSpeed > 2.8 then --Super Swift Flying Mount
        if NormalMount == 1 then
          AddMountMyMounts("mySuperSwiftFlyingMounts", Category, Mount, myMounts)
        end
        if AQMount == 1 then
          AddMountMyMounts("mySuperSwiftFlyingMounts", Category, Mount, myAQMounts)
        end
      end
      if SwimSpeed > 0 then -- Swimming Mount
        if NormalMount == 1 then
          AddMountMyMounts("mySwimmingMounts", Category, Mount, myMounts)
        end
        if AQMount == 1 then
          AddMountMyMounts("mySwimmingMounts", Category, Mount, myAQMounts)
        end
      end
    end
  end
  
  --Put Categories into myCurrentMountsCategories
  RecordMountCategories(myMounts, myMountsCategories)
  RecordMountCategories(myAQMounts, myAQMountsCategories)

  --Update Current tables
  if CurrentZoneCategory == "Ahn'Qiraj" then
    myCurrentMounts = myAQMounts
    myCurrentMountsCategories = myAQMountsCategories
  else
    myCurrentMounts = myMounts
    myCurrentMountsCategories = myMountsCategories
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

--Gets mounts and updates macro when addon is loaded.
local function InitialStartup(self, event, ...)
  CurrentZoneCategory = GetCurrentZoneCategory()
  UpdateMyMounts() --Update mount table with current mounts
  local groundMount, flyingMount, swimmingMount = GetRandomMounts() --Get random Mounts
  UpdateMacro(groundMount, flyingMount, swimmingMount) --Update macro with random Mounts
end

--Handles the entering world event
local function InitialStartupHandler(self, event, ...)
  print("InitialStartup Event: " .. event)
  InitialStartup(self, event, ...) --Gets the addon into a usable state
  wrm_wait(10, InitialStartup, self, event, ...) --Reruns startup incase parts of the API had not started yet (Updating Macros can fail if called too early)
end

local function UpdateMountMacro()
  local groundMount, flyingMount, swimmingMount = GetRandomMounts()
  if IsMounted() == false then --Only update macro if player is not mounted and delay by 0.1s so macro is not being updated while it is being run.
    UpdateMacro(groundMount, flyingMount, swimmingMount)
  end
end

--Captures console commands that are entered
local function WRMHandler(parameter)
    
  if(string.len(parameter) > 0) then --If a parameter was supplied
    if parameter == "list" then
      PrintMounts() --Prints players mounts to console
    elseif parameter == "update" then
      InitialStartup() --Rerun Startup to capture new mounts
    elseif parameter == "debug" then
      inDebugMode = not inDebugMode --Change the debug state of the addon
      print('DebugMode Changed to: ' .. tostring(inDebugMode))
    elseif parameter == "zone" then
      print('Current Zone Category: ' .. CurrentZoneCategory)
    else
      print('Parameter was: ' .. parameter) --Print a list of valid command to the console
      print('Accepted Parameters are: "list", "update", "debug", "zone"')
    end
  else --If no parameter was supplied update macro with new random mounts
    wrm_wait(0.1, UpdateMountMacro)
  end

  if inDebugMode then
      print("WRM was called with parameter: " .. parameter)
  end
end

local function WRPHandler(parameter)
    
  if(string.len(parameter) > 0) then --If a parameter was supplied
    if parameter == "list" then
      --PrintPets() --Prints players mounts to console
      print("Pets : " .. "ToDo")
    elseif parameter == "update" then
      --InitialStartupHandler() --Rerun Startup to capture new pets
      print("Update Pets ToDo")
    elseif parameter == "debug" then
      inDebugMode = not inDebugMode --Change the debug state of the addon
      print('DebugMode Changed to: ' .. tostring(inDebugMode))
    else
      print('Parameter was: ' .. parameter) --Print a list of valid command to the console
      print('Accepted Parameters are: "list", "update", "debug"')
    end
  else --If no parameter was supplied update macro with new random pets
    --local pet = GetRandomPets()
    --wrm_wait(0.1, UpdateMacro, groundMount, flyingMount, swimmingMount)
    print("Update pet macro")
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
      myCurrentMounts = myAQMounts
      myCurrentMountsCategories = myAQMountsCategories
    else
      myCurrentMounts = myMounts
      myCurrentMountsCategories = myMountsCategories
    end
    UpdateMountMacro()
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
