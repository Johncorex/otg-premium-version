--
-- Created by CLion.
-- User: leonardopereira
-- Date: 17/01/18
-- Time: 15:30
--

--[[
-- LANES =
    -- Free Account Players
        1- Choose 5 runes or potions.
        2- Choose 5 runes or potions.
        3- One Prey Bonus Rerolls.
        4- Choose 10 runes or potions.
        5- Choose 10 runes or potions.
        6- One temporary Gold Converter with 100 charges.
        7- 10 minutes 50% XP Boost.

    -- Premium Players
        1. Choose 10 runes or potions.
        2. Choose 10 runes or potions.
        3. Two Prey Bonus Rerolls.
        4. Choose 20 runes or potions.
        5. Choose 20 runes or potions.
        6. One temporary Temple Teleport scroll and one temporary Gold Converter with 100 charges.
        7. 30 minutes of 50% XP Boost.

--  STREAKS
--      1. No bonus for the first day.
        2. Allow hitpoints regeneration
        3. Allow mana regeneration
        4. Stamina regeneration (Premium only)
        5. Double hitpoints regeneration (Premium only)
        6. Double mana regeneration (Premium only)
        7. Soul Points regeneration (Premium only)
-- ]]

REWARD_TYPE_RUNE_POT = 1
REWARD_TYPE_PREY_REROLL = 2
REWARD_TYPE_TEMPORARYITEM = 3
REWARD_TYPE_XP_BOOST = 4

local MODAL_STATE_MAINMENU = 1
local MODAL_STATE_VIEWDAILYREWARD_LANE = 2
local MODAL_STATE_VIEWSTREAKBONUSES_INDEX = 3
local MODAL_STATE_VIEWSTREAKBONUSES_DETAILS = 4
local MODAL_STATE_SELECTING_REWARD_ITEMS = 5
local MODAL_STATE_CONFIRM_REWARD_PICK = 6
local MODAL_STATE_VIEWREWARDHISTORY = 7
local MODAL_STATE_VIEWREWARDHISTORY_DETAILS = 8

local dailyRewardStates = {}
local itemsCache = {}

local runesIds = {2311, 2313, 2310, 2308, 2305, 2304, 2303, 2302, 2301, 2295, 2293, 2292, 2291, 2290, 2289, 2288, 2287, 2286, 2285, 2279, 2278, 2277, 2274, 2273, 2271, 2269, 2268, 2266, 2265, 2262, 2261, 2316, 2315, 19792, 23722, 23723, } -- since there's no GetPotionList on sources, this should solve the problem for now
local potionsIds = {7588, 7589, 7590, 7591, 7618, 7620, 8472, 8473, 26029, 26030, 26031} -- since there's no GetPotionList on sources, this should solve the problem for now
local rewardShrineIds ={
    29021,29022,29023,29024,29089,29090
}

REWARD_LANE = {
    FREE_ACC = {
        {
            description='Choose 5 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 5,
            available = {} --ids das potions e runas disponíveis para escolher (Não Implementado)
        },
        {
            description='Choose 5 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 5,
            available = {} --ids das potions e runas disponíveis para escolher
        },
        {
            description = 'ONE Prey Bonus Reroll',
            type = REWARD_TYPE_PREY_REROLL,
            ammount=1,
        },
        {
            description='Choose 10 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {} --ids das potions e runas disponíveis para escolher
        },
        {
            description='Choose 10 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {} --ids das potions e runas disponíveis para escolher
        },
        {
            description = 'One temporary Gold Converter with 100 charges',
            type = REWARD_TYPE_TEMPORARYITEM,
            ammount = 1,
            items = {
                {id =29019, ammount=100}
            },
            expires = true
        },
        {
            description = 'Ten minutes 50% XP Boost',
            type = REWARD_TYPE_XP_BOOST,
            ammount = 10, --*60 ??  xp boost é por minuto ou por segundo??
            expires = true
        }
    },
    PREMIUM_ACC = {
        {
            description='Choose 10 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {} --ids das potions e runas disponíveis para escolher
        },
        {
            description='Choose 10 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {} --ids das potions e runas disponíveis para escolher
        },
        {
            description = 'TWO Prey Bonus Reroll',
            type = REWARD_TYPE_PREY_REROLL,
            ammount=2,
        },
        {
            description='Choose 20 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 20,
            available = {} --ids das potions e runas disponíveis para escolher
        },
        {
            description='Choose 20 runes or potions',
            type = REWARD_TYPE_RUNE_POT,
            ammount = 20,
            available = {} --ids das potions e runas disponíveis para escolher
        },
        {
            description = 'One temporary Temple Teleport scroll and one temporary Gold Converter with 100 charges.',
            type = REWARD_TYPE_TEMPORARYITEM,
            ammount = 1,
            expires = true,
            items = {
                {id =29019, ammount=100},
                {id =29018, ammount=1 }
            }
        },
        {
            description = 'Thirty minutes 50% XP Boost',
            type = REWARD_TYPE_XP_BOOST,
            ammount = 30, --*60 ??  xp boost é por minuto ou por segundo??
            expires = true
        }
    }
}

REWARD_STREAK = {
    {
        days = 2,
        description = 'Allow hitpoints regeneration',
        fullDescription = 'This bonus grants you the ability of regenerate your hitpoints inside resting areas (affects all health regeneration from items/food).'
    },
    {
        days = 3,
        description = 'Allow mana regeneration',
        fullDescription = 'This bonus grants you the ability of regenerate your mana inside resting areas (affects all mana regeneration from items/food).'
    },
    {
        days = 4,
        description = 'Stamina regeneration',
        fullDescription = 'This bonus grants you the ability of regenerate your stamina inside resting areas. Just like if you were logged out.\n'..
                '\nIf your stamina is below 40 hours, you recover 1 stamina minute for every 3 minutes inside resting areas;'..
                '\nIf it is over 40 hours, you recover 1 stamina minute for every 10 minutes.',
        premium = true
    },
    {
        days = 5,
        description = 'Double hitpoints regeneration',
        fullDescription = 'Your current hitpoint regeneration inside resting areas is DOUBLED (affects all health regeneration from items/food).',
        premium = true
    },
    {
        days = 6,
        description = 'Double mana regeneration',
        fullDescription = 'Your current mana regeneration inside resting areas is DOUBLED (affects all mana regeneration from items/food).',
        premium = true
    },
    {
        days = 7,
        description = 'Soul Points regeneration',
        fullDescription = 'This bonus grants you the ability of regenerate your soul points inside resting areas. Just like if you were killing creatures.'..
                '\n- Regular characters regenerate 1 Soul point every 2 minutes;'..
                '\n- Promoted characters regenerate 1 Soul point every 15 seconds;',
        premium = true
    }
}

