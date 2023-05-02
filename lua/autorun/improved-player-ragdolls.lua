local ENTITY, PLAYER = FindMetaTable( "Entity" ), FindMetaTable( "Player" )
local NULL = NULL

-- Entity:GetPlayerColor()
function ENTITY:GetPlayerColor()
    return self:GetNW2Vector( "player-color", nil )
end

-- Entity:SetPlayerColor( vector )
function ENTITY:SetPlayerColor( vector )
    self:SetNW2Vector( "player-color", vector )
end

-- Entity:IsPlayerRagdoll()
function ENTITY:IsPlayerRagdoll()
    return self:GetNWBool( "improved-player-ragdolls", false )
end

-- Player:GetRagdollEntity()
function PLAYER:GetRagdollEntity()
    return self:GetNW2Entity( "improved-player-ragdolls", NULL )
end