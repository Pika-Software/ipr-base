import( "https://gist.githubusercontent.com/PrikolMen/17cf58e562bc154076f067a54afc4822/raw/997b3839fae8f7d5e24e4aac0a68c3d76760eb6d/setf.lua" )

local ENTITY, PLAYER = FindMetaTable( "Entity" ), FindMetaTable( "Player" )
local packageName = _PKG:GetIdentifier()
local NULL = NULL

-- Entity:IsPlayerRagdoll()
function ENTITY:IsPlayerRagdoll()
    return self:GetNW2Entity( packageName, false ) ~= false
end

-- Player:GetRagdollEntity()
function PLAYER:GetRagdollEntity()
    return self:GetNW2Entity( packageName, NULL )
end

local getRagdollOwner = debug.setf( _PKG:GetIdentifier( "ENTITY.GetRagdollOwner", ENTITY.GetRagdollOwner ) )

function ENTITY:GetRagdollOwner()
    local entity = self:GetNW2Entity( packageName, false )
    if entity ~= false then
        return entity
    end

    return getRagdollOwner( self )
end

if SERVER then
    include( "server.lua" )
end

hook.Run( "IPR - Initialized" )