--forward declared function names
local getDefaultModalState --(player)
local sendModalSelectRecursive --(player)
local getChoiceModalState --(playerid, rewardAmmount)
-- -----------------
local function getHours(seconds)
    return math.floor((seconds/60)/60)
end

local function getMinutes(seconds)
    return math.floor(seconds/60)
end

local function getSeconds(seconds)
    return seconds%60
end
local function getTimeinWords(secs)
    local hours, minutes, seconds = getHours(secs), getMinutes(secs), getSeconds(secs)
    if (minutes > 59) then
        minutes = minutes-hours*60
    end

    local timeStr = ''

    if hours > 0 then
        timeStr = timeStr .. string.format('%d hour%s',hours,(hours > 1 and "s" or '') )
    end

    timeStr = timeStr .. string.format('%d minute%s and %d second%s',minutes,(minutes~=1 and "s" or ''), seconds, (seconds~=1 and 's' or ''))

    return timeStr
end

local function getDefaultStateData(player, MODAL_STATE)
    local statedata = {}
    if MODAL_STATE == MODAL_STATE_MAINMENU then
        statedata.playerid = player:getId()
        statedata.title = "Reward Wall"


        local currentDayStreak = player:getCurrentDayStreak()
        local currentLanePlace = player:getCurrentRewardLaneIndex()
        local instantTokenBalance = player:getInstantRewardTokens()

        statedata.message = string.format("--------------- Welcome to your reward wall! ------------------\n\nYou're in a %d-day streak\nOn the reward #%d\nInstant Reward Access: %d\n\nRemember that you can always open this window with the \"!daily\" command.\n", currentDayStreak, currentLanePlace, instantTokenBalance)
    end

    return statedata
end

local function setModalState(playerid, state)
    if playerid and state then
        dailyRewardStates[playerid] = state
    end
end

local function clearModalState(playerid)
    if not playerid or not dailyRewardStates[playerid] then return end

    dailyRewardStates[playerid] = nil

end

local function getDefaultChoices(player)
    local defaultChoices = {
        ids = {},
        names = {
            "Resting Area Bonuses ("..tostring(player:getCurrentDayStreak()) .. ")",
            "Daily Rewards " .. tostring((player:canGetDailyReward()) and "[*]" or "[ ]"),
            "Reward History"
        },
        choicedata = {
            {tostate = MODAL_STATE_VIEWSTREAKBONUSES_INDEX},
            {tostate = MODAL_STATE_VIEWDAILYREWARD_LANE},
            {tostate = MODAL_STATE_VIEWREWARDHISTORY}
        }
    }


    return defaultChoices
end

local function getDefaultButtonsNames()
    local buttonsNames = {
        "Submit",
        "Close"
    }

    return buttonsNames
end

local function getDefaultEnterButtonName()
    return "Submit"
end

local function getDefaultCancelButtonName()
    return "Close"
end

local function getStreakStatusText(player, rewardStreak)

    local isPremiumPlayer = player:isPremium()
    local message
    local currentDayStreak = player:getCurrentDayStreak()

    if rewardStreak.premium and not isPremiumPlayer then
        message = 'locked - Premium only'
    elseif currentDayStreak >= rewardStreak.days then
        message = 'active'
    elseif currentDayStreak == rewardStreak.days - 1 and player:canGetDailyReward() then
        message = "GET TODAY'S REWARD TO ACTIVATE"
    else
        message = 'locked'
    end

    return message
end

local function getAvailableRewardItems(pid, forceReload)
    -- TODO: cache
    local reward = {}
    if not forceReload and itemsCache[pid] then
        return itemsCache[pid]
    else


        local player = Player(pid)

        local runes = {}
        for i=1, #runesIds do
                local itype = ItemType(runesIds[i])
                local rune = {
                    name = itype:getArticle() .. " " .. itype:getName(),
                    runeid = runesIds[i],
                    spriteid = itype:getClientId()
                }
                table.insert(runes, rune)
        end

        if runes then
            reward.runes = runes
        end


        local potions = {}
        for i=1, #potionsIds do
            if player:canUsePotion(potionsIds[i],true) then
                local itype = ItemType(potionsIds[i])
                local potion = {
                    name = itype:getArticle() .. " " .. itype:getName(),
                    potionid = potionsIds[i],
                    spriteid = itype:getClientId()
                }
                table.insert(potions, potion)
            end
        end

        if potions then
            reward.potions = potions
        end

        itemsCache[pid] = reward
        return reward
    end
end

function Player:getAvailableDailyRewardItems()
    return getAvailableRewardItems(self:getId())
end

