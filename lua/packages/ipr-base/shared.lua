install( "packages/player-extensions", "https://github.com/Pika-Software/player-extensions" )
install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )

local ENTITY = FindMetaTable( "Entity" )

-- Entity:IsPlayerRagdoll()
function ENTITY:IsPlayerRagdoll()
    return ENTITY.GetNW2Bool( self, "player-ragdoll", false )
end

do

    local NULL = NULL

    -- Player:GetRagdollOwner()
    function ENTITY:GetRagdollOwner()
        if ENTITY.IsPlayerRagdoll( self ) then
            return ENTITY.GetCreator( self )
        end

        return NULL
    end

end

-- Player:GetRagdollEntity()
do

    local PLAYER = FindMetaTable( "Player" )

    function PLAYER:GetRagdollEntity()
        return ENTITY.GetNW2Entity( self, "player-ragdoll" )
    end

end

if CLIENT then return end
include( "init.lua" )