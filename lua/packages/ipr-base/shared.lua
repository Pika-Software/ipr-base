install( "packages/player-extensions", "https://github.com/Pika-Software/player-extensions" )
install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:IsPlayerRagdoll()
    function ENTITY:IsPlayerRagdoll()
        return self:GetNW2Bool( "player-ragdoll", false )
    end

    -- Player:GetRagdollOwner()
    function ENTITY:GetRagdollOwner()
        if not self:IsPlayerRagdoll() then return end
        return self:GetCreator()
    end

end

-- Player:GetRagdollEntity()
do

    local PLAYER = FindMetaTable( "Player" )

    function PLAYER:GetRagdollEntity()
        return self:GetNW2Entity( "player-ragdoll" )
    end

end

if CLIENT then return end
include( "init.lua" )