local function getStaticState(pid, MODAL_STATE, additional)
    local state

    if MODAL_STATE == MODAL_STATE_VIEWSTREAKBONUSES_INDEX then
        local p = Player(pid)
        state = {stateId = MODAL_STATE_VIEWSTREAKBONUSES_INDEX}
        local currentDayStreak = p:getCurrentDayStreak()

        local message = string.format("These are your Resting Area Bonuses!\n" ..
                "\nYou're in a %d-day streak%s\n",currentDayStreak, currentDayStreak > 2 and "!!" or "." )

        if p:canGetDailyReward() then
            local timeleft = Game.getLastServerSave() + 24*60*60 - os.time()
            message = message .. "Hurry up! Pick up your daily reward within the next " .. getTimeinWords(timeleft) ..
                    " (before the next regular server save) to raise your reward streak by one and.\n"..
                    "Raise your reward streak to benefit from bonuses in resting areas."
        end

        state.statedata = {
            playerid = pid,
            title = "Resting Area Bonuses",
            message = message
        }

        local names = {}
        local choicesData = {}
        for i=1, #REWARD_STREAK do
            local rs = REWARD_STREAK[i]
            local isPremiumPlayer = p:isPremium()
            local status

            if rs.premium and not isPremiumPlayer then
                status = 'locked - Premium only'
            elseif currentDayStreak >= rs.days then
                status = 'active'
            elseif currentDayStreak == rs.days - 1 and p:canGetDailyReward() then
                status = "GET TODAY'S REWARD TO ACTIVATE"
            else
                status = 'locked'
            end

            names[i] = string.format("%d - %s [%s]", rs.days,rs.description,status)
            choicesData[i] = {
                tostate = MODAL_STATE_VIEWSTREAKBONUSES_DETAILS,
                streak_index = i
            }
        end

        state.choices ={
            ids ={},
            names = names,
            choicedata = choicesData
        }


        state.buttons = {
            names = {"Close","Back","Details"},
            defaultEnterName = "Details",
            defaultCancelName = "Close",
            callbacks = {
                function(button, choice) --close
                    clearModalState(pid)
                end,

                function(button,choice) -- Back
                    local stateDefault = getDefaultModalState(Player(pid))
                    setModalState(pid, stateDefault)
                    sendModalSelectRecursive(Player(pid))
                end,
                function(button,choice) --Details
                    local stateDetails = getStaticState(pid, MODAL_STATE_VIEWSTREAKBONUSES_DETAILS,choice.choicedata.streak_index)
                    setModalState(pid, stateDetails)
                    sendModalSelectRecursive(Player(pid))
                end
            }
        }

    elseif MODAL_STATE == MODAL_STATE_VIEWSTREAKBONUSES_DETAILS  then
        local streak_index = additional

        local rewardStreak = REWARD_STREAK[streak_index]

        local message = tostring(rewardStreak.days) .. "-Day streak bonus ("

        local player = Player(pid)

        message = message .. getStreakStatusText(player, rewardStreak) ..
                string.format(")\n\nThis bonus is active if you reached a reward streak of at least %d.\n\n", rewardStreak.days) ..
                rewardStreak.fullDescription
        state = { stateId = MODAL_STATE_VIEWSTREAKBONUSES_DETAILS }

        state.statedata = {
            playerid = pid,
            title = "Resting Area Bonuses (Details)",
            message = message
        }

        -- state.choices absent here (info-only modal)

        state.buttons = {
            names = {"Back","Close"},
            defaultEnterName = "Back",
            defaultCancelName = "Close",
            callbacks = {
                function(button,choice) -- Back
                    local stateDetails = getStaticState(pid, MODAL_STATE_VIEWSTREAKBONUSES_INDEX)
                    setModalState(pid, stateDetails)
                    sendModalSelectRecursive(Player(pid))
                end,
                function(button, choice) -- Close
                    clearModalState(pid)
                end
            }
        }
    elseif MODAL_STATE == MODAL_STATE_VIEWDAILYREWARD_LANE then
        state = { stateId = MODAL_STATE_VIEWDAILYREWARD_LANE }

        local laneIndex = additional
        local player = Player(pid)
        local reward
        if player:isPremium() then
            reward = REWARD_LANE.PREMIUM_ACC[laneIndex]
        else
            reward = REWARD_LANE.FREE_ACC[laneIndex]
        end

        local message = ""

        if player:canGetDailyReward() then
            message = string.format("Your today's reward is:\n\n- %s.\n\n",reward.description)
            if player:isCloseToRewardShrine() then
                message = message .. "Since you're close to a reward shrine, this reward pickup is FREE!"
            else
                local instantRewardTokens = player:getInstantRewardTokens()
                if instantRewardTokens > 0 then
                    message = message .. string.format("Caution! You are far from a reward shrine. This reward pickup will use 1 of your %d Instant Reward Access.", instantRewardTokens)
                else
                    message = message .. "Not enough Instance Reward Access points to pick up this reward.\n"
                    message = message .. "You can purchase an Instant Reward Acces in the store or visit a reward shrine to pick up your daily reward for FREE."
                    --cannot proceed show error message and display only back and close buttons
                    local buttons = {
                        names = {"Back", "Store", "Close"},
                        defaultEnterName = "Store",
                        defaultCancelName = "Close",
                        callbacks = {
                            function(button, choice) -- Back
                                local stateDetails = getDefaultModalState(Player(pid))
                                setModalState(pid, stateDetails)
                                sendModalSelectRecursive(Player(pid))
                            end,
                            function(button, choice) -- Open Store
                                clearModalState(pid)

                                local p = Player(pid)
                                if p~= nil then
                                    p:openStore("Useful Things")  --category with the Instant Reward Access offer
                                end
                            end,
                            function(button, choice) -- Close
                                clearModalState(pid)
                            end
                        }
                    }

                    state.buttons = buttons
                    state.statedata = {
                        playerid = pid,
                        title = "Daily Reward",
                        message = message
                    }

                    return state --halt execution
                end
            end

            local buttons
            if reward.type == REWARD_TYPE_RUNE_POT then
                buttons = {
                    names = {"Back", "Choose", "Close"},
                    defaultEnterName = "Choose",
                    defaultCancelName = "Close",
                    callbacks = {
                        function(button, choice) -- back
                            local stateDetails = getDefaultModalState(Player(pid))
                            setModalState(pid, stateDetails)
                            sendModalSelectRecursive(Player(pid))
                        end,
                        function(button, choice) -- choose items
                            local stateChooseItems = getStaticState(pid, MODAL_STATE_SELECTING_REWARD_ITEMS, reward)
                            setModalState (pid, stateChooseItems)
                            sendModalSelectRecursive(Player(pid))
                        end,
                        function(button, choice) -- close
                            clearModalState(pid)
                        end,
                    }
                }
            else
                buttons = {
                    names = {"Back", "Claim", "Close"},
                    defaultEnterName = "Claim",
                    defaultCancelName = "Close",
                    callbacks = {
                        function(button, choice) -- back
                            local stateDetails = getDefaultModalState(Player(pid))
                            setModalState(pid, stateDetails)
                            sendModalSelectRecursive(Player(pid))
                        end,
                        function(button, choice) -- claim
                            local stateConfirm = getStaticState(pid, MODAL_STATE_CONFIRM_REWARD_PICK, reward)
                            setModalState (pid, stateConfirm)
                            sendModalSelectRecursive(Player(pid))
                        end,
                        function(button, choice) -- close
                            clearModalState(pid)
                        end,
                    }
                }
            end
            state.buttons = buttons
        else
            local laneIndex = player:getCurrentRewardLaneIndex(false)
            local nextReward =  player:isPremium() and REWARD_LANE["PREMIUM_ACC"][laneIndex].description or REWARD_LANE["FREE_ACC"][laneIndex].description
            message =string.format("Congratulations! You've already taken your daily reward."..
                    "\n\nThe next daily reward will be available in the next server save (in %s).\n\nYour next daily reward will be:\n        %s\n", getTimeinWords(player:getNextRewardPick() - os.time()), nextReward )

            state.buttons = {
                names = {"Back", "Close"},
                defaultEnterName="Back",
                defaultCancelName = "Close",
                callbacks = {
                    function(button, choice) -- back
                        local stateMainMenu = getDefaultModalState(Player(pid))
                        setModalState(pid, stateMainMenu)
                        sendModalSelectRecursive(Player(pid))
                    end,
                    function(button,choice) -- close
                        clearModalState(pid)
                    end
                }
            }
        end



        state.statedata ={
            title = "Daily Reward",
            message = message,
            playerid = pid
        }

    elseif MODAL_STATE == MODAL_STATE_CONFIRM_REWARD_PICK then
        --recheck reward get condition
        local reward = additional
        local player = Player(pid)

        if reward.type == REWARD_TYPE_RUNE_POT then
            local current = dailyRewardStates[pid]

            if current and current.statedata and current.statedata.selection then
                local selectionReward = current.statedata.selection
                local playerSelection = {}
                local totalWeight = 0
                local message = "The following items will be delivered to your store inbox: \n"
                for itemId, count in pairs(selectionReward) do
                    table.insert(playerSelection,{itemid = itemId, count = count})
                    local ittype = ItemType(itemId)
                    totalWeight = totalWeight + ittype:getWeight(count)
                    message = message .. string.format("%dx %s; ",count, ittype:getName())
                end

                message = message .. string.format("\n\nTotal weight: %.2f oz.\nMake sure you have enough capacity.\nConfirm selection?\n", totalWeight/100.0)

                local useToken = player:isCloseToRewardShrine() and 0 or 1
                if useToken > 0 then
                    message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
                end

                state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}

                local buttons = {
                    names = {"Cancel", "Confirm"},
                    defaultEnterName = "Confirm",
                    defaultCancelName = "Cancel",
                    callbacks = {
                        function(button, choice) -- Cancel
                            clearModalState(pid)
                        end,
                        function(button, choice)  -- Confirm
                            local player = Player(pid)
                            local useToken = player:isCloseToRewardShrine() and 0 or 1
                            player:receiveReward(useToken, reward.type, playerSelection)
                            clearModalState(pid)
                        end
                    }
                }


                local stateData = {
                    playerid = pid,
                    title = "Reward Selection",
                    message = message
                }

                state.statedata = stateData
                state.buttons = buttons

            else --error
                state = {
                    stateId = MODAL_STATE_CONFIRM_REWARD_PICK,
                    statedata = {
                        playerid = pid,
                        title = "Daily Reward System - Error",
                        message = "Invalid items selection!\n\nTry again with valid items."
                    },
                    buttons = {
                        names=  {"Close"},
                        callbacks = {
                            function(button, choice)
                                clearModalState(pid)
                            end
                        },
                        defaultEnterName = "Close",
                        defaultCancelName = "Close"
                    }
                }
            end

        elseif reward.type == REWARD_TYPE_TEMPORARYITEM then
            local items = reward and reward.items

            local playerSelection = {}
            local totalWeight = 0
            local message = "The following items will be delivered to your store inbox: \n"
            for i=1, #items do
                local itemId, count = items[i].id,items[i].ammount

                table.insert(playerSelection,{itemid = itemId, count = count})
                local ittype = ItemType(itemId)
                totalWeight = totalWeight + ittype:getWeight(count)
                message = message .. string.format("%dx %s; ",count, ittype:getName())
            end

            message = message .. string.format("\n\nTotal weight: %.2f oz.\nMake sure you have enough capacity.\nConfirm selection?\n", totalWeight/100.0)

            local useToken = player:isCloseToRewardShrine() and 0 or 1
            if useToken > 0 then
                message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
            end

            state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}

            local buttons = {
                names = {"Cancel", "Confirm"},
                defaultEnterName = "Confirm",
                defaultCancelName = "Cancel",
                callbacks = {
                    function(button, choice) -- Cancel
                        clearModalState(pid)
                    end,
                    function(button, choice)  -- Confirm
                        local player = Player(pid)
                        local useToken = player:isCloseToRewardShrine() and 0 or 1
                        player:receiveReward(useToken, reward.type, playerSelection)
                        clearModalState(pid)
                    end
                }
            }


            local stateData = {
                playerid = pid,
                title = "Pick Reward",
                message = message
            }

            state.statedata = stateData
            state.buttons = buttons

        elseif reward.type == REWARD_TYPE_XP_BOOST then
            local message = string.format("You will receive: \n\n%d minutes of XP BOOST will be added to your character\nConfirm selection?\n", reward.ammount)

            local useToken = player:isCloseToRewardShrine() and 0 or 1
            if useToken > 0 then
                message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
            end


            state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}

            local buttons = {
                names = {"Cancel", "Confirm"},
                defaultEnterName = "Confirm",
                defaultCancelName = "Cancel",
                callbacks = {
                    function(button, choice) -- Cancel
                        clearModalState(pid)
                    end,
                    function(button, choice)  -- Confirm
                        local player = Player(pid)
                        local useToken = player:isCloseToRewardShrine() and 0 or 1
                        player:receiveReward(useToken, reward.type, reward.ammount)
                        clearModalState(pid)
                    end
                }
            }

            local stateData = {
                playerid = pid,
                title = "Pick Reward",
                message = message
            }

            state.statedata = stateData
            state.buttons = buttons

        elseif reward.type == REWARD_TYPE_PREY_REROLL then
            local message = string.format("You will receive: \n\n%d Prey Bonus Reroll%s will be added to your character\nConfirm selection?\n", reward.ammount, reward.ammount>1 and "s" or "")

            local useToken = player:isCloseToRewardShrine() and 0 or 1
            if useToken > 0 then
                message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
            end


            state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}

            local buttons = {
                names = {"Cancel", "Confirm"},
                defaultEnterName = "Confirm",
                defaultCancelName = "Cancel",
                callbacks = {
                    function(button, choice) -- Cancel
                        clearModalState(pid)
                    end,
                    function(button, choice)  -- Confirm
                        local player = Player(pid)
                        local useToken = player:isCloseToRewardShrine() and 0 or 1
                        player:receiveReward(useToken, reward.type, reward.ammount)
                        clearModalState(pid)
                    end
                }
            }

            local stateData = {
                playerid = pid,
                title = "Pick Reward",
                message = message
            }

            state.statedata = stateData
            state.buttons = buttons
        end
    elseif MODAL_STATE == MODAL_STATE_SELECTING_REWARD_ITEMS then
        if not itemsCache[pid] then
            itemsCache[pid] = getAvailableRewardItems(pid)
        end
        local reward = additional
        state = getChoiceModalState(pid, reward)
    elseif MODAL_STATE == MODAL_STATE_VIEWREWARDHISTORY_DETAILS then
        local history = additional

        state = {}
        state.stateId = MODAL_STATE_VIEWREWARDHISTORY_DETAILS

        state.buttons = {
            names = {"Back","Close"},
            defaultEnterName = "Back",
            defaultCancelName = "Close",
            callbacks = {
                function(button,choice) -- Back
                    local stateDefault = getDefaultModalState(Player(pid))
                    setModalState(pid, stateDefault)
                    sendModalSelectRecursive(Player(pid))
                end,
                function(button, choice) -- Close
                    clearModalState(pid)
                end
            }
        }

        local pickCost

        if history.instantCost > 0 then
            pickCost = string.format("This reward pick used %d Instant Reward Access.", history.instantCost)
        else
            pickCost = "This reward pick was FREE."
        end
        local msg = string.format("History Details\n\nDate: %s\nStreak: %d\nEvent: %s\n\n%s",
                os.date("%Y-%m-%d %X",history.timestamp), history.streak, history.event, pickCost)

        state.statedata = {
            playerid = pid,
            title = "Reward Wall - History Details",
            message = msg
        }
    end

    return state
