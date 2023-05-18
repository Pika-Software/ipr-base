import( gpm.PackageExists( "packages/player-extensions" ) and "packages/player-extensions" or "https://github.com/Pika-Software/player-extensions" )

local ENTITY, PLAYER = FindMetaTable( "Entity" ), FindMetaTable( "Player" )
local NULL = NULL

-- Entity:IsPlayerRagdoll()
function ENTITY:IsPlayerRagdoll()
    return self:GetNWBool( "improved-player-ragdolls", false )
end

-- Player:GetRagdollEntity()
function PLAYER:GetRagdollEntity()
    return self:GetNW2Entity( "improved-player-ragdolls", NULL )
end

if SERVER then
    include( "server.lua" )
end
