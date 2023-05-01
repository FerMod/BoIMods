local mod = RegisterMod("Improved Creep Visibility", 1)
local game = Game()

---A table with the type of creep that will have the visibility change.
---@type table<BackdropType, boolean>
mod.creepEffectVariant = {
  [EffectVariant.CREEP_RED]                    = true,
  [EffectVariant.CREEP_GREEN]                  = true,
  [EffectVariant.CREEP_YELLOW]                 = true,
  [EffectVariant.CREEP_WHITE]                  = true,
  [EffectVariant.CREEP_BLACK]                  = true,
  [EffectVariant.CREEP_BROWN]                  = false,
  [EffectVariant.CREEP_SLIPPERY_BROWN]         = false,
  [EffectVariant.CREEP_SLIPPERY_BROWN_GROWING] = false,
  [EffectVariant.CREEP_STATIC]                 = false,
  [EffectVariant.CREEP_LIQUID_POOP]            = false,
}

---A table that contains which backdrops should have the sprite render enabled.
---@type table<BackdropType, boolean>
mod.enabledBackdrop = {
  [BackdropType.WOMB]  = true,
  [BackdropType.UTERO] = true,
}

---Cached effect sprites, used when rendering.
---@type table<integer, Sprite>
mod.effectSpriteCache = {}
mod.spriteColor = Color(1, 1, 1, 0.5)

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

---Whether the `EntityEffect` is a type of creep from an enemy.
---@param effect EntityEffect
---@return boolean
local function isEnemyCreep(effect)
  if effect.Type ~= EntityType.ENTITY_EFFECT then
    return false
  end
  if EntityEffect.IsPlayerCreep(effect.Variant) then
    return false
  end
  return mod.creepEffectVariant[effect.Variant] == true
end

---Whether the effect sprite should enable for the current room backdrop.
---@return boolean
function mod:IsEnabledForCurrentBackdrop()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local backdrop = room:GetBackdropType()
  return mod.enabledBackdrop[backdrop] == true
end

---Loads the sprite for the given effect and returns it. The sprite is stored in
---the cache for later use.
---@param effect EntityEffect
function mod:LoadEffectSprite(effect)
  local effectHash = GetPtrHash(effect)
  local sprite = mod.effectSpriteCache[effectHash]
  if not sprite then
    local effectSprite = effect:GetSprite()

    sprite = Sprite()
    sprite:Load(effectSprite:GetFilename(), true)
    sprite:ReplaceSpritesheet(0, "gfx/creep_effect.png")
    sprite:LoadGraphics()
    sprite.Color = mod.spriteColor

    mod.effectSpriteCache[effectHash] = sprite
  end
  return sprite
end

---Whether the sprite is loaded.
---@param effect EntityEffect
function mod:IsEffectSpriteLoaded(effect)
  local sprite = mod.effectSpriteCache[GetPtrHash(effect)]
  if not sprite then
    return false
  end

  return sprite:IsLoaded()
end

---Draws the effect sprite to the given position.
---@param effect EntityEffect
---@param position Vector
function mod:DrawEffectSprite(effect, position)
  local effectSprite = effect:GetSprite()
  local sprite = mod:LoadEffectSprite(effect)
  sprite:SetFrame(effectSprite:GetAnimation(), effectSprite:GetFrame())
  -- if effectSprite.Scale.X < Vector.One.X or effectSprite.Scale.Y < Vector.One.Y then
  --   mod.effectSpriteCache[GetPtrHash(effectSprite)] = nil
  --   return
  -- end
  sprite.Color = Color(
    mod.spriteColor.R,
    mod.spriteColor.G,
    mod.spriteColor.B,
    mod.spriteColor.A * effectSprite.Color
  )
  sprite.Scale = effectSprite.Scale
  sprite.Rotation = effectSprite.Rotation
  sprite.FlipX = effectSprite.FlipX
  sprite.FlipY = effectSprite.FlipY
  sprite.PlaybackSpeed = effectSprite.PlaybackSpeed
  sprite.Rotation = effectSprite.Rotation
  sprite.Offset = effectSprite.Offset

  sprite:Render(position)
end

---After effect init.
---@param effect EntityEffect
function mod:PostEffecInit(effect)
  if not mod:IsEnabledForCurrentBackdrop() then return end
  if not isEnemyCreep(effect) then return end
  if mod:IsEffectSpriteLoaded(effect) then return end
  mod:LoadEffectSprite(effect)
end

---After effect rendering.
---@param effect EntityEffect
---@param offset Vector
function mod:PostEffectRender(effect, offset)
  if not mod:IsEffectSpriteLoaded(effect) then return end

  -- local effectSprite = effect:GetSprite()
  -- effectSprite:ReplaceSpritesheet(0, "gfx/creep_effect.png")
  -- effectSprite:LoadGraphics()

  local position = Isaac.WorldToRenderPosition(effect.Position + offset)
  mod:DrawEffectSprite(effect, position)
end

---Called whenever an Entity gets removed by the game.
---@param entity EntityEffect
function mod:PostEntityRemove(entity)
  if not isEnemyCreep(entity) then return end
  mod.effectSpriteCache[GetPtrHash(entity)] = nil
end

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.PostEffecInit)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.PostEffectRender)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.PostEntityRemove, EntityType.ENTITY_EFFECT)

-- Only debug code from here on
if not debug then return end

function mod:DebugPostNewLevel()
  local player = Isaac.GetPlayer()
  player:AddCollectible(CollectibleType.COLLECTIBLE_PUNCHING_BAG)
  player:AddCollectible(CollectibleType.COLLECTIBLE_GNAWED_LEAF)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CAMO_UNDIES)
  player:AddCollectible(CollectibleType.COLLECTIBLE_DADS_KEY)

  local enemy = game:Spawn(
    EntityType.ENTITY_BRAIN,       -- Type
    0,                             -- Variant
    game:GetRoom():GetCenterPos(), -- Position
    Vector.Zero,                   -- Velocity
    nil,                           -- Parent
    0,                             -- SubType
    game:GetRoom():GetSpawnSeed()  -- Seed
  )

  Isaac.ExecuteCommand('keybinds 1')
  Isaac.ExecuteCommand('debug 3')
  Isaac.ExecuteCommand('debug 4')
  Isaac.ExecuteCommand('debug 8')
end

function mod:DebugPostPlayerInit(player)
  local level = game:GetLevel()
  level:SetNextStage()
  level:SetNextStage()
  level:SetNextStage()
  level:SetNextStage()
  level:SetNextStage()
  level:SetNextStage()
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.DebugPostNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.DebugPostPlayerInit)
