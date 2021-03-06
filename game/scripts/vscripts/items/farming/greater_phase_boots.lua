item_greater_phase_boots = class({})

LinkLuaModifier( "modifier_item_greater_phase_boots_active", "items/farming/greater_phase_boots.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_greater_phase_boots:GetAbilityTextureName (brokenAPI)
  return self.BaseClass.GetAbilityTextureName(self)
end

function item_greater_phase_boots:GetIntrinsicModifierName()
	-- we're not modifying the passive benefits at all
	-- ( besides the numbers )
	-- so we can just reuse the normal phase boot modifier
	return "modifier_item_phase_boots"
end

--------------------------------------------------------------------------------

function item_greater_phase_boots:OnSpellStart()
	local caster = self:GetCaster()

	-- play the sound
	caster:EmitSound( "DOTA_Item.PhaseBoots.Activate" )

	-- add the new phase modifier
	caster:AddNewModifier( caster, self, "modifier_item_greater_phase_boots_active", { duration = self:GetSpecialValueFor( "phase_duration" ) } )
end

--------------------------------------------------------------------------------

modifier_item_greater_phase_boots_active = class({})

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:IsHidden()
	return false
end

function modifier_item_greater_phase_boots_active:IsDebuff()
	return false
end

function modifier_item_greater_phase_boots_active:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:GetEffectName()
	return "particles/items2_fx/phase_boots.vpcf"
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:OnCreated( event )
	local spell = self:GetAbility()

	self.moveSpd = spell:GetSpecialValueFor( "phase_movement_speed" )
	self.moveSpdRange = spell:GetSpecialValueFor( "phase_movement_speed_range" )
	self.dmgReduction = spell:GetSpecialValueFor( "phase_attack_outgoing" ) - 100

	if IsServer() then
		-- set up the table that stores the targets already hit
		self.hitTargets = {}

		-- start thinking
		-- we call OnIntervalThink to make it so it can go into effect immediately
		-- as StartIntervalThink waits for the interval to pass first
		self:OnIntervalThink()
		self:StartIntervalThink( 1 / 30 )
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:OnRefresh( event )
	local spell = self:GetAbility()

	self.moveSpd = spell:GetSpecialValueFor( "phase_movement_speed" )
	self.moveSpdRange = spell:GetSpecialValueFor( "phase_movement_speed_range" )
	self.dmgReduction = spell:GetSpecialValueFor( "phase_attack_outgoing" ) - 100

	if IsServer() then
		-- clear the tagets hit table on refresh
		self.hitTargets = {}
	end
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_item_greater_phase_boots_active:HasHitUnit( target )
		for _, unit in pairs( self.hitTargets ) do
			if unit == target then
				return true
			end
		end

		return false
	end

--------------------------------------------------------------------------------

	function modifier_item_greater_phase_boots_active:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- find all enemy creeps in range
		local units = FindUnitsInRadius(
			parent:GetTeamNumber(),
			parent:GetAbsOrigin(),
			nil,
			spell:GetSpecialValueFor( "phase_radius" ),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false
		)

		-- tell this modifier to reduce the damage of any further attacks
		-- aka, the instant attacks
		self.doReduction = true

		for _, unit in pairs( units ) do
			-- we don't hit units that have already been hit by this cast
			-- or those that are controlled by a player
			if not unit:IsControllableByAnyPlayer() and not self:HasHitUnit( unit ) then
				-- add the unit to the targets hit list
				table.insert( self.hitTargets, unit )

				-- do an instant attack with no projectile that applies procs
				parent:PerformAttack( unit, true, true, true, false, false, false, true )

				-- play the particle
				local part = ParticleManager:CreateParticle( "particles/items/phase_divehit.vpcf", PATTACH_ABSORIGIN, unit )
				ParticleManager:SetParticleControlEnt( part, 1, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true )
				ParticleManager:ReleaseParticleIndex( part )
			end
		end

		-- undo the damage reduction, so it doesn't leak into actual attacks
		self.doReduction = false
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:GetModifierMoveSpeedBonus_Percentage( event )
	local spell = self:GetAbility()
	local parent = self:GetParent()

	if parent:IsRangedAttacker() then
		return self.moveSpdRange or spell:GetSpecialValueFor( "phase_movement_speed_range" )
	end

	return self.moveSpd or spell:GetSpecialValueFor( "phase_movement_speed" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:GetModifierDamageOutgoing_Percentage( event )
	local spell = self:GetAbility()
	local parent = self:GetParent()

	if self.doReduction then
		return self.dmgReduction or spell:GetSpecialValueFor( "phase_attack_outgoing" ) - 100
	end

	return 0
end

--------------------------------------------------------------------------------

item_greater_phase_boots_2 = item_greater_phase_boots
item_greater_phase_boots_3 = item_greater_phase_boots
item_greater_phase_boots_4 = item_greater_phase_boots
item_greater_phase_boots_5 = item_greater_phase_boots
