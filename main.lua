local addonName, WrathRandomMounter = ...

SLASH_WRM1 = "/WRM"
local inDebugMode = false

local mounted = IsMounted()
local inCombat = InCombatLockdown()

local myMounts = {
  ["myGroundMounts"] = {},
  ["mySwiftGroundMounts"] = {},
  ["myFlyingMounts"] = {},
  ["mySwiftFlyingMounts"] = {},
  ["mySuperSwiftFlyingMounts"] = {},
  ["mySwimmingMounts"] = {}
}
local myGroundMountsCategories = {}
local mySwiftGroundMountsCategories = {}
local myFlyingMountsCategories = {}
local mySwiftFlyingMountsCategories = {}
local mySuperSwiftFlyingMountsCategories = {}
local mySwimmingMountsCategories = {}

local myMountsCount = 0
local myMountsPreviousCount = 0

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
  for mountType in pairs (myMounts) do
    local mountString = nil
    for mountCategory in pairs(myMounts[mountType]) do
      for mount in pairs(myMounts[mountType][mountCategory]) do
        if mountString == nil then
          mountString = myMounts[mountType][mountCategory][mount][1]
        else
          mountString = mountString .. ", " .. myMounts[mountType][mountCategory][mount][1]
        end
      end
    end
    print(mountType .. ": " .. tostring(mountString))
  end
end

local function GetRandomMount(mountType)
  local numberOfCategories = tablelength(myMounts[mountType])
  local mount
  if numberOfCategories > 0 then
    local CategoryId = math.random(numberOfCategories)
    local CategoryName = nil
    if mountType == "myGroundMounts" then
      CategoryName = myGroundMountsCategories[CategoryId]
    elseif mountType == "mySwiftGroundMounts" then
      CategoryName = mySwiftGroundMountsCategories[CategoryId]
    elseif mountType == "myFlyingMounts" then
      CategoryName = myFlyingMountsCategories[CategoryId]
    elseif mountType == "mySwiftFlyingMounts" then
      CategoryName = mySwiftFlyingMountsCategories[CategoryId]
    elseif mountType == "mySuperSwiftFlyingMounts" then
      CategoryName = mySuperSwiftFlyingMountsCategories[CategoryId]
    elseif mountType == "mySwimmingMounts" then
      CategoryName = mySwimmingMountsCategories[CategoryId]
    end
    --print(mountType .. " Category Picker was: " .. tostring(CategoryName))
    local numberOfMounts = tablelength(myMounts[mountType][CategoryName])
    if numberOfMounts > 0 then
      local mountID = math.random(numberOfMounts)
      mount = myMounts[mountType][CategoryName][mountID][1]
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
  
  if superSwiftFlyingMount ~= nil then
    swiftFlyingMount = superSwiftFlyingMount
  end
  if swiftFlyingMount ~= nil then
    flyingMount = swiftFlyingMount
  end
  if swiftGroundMount ~= nil then
    groundMount = swiftGroundMount
  end

  return groundMount, flyingMount, swimmingMount
end

local function UpdateMacro(groundMount, flyingMount, swimmingMount)

    local groundMountMacro = ""
    local groundMountMacro2 = ""
    local flyingMountMacro = ""
    local swimmingMountMacro = ""
    local tooltip = ""

    if groundMount ~= nil then
      groundMountMacro = "\n/cast [nomounted,mod:alt] " .. tostring(groundMount)
      groundMountMacro2 = "\n/cast [nomounted] " .. tostring(groundMount)
      tooltip = tostring(groundMount)
    end
    if flyingMount ~= nil then
      flyingMountMacro = "\n/cast [nomounted,flyable] " .. tostring(flyingMount)
      if 	IsFlyableArea() then
        tooltip = tostring(flyingMount)
      end
    end
    if swimmingMount ~= nil then
      swimmingMountMacro = "\n/cast [swimming] " .. tostring(swimmingMount)
    end

    local body = "#showtooltip " .. "\n/stopcasting" .. groundMountMacro .. swimmingMountMacro .. flyingMountMacro .. groundMountMacro2 .. "\n/WRM" .. "\n/dismount"
    --print (body)
    EditMacro("Mount", "Mount", nil, body, 1, 1)
end

local function CheckIfItemInBags(item)
  local foundItem = false
  local _, itemLink = GetItemInfo(item)

  if itemLink ~= nil then
    for bagID = 0, NUM_BAG_SLOTS do
      for slotInBag = 1, GetContainerNumSlots(bagID) do
        if(GetContainerItemLink(bagID, slotInBag) == itemLink) then
          if inDebugMode then
            print("WRM Found: " .. GetContainerItemLink(bagID, slotInBag))
          end
          foundItem = true
        end
      end
    end
  end

  return foundItem
end

local function tableContains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local function AddMountMyMounts(type, category, mount)
  --print("AddMount:" .. type .. ", " .. category .. ", " .. tostring(mount))
  if myMounts[type][category] == nil then
    --myMounts[type].insert(key = category, val = {mount})
    myMounts[type][category] = {mount}
  else
    --myMounts[type][category].insert(mount)
    table.insert(myMounts[type][category], mount)
  end

end

local function UpdateMyMounts()
  myMounts = {
    ["myGroundMounts"] = {},
    ["mySwiftGroundMounts"] = {},
    ["myFlyingMounts"] = {},
    ["mySwiftFlyingMounts"] = {},
    ["mySuperSwiftFlyingMounts"] = {},
    ["mySwimmingMounts"] = {}
  }

  CompanionType = "MOUNT"
  MountsKnown = {}
  numMounts = GetNumCompanions(CompanionType)
  --print("Number of Mounts: " .. tostring(numMounts))
  mountCounter = 1
  while mountCounter <= numMounts do --numMounts
    creatureID, creatureName, creatureSpellID, icon, issummoned, mountType = GetCompanionInfo(CompanionType, mountCounter)
    --print(tostring(creatureSpellID))
    table.insert(MountsKnown, creatureSpellID)
    --print ("Mount: " .. tostring(mountCounter) .. ", Name: " .. tostring(creatureName) .. ", Type: " .. tostring(mountType))
    mountCounter = mountCounter + 1
  end

  for mount in pairs(WrathRandomMounter.itemMounts) do --2:SpellID, 4:MaxSpeed, 5:MinSpeed, 6:SwimSpeed, 7:Category
    if tableContains(MountsKnown, WrathRandomMounter.itemMounts[mount][2]) then
      --print(WrathRandomMounter.itemMounts[mount][4])
      if WrathRandomMounter.itemMounts[mount][5] <= 1 and WrathRandomMounter.itemMounts[mount][4] > 0 then
        --table.insert(myMounts["myGroundMounts"], WrathRandomMounter.itemMounts[mount])
        AddMountMyMounts("myGroundMounts", WrathRandomMounter.itemMounts[mount][7], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][5] <= 1 and WrathRandomMounter.itemMounts[mount][4] >=1 then
        --table.insert(myMounts["mySwiftGroundMounts"], WrathRandomMounter.itemMounts[mount])
        AddMountMyMounts("mySwiftGroundMounts", WrathRandomMounter.itemMounts[mount][7], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][4] > 1 then
        --table.insert(myMounts["myFlyingMounts"], WrathRandomMounter.itemMounts[mount])
        AddMountMyMounts("myFlyingMounts", WrathRandomMounter.itemMounts[mount][7], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][5] <= 2.8 and WrathRandomMounter.itemMounts[mount][4] >= 2.8 then
        --table.insert(myMounts["mySwiftFlyingMounts"], WrathRandomMounter.itemMounts[mount])
        AddMountMyMounts("mySwiftFlyingMounts", WrathRandomMounter.itemMounts[mount][7], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][4] > 2.8 then
        --table.insert(myMounts["mySuperSwiftFlyingMounts"], WrathRandomMounter.itemMounts[mount])
        AddMountMyMounts("mySuperSwiftFlyingMounts", WrathRandomMounter.itemMounts[mount][7], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][6] > 0 then
        --table.insert(myMounts["mySwimmingMounts"], WrathRandomMounter.itemMounts[mount])
        AddMountMyMounts("mySwimmingMounts", WrathRandomMounter.itemMounts[mount][7], WrathRandomMounter.itemMounts[mount])
      end
    end
  end
  
  for mountCategory, mounts in pairs(myMounts["myGroundMounts"]) do
    table.insert(myGroundMountsCategories, mountCategory)
  end
  for mountCategory, mounts in pairs(myMounts["mySwiftGroundMounts"]) do
    table.insert(mySwiftGroundMountsCategories, mountCategory)
  end
  for mountCategory, mounts in pairs(myMounts["myFlyingMounts"]) do
    table.insert(myFlyingMountsCategories, mountCategory)
  end
  for mountCategory, mounts in pairs(myMounts["mySwiftFlyingMounts"]) do
    table.insert(mySwiftFlyingMountsCategories, mountCategory)
  end
  for mountCategory, mounts in pairs(myMounts["mySuperSwiftFlyingMounts"]) do
    table.insert(mySuperSwiftFlyingMountsCategories, mountCategory)
  end
  for mountCategory, mounts in pairs(myMounts["mySwimmingMounts"]) do
    table.insert(mySwimmingMountsCategories, mountCategory)
  end

  --local mySwimmingMountsCategories = {}

  local numberOfMounts = tablelength(myMounts["myGroundMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["mySwiftGroundMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["myFlyingMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["mySwiftFlyingMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["mySuperSwiftFlyingMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["mySwimmingMounts"])

  myMountsPreviousCount = myMountsCount
  myMountsCount = numberOfMounts

  if inDebugMode then
    print("Total Mounts Found: " .. tostring(numberOfMounts))
    PrintMounts()
  end
end

local function InitialStartup(forceRunHandler, debugString)
  UpdateMyMounts()

  local groundMount, flyingMount, swimmingMount = GetRandomMounts()

  UpdateMacro(groundMount, flyingMount, swimmingMount)
end

local function InitialStartupHandler(forceRunHandler, debugString)
  InitialStartup(forceRunHandler, debugString)
  
  wrm_wait(10, InitialStartup, forceRunHandler, debugString)
end

local function WRMHandler(parameter)
    
  if(string.len(parameter) > 0) then
    if parameter == "list" then
      PrintMounts()
    elseif parameter == "update" then
      InitialStartupHandler()
    elseif parameter == "debug" then
      inDebugMode = true
    elseif parameter == "Mount" then
      CallCompanion("MOUNT", 2)
    elseif parameter == "Dismount" then
      DismissCompanion("MOUNT")
    else
      print(parameter)
    end
  else
    if myMountsCount ~= myMountsPreviousCount then --used to ensure that all mounts are found
      InitialStartup()
    end
    local groundMount, flyingMount, swimmingMount = GetRandomMounts()
    if IsMounted() == false then
      wrm_wait(0.1, UpdateMacro, groundMount, flyingMount, swimmingMount)
    end
  end

  if inDebugMode then
      print("WRM was called with parameter: " .. parameter)
  end
end

-- Initilize addon when entering world
local EnterWorldFrame = CreateFrame("Frame")
EnterWorldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EnterWorldFrame:SetScript("OnEvent", InitialStartupHandler)

-- Register slash commands
SlashCmdList["WRM"] = WRMHandler;



-- New API Commands
--CallCompanion(Type, ID) - uses companion
--DismissCompanion(Type) - dismisses compaion
--GetCompanionCooldown(Type, ID) - (startTime, duration, isEnabled)
--GetCompanionInfo - (creatureID, creatureName, creatureSpellID, icon, issummoned)
--GetNumCompanions(Type) - (NumberOfCompanions)
--PickupCompanion(Type, ID)


--Message: Interface\AddOns\WrathRandomMounter\main.lua:228: Usage: GetCompanionInfo(type, index)
--Time: Thu Jul 28 09:28:22 2022
--Count: 1
--Stack: Interface\AddOns\WrathRandomMounter\main.lua:228: Usage: GetCompanionInfo(type, index)
--[string "=[C]"]: in function `GetCompanionInfo'
--[string "@Interface\AddOns\WrathRandomMounter\main.lua"]:228: in function <Interface\AddOns\WrathRandomMounter\main.lua:222>
--
--Locals: (*temporary) = "MOUNT"
--(*temporary) = nil


--CompanionType = "MOUNT"
--numMounts = GetNumCompanions(CompanionType)
--print("Number of Mounts: " .. tostring(numMounts))
--mountCounter = 1
--while mountCounter <= numMounts do --numMounts
--  creatureID, creatureName, creatureSpellID, icon, issummoned, mountType = GetCompanionInfo(CompanionType, mountCounter)
--  print ("Mount: " .. tostring(mountCounter) .. ", Name: " .. tostring(creatureName) .. ", Type: " .. tostring(mountType))
--  mountCounter = mountCounter + 1
--end
