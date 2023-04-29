-- Author:      FerMod
-- Source Code: https://github.com/FerMod/BoIMods

local mod = RegisterMod("Lemegeton Wisp Count", 1)
local game = Game()

local offsetMultiplier = Vector(20, 12)

mod.position = Vector(-12, -14)
mod.alignment = Vector(0.5, 1)

---@type table<integer, integer>
mod.wispCount = {}
mod.maxWisps = 26
mod.fontColor = KColor(1, 1, 1, 1)
---@type table<integer, Color>
mod.playerColorize = {
  Color(0, 0, 0, 0),   -- Default color
  Color(0, 1, 2, 1),   -- Blue
  Color(1, 2.5, 0, 1), -- Lime
  Color(3, 2.5, 0, 1), -- Yellow
  Color(3, 1.5, 1, 1), -- Orange
  Color(3, 0, 0, 1),   -- Red
  Color(0, 3, 0, 1),   -- Green
  Color(2, 2, 2, 1),   -- White
}

---Enables debug features like printing with `debugPrint`.
local debug = false

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
  --TODO get closest side of screen?
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

---Pause animation if the game is paused. Otherwise, continue or resume animation.
---@param sprite Sprite
---@param animationName string? @default: The sprite default animation
local function updateAnimation(sprite, animationName)
  animationName = animationName or sprite:GetDefaultAnimation()

  if game:IsPaused() then
    sprite:Stop()
  else
    sprite:Play(animationName, false)
    sprite:Update()
  end
end

---Whether the HUD is visible.
---@return boolean
local function isHudVisible()
  if not game:GetHUD():IsVisible() then
    return false
  end
  if not Options.FoundHUD then
    return false
  end
  if game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) then
    return false
  end
  return true
end

---Returns the player color with the given `playerIndex` index.
---@param playerIndex integer
---@return Color
function mod:playerWispColor(playerIndex)
  local colorize = mod.playerColorize[playerIndex + 1]

  local color = Color(1, 1, 1, 1)
  color:SetColorize(colorize.R, colorize.G, colorize.B, colorize.A)
  return color
end

---Returns the position where the element aligns in the screen.
---@return Vector
function mod:GetAlignmentPosition()
  local screenSize = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
  return screenSize * mod.alignment
end

---The element position in the screen.
---@return Vector
function mod:GetPosition()
  return self.position + mod:GetAlignmentPosition() + hudOffset()
end

---Draws to the screen the text with the number of wisps and the maximum number of wisp.
---@param wispCount integer
---@param maxWispCount integer
---@param position Vector
function mod:DrawWispCountText(wispCount, maxWispCount, position)
  -- local maxWispAmount = math.min(wispCount, maxWispCount)
  local valueOutput = string.format("%1u/%u", wispCount, maxWispCount)
  self.font:DrawStringScaledUTF8(
    valueOutput,    -- string String
    position.X,     -- float PositionX,
    position.Y,     -- float PositionY,
    1,              -- float ScaleX,
    1,              -- float ScaleY,
    self.fontColor, -- KColor RenderColor,
    0,              -- int BoxWidth = 0,
    false           -- boolean Center = false
  )
end

---Draws to the screen the text with the number of wisps and the maximum number of wisp.
---@param playerNum integer
---@param position Vector
function mod:DrawNumPlayerText(playerNum, position)
  mod.font:DrawStringScaledUTF8(
    tostring(playerNum), -- string String
    position.X,          -- float PositionX,
    position.Y,          -- float PositionY,
    0.5,                 -- float ScaleX,
    0.5,                 -- float ScaleY,
    KColor(1, 1, 1, 1),  -- KColor RenderColor,
    0,                   -- int BoxWidth = 0,
    false                -- boolean Center = false
  )
end

---Updates and returns the number of whisp that the player has.
---@param player EntityPlayer
---@return integer?
function mod:UpdateWispCount(player)
  ---@type number?
  local wispCount = lemegetonWispCount(player)
  if not hasLemegeton(player) and wispCount == 0 then
    wispCount = nil
  end
  mod.wispCount[GetPtrHash(player)] = wispCount
  return wispCount
