/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2020  Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "otpch.h"

#include "protocolcaster.h"

#include "outputmessage.h"

#include "tile.h"
#include "player.h"
#include "chat.h"

#include "configmanager.h"

#include "game.h"

#include "connection.h"
#include "scheduler.h"
#include "ban.h"

#include "databasetasks.h"

#include "creatureevent.h"

#include "protocolspectator.h"

extern Game g_game;
extern ConfigManager g_config;
extern Chat* g_chat;
extern CreatureEvents* g_creatureEvents;

ProtocolCaster::LiveCastsMap ProtocolCaster::m_liveCasts;

ProtocolCaster::ProtocolCaster(Connection_ptr connection):
	ProtocolGame(connection),
	m_isLiveCaster(false)
{
	std::cout << "New connection" << std::endl;
}

void ProtocolCaster::releaseProtocol()
{
	stopLiveCast();

	ProtocolGame::releaseProtocol();
}

void ProtocolCaster::disconnectClient(const std::string& message)
{
	stopLiveCast();

	ProtocolGame::disconnectClient(message);
}

void ProtocolCaster::logout(bool displayEffect, bool forced)
{
	//dispatcher thread
	if (!player) {
		return;
	}

	if (!player->isRemoved()) {
		if (!forced) {
			if (!player->isAccessPlayer()) {
				if (player->getTile()->hasFlag(TILESTATE_NOLOGOUT)) {
					player->sendCancelMessage(RETURNVALUE_YOUCANNOTLOGOUTHERE);
					return;
				}

				if (!player->getTile()->hasFlag(TILESTATE_PROTECTIONZONE) && player->hasCondition(CONDITION_INFIGHT)) {
					player->sendCancelMessage(RETURNVALUE_YOUMAYNOTLOGOUTDURINGAFIGHT);
					return;
				}
			}

			//scripting event - onLogout
			if (!g_creatureEvents->playerLogout(player)) {
				//Let the script handle the error message
				return;
			}
		}

		if (displayEffect && player->getHealth() > 0) {
			g_game.addMagicEffect(player->getPosition(), CONST_ME_POFF);
		}
	}

	stopLiveCast();

	if (Connection_ptr connection = getConnection()) {
		connection->close();
	}

	g_game.removeCreature(player);
}

void ProtocolCaster::parsePacket(NetworkMessage& msg)
{
	if (!m_acceptPackets || g_game.getGameState() == GAME_STATE_SHUTDOWN || msg.getLength() <= 0) {
		return;
	}

	if (player && (player->isRemoved() || player->getHealth() <= 0)) {
		stopLiveCast();
	}

	ProtocolGame::parsePacket(msg);
}

void ProtocolCaster::parseSay(NetworkMessage& msg)
{
	std::string receiver;
	uint16_t channelId;

	SpeakClasses type = static_cast<SpeakClasses>(msg.getByte());
	switch (type) {
	case TALKTYPE_PRIVATE_TO:
	case TALKTYPE_PRIVATE_RED_TO:
		receiver = msg.getString();
		channelId = 0;
		break;

	case TALKTYPE_CHANNEL_Y:
	case TALKTYPE_CHANNEL_R1:
		channelId = msg.get<uint16_t>();
		break;

	default:
		channelId = 0;
		break;
	}

	const std::string text = msg.getString();
	if (text.length() > 255) {
		return;
	}

	if (channelId == CHANNEL_CAST) {
		g_dispatcher.addTask(createTask(std::bind(&ProtocolGame::sendChannelMessage, this, player->getName(), text, TALKTYPE_CHANNEL_R1, channelId)));
	} else {
		addGameTask(&Game::playerSay, player->getID(), channelId, type, receiver, text);
	}
}

bool ProtocolCaster::startLiveCast(const std::string& password /*= ""*/)
{
	auto connection = getConnection();
	if (!g_config.getBoolean(ConfigManager::ENABLE_LIVE_CASTING) || m_isLiveCaster || !player || player->isRemoved() || !connection) {
		return false;
	}

	{
		//DO NOT do any send operations here
		if (m_liveCasts.size() >= getMaxLiveCastCount()) {
			return false;
		}

		m_spectatorsCount = 0;

		m_spectators.clear();

		m_liveCastName = player->getName();
		m_liveCastPassword = password;
		m_isLiveCaster = true;
		m_liveCasts.insert(std::make_pair(player, this));
	}

	registerLiveCast();
	//Send a "dummy" channel
	sendChannel(CHANNEL_CAST, LIVE_CAST_CHAT_NAME, nullptr, nullptr);
	return true;
}

bool ProtocolCaster::stopLiveCast()
{
	if (!m_isLiveCaster) {
		return false;
	}

	CastSpectatorVec spectators;

	std::swap(spectators, m_spectators);
	m_isLiveCaster = false;
	m_liveCasts.erase(player);

	for (auto& spectator : spectators) {
		spectator->setPlayer(nullptr);
		spectator->disconnect();
		spectator->unRef();
	}

	m_spectators.clear();

	if (player) {
		unregisterLiveCast();
	}

	return true;
}

void ProtocolCaster::clearLiveCastInfo()
{
	static std::once_flag flag;
	std::call_once(flag, []() {
		assert(g_game.getGameState() == GAME_STATE_INIT);
		std::ostringstream query;
		query << "DELETE FROM `live_casts`;";
		g_databaseTasks.addTask(query.str());
	});
}

void ProtocolCaster::registerLiveCast()
{
	std::ostringstream query;
	query << "INSERT into `live_casts` (`player_id`, `cast_name`, `password`) VALUES (" << player->getGUID() << ", '"
		<< getLiveCastName() << "', " << isPasswordProtected() << ");";
	g_databaseTasks.addTask(query.str());
}

void ProtocolCaster::unregisterLiveCast()
{
	std::ostringstream query;
	query << "DELETE FROM `live_casts` WHERE `player_id`=" << player->getGUID() << ";";
	g_databaseTasks.addTask(query.str());
}

void ProtocolCaster::updateLiveCastInfo()
{
	std::ostringstream query;
	query << "UPDATE `live_casts` SET `cast_name`='" << getLiveCastName() << "', `password`="
		<< isPasswordProtected() << ", `spectators`=" << getSpectatorCount()
		<< " WHERE `player_id`=" << player->getGUID() << ";";
	g_databaseTasks.addTask(query.str());
}

void ProtocolCaster::addSpectator(ProtocolGame* spectatorClient)
{
	//DO NOT do any send operations here
	m_spectatorsCount++;
	m_spectators.push_back(spectatorClient);
	spectatorClient->addRef();

	std::stringstream ss;
	ss << "Spectator " << m_spectatorsCount;

	static_cast<ProtocolSpectator*>(spectatorClient)->setSpectatorName(ss.str().c_str());

	updateLiveCastInfo();
}

void ProtocolCaster::removeSpectator(ProtocolGame* spectatorClient)
{
	//DO NOT do any send operations here
	auto it = std::find(m_spectators.begin(), m_spectators.end(), spectatorClient);
	if (it != m_spectators.end()) {
		m_spectators.erase(it);
		spectatorClient->unRef();
	}
	updateLiveCastInfo();
}