-- Author:      FerMod
-- Source Code: https://github.com/FerMod/BoIMods

local json = require("json")
local mod = RegisterMod("Start Item Options", 1)

local spawnPositions = {
  Vector(200, 400), -- Left
  Vector(250, 300), -- Top Left
  Vector(400, 300), -- Top Right
  Vector(450, 400), -- Right
}

local function defaultData()
  return {
    allowPickAnother = false,
    hasSpawnedItems = false,
    initialItems = {},
  }
end

local data = defaultData()

local debug = false
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

---Whether is a Repentance stage type.
---@param stageType StageType
---@return boolean
local function isRepentanceStage(stageType)
  if (stageType == StageType.STAGETYPE_REPENTANCE) then
    return true
  end
  if (stageType == StageType.STAGETYPE_REPENTANCE_B) then
    return true
  end
  return false
end

---Whether is the first stage of the run and is not `Ascent`.
---@return boolean
local function isFirstStage()
  local level = Game():GetLevel()
  if (level:GetStage() ~= LevelStage.STAGE1_1) then
    return false
  end
  if (isRepentanceStage(level:GetStageType())) then
    return false
  end
  if (level:IsAscent()) then
    return false
  end
  return true
end

---Wheter is the starting room.
---@return boolean
local function isStartingRoom()
  local level = Game():GetLevel()
  return level:GetCurrentRoomIndex() == level:GetStartingRoomIndex()
end

---Whether is not in Greed mode or a challenge run.
---@return boolean
local function isNormalRun()
  local game = Game()
  if (game:IsGreedMode()) then
    return false
  end
  if (game.Challenge ~= Challenge.CHALLENGE_NULL) then
    return false
  end

  return true
end

---Whether the current room is a treasure room.
---@return boolean
local function isTreasureRoom()
  local level = Game():GetLevel()
  return level:GetCurrentRoom():GetType() == RoomType.ROOM_TREASURE
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
  -- The enum ActiveSlot is only present in Rep
  if (not ActiveSlot) then
    return false
  end

  local player = Game():GetPlayer(playerIndex)
  for _, value in pairs(ActiveSlot) do
    if player:GetActiveItem(value) == itemId then
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
  local player = Game():GetPlayer(playerIndex)
  return player:HasCollectible(itemId)
end

---Check any player has the item id.
---@param itemId integer
---@return boolean
local function anyPlayerHasItem(itemId)
  local game = Game()
  local numPlayers = game:GetNumPlayers()
  --debugPrint('numPlayers', numPlayers)
  for playerIndex = 0, numPlayers - 1 do
    --debugPrint('player', playerIndex)

    if playerHasActive(playerIndex, itemId) == itemId then
      return true
    end

    if playerHasCollectible(playerIndex, itemId) then
      return true
    end
  end

  return false
end

---Returns the entity item config hash for the given `collectibleId`.
---@param collectibleId integer The collectible id. Sometimes also referred as `SubType`.
---@return integer hash Then entity item config hash.
local function entityHashCode(collectibleId)
  local itemConfig = Isaac.GetItemConfig():GetCollectible(collectibleId)
  return GetPtrHash(itemConfig)
end

---Spawn an item in the given `position` with an optional group index parameter.
---@param position Vector The position where the item should be spawned.
---@param optionGroupIndex integer? The option group index of the item. Defaults to 1.
---@return Entity entity The spawned entity.
local function spawnItem(position, optionGroupIndex)
  optionGroupIndex = optionGroupIndex or 1

  ---Anonymous function that spawns an item with the given `id`.
  ---If no id is given a random item is spawned.
  ---@param id integer? Defaults to 0.
  ---@return Entity
  local spawnEntity = function(id)
    local subType = id or CollectibleType.COLLECTIBLE_NULL
    local game = Game()
    local item = game:Spawn(
      EntityType.ENTITY_PICKUP, -- Type
      PickupVariant.PICKUP_COLLECTIBLE, -- Variant
      position, -- Position
      Vector.Zero, -- Velocity
      nil, -- Parent
      subType, -- SubType
      game:GetRoom():GetSpawnSeed()-- Seed ('GetSpawnSeed' function gets a reproducible seed based on the room)
    )
    game:GetItemPool():AddRoomBlacklist(item.SubType)
    return item
  end

  local entity = spawnEntity()
  if (anyPlayerHasItem(entity.SubType)) then
    debugPrint('Has item!', entity.SubType)
    entity:Remove()
    entity = spawnEntity()
  end

  if (optionGroupIndex) then
    entity:ToPickup().OptionsPickupIndex = optionGroupIndex
  end
  return entity
