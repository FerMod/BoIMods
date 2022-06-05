local json = require("json")
local mod = RegisterMod("Start Item Options", 1)

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

local debug = true
local function debugPrint(...)
  if (not debug) then return end
  print(...)
end

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

---Whether is the first stage of the run
local function isFirstStage()
  return Game():GetLevel():GetStage() == 1
end

---Wheter is the starting room
---@return boolean
local function isStartingRoom()
  local level = Game():GetLevel()
  return level:GetCurrentRoomIndex() == level:GetStartingRoomIndex()
end

---Whether is not in Greed mode or a challenge run
local function isNormalRun()
  if (Game():IsGreedMode()) then
    return false
  end
  if (Game().Challenge ~= Challenge.CHALLENGE_NULL) then
    return false
  end

  return true
end

---Whether the current room is a treasure room
local function isTreasureRoom()
  return Game():GetLevel():GetCurrentRoom():GetType() == RoomType.ROOM_TREASURE
end

local function shouldRemoveCollectible()
  if not isTreasureRoom() then return false end
  return Game():GetRoom():IsFirstVisit() and data.allowPickAnother
end

---Whether the given `entity` is a collectible.
---@param entity Entity
---@return boolean
local function isCollectible(entity)
  return entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE
end

---Whether the current level has the curse 'Curse Of Labyrinth' active.
---@return boolean
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
  debugPrint('numPlayers', numPlayers)
  for playerIndex = 0, numPlayers - 1 do
    debugPrint('player', playerIndex)

    if playerHasActive(playerIndex, itemId) == itemId then
      return true
    end

    if playerHasCollectible(playerIndex, itemId) then
      return true
    end
  end

  return false
end

---Spawn an item in the given `position` with an optional group index parameter.
---@param position Vector The position where the item should be spawned.
---@param optionGroupIndex integer? The option group index of the item. Defaults to 1.
---@return integer id The spawned item id.
local function spawnItem(position, optionGroupIndex)
  optionGroupIndex = optionGroupIndex or 1

  local game = Game()
  local itemPool = game:GetItemPool()
  local collectibleId = itemPool:GetCollectible(
    ItemPoolType.POOL_TREASURE,
    false,
    game:GetRoom():GetSpawnSeed()
  )

  -- Anonymous function that spawns an item with the given id.
  -- If no id is given a random item is spawned.
  local spawnEntity = function(id)
    local subType = id or CollectibleType.COLLECTIBLE_NULL
    return game:Spawn(
      EntityType.ENTITY_PICKUP, -- Type
      PickupVariant.PICKUP_COLLECTIBLE, -- Variant
      position, -- Position
      Vector.Zero, -- Velocity
      nil, -- Parent
      subType, -- SubType
      game:GetRoom():GetSpawnSeed()-- Seed ('GetSpawnSeed' function gets a reproducible seed based on the room)
    )
  end

  local entity = spawnEntity()
  debugPrint(entity.SubType)
  if (anyPlayerHasItem(entity.SubType)) then
    debugPrint('Has item!', entity.SubType)
    spawnEntity()
  end

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

---Callback triggered after entering a new level.
function mod:postNewLevel()
  if (not isNormalRun()) then return end
  if (not isFirstStage()) then return end

  debugPrint('postNewLevel')
  data = {
    allowPickAnother = isCurseOfLabyrinth(),
    initialItems = {},
  }

  for _, position in ipairs(spawnPositions) do
    local itemId = spawnItem(position)
    data.initialItems[itemId] = true
  end

  debugPrint(dump(data))
  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.postUpdate)
end

---Callback function to remove collectibles from a treasure room.
function mod:removeTreasure()
  if (not isNormalRun()) then return end
  if (not isFirstStage()) then return end
  if (not isTreasureRoom()) then return end

  debugPrint('IsFirstVisit', Game():GetRoom():IsFirstVisit())
  if (not Game():GetRoom():IsFirstVisit()) then return end
  debugPrint('allowPickAnother', data.allowPickAnother)
  if (data.allowPickAnother) then
    -- Dont let pick other treasure room collectible (if present)
    data.allowPickAnother = false
    return
  end


  local entities = Isaac.GetRoomEntities()
  for _, entity in ipairs(entities) do
    if isCollectible(entity) then
      debugPrint('Removing', entity.SubType, 'from treasure room...')
      entity:Remove()
    end
  end

end

---Callback function that handles when the player has picked up an item.
function mod:postUpdate()
  if (not isNormalRun()) then return end
  if (not isFirstStage()) then return end
  if (not isStartingRoom()) then return end

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
    debugPrint(entity.Type, entity.Variant, entity.SubType, '|', isCollectible(entity), '|', data.initialItems[entity.SubType])
    if isCollectible(entity) and data.initialItems[entity.SubType] then
      entity:Remove()
    end
  end
  ]]
  mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, mod.postUpdate)
end

---Parse mod data from a json and load it.
function mod:fromJson()
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

---Parse mod data to a json and save it.
function mod:toJson()
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

---Load stored mod data.
---@param isContinued boolean Is continuing from a savestate.
function mod:loadData(isContinued)
  debugPrint('isContinued: ', tostring(isContinued))
  if isContinued and mod:HasData() then
    data = mod:fromJson()
  end
end

---Save mod data to a file.
---@param shouldSave boolean Whether the data should be saved to a file.
function mod:saveData(shouldSave)
  debugPrint('shouldSave: ', tostring(shouldSave))
  if shouldSave then return end
  mod:toJson()
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.loadData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.saveData)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.postNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.removeTreasure)
