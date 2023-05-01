local mod = RegisterMod("Improved Creep Visibility", 1)
local game = Game()

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


mod.effectSpriteCache = {}

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



function mod:GetShaderParams(shaderName)
  if shaderName == 'VortexStreet' then
    local params = {
      Enabled = 1,
      Time = Isaac.GetFrameCount()
    }
    return params;
  end
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

---@param color Color
---@param step integer
---@return Color
local function nextRainbowColor(color, step)
  local result = color or Color(0, 0, 0)
  if (result.R > 0 and result.B == 0) then
    result.R = result.R - step
    result.G = result.G + step
  end
  if (result.G > 0 and result.R == 0) then
    result.G = result.G - step
    result.B = result.B + step
  end
  if (result.B > 0 and result.G == 0) then
    result.R = result.R + step
    result.B = result.B - step
  end
  print(result.R, result.G, result.B)
  return result
end

local invert = false
local invertCount = 0
local invertSteps = 1000

---comment
---@param effect EntityEffect
local function lerpEffectColor(effect)
  local sprite = effect:GetSprite()
  local color = Color(1, 1, 1, 1, 0, 0, 0)
  color:SetColorize(1, 1, 1, 2 * (invertCount / invertSteps))
  sprite.Color = color

  if invert then
    invertCount = invertCount - 1
  else
    invertCount = invertCount + 1
  end

  if (invertCount % invertSteps == 0) then
    invert = not invert
  end
end

-- local function deepcopy(orig)
--   local orig_type = type(orig)
--   local copy
--   if orig_type == 'table' then
--     copy = {}
--     for orig_key, orig_value in next, orig, nil do
--       copy[deepcopy(orig_key)] = deepcopy(orig_value)
--     end
--     setmetatable(copy, deepcopy(getmetatable(orig)))
--   else -- number, string, boolean, etc
--     copy = orig
--   end
--   return copy
-- end

---After effect init.
---@param effect EntityEffect
function mod:PostEffecInit(effect)
  --print('IsEnemyCreep(' .. tostring(effect.Variant) .. '): ', IsEnemyCreep(effect))
  if isEnemyCreep(effect) then
    -- local originalSprite = effect:GetSprite()
    -- local sprite = Sprite()
    -- sprite:Load(originalSprite:GetFilename(), true)
    -- sprite:ReplaceSpritesheet(1, "gfx/creep_effect.png")
    -- sprite:LoadGraphics()
    -- currentStep = currentStep + stepSize
    -- sprite.Color = nextRainbowColor(Color(sprite.Color.R, sprite.Color.G, sprite.Color.B), currentStep)
    -- invert = not invert
    -- local color = Color(1, 1, 1, 1, 0, 0, 0)
    -- color:SetColorize(1, 1, 1, 2)
    -- local sprite = effect:GetSprite()
    -- sprite.Color = color
    -- debugPrint(effect:GetSprite():GetFilename())
    -- local customEffect = Isaac.Spawn(
    --   effect.Type,
    --   effect.Variant,
    --   effect.SubType,
    --   effect.ParentOffset,
    --   effect.Velocity,
    --   effect.SpawnerEntity
    -- )
    -- mod.effects[GetPtrHash(customEffect)] = true

    -- local customCreep = Sprite()
    -- customCreep:Load("gfx/1000.022_creep (red).anm2", true)
    -- customCreep:ReplaceSpritesheet(1, "gfx/creep_effect.png")
    -- customCreep:LoadGraphics()
  end

  -- print(Effect.IsPlayerCreep(EffectVariant.CREEP_RED))
end

---Loads the sprite for the given effect and returns it. The sprite is stored in
---the cache for later use.
---@param effect EntityEffect
function mod:GetEffectSprite(effect)
  local effectHash = GetPtrHash(effect)
  local sprite = mod.effectSpriteCache[effectHash]
  if not sprite then
    local effectSprite = effect:GetSprite()

    sprite = Sprite()
    sprite:Load(effectSprite:GetFilename(), true)
    sprite:ReplaceSpritesheet(0, "gfx/creep_effect.png")
    sprite:LoadGraphics()
    sprite:SetFrame(effectSprite:GetAnimation(), effectSprite:GetFrame())
    sprite.Color = Color(1, 1, 1, 0.4)

    mod.effectSpriteCache[effectHash] = sprite
  end
  return sprite
end

---After effect rendering.
---@param effect EntityEffect
---@param offset Vector
function mod:PostEffectRender(effect, offset)
  if not isEnemyCreep(effect) then return end

  -- lerpEffectColor(effect)

  ---@type Sprite
  local effectSprite = effect:GetSprite()
  -- effectSprite:ReplaceSpritesheet(0, "gfx/creep_effect.png")
  -- effectSprite:LoadGraphics()

  local sprite = mod:GetEffectSprite(effect)
  sprite.Scale = effectSprite.Scale
  sprite:Update()
  sprite:Render(Isaac.WorldToRenderPosition(effect.Position + offset))
  -- local customEffect = Isaac.Spawn(
  --   effect.Type,
  --   effect.Variant,
  --   effect.SubType,
  --   effect.ParentOffset,
  --   effect.Velocity,
  --   effect.SpawnerEntity
  -- )
  -- mod.effects[GetPtrHash(customEffect)] = true

  -- local customCreep = Sprite()
  -- customCreep:Load("gfx/1000.022_creep (red).anm2", true)
  -- customEffect:GetSprite():ReplaceSpritesheet(1, "gfx/creep_effect.png")
  -- customEffect:GetSprite():LoadGraphics()
  -- print(effect:GetSprite():GetOverlayFrame())

  -- local originalColor = effect.Color
  -- local originalSpriteScale = effect.SpriteScale

  -- local color = Color(1, 1, 1, 1, 0, 0, 0)
  -- color:SetColorize(4, 0, 4, 1)
  -- effect.Color = color
  -- effect.Scale = 1.2
  --sprite:Render(offset)

  -- effect.SpriteScale = originalSpriteScale
  -- effect.Color = originalColor
end

---Called whenever an Entity gets removed by the game.
---@param entity EntityEffect
function mod:PostEntityRemove(entity)
  if not isEnemyCreep(entity) then return end
  mod.effectSpriteCache[GetPtrHash(entity)] = nil
end

-- mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.GetShaderParams)
-- mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.PostNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.PostEffecInit)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.PostEffectRender)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.PostEntityRemove, EntityType.ENTITY_EFFECT)
-- mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.PostRender)

-- From here on, only debug code
if not debug then
  return
end

local setupDone = false
function mod:SetUpDebug()
  setupDone = true
  local player = Isaac.GetPlayer()
  player:AddCollectible(CollectibleType.COLLECTIBLE_PUNCHING_BAG)
  player:AddCollectible(CollectibleType.COLLECTIBLE_GNAWED_LEAF)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CAMO_UNDIES)

  local enemy = game:Spawn(
    EntityType.ENTITY_BRAIN,       -- Type
    0,                             -- Variant
    game:GetRoom():GetCenterPos(), -- Position
    Vector.Zero,                   -- Velocity
    nil,                           -- Parent
    0,                             -- SubType
    game:GetRoom():GetSpawnSeed()  -- Seed
  )

  local entities = Isaac.GetRoomEntities()
  for _, value in pairs(entities) do
    debugPrint(value.Type)
    if value:IsEnemy() then
      debugPrint('Entity data:', dump(value:GetData()))
    end
  end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.SetUpDebug)
