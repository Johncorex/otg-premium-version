---
--- JetBrains CLion
--- Created by Leonardo Pereira.
--- DateTime: 16/01/18 14:33
---

DailyRewardSystem = {
    Developer = "Leu (jlcvp@github)",
    Version = "0.3",
    lastUpdate = "28/03/2019"
}

local exhaustTime = 5 -- seconds

local ServerPackets = {
    DailyRewardCollectionState = 0xDE, -- 222 --client 11 flag?
    OpenRewardWall = 0xE2, -- 226
    CloseRewardWall = 0xE3, -- 227
    DailyRewardBasic = 0xE4,-- 228
    DailyRewardHistory = 0xE5 -- 229
}

local ClientPackets ={
    OpenRewardWallButton = 0xD8, -- 216
    RewardHistoryRequest = 0xD9, -- 217
    RewardConfirm = 0xDA -- 218
}

function Player:sendDailyRewardCollectionState(state)
    local msg = NetworkMessage()
    msg:addByte(ServerPackets.DailyRewardCollectionState)
    msg:addByte(state) -- activated/deactivated/expired ??
    msg:sendToPlayer(self)
end

function Player:sendAvailableTokens()
    local client = self:getClient()
    if ((client.os ~= CLIENTOS_NEW_WINDOWS and client.os ~= CLIENTOS_FLASH) or client.version < 1140) then
        return false --silently ignore
    end

    local msg = NetworkMessage()
    msg:addByte(0xEE)
    msg:addByte(20) --instantRewardToken Resource Identifier
    msg:addU64(self:getInstantRewardTokens())
    msg:sendToPlayer(self)
end