end

---Updates and returns the draw position of whisp count.
---@param player EntityPlayer
---@return Vector
---@deprecated
function mod:UpdateCounterPosition(player)
  local position = mod:GetPosition()
  if hasBookOfVirtues(player) then
    position = mod.positionBookOfVirtues
  end
  return position
end

---Draw the wisp counter in a position on the screen. When `hasMultiplePlayers`
---is not false, then the player number (`playerIndex + 1`) e wisps.
---will be displayed
---on top of the wisp to indicate to which player belongs th
---The first player has a wisp with the original color, and the next players has
---a wisp of different color.
---@param position Vector
---@param wispCount integer
---@param playerIndex integer? @default: 0
---@param hasMultiplePlayers boolean?  @default: false
function mod:DrawWispCounter(position, wispCount, playerIndex, hasMultiplePlayers)
  playerIndex = playerIndex or 0
  hasMultiplePlayers = hasMultiplePlayers or false

  local iconOffset = Vector(4, 6)
  mod.sprite.Color = mod:playerWispColor(playerIndex)
  mod.sprite:Render(position + iconOffset)

  -- local position = mod:UpdateCounterPosition(player)

  local fontOffset = Vector(iconOffset.X + 6, 0)
  mod:DrawWispCountText(wispCount, mod.maxWisps, position + fontOffset)

  if hasMultiplePlayers then
    local playerNumOffset = Vector(3, iconOffset.Y / 2 + 2)
    mod:DrawNumPlayerText(playerIndex + 1, position + playerNumOffset)
  end
end

function mod:OnPostRender()
  if not isHudVisible() then return end
  if not isLoaded(mod.font) then return end
  if not isLoaded(mod.sprite) then return end

  updateAnimation(mod.sprite)

  local currentOffset = Vector.Zero
  local numPlayers = game:GetNumPlayers()
  local hasMultiplePlayers = numPlayers > 1
  for playerIndex = numPlayers - 1, 0, -1 do
    local player = game:GetPlayer(playerIndex)
    local wispCount = mod:UpdateWispCount(player)

    if wispCount then
      -- mod:DrawWispCounter(position + currentOffset, wispCount, playerNum)
      -- currentOffset = currentOffset + Vector(0, -10)

      -- mod:ChangeSpriteColor(playerNum + 1)
      -- mod:DrawWispCounter(position + currentOffset, wispCount, playerNum + 1)
      -- currentOffset = currentOffset + Vector(0, -10)

      -- mod:ChangeSpriteColor(playerNum + 2)
      -- mod:DrawWispCounter(position + currentOffset, wispCount, playerNum + 2)
      -- currentOffset = currentOffset + Vector(0, -10)

      -- mod:ChangeSpriteColor(playerNum + 3)
      -- mod:DrawWispCounter(position + currentOffset, wispCount, playerNum + 3)
      -- currentOffset = currentOffset + Vector(0, -10)
      local position = mod:GetPosition()
      mod:DrawWispCounter(position + currentOffset, wispCount, playerIndex, hasMultiplePlayers)
      currentOffset = currentOffset + Vector(0, -10)
    end
  end
end

---Load the font.
function mod:LoadFont()
  if isLoaded(mod.font) then return end
  mod.font = Font()
  mod.font:Load("font/luaminioutlined.fnt")
end

---Load the wisp sprite.
function mod:LoadSprite()
  if isLoaded(mod.sprite) then return end
  mod.sprite = Sprite()
  mod.sprite:Load("gfx/wisp.anm2", true)
  mod.sprite:Play(mod.sprite:GetDefaultAnimation())
  mod.sprite.Color = Color(1, 1, 1, 0.5)
  mod.sprite.Scale = Vector(0.5, 0.5)
end

---Called after a Player Entity is initialized.
---@param player EntityPlayer
function mod:PostPlayerInit(player)
  mod:LoadFont()
  mod:LoadSprite()

  mod:DebugGiveLemegeton(player)
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.OnPostRender)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.PostPlayerInit)

if debug then
  mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.SetUpDebug)
  -- mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.setUpDebug)
end