end

getChoiceModalState = function(pid, reward)
    local player = Player(pid)
    local state = {stateId = MODAL_STATE_SELECTING_REWARD_ITEMS}

    local potionsSelectable = itemsCache[pid].potions
    local runesSelectable = itemsCache[pid].runes

    local choices = dailyRewardStates[pid].choices or {ids={}}
    if not choices.names then
        local choicesNames = {}
        local choicesData = {}

        local i=1

        if potionsSelectable then
            for j=1, #potionsSelectable do
                choicesNames[i] = potionsSelectable[j].name
                choicesData[i] = potionsSelectable[j].potionid
                i = i+1
            end
        end

        if runesSelectable then
            for j=1, #runesSelectable do
                local itype = ItemType(runesSelectable[j].runeid)
                choicesNames[i] = itype:getArticle() .. " " ..itype:getName() --get name item name instead of spell name
                choicesData[i] = runesSelectable[j].runeid
                i = i+1
            end
        end

        choices.names = choicesNames
        choices.choicedata = choicesData
    end

    state.choices = choices
    local currentSelection = dailyRewardStates[pid] and dailyRewardStates[pid].statedata and dailyRewardStates[pid].statedata.selection or nil
    -- { [itemId] = ammount, [item2Id] = ...}

    local selectionText
    local selectedItemsCount = 0
    local totalWeight = 0
    if currentSelection then
        selectionText="\nCurrently selected:\n"
        for itemId, quantity in pairs(currentSelection) do
            if not selectionText then end
            local ittype = ItemType(itemId)
            totalWeight = totalWeight+ittype:getWeight(quantity)
            selectedItemsCount = selectedItemsCount+quantity
            selectionText = selectionText .. string.format("%dx %s; ",quantity, ittype:getName())
        end
        selectionText = selectionText .. "\n"
    end

    --Message
    local message

    message = string.format("You have selected %d of %d reward items.\n",selectedItemsCount, reward.ammount)

    if selectionText then
        message = message..selectionText
    end

    message = message .. string.format("\nFree Capacity: %.2f oz.\nTotal weight: %.2f oz", player:getFreeCapacity()/100.0, totalWeight/100.0)
    state.statedata = {
        playerid = pid,
        title = "Pick Reward",
        message = message
    }

    if currentSelection then
        state.statedata.selection = currentSelection
    end

    local addFunc = function(button, choice, addAmmount, remainingCount)
        local curSelection = dailyRewardStates[pid] and dailyRewardStates[pid].statedata and dailyRewardStates[pid].statedata.selection or nil
        if not curSelection then
            curSelection = {}
        end

        local itemId = choice.choicedata

        if not curSelection[itemId] then
            curSelection[itemId] = addAmmount
        else
            curSelection[itemId] = curSelection[itemId] + addAmmount
        end


        local sta = dailyRewardStates[pid]
        sta.statedata.selection = curSelection
        setModalState(pid, sta)

        sta = getChoiceModalState(pid, reward)
        setModalState(pid, sta)
        if remainingCount - addAmmount == 0 then
            local stateReceiveReward = getStaticState(pid, MODAL_STATE_CONFIRM_REWARD_PICK, reward)
            setModalState(pid, stateReceiveReward)
        end

    end

    local remaining  = reward.ammount - selectedItemsCount

    local buttons = {
        names= {"Back", "Add", string.format("Add %dx", math.ceil(remaining/2)),string.format("Add %dx", math.ceil(remaining)) },
        defaultEnterName = "Add",
        defaultCancelName = "Back",
        callbacks = {
            function(button, choice) --Back
                local st = getStaticState(pid, MODAL_STATE_VIEWDAILYREWARD_LANE,  player:getCurrentRewardLaneIndex())
                setModalState(pid,st)
                sendModalSelectRecursive(Player(pid))
            end,
            function(button, choice) -- Add 1
                addFunc(button,choice,1, remaining)
                sendModalSelectRecursive(Player(pid))
            end,
            function(button, choice)-- Add half of remaining (ceil)
                addFunc(button,choice, math.ceil(remaining/2), remaining)
                sendModalSelectRecursive(Player(pid))
            end,
            function(button, choice)-- Add remaining
                addFunc(button,choice, remaining, remaining)
                sendModalSelectRecursive(Player(pid))
            end,
        }
    }

    state.buttons = buttons


    return state