local function addRewardtoMsg(player, reward , msg)
    local typeReward

    if reward.type == REWARD_TYPE_RUNE_POT then
        typeReward = 1
    else
        typeReward = 2
    end

    msg:addByte(typeReward)
    if typeReward == 1 then
        msg:addByte(reward.ammount)

        local rewardList = player:getAvailableDailyRewardItems()

        local rewardCount = 0

        local runes = rewardList.runes
        local potions = rewardList.potions

        if runes then
            rewardCount = rewardCount + #runes
        end
        if potions then
            rewardCount = rewardCount + #potions
        end

        msg:addByte(rewardCount)
        if potions then
            for i = 1, #potions do
                local potion = potions[i]
                local itype = ItemType(potion.potionid)

                msg:addU16(potion.spriteid)
                msg:addString(potion.name)
                msg:addU32(itype:getWeight())
            end
        end
        if runes then
            for i = 1, #runes do
                local rune = runes[i]
                local itype = ItemType(rune.runeid)
                msg:addU16(rune.spriteid)
                msg:addString(itype:getArticle() .. " " .. itype:getName())
                msg:addU32(itype:getWeight())
            end
        end
    else

        if reward.type == REWARD_TYPE_PREY_REROLL then
            msg:addByte(1) --counter
            msg:addByte(2) -- prey flag
            msg:addByte(math.max(1, reward.ammount))
        elseif reward.type == REWARD_TYPE_TEMPORARYITEM then
            msg:addByte(#reward.items) --counter
            for j=1, #reward.items do
                msg:addByte(1) -- flag fixed item
                local item = reward.items[j]
                msg:addU16(item.id)
                msg:addString(getItemName(item.id))
                msg:addByte(item.ammount)
            end
        elseif reward.type == REWARD_TYPE_XP_BOOST then
            msg:addByte(1) -- counter
            msg:addByte(3) -- xp boost
            msg:addU16(reward.ammount)
        end
    end
end

function Player:sendDailyRewardBasic()

    local client = self:getClient()
    if ((client.os ~= CLIENTOS_NEW_WINDOWS and client.os ~= CLIENTOS_FLASH) or client.version < 1140) then
        return
    end
    if self:getStorageValue(Storage.dailyReward.exhaust) > os.time() then
        self:sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED)
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
        return
    end

    self:setStorageValue(Storage.dailyReward.exhaust, os.time() + exhaustTime)

    local rewardCount = #REWARD_LANE["PREMIUM_ACC"] --reads doubled because of the free/pacc
    local msg = NetworkMessage()

    msg:addByte(ServerPackets.DailyRewardBasic)
    msg:addByte(rewardCount)

    local freeAccLane = REWARD_LANE["FREE_ACC"]
    local paccLane = REWARD_LANE["PREMIUM_ACC"]
    for i=1, rewardCount do
        --FREEACC
        addRewardtoMsg(self, freeAccLane[i], msg)
        --PREMIUM_ACC
        addRewardtoMsg(self, paccLane[i], msg)
    end

    --daily reward
    local freeRewardLimit = 1
    msg:addByte(#REWARD_STREAK)
    for i=1, #REWARD_STREAK do
        msg:addString(REWARD_STREAK[i].description)
        msg:addByte(REWARD_STREAK[i].days)
        if not REWARD_STREAK[i].premium and freeRewardLimit + 1 == REWARD_STREAK[i].days then
            freeRewardLimit = REWARD_STREAK[i].days
        end
    end
    msg:addByte(freeRewardLimit) --max free accounts days bonus <inclusive>

    msg:sendToPlayer(self)
end



function Player:sendOpenRewardWall(isFreePick, nextRewardPick, hasString, confirmationString)
    local isFreePick = isFreePick or 0 --next to a reward shrine
    local nextRewardPick = nextRewardPick or os.time() --next reward pick timestamp
    local currentReward = self:getCurrentRewardLaneIndex(--[[zerobased=]]true) --current reward index 0-based
    local activateString = hasString -- a bool to activate/deactivate the dialog confirmation for certain operations
    local someString = confirmationString -- string in the dialog
    local timestampPickLimit -- timeout to pick the reward before reset streak (server save)

    if not self:canGetDailyReward() then
        timestampPickLimit = 0
    else
        timestampPickLimit = Game.getLastServerSave() + 24*60*60
    end

    local currentDayStreak = self:getCurrentDayStreak()
    local someOtherU16 = 200 -- have no idea


    local msg = NetworkMessage()
    msg:addByte(ServerPackets.OpenRewardWall)

    msg:addByte(isFreePick) --some boolean (0,1)
    msg:addU32(nextRewardPick)
    msg:addByte(currentReward)
    msg:addByte(activateString)

    if activateString ~= 0 then
        msg:addString(someString)
    end

    msg:addU32(timestampPickLimit)
    msg:addU16(currentDayStreak)
    msg:addU16(someOtherU16)

    msg:sendToPlayer(self)
end

function Player:sendCloseRewardWall()
    local msg = NetworkMessage()
    msg:addByte(ServerPackets.CloseRewardWall)
    --empty body
    msg:sendToPlayer(self)
end

function Player:sendDailyRewardHistory(history)
    if history and #history>0 then
        local msg = NetworkMessage()
        msg:addByte(ServerPackets.DailyRewardHistory)

        msg:addByte(#history) --number of entries perhaps?
        for i=1, #history do
            local entry = history[i]
            msg:addU32(entry.timestamp)
            msg:addByte(0) -- toggle green font (talvez seja a recompensa do dia de hoje?) --só 1 permitido
            msg:addString(entry.event)
            msg:addU16(entry.streak)
        end

        msg:sendToPlayer(self)
    end
end

function onRecvbyte(player, msg, byte)
    if(byte == ClientPackets.RewardConfirm) then
        local client = player:getClient()
        if ((client.os ~= CLIENTOS_NEW_WINDOWS and client.os ~= CLIENTOS_FLASH) or client.version < 1140) then
            return player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
        end
        local currentRewardIndex = player:getCurrentRewardLaneIndex(--[[zerobased=]]true) --zero-based
        local usedToken = msg:getByte()
        if usedToken == 0 and not player:isCloseToRewardShrine() then
            return player:sendCancelMessage(RETURNVALUE_TOOFARAWAY)
        end

        local reward

        if player:isPremium() then
            reward = REWARD_LANE["PREMIUM_ACC"][currentRewardIndex+1]
        else
            reward = REWARD_LANE["FREE_ACC"][currentRewardIndex+1]
        end


        if reward.type == REWARD_TYPE_RUNE_POT then
            local count = msg:getByte()
            local selectedCount=0
            local rewardsSelected = {}
            for i=1, count do
                local itemType = Game.getItemIdByClientId(msg:getU16())
                local itemCount = msg:getByte()
                local currentSelection = {
                    itemid = itemType:getId(),
                    count = itemCount
                }
                selectedCount= selectedCount+itemCount

                table.insert(rewardsSelected, currentSelection)
            end

            if selectedCount > reward.ammount then -- evitando receber mais reward que o permitido via WPE
                return player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
            end

            --TODO: verificar se todos os itens selecionados são legítimos

            player:receiveReward(usedToken, reward.type, rewardsSelected)

        elseif reward.type == REWARD_TYPE_TEMPORARYITEM then
            local rewardsSelected = {}
            for i=1,#reward.items do
                local currentSelection = {
                    itemid = reward.items[i].id,
                    count = reward.items[i].ammount
                }
                table.insert(rewardsSelected, currentSelection)
            end

            player:receiveReward(usedToken, reward.type, rewardsSelected)

        elseif reward.type == REWARD_TYPE_PREY_REROLL or reward.type == REWARD_TYPE_XP_BOOST then
            player:receiveReward(usedToken, reward.type, reward.ammount)
        end
    elseif byte == ClientPackets.OpenRewardWallButton then
        local client = player:getClient()
        if ((client.os ~= CLIENTOS_NEW_WINDOWS and client.os ~= CLIENTOS_FLASH) or client.version < 1140) then
            return player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
        end

        player:sendRewardWindow()
    elseif byte == ClientPackets.RewardHistoryRequest then
        local cb = function(history)
            if history then
                player:sendDailyRewardHistory(history)
            end
        end

        player:getDailyRewardHistory(cb, 20)
    end

    return true
end