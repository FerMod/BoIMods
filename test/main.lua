-- Author:      FerMod
-- Source Code: https://github.com/FerMod/BoIMods

local mod = RegisterMod("Mod Testing", 1)
local game = Game()


---Enables debug features like printing with `debugPrint`.
local debug = false
if not debug then return end

---Receives any number of arguments and prints their values to `stdout`.
---@param ... any
local function debugPrint(...)
  if not debug then return end
  print(...)
end

---Returns a `string` representation of `object`.
---@param object any
---@param indentLevel integer?
---@param indentStr string?
---@return string
local function dump(object, indentLevel, indentStr)
  local function quoteIfString(value)
    if type(value) ~= "string" then
      return tostring(value)
    end
    return '"' .. value .. '"'
  end

  if type(object) ~= 'table' then
    return quoteIfString(object)
  end

  indentLevel = indentLevel or 0
  indentStr = indentStr or '  '

  local s = '{'
  if next(object) then
    s = s .. '\n'
  end

  local currentIndentStr = string.rep(indentStr, indentLevel)
  for k, v in pairs(object) do
    s = s .. currentIndentStr .. '[' .. quoteIfString(k) .. '] = ' .. dump(v, indentLevel + 1) .. ',\n'
  end
  return s .. string.rep(indentStr, indentLevel - 1) .. '}'
end

function mod:DebugGiveLemegeton(player)
  if not player:HasCollectible(CollectibleType.COLLECTIBLE_LEMEGETON) then
    player:AddCollectible(CollectibleType.COLLECTIBLE_LEMEGETON, 12)
  end
end

function mod:SetUpDebug()
  local numPlayers = game:GetNumPlayers()
  for playerIndex = 0, numPlayers - 1 do
    local player = game:GetPlayer(playerIndex)
    player:AddCollectible(CollectibleType.COLLECTIBLE_GNAWED_LEAF)
    player:AddCollectible(CollectibleType.COLLECTIBLE_LEMEGETON, 12)
    -- player:AddCollectible(CollectibleType.COLLECTIBLE_HOURGLASS, 12, true, ActiveSlot.SLOT_SECONDARY)
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG)
    player:AddTrinket(TrinketType.TRINKET_DICE_BAG)
    -- player:AddPill(PillColor.PILL_BLUE_BLUE)
  end

  local room = game:GetRoom()
  local roomCenterPos = room:GetCenterPos()
  game:Spawn(
    EntityType.ENTITY_PICKUP,                    -- Type
    PickupVariant.PICKUP_COLLECTIBLE,            -- Variant
    roomCenterPos - Vector(40, 0),               -- Position
    Vector.Zero,                                 -- Velocity
    nil,                                         -- Parent
    CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, -- SubType
    room:GetSpawnSeed()                          -- Seed ('GetSpawnSeed' function gets a reproducible seed based on the room)
  )
  game:Spawn(
    EntityType.ENTITY_PICKUP,                  -- Type
    PickupVariant.PICKUP_COLLECTIBLE,          -- Variant
    roomCenterPos - Vector(80, 0),             -- Position
    Vector.Zero,                               -- Velocity
    nil,                                       -- Parent
    CollectibleType.COLLECTIBLE_DECK_OF_CARDS, -- SubType
    room:GetSpawnSeed()                        -- Seed ('GetSpawnSeed' function gets a reproducible seed based on the room)
  )
  game:Spawn(
    EntityType.ENTITY_PICKUP,              -- Type
    PickupVariant.PICKUP_COLLECTIBLE,      -- Variant
    roomCenterPos + Vector(30, 0),         -- Position
    Vector.Zero,                           -- Velocity
    nil,                                   -- Parent
    CollectibleType.COLLECTIBLE_LEMEGETON, -- SubType
    room:GetSpawnSeed()                    -- Seed ('GetSpawnSeed' function gets a reproducible seed based on the room)
  )
  game:Spawn(
    EntityType.ENTITY_PICKUP,              -- Type
    PickupVariant.PICKUP_COLLECTIBLE,      -- Variant
    roomCenterPos + Vector(80, 0),         -- Position
    Vector.Zero,                           -- Velocity
    nil,                                   -- Parent
    CollectibleType.COLLECTIBLE_LEMEGETON, -- SubType
    room:GetSpawnSeed()                    -- Seed ('GetSpawnSeed' function gets a reproducible seed based on the room)
  )

  Isaac.ExecuteCommand('keybinds 1')
  Isaac.ExecuteCommand('consolefade 1')
  Isaac.ExecuteCommand('pauseonfocuslost 0')
  Isaac.ExecuteCommand('mouse 0')
  Isaac.ExecuteCommand('debug 3')
  Isaac.ExecuteCommand('debug 8')
end

local function defaultStageOfFloor(StageOffset)
  if (StageOffset == 0) then
    print("Attempting to get default stage of floor 0. This is not recommended")
    return 0
  elseif (StageOffset <= 8) then
    return math.ceil(StageOffset / 2) * 3 - 2
  else
    return 10 + (StageOffset - 8) * 2
  end
end

function mod:TeleportPlayer()
  local level = game:GetLevel()
  if (level:GetStage() == LevelStage.STAGE1_2) then return end
  Isaac.ExecuteCommand('stage 2c')

  local roomCount = level:GetRoomCount()
  for roomIndex = 0, roomCount - 1 do
    local roomDesc = level:GetRooms():Get(roomIndex)
    if (mod:IsMirrorRoom(roomDesc)) then
      game:ChangeRoom(roomDesc.GridIndex)
      break
    end
  end

  mod:PostNewRoom()
  mod:PostNewLevel()
end

---Whether is the mirror room.
---@param roomDesc RoomDescriptor
---@return boolean
function mod:IsMirrorRoom(roomDesc)
  local roomData = roomDesc.Data
  debugPrint(roomData.Type, roomData.Variant, roomData.Subtype, roomData.Name)
  if (roomData.Type ~= RoomType.ROOM_DEFAULT) then
    return false
  end
  -- if (roomData.Variant ~= 10000 or roomData.Variant ~= 10001) then
  --   return false
  -- end
  -- if (roomData.Subtype ~= 34) then
  --   return false
  -- end

  return roomData.Name == "Mirror Room"
end

function mod:PostNewRoom()
  local level = game:GetLevel()
  level:RemoveCurses(255)
  level:ShowMap()

  local currentIndex = level:GetCurrentRoomIndex()
  local curRoomDesc = level:GetRoomByIdx(currentIndex)
  -- debugPrint('RoomIndex:', currentIndex, curRoomDesc.GridIndex)

  -- White Fire. Type: 33, Variant: 4, Subtype: 2
  -- Mirror. Type: 33, Variant: 4, Subtype: 2
  -- for _, v in pairs(Isaac.GetRoomEntities()) do
  --   debugPrint(v.Type, v.Variant, v.SubType, v:GetSprite():GetFilename())
  -- end

  --debugPrint('Stage: ', level:GetStage())
end

function mod:PostNewLevel()
end

function mod:PostGameStarted()
  self:TeleportPlayer()

  Isaac.GetPlayer():AddCollectible(CollectibleType.COLLECTIBLE_PYRO);
end

-- mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.DebugGiveLemegeton)
-- mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.SetUpDebug)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.PostNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.PostNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.PostGameStarted)
