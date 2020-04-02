local defensor = {
	["eshtaba the conjurer"] = Position(33093, 31919, 15),
	["dorokoll the mystic"] = Position(33095, 31925, 15),
	["mezlon the defiler"] = Position(33101, 31925, 15),
	["eliz the unyielding"] = Position( 33103, 31919, 15),
	["malkhar deathbringer"] = Position(33098, 31915, 15),
}

function onCreatureMove(self, creature, oldPosition, newPosition)
	local monster = defensor[self:getName():lower()]
	if monster then
		local protector = 'pillar of'
		local pMonster = Tile(Position(monster)):getTopCreature()
		if not pMonster then
			return true
		end
		if pMonster:getName():lower():find(protector) then
			return false
		end
	end
end