end

local function getDefaultCallbacks(player)
    local playerid = player:getId()
    local callbacks = {
        function(button, choice) -- SubmitCallback
            local selection = choice.choicedata.tostate

            if selection == MODAL_STATE_VIEWDAILYREWARD_LANE then
                local newState = getStaticState(playerid, MODAL_STATE_VIEWDAILYREWARD_LANE, player:getCurrentRewardLaneIndex())
                setModalState(playerid, newState)
                sendModalSelectRecursive(Player(playerid))
            elseif selection == MODAL_STATE_VIEWSTREAKBONUSES_INDEX then
                local newState = getStaticState(playerid, MODAL_STATE_VIEWSTREAKBONUSES_INDEX)
                setModalState(playerid, newState)
                sendModalSelectRecursive(Player(playerid))
            elseif selection == MODAL_STATE_VIEWREWARDHISTORY then
                local cb = function(history)
                    local state = {}
                    state.stateId = MODAL_STATE_VIEWREWARDHISTORY

                    state.buttons = {
                        names = {"Back","Details","Close"},
                        defaultEnterName = "Details",
                        defaultCancelName = "Close",
                        callbacks = {
                            function(button,choice) -- Back
                                local stateDefault = getDefaultModalState(Player(playerid))
                                setModalState(playerid, stateDefault)
                                sendModalSelectRecursive(Player(playerid))
                            end,
                            function(button,choice) --details
                                local stateDetails = getStaticState(playerid, MODAL_STATE_VIEWREWARDHISTORY_DETAILS,choice.choicedata)
                                setModalState(playerid, stateDetails)
                                sendModalSelectRecursive(Player(playerid))
                            end,
                            function(button, choice) -- Close
                                clearModalState(playerid)
                            end
                        }
                    }
                    local message = '---------------------- Reward History ----------------------'
                    local choices
                    local cnames,cdata
                    if history and #history>0 then
                        for i=1, #history do
                            if not cnames then
                                cnames = {}
                                cdata = {}
                            end

                            local dt = os.date("%Y-%m-%d %X",history[i].timestamp)
                            local choiceName = string.format("%s - strk:%d - %s", dt, history[i].streak ,history[i].event)
                            table.insert(cnames, choiceName)
                            table.insert(cdata, history[i])
                        end
                        choices = {
                            ids ={},
                            names = cnames,
                            choicedata = cdata
                        }

                        state.choices = choices
                    else
                        message = message .. "\n\nNo reward history yet."
                    end
                    state.statedata = {
                        playerid = playerid,
                        title = "Reward Wall - History",
                        message = message
                    }

                    setModalState(playerid, state)
                    sendModalSelectRecursive(Player(playerid))
                end
                player:getDailyRewardHistory(cb,10)
            end

        end,
        function(button, choice)--closeCallback
            clearModalState(playerid)
        end
    }

    return callbacks
