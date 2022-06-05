local json = require("json")
local mod = RegisterMod("Start Item Options", 1)

local debug = true
local function debugPrint(...)
  if (not debug) then return end
  print(...)
end

local spawnPositions = {
  Vector(250, 300),
  Vector(200, 400),
  Vector(400, 300),
  Vector(450, 400),
}

local data = {
  allowPickAnother = false,
  initialItems = {},
}


local function dump(object, indentLevel, indentStr)
  if type(object) == 'table' then
    indentLevel = indentLevel or 0
    indentStr = indentStr or '  '

    local currentIndentStr = ''
    for i = 1, indentLevel do
      currentIndentStr = currentIndentStr .. indentStr
    end

    local s = '{\n'
    for k, v in pairs(object) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. currentIndentStr .. '[' .. k .. '] = ' .. dump(v, indentLevel + 1) .. ',\n'
    end
    return s .. '}'
  else
    return tostring(object)
  end
end

--- Whether is the first stage of the run
local function isFirstStage()
  return Game():GetLevel():GetStage() == 1
end

--- Whether is not in Greed mode or a challenge run
local function isNormalRun()
  if (Game():IsGreedMode()) then
    return false
  end
  if (Game().Challenge ~= Challenge.CHALLENGE_NULL) then
    return false
  end

  return true
end

--- Whether the current room is a treasure room
local function isTreasureRoom()
  return Game():GetLevel():GetCurrentRoom():GetType() == RoomType.ROOM_TREASURE
end

local function shouldRemoveCollectible()
  if not isTreasureRoom() then return false end
  return Game():GetRoom():IsFirstVisit() and data.allowPickAnother
end

local function isCollectible(entity)
  return entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE
end

local function isCurseOfLabyrinth()
  local curse = Game():GetLevel():GetCurses()
  return (curse & LevelCurse.CURSE_OF_LABYRINTH) == LevelCurse.CURSE_OF_LABYRINTH
end

---Check player has active item in any of the 4 slots.
---@param playerIndex integer
---@param itemId integer
---@return boolean
local function playerHasActive(playerIndex, itemId)
  local player = Isaac.GetPlayer(playerIndex)
  for index = 0, 3 do
    if player:GetActiveItem(index) == itemId then
      return true
    end
  end
  return false
end

---Check player has collectible.
---@param playerIndex integer
---@param itemId integer
---@return boolean
local function playerHasCollectible(playerIndex, itemId)
  local player = Isaac.GetPlayer(playerIndex)
  return player:HasCollectible(itemId)
end

---Check any player has the item id.
---@param itemId integer
---@return boolean
local function anyPlayerHasItem(itemId)
  local game = Game()
  local numPlayers = game:GetNumPlayers()
  print('numPlayers', numPlayers)
  for playerIndex = 0, numPlayers - 1 do
    print('player', playerIndex)

    if playerHasActive(playerIndex, itemId) == itemId then
      return true
    end

    if playerHasCollectible(playerIndex, itemId) then
      return true
    end
  end

  return false
  -- return Isaac.GetPlayer():GetCollectibleNum(itemId, true) > 0;
end

local function spawnItem(position, optionGroupIndex)
  local game = Game()
  local itemPool = game:GetItemPool()
  local collectibleId = itemPool:GetCollectible(
    ItemPoolType.POOL_TREASURE,
    false,
    game:GetRoom():GetSpawnSeed()
  )

  local spawnEntity = function(id)
    local subType = id or CollectibleType.COLLECTIBLE_NULL
    return game:Spawn(
      EntityType.ENTITY_PICKUP, -- Type
      PickupVariant.PICKUP_COLLECTIBLE, -- Variant
      position, -- Position
      Vector.Zero, -- Velocity
      nil, -- Parent
      subType, -- SubType
      game:GetRoom():GetSpawnSeed()-- Seed (the "GetSpawnSeed()" function gets a reproducible seed based on the room, e.g. "2496979501")
    )
    --[[
    return Isaac.Spawn(
      EntityType.ENTITY_PICKUP, -- Type
      PickupVariant.PICKUP_COLLECTIBLE, -- Variant
      id, -- SubType
      position, -- Position
      Vector.Zero, -- Velocity
      nil-- Spawner
    )
    ]]
  end

  local entity = spawnEntity()
  --[[   print(entity.SubType)
  if (anyPlayerHasItem(entity.SubType)) then
    print('Has item!', entity.SubType)
    spawnEntity()
  end ]]


  -- local entity = Isaac.Spawn(
  --   EntityType.ENTITY_PICKUP,
  --   PickupVariant.PICKUP_COLLECTIBLE,
  --   collectibleId, -- 0
  --   position,
  --   Vector.Zero,
  --   nil
  -- )

  if (optionGroupIndex) then
    entity:ToPickup().OptionsPickupIndex = optionGroupIndex
  end
  return entity.SubType
