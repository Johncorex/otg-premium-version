dofile('data/modules/scripts/supplystash/supplystash.lua')
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getClient().os == CLIENTOS_NEW_WINDOWS then
	SupplyStash.sendOpenWindow(player)
	end
	return true
end