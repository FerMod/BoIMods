-- Author:      FerMod
-- Source Code: https://github.com/FerMod/BoIMods

local mod = RegisterMod("No Broken Mirror Death", 1)

---Whether the mirror dimension mirror is broken.
---@param level Level
---@return boolean
local function isMirrorDimensionMirrorBroken(level)
  if not level:GetCurrentRoom():IsMirrorWorld() then
    return false
  end
  return level:GetStateFlag(LevelStateFlag.STATE_MIRROR_BROKEN)
end

function mod:PostUpdate()
  local game = Game()
  local level = game:GetLevel()
  if not isMirrorDimensionMirrorBroken(level) then return end
  level:SetStateFlag(LevelStateFlag.STATE_MIRROR_BROKEN, false)
  game:GetHUD():ShowFortuneText('You fucked up', '. . .')
  game:ShowHallucination(100, BackdropType.DOWNPOUR)
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.PostUpdate)