end

-- Remove all collectibles from room
local function removeItems(whereCallback)
  whereCallback = whereCallback or true
  local entities = Isaac.GetRoomEntities()
  for _, entity in ipairs(entities) do
    if isCollectible(entity) and whereCallback then
      entity:Remove();
    end
  end
end

function mod:postNewLevel()
  if (not isNormalRun()) then return end
  if (not isFirstStage()) then return end

  print('postNewLevel')
  data = {
    allowPickAnother = isCurseOfLabyrinth(),
    initialItems = {},
  }

  for _, position in ipairs(spawnPositions) do
    local itemId = spawnItem(position, 1)
    data.initialItems[itemId] = true
  end

  print(dump(data))
  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.postUpdate)


  --[[  for _, position in ipairs(spawnPositions) do
    local collectibleID = itemPool:GetCollectible(
      ItemPoolType.POOL_TREASURE,
      true,
      Game():GetRoom():GetSpawnSeed()
    )
    local entity = Isaac.Spawn(
      EntityType.ENTITY_PICKUP,
      PickupVariant.PICKUP_COLLECTIBLE,
      -- collectibleID
      0,
      position,
      Vector.Zero,
      nil
    )
    entity:ToPickup().OptionsPickupIndex = 1

    -- local collectibleID = entity.SubType
    data.initialItems[collectibleID] = true
  end ]]

end

function mod:removeTreasure()
  if (not isNormalRun()) then return end
  if (not isFirstStage()) then return end
  if (not isTreasureRoom()) then return end
  print('IsFirstVisit', Game():GetRoom():IsFirstVisit())
  if (not Game():GetRoom():IsFirstVisit()) then return end
  print('allowPickAnother', data.allowPickAnother)
  if (data.allowPickAnother) then
    -- Dont let pick other treasure room collectible (if present)
    data.allowPickAnother = false
    return
  end


  local entities = Isaac.GetRoomEntities()
  for _, entity in ipairs(entities) do
    if isCollectible(entity) then
      print(entity.SubType)
      entity:Remove()
    end
  end

end

function mod:postUpdate()
  if (not isNormalRun()) then return end
  if (not isFirstStage()) then return end

  local player = Isaac.GetPlayer()
  if (player:IsItemQueueEmpty()) then return end

  local item = player.QueuedItem.Item
  if (not data.initialItems[item.ID]) then return end

  Game():AddTreasureRoomsVisited()

  if (data.allowPickAnother) then
    data.allowPickAnother = false
    data.initialItems[item.ID] = false
    return
  end

  --[[
  -- Remove our spawned collectibles
  local entities = Isaac.GetRoomEntities()
  for _, entity in ipairs(entities) do
    print(entity.Type, entity.Variant, entity.SubType, '|', isCollectible(entity), '|', data.initialItems[entity.SubType])
    if isCollectible(entity) and data.initialItems[entity.SubType] then
      entity:Remove()
    end
  end
  ]]
  mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, mod.postUpdate)
end

local function fromJson()
  -- Load data from a file and parse it
  local jsonData = json.decode(mod:LoadData())
  local result = {
    allowPickAnother = jsonData.allowPickAnother or false,
    initialItems = jsonData.initialItems or {},
  }
  for _, value in ipairs(jsonData.initialItems) do
    result.initialItems[value] = true
  end

  return result
end

local function toJson()
  local jsonData = {
    allowPickAnother = data.allowPickAnother,
    initialItems = {},
  }
  for key, _ in pairs(data.initialItems) do
    table.insert(jsonData.initialItems, key)
  end

  -- Parse data and save it to a file
  mod:SaveData(json.encode(jsonData))
end

function mod:loadData(isContinued)
  print('isContinued: ', tostring(isContinued))
  if isContinued and mod:HasData() then
    data = fromJson()
  end
end

function mod:saveData(shouldSave)
  print('shouldSave: ', tostring(shouldSave))
  if not shouldSave then return end
  toJson()
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.loadData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.saveData)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.postNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.removeTreasure)