end

local function getDefaultButtons(player)
    local defaultButtons = {}
    defaultButtons.names = getDefaultButtonsNames()
    defaultButtons.callbacks = getDefaultCallbacks(player)
    defaultButtons.defaultEnterName = getDefaultEnterButtonName()
    defaultButtons.defaultCancelName = getDefaultCancelButtonName()

    return defaultButtons
end

getDefaultModalState = function (player)
    local defaultState = {
        stateId = MODAL_STATE_MAINMENU,
        choices = getDefaultChoices(player),
        buttons = getDefaultButtons(player),
        statedata = getDefaultStateData(player,MODAL_STATE_MAINMENU)
    }

    return defaultState
end

local function getModalState(playerid)
    if not playerid then return nil end
    local state

    if not dailyRewardStates[playerid] then
        state = getDefaultModalState(Player(playerid))
    else
        state = dailyRewardStates[playerid]
    end

    return state
end

local function callbackAddItemModal ()

end

function Player:initDailyRewardSystem()
    local nextRewardPick = self:getStorageValue(Storage.dailyReward.nextRewardPick)

    if nextRewardPick < (Game.getLastServerSave() - (24*60*60)) then -- 24 hours of the limit time has passed, reset streak
        self:setCurrentDayStreak(0)
        print('reset current day streak')
    end

    self:loadStreakBonuses()
    self:sendAvailableTokens()
    self:sendDailyRewardBasic()
end

function Player:getLastRewardPick()
    return math.max(self:getStorageValue(Storage.dailyReward.lastRewardPick),0)
end

function Player:setLastRewardPick(timestamp)
    if tonumber(timestamp) then
        self:setStorageValue(Storage.dailyReward.lastRewardPick, timestamp)
    else
        print('[WARNING - DAILY REWARD]: Invalid last reward timestamp')
    end

end

function Player:getNextRewardPick()
    return math.max(self:getStorageValue(Storage.dailyReward.nextRewardPick),0)
end

