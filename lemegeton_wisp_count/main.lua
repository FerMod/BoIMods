-- Author:      FerMod
-- Source Code: https://github.com/FerMod/BoIMods

local mod = RegisterMod("Lemegeton Wisp Count", 1)
local game = Game()

-- do return end

local offsetMultiplier = Vector(20, 12)

mod.positionBookOfVirtues = Vector(34, -6)
mod.position = Vector(10, 24)
-- mod.position = Vector(34, -6)
mod.wispCount = {}
mod.maxWisps = 26

---Enables debug features like printing with `debugPrint`.
local debug = true

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

function mod:SetUpDebug()
  local numPlayers = game:GetNumPlayers()
  for playerIndex = 0, numPlayers - 1 do
    local player = game:GetPlayer(playerIndex)
    player:AddCollectible(CollectibleType.COLLECTIBLE_GNAWED_LEAF)
    -- player:AddCollectible(CollectibleType.COLLECTIBLE_LEMEGETON, 12)
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


  Isaac.ExecuteCommand('keybinds 1')
  Isaac.ExecuteCommand('consolefade 1')
  Isaac.ExecuteCommand('pauseonfocuslost 0')
  Isaac.ExecuteCommand('mouse 0')
  Isaac.ExecuteCommand('debug 3')
  Isaac.ExecuteCommand('debug 8')
end

---Whether `object1` is the same as `object2`.
---Compares their pointer hash to perform the equality check.
---@param object1 any
---@param object2 any
---@return boolean
local function isSameEntity(object1, object2)
  return GetPtrHash(object1) == GetPtrHash(object2)
end

---Whether the given `entity` is a familiar.
---@param entity Entity
---@return boolean
local function isFamiliar(entity)
  if not entity then
    return false
  end
  return entity.Type == EntityType.ENTITY_FAMILIAR
end

---Whether the given `entity` is a wisp of *Lemegeton*.
---@param entity Entity
---@return boolean
local function isLemegetonWisp(entity)
  if not isFamiliar(entity) then
    return false
  end
  return entity.Variant == FamiliarVariant.ITEM_WISP;
end

---Whether the player has the *Lemegeton* active item.
---@param player EntityPlayer
---@return boolean
local function hasLemegeton(player)
  return player:HasCollectible(CollectibleType.COLLECTIBLE_LEMEGETON)
end

---Whether the player has the *Book Of Virtues* active item.
---@param player EntityPlayer
---@return boolean
local function hasBookOfVirtues(player)
  return player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES)
end

---Whether the player owns the familiar.
---@param player EntityPlayer
---@param familiar EntityFamiliar
---@return boolean
local function playerOwnsFamiliar(player, familiar)
  return isSameEntity(player, familiar.Player)
end

---Return the number of Lemegeton wisps.
---@param player EntityPlayer
---@return integer
local function lemegetonWispCount(player)
  local wispCount = 0
  local entities = Isaac.GetRoomEntities()
  for _, entity in ipairs(entities) do
    if isLemegetonWisp(entity) and playerOwnsFamiliar(player, entity:ToFamiliar()) then
      wispCount = wispCount + 1;
    end
  end
  return wispCount
end

---Returns the current hud offset.
---@return Vector
local function hudOffset()
  return offsetMultiplier * Options.HUDOffset + game.ScreenShakeOffset
end

---Whether the Font or Sprite is not `nil` and is loaded.
---@param resource Font | Sprite
local function isLoaded(resource)
  if not resource then
    return false
  end
  return resource:IsLoaded()
end

---Draws to the screen the text with the number of wisps and the maximum number of wisp.
---@param font Font
---@param wispCount integer
---@param maxWispCount integer
---@param position Vector
function DrawWispCountText(font, wispCount, maxWispCount, position)
  local maxWispAmount = math.max(wispCount, maxWispCount)
  local valueOutput = string.format("%1u/%u", wispCount, maxWispAmount)
  local renderPosition = position + hudOffset()

  font:DrawStringScaledUTF8(
    valueOutput,        -- string String
    renderPosition.X,   -- float PositionX,
    renderPosition.Y,   -- float PositionY,
    1,                  -- float ScaleX,
    1,                  -- float ScaleY,
    KColor(1, 1, 1, 1), -- KColor RenderColor,
    22,                 -- int BoxWidth = 0,
    true                -- boolean Center = false
  )
end

---Updates and returns the number of whisp that the player has.
---@param player EntityPlayer
---@return integer
function mod:UpdateWispCount(player)
  local wispCount = lemegetonWispCount(player)
  mod.wispCount[GetPtrHash(player)] = wispCount
  return wispCount
end

---Updates and returns the draw position of whisp count.
---@param player EntityPlayer
---@return Vector
function mod:UpdateCounterPosition(player)
  local position = mod.position
  if hasBookOfVirtues(player) then
    position = mod.positionBookOfVirtues
  end
  return position
end

---Pause animation if the game is paused. Otherwise, continue or resume animation.
---@param sprite Sprite
---@param animationName string? @default: "Idle"
local function updateAnimation(sprite, animationName)
  animationName = animationName or sprite:GetDefaultAnimation()

  if game:IsPaused() then
    sprite:Stop()
  else
    sprite:Play(animationName, false)
    sprite:Update()
  end
end

function mod:OnPostRender()
  if not game:GetHUD():IsVisible() then return end
  if not isLoaded(mod.font) then return end
  if not isLoaded(mod.sprite) then return end

  updateAnimation(mod.sprite)

  local numPlayers = game:GetNumPlayers()
  for playerIndex = 0, numPlayers - 1 do
    local player = game:GetPlayer(playerIndex)
    if hasLemegeton(player) then
      local wispCount = mod:UpdateWispCount(player)
      local position = mod:UpdateCounterPosition(player)
      mod:DrawWispCountText(mod.font, wispCount, mod.maxWisps, position)
    end
  end

---Load the font.
function mod:LoadFont()
  if mod.font then return end
  mod.font = Font()
  mod.font:Load("font/luaminioutlined.fnt")
end

---Load the wisp sprite.
function mod:LoadSprite()
  if mod.sprite then return end
  mod.sprite = Sprite()
  mod.sprite:Load("gfx/wisp.anm2", true)
  mod.sprite:Play("Idle")
  mod.sprite.Color = Color(1, 1, 1, 0.5)
end

---Called after a Player Entity is initialized.
---@param player EntityPlayer
function mod:PostPlayerInit(player)
  mod:LoadFont()
  mod:LoadSprite()
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.OnPostRender)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.PostPlayerInit)

if debug then
  mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.SetUpDebug)
  -- mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.setUpDebug)
end
