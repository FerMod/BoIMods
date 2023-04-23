-- Author:      FerMod
-- Source Code: https://github.com/FerMod/BoIMods

local mod = RegisterMod("Lemegeton Wisp Count", 1)
local game = Game()

local offsetMultiplier = Vector(20, 12)
local MAX_LEMEGETON_WISP = 26;

mod.position = Vector(10, 24)
mod.wispCount = {}

-- Enables debug features like printing with `debugPrint`.
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

function mod:setUpDebug()
  debugPrint('SetUpDebug')


  local player = Isaac.GetPlayer()
  player:AddCollectible(CollectibleType.COLLECTIBLE_LEMEGETON, 100)
  player:AddCollectible(CollectibleType.COLLECTIBLE_GNAWED_LEAF)
  --player:AddCollectible(CollectibleType.COLLECTIBLE_CAMO_UNDIES)


  -- game:Spawn(
  --   EntityType.ENTITY_HOST,           -- Type
  --   0,                                -- Variant
  --   player.Position + Vector(0, -20), -- Position
  --   Vector.Zero,                      -- Velocity
  --   nil,                              -- Parent
  --   0,                                -- SubType
  --   Game():GetRoom():GetSpawnSeed()   -- Seed
  -- )

  Isaac.ExecuteCommand('keybinds 1')
  Isaac.ExecuteCommand('consolefade 1')
  Isaac.ExecuteCommand('pauseonfocuslost 0')
  Isaac.ExecuteCommand('mouse 0')
end

---Whether the given `entity` is a familiar.
---@param entity Entity
---@return boolean
local function IsFamiliar(entity)
  return entity.Type == EntityType.ENTITY_FAMILIAR
end

---Whether the given `familiar` is a Lemegeton wisp.
---@param entity Entity
---@return boolean
local function IsLemegetonWisp(entity)
  if (not IsFamiliar(entity)) then
    return false
  end
  return entity.Variant == FamiliarVariant.ITEM_WISP;
end

---Return the number of Lemegeton wisps.
---@param player EntityPlayer
---@return integer
local function LemegetonWispCount(player)
  local wispCount = 0
  local entities = Isaac.GetRoomEntities()
  for _, entity in ipairs(entities) do
    if IsLemegetonWisp(entity) then
      wispCount = wispCount + 1;
    end
  end
  return wispCount
end

---Whether the player has the Lemegeton item.
---@param player EntityPlayer
---@return boolean
local function HasLemegeton(player)
  return player:HasCollectible(CollectibleType.COLLECTIBLE_LEMEGETON)
end

---Returns the current hud offset.
---@return Vector
local function HudOffset()
  return offsetMultiplier * Options.HUDOffset + game.ScreenShakeOffset
end

function mod:useItem(collectibleType, rng, player, useFlag, activeSlot, varData)
  if (not debug) then return end
  return {
    Discharge = false,
    Remove = false,
    ShowAnim = false,
  }
end

function mod:onPostRender()
  if not mod.font then return end

  local player = Isaac.GetPlayer()
  if not HasLemegeton(player) then return end

  local renderPosition = mod.position + HudOffset()

  local wispCount = LemegetonWispCount(player)
  local maxWispCount = math.max(wispCount, MAX_LEMEGETON_WISP)
  local valueOutput = string.format("%1u/%u", wispCount, maxWispCount)
  mod.font:DrawString(valueOutput, renderPosition.X, renderPosition.Y, KColor(1, 1, 1, 1), 0, true)

  -- local iconPosition = mod.position + Vector(0, 22)
  -- mod.hudSprite:Render(iconPosition)
  -- mod.font:DrawString(valueOutput, mod.position.X + 8, mod.position.Y + 1, KColor(1, 1, 1, 0.5), 0, true)
end

---Called after a Player Entity is initialized.
---@param player EntityPlayer
function mod:postPlayerInit(player)
  local itemConfig = Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_LEMEGETON)
  mod.hudSprite = Sprite()
  mod.hudSprite:Load("gfx/005.100_Collectible.anm2", true)
  mod.hudSprite:ReplaceSpritesheet(1, itemConfig.GfxFileName)
  mod.hudSprite:LoadGraphics()
  mod.hudSprite:SetFrame("Idle", 8)
  mod.hudSprite.Color = Color(1, 1, 1, 0.45)
  mod.hudSprite.Scale = Vector(0.5, 0.5)

  mod.font = Font()
  mod.font:Load("font/luaminioutlined.fnt")
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onPostRender)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.postPlayerInit)

if debug then
  mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.useItem, CollectibleType.COLLECTIBLE_LEMEGETON)
  mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.setUpDebug)
end