function Player:setNextRewardPick(timestamp)
    if tonumber(timestamp) then
        self:setStorageValue(Storage.dailyReward.nextRewardPick, timestamp)
    else
        print('[WARNING - DAILY REWARD]: Invalid next reward timestamp')
    end

end

function Player:getCurrentDayStreak()
    return math.max(self:getStorageValue(Storage.dailyReward.streakDays),0)
end

function Player:setCurrentDayStreak(value)
    self:setStorageValue(Storage.dailyReward.streakDays, value)
end

function Player:getCurrentRewardLaneIndex(zerobased)
    local rewardIndex = math.max(self:getStorageValue(Storage.dailyReward.currentIndex),0)
    if not zerobased then
        rewardIndex = rewardIndex+1
    end

    return rewardIndex
end

function Player:setCurrentRewardLaneIndex(value)
    self:setStorageValue(Storage.dailyReward.currentIndex, value)
end

function Player:incrementCurrentRewardLaneIndex()
    local currentIndex = self:getCurrentRewardLaneIndex(true)
    local lanelength

    if self:isPremium() then
        lanelength = #REWARD_LANE["PREMIUM_ACC"] or 1
    else
        lanelength = #REWARD_LANE["FREE_ACC"] or 1
    end

    currentIndex = (currentIndex + 1) % lanelength
    self:setCurrentRewardLaneIndex(currentIndex)
end

function Player:addRewardTokens(ammount)
    local current = self:getInstantRewardTokens()
    ammount = math.abs(ammount)

    self:setInstantRewardTokens(current+ammount)
    self:sendAvailableTokens()
end

function Player:removeRewardTokens(ammount)
    local current = self:getInstantRewardTokens()
    ammount = math.abs(ammount)

    self:setInstantRewardTokens(current-ammount)
    self:sendAvailableTokens()
end

function Player:useRewardToken()
    self:removeRewardTokens(1)
end

function Player:isCloseToAnyOfItems(itemList)
    for x = -1, 1 do
        for y = -1, 1 do
            local posX, posY, posZ = self:getPosition().x+x, self:getPosition().y+y, self:getPosition().z
            local tile = Tile(posX, posY, posZ)
            if (tile) then
                for _, itemId in pairs(itemList) do
                    if tile:getItemById(itemId) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function Player:isCloseToRewardShrine()
    return self:isCloseToAnyOfItems(rewardShrineIds)
end

function Player:enableSoulRegenInRestAreas()
    local soulCondition = Condition (CONDITION_SOULBONUS, CONDITIONID_DEFAULT)
    soulCondition:setTicks((Game.getLastServerSave() + (24*60*60) - os.time()) *1000)
    local vocation = self:getVocation()
    soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
    soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

    self:addCondition(soulCondition)
end

function Player:enableStaminaRegenInRestAreas()
    local conditionStamina = Condition(CONDITION_STAMINAREGEN, CONDITIONID_DEFAULT)
    conditionStamina:setTicks((Game.getLastServerSave() + (24*60*60) - os.time()) *1000) --until next SS


    conditionStamina:setParameter(CONDITION_PARAM_STAMINAGAIN, 1)

    self:addCondition(conditionStamina);
end

function Player:enableStreakBonus(day)
    --Nem todos precisam ser ativados, o regen de mana e health já estão prontos nas srcs
    if day == 7 then
        self:enableSoulRegenInRestAreas()
    elseif day == 4 then
        self:enableStaminaRegenInRestAreas()
    end
end

function Player:loadStreakBonuses()
    local isPremium = self:isPremium()

    local function applyBonusRecursive(day)
        if day<2 then
            return
        elseif day>7 then
            day=7
        end

        self:enableStreakBonus(day)
        applyBonusRecursive(day-1)
    end

    local streakDays = self:getCurrentDayStreak()
    if(isPremium) then
        streakDays= math.min(7,streakDays)
    else
        streakDays = math.min(3, streakDays)
    end

    applyBonusRecursive(streakDays)
end

function Player:receiveReward(useToken, rewardType, additional)
    local client = self:getClient()

    -- Client 11 only
    if ((client.os == CLIENTOS_NEW_WINDOWS or client.os ~= CLIENTOS_FLASH) and client.version >= 1140) then
        self:sendCloseRewardWall()
    end

    if useToken > 0 and self:getInstantRewardTokens() == 0 then
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
        return self:sendCancelMessage("Not enough instant reward tokens.")
    end

    local historyExtra =''
    if rewardType == REWARD_TYPE_RUNE_POT or rewardType == REWARD_TYPE_TEMPORARYITEM then
        local totalWeight = 0
        local selection = additional
        for i=1, #selection do
            totalWeight = totalWeight + ItemType(selection[i].itemid):getWeight(selection[i].count)
        end

        if self:getFreeCapacity() < totalWeight then
            self:getPosition():sendMagicEffect(CONST_ME_POFF)
            return self:sendCancelMessage(RETURNVALUE_NOTENOUGHCAPACITY)
        end

        local inbox = self:getSlotItem(CONST_SLOT_STORE_INBOX)
        if not inbox or inbox:getEmptySlots() == 0 then
            self:getPosition():sendMagicEffect(CONST_ME_POFF)
            return self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
        end
        for i=1, #selection do
            local itype = ItemType(selection[i].itemid)
            inbox:addItem(selection[i].itemid, selection[i].count, INDEX_WHEREEVER, FLAG_NOLIMIT)
            historyExtra = historyExtra .. string.format(" %dx %s;",selection[i].count, itype:getName())
        end
    elseif rewardType == REWARD_TYPE_PREY_REROLL then
        local bonusCount = additional
        --TODO expire after 7 days
        self:setBonusRerollCount(math.abs(bonusCount))

    elseif rewardType == REWARD_TYPE_XP_BOOST then
        local minutes = additional
        --TODO verify the type of exp bonus here
        local currentExpBoostTime = self:getExpBoostStamina()
        self:setExpBoostStamina(currentExpBoostTime + minutes*60);

        self:setStoreXpBoost(50)
        self:sendStats()
    end

    --validations passed
    if useToken > 0 then
        self:useRewardToken()
    end

    --save history message
    local historymsg = string.format('Claimed reward no.%d.',self:getCurrentRewardLaneIndex(false))
    if rewardType == REWARD_TYPE_RUNE_POT or rewardType == REWARD_TYPE_TEMPORARYITEM then
        historymsg = historymsg .. ' Picked items:' .. historyExtra
    end

    --update values
    local nextReward = Game.getLastServerSave() + (24*60*60) -- next day

    self:incrementCurrentRewardLaneIndex()
    self:setCurrentDayStreak(self:getCurrentDayStreak()+1)
    self:setLastRewardPick(os.time())
    self:setNextRewardPick(nextReward)
    if self:getCurrentDayStreak()<=7 then
        self:enableStreakBonus(self:getCurrentDayStreak()) --load the new bonus
    end

    -- persist history
    self:addDailyRewardHistory(self:getCurrentDayStreak(), historymsg , useToken)

    -- Client 11 only
    if ((client.os == CLIENTOS_NEW_WINDOWS or client.os ~= CLIENTOS_FLASH) and client.version >= 1140) then
        self:sendDailyRewardBasic()
        self:sendNativeRewardWindow()
    end


    local effect = math.random(29,31)
    self:getPosition():sendMagicEffect(effect)
