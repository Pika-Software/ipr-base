import( "https://gist.githubusercontent.com/PrikolMen/17cf58e562bc154076f067a54afc4822/raw/d873b3cef8e56ce7728530e5158021ce77348822/setf.lua" )

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

local getRagdollOwner = debug.setf( _PKG:GetIdentifier( "ENTITY.GetRagdollOwner" ), ENTITY.GetRagdollOwner )

-- Player:GetRagdollOwner()
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