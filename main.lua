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
  ["mySuperSwiftFlyingMounts"] = {}
}

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
    for mount in pairs(myMounts[mountType]) do
      if mountString == nil then
        mountString = myMounts[mountType][mount][1]
      else
        mountString = mountString .. ", " .. myMounts[mountType][mount][1]
      end
    end
    print(mountType .. ": " .. tostring(mountString))
  end
end

local function GetRandomMount(mountType)
  local numberOfMounts = tablelength(myMounts[mountType])

  local mount

  if numberOfMounts > 0 then
    local mountID = math.random(numberOfMounts)

    mount = myMounts[mountType][mountID][1]
  end

  return mount
end

local function GetRandomMounts()
  local groundMount = GetRandomMount("myGroundMounts")
  local swiftGroundMount = GetRandomMount("mySwiftGroundMounts")
  local flyingMount = GetRandomMount("myFlyingMounts")
  local swiftFlyingMount = GetRandomMount("mySwiftFlyingMounts")
  local superSwiftFlyingMount = GetRandomMount("mySuperSwiftFlyingMounts")
  
  if superSwiftFlyingMount ~= nil then
    swiftFlyingMount = superSwiftFlyingMount
  end
  if swiftFlyingMount ~= nil then
    flyingMount = swiftFlyingMount
  end
  if swiftGroundMount ~= nil then
    groundMount = swiftGroundMount
  end

  return groundMount, flyingMount
end

local function UpdateMacro(groundMount, flyingMount)

    local groundMountMacro = ""
    local groundMountMacro2 = ""
    local flyingMountMacro = ""
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

    local body = "#showtooltip " .. tooltip .. "\n/stopcasting" .. groundMountMacro .. flyingMountMacro .. groundMountMacro2 .. "\n/WRM" .. "\n/dismount"
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

local function UpdateMyMounts()
  myMounts = {
    ["myGroundMounts"] = {},
    ["mySwiftGroundMounts"] = {},
    ["myFlyingMounts"] = {},
    ["mySwiftFlyingMounts"] = {},
    ["mySuperSwiftFlyingMounts"] = {}
  }

  CompanionType = "MOUNT"
  MountsInBag = {}
  numMounts = GetNumCompanions(CompanionType)
  --print("Number of Mounts: " .. tostring(numMounts))
  mountCounter = 1
  while mountCounter <= numMounts do --numMounts
    creatureID, creatureName, creatureSpellID, icon, issummoned, mountType = GetCompanionInfo(CompanionType, mountCounter)
    --print(tostring(creatureSpellID))
    table.insert(MountsInBag, creatureSpellID)
    --print ("Mount: " .. tostring(mountCounter) .. ", Name: " .. tostring(creatureName) .. ", Type: " .. tostring(mountType))
    mountCounter = mountCounter + 1
  end

  for mount in pairs(WrathRandomMounter.itemMounts) do
    if tableContains(MountsInBag, WrathRandomMounter.itemMounts[mount][2]) then
      --print(WrathRandomMounter.itemMounts[mount][4])
      if WrathRandomMounter.itemMounts[mount][4] <= 1 then
        table.insert(myMounts["myGroundMounts"], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][4] == 1 then
        table.insert(myMounts["mySwiftGroundMounts"], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][4] > 1 then
        table.insert(myMounts["myFlyingMounts"], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][4] >= 2.8 then
        table.insert(myMounts["mySwiftFlyingMounts"], WrathRandomMounter.itemMounts[mount])
      end
      if WrathRandomMounter.itemMounts[mount][4] > 2.8 then
        table.insert(myMounts["mySuperSwiftFlyingMounts"], WrathRandomMounter.itemMounts[mount])
      end
    end
  end
  
  local numberOfMounts = tablelength(myMounts["myGroundMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["mySwiftGroundMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["myFlyingMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["mySwiftFlyingMounts"])
  numberOfMounts = numberOfMounts + tablelength(myMounts["mySuperSwiftFlyingMounts"])

  myMountsPreviousCount = myMountsCount
  myMountsCount = numberOfMounts

  if inDebugMode then
    print("Total Mounts Found: " .. tostring(numberOfMounts))
    PrintMounts()
  end
end

local function InitialStartup(forceRunHandler, debugString)
  UpdateMyMounts()

  local groundMount, flyingMount = GetRandomMounts()

  UpdateMacro(groundMount, flyingMount)
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
    local groundMount, flyingMount = GetRandomMounts()
    if IsMounted() == false then
      wrm_wait(0.1, UpdateMacro, groundMount, flyingMount)
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