end

---Callback triggered after entering a new level.
function mod:postNewLevel()
  if (not isNormalRun()) then return end
  if (data.hasSpawnedItems) then return end
  if (not isFirstStage()) then return end

  debugPrint('postNewLevel')
  data.allowPickAnother = isCurseOfLabyrinth()
  data.hasSpawnedItems = true -- Prevent items from spawning again.
  data.initialItems = {}

  for _, position in ipairs(spawnPositions) do
    local entity = spawnItem(position)
    local itemConfigHash = entityHashCode(entity.SubType)
    debugPrint('Item(' .. tostring(itemConfigHash) .. '):', entity.SubType)
    data.initialItems[itemConfigHash] = true
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
  debugPrint('removeTreasure allowPickAnother', data.allowPickAnother)
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

---Check if the player has picked up any item and handle it if its one of the starting items.
---Does nothing if the player has not picked up any.
---@param player EntityPlayer The player entity.
local function handlePickedUpItem(player)
  if (player:IsItemQueueEmpty()) then return end

  local item = player.QueuedItem.Item
  local itemConfigHash = entityHashCode(item.ID)
  --debugPrint('postUpdate initialItem[' .. itemConfigHash .. ']', data.initialItems[itemConfigHash])
  if (not data.initialItems[itemConfigHash]) then return end

  Game():AddTreasureRoomsVisited()

  debugPrint('postUpdate allowPickAnother', data.allowPickAnother)
  if (data.allowPickAnother) then
    data.initialItems[itemConfigHash] = false
    return
  end

  mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, mod.postUpdate)
end

---Callback function that handles when the player has picked up an item.
function mod:postUpdate()
  if (not isNormalRun()) then return end
  if (not isFirstStage()) then return end
  if (not isStartingRoom()) then return end

  local game = Game()
  local numPlayers = game:GetNumPlayers()
  for playerIndex = 0, numPlayers - 1 do
    local player = Isaac.GetPlayer(playerIndex)
    --debugPrint('Player', playerIndex, 'IsItemQueueEmpty', player:IsItemQueueEmpty())
    handlePickedUpItem(player)
  end
end

---Parse mod data from a json and load it.
---@param jsonString string The json format string.
function mod:fromJson(jsonString)
  -- Load data from a file and parse it
  local jsonData = json.decode(jsonString)
  local result = {
    allowPickAnother = jsonData.allowPickAnother or false,
    hasSpawnedItems = jsonData.hasSpawnedItems or true,
    initialItems = jsonData.initialItems or {},
  }
  for _, value in ipairs(jsonData.initialItems) do
    result.initialItems[value] = true
  end

  return result
end

---Parse mod data to a json and save it.
---@return string
function mod:toJson()
  local jsonData = {
    allowPickAnother = data.allowPickAnother,
    hasSpawnedItems = data.hasSpawnedItems,
    initialItems = {},
  }
  for key, _ in pairs(data.initialItems) do
    table.insert(jsonData.initialItems, key)
  end

  -- Parse data to a json string
  return json.encode(jsonData)
end

---Load stored mod data.
---@param isContinued boolean Is continuing from a savestate.
function mod:loadModData(isContinued)
  debugPrint('isContinued: ', tostring(isContinued))
  if not mod:HasData() then return end
  if isContinued then
    -- Load data from file and parse it from a json string
    data = mod:fromJson(mod:LoadData())
  else
    data = defaultData()
  end
end

---Save mod data to a file.
---@param shouldSave boolean Whether the data should be saved to a file.
function mod:saveModData(shouldSave)
  debugPrint('shouldSave: ', tostring(shouldSave))
  if shouldSave then
    -- Parse data and save it to a file
    mod:SaveData(mod:toJson())
  else
    data = defaultData()
  end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.removeTreasure)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.postNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.loadModData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.saveModData)
