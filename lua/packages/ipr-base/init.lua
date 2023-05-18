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