end

function Player:canGetDailyReward()
    return os.time() > self:getNextRewardPick()
end

--[[
state = {
    stateId = MODAL_STATE_MAINMENU,
    choices = {
        ids = {},
        names ={
            "Resting area bonuses",
            "DailyRewards"
        },
        choicedata = {
            {} --array of tables  (#names == #choicedata)
        }
    },
    buttons = {
        names = { "Cancel", "Submit" },
        callbacks = { function(button, choice) end, function(button, choice) end}, --#names == # callbacks
        defaultEnterName = "Submit",
        defaultCancelName = "Cancel"
    },
    statedata = {
        playerid = 123123123
        title = "Modal window title",
        message = "Modal window message\naccepts multiline\n\n\n nice!",
        anyAdditionalFieldData = {}
    }
}
]]
sendModalSelectRecursive = function(player)
    local playerid = player:getId()

    local state = getModalState(playerid)

    local modal = ModalWindow {
        title = state.statedata.title,
        message = state.statedata.message
    }

    if state.choices then
        for i=1,#state.choices.names do
            local choiceId = modal:addChoice(state.choices.names[i])
            choiceId.choicedata = state.choices.choicedata[i]
            state.choices.ids[i] = choiceId
        end
    end

    local buttonCount = math.min(4, #state.buttons.names) --modal has a limit of 4 buttons
    for i=1, buttonCount do
        modal:addButton(state.buttons.names[i], state.buttons.callbacks[i])
    end

    if state.buttons and state.buttons.defaultEnterName then
        modal:setDefaultEnterButton(state.buttons.defaultEnterName)
    end

    if state.buttons and state.buttons.defaultCancelName then
        modal:setDefaultEscapeButton(state.buttons.defaultCancelName)
    end

    modal:sendToPlayer(player)


end

function Player:sendRewardWindow()
    local client = self:getClient()
    --if modal, verify current prize and prepare appropriate modal window
    if ((client.os ~= CLIENTOS_NEW_WINDOWS and client.os ~= CLIENTOS_FLASH) or client.version < 1140) then
        -- client 10, flash or 11.40-
        self:sendModalRewardWindow()
    else
        --client 11.40+
        self:sendNativeRewardWindow()
    end

end

function Player:sendModalRewardWindow()
    sendModalSelectRecursive(self)
end

function Player:sendNativeRewardWindow()
    local warnUser = 0
    local warnMessage = 'Warning'

    if not self:isCloseToRewardShrine() then
        warnUser = 1
        warnMessage = "Are you sure you want to pick this reward?\n\nTHIS WILL USE 1 INSTANT REWARD ACCESS"
    end
    self:sendOpenRewardWall(self:isCloseToRewardShrine()and 1 or 0, self:getNextRewardPick(), warnUser,warnMessage)
end

function Player:addDailyRewardHistory(currentStreak, eventText, instantCost)
    db.query(string.format("INSERT INTO `daily_reward_history`(`streak`,`event`,`instant`,`player_id`) VALUES (%d, %s, %d, %d)",currentStreak, db.escapeString(eventText),instantCost, self:getGuid()))
end

function Player:getDailyRewardHistory(_callback, limit, page)
    --[[CREATE TABLE IF NOT EXISTS daily_reward_history (
			`id` INT NOT NULL PRIMARY KEY auto_increment,
			`streak` smallint(2) not null default 0,
			`event` varchar(255),
			`time` TIMESTAMP NOT NULL default current_timestamp,
			`instant` tinyint unsigned NOT NULL DEFAULT 0 ,
			`player_id` INT NOT NULL,

			FOREIGN KEY(`player_id`) REFERENCES `players`(`id`)
				ON DELETE CASCADE
		)
    ]]
    local sql = string.format("SELECT `streak`, `event`, UNIX_TIMESTAMP(`time`) as `time`, `instant`"..
            " FROM daily_reward_history WHERE player_id = %d ORDER BY `time` DESC", self:getGuid())

    if tonumber(limit) then
        sql = sql .. " limit "
        if tonumber(page) then
            sql = sql .. string.format("%d,", (page*limit))

        end
        sql = sql .. tostring(tonumber(limit))
    end

    db.asyncStoreQuery(sql,
            function(resultId)
                local retTable
                if(resultId) then
                    retTable = {}
                    repeat
                        local streak  = result.getDataInt(resultId, 'streak')
                        local event = result.getDataString(resultId, "event")
                        local timestamp = result.getDataInt(resultId, "time")
                        local instantCost = result.getDataInt(resultId, "instant")

                        local t = {
                            streak = streak,
                            event = event,
                            timestamp = timestamp,
                            instantCost = instantCost
                        }

                        table.insert(retTable,t)
                    until not result.next(resultId)
                    result.free(resultId)

                end

                _callback(retTable)
            end
    )

end