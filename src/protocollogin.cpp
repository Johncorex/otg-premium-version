/**
 * @file protocollogin.cpp
 * 
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2020 Mark Samman <mark.samman@gmail.com>
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

#include "protocollogin.h"

#include "outputmessage.h"
#include "rsa.h"
#include "tasks.h"

#include "configmanager.h"
#include "iologindata.h"
#include "ban.h"
#include "game.h"

#include "protocolcaster.h"

extern ConfigManager g_config;
extern Game g_game;

void ProtocolLogin::disconnectClient(const std::string& message, uint16_t version)
{
	auto output = OutputMessagePool::getOutputMessage();

	output->addByte(version >= 1076 ? 0x0B : 0x0A);
	output->addString(message);
	send(output);

	disconnect();
}

void ProtocolLogin::getCharacterList(const std::string& accountName, const std::string& password, uint16_t version)
{
	//dispatcher thread
	Account account;
	if (!IOLoginData::loginserverAuthentication(accountName, password, account)) {
		disconnectClient("Account name or password is not correct.", version);
		return;
	}

	auto output = OutputMessagePool::getOutputMessage();
	//Update premium days
	Game::updatePremium(account);

	//
	const std::string& motd = g_config.getString(ConfigManager::MOTD);
	if (!motd.empty()) {
		//Add MOTD
		output->addByte(0x14);

		std::ostringstream ss;
		ss << g_game.getMotdNum() << "\n" << motd;
		output->addString(ss.str());
	}

	//Add session key
	output->addByte(0x28);
	output->addString(accountName + "\n" + password);

	//Add char list
	output->addByte(0x64);

	output->addByte(1); // number of worlds

	output->addByte(0); // world id
	output->addString(g_config.getString(ConfigManager::SERVER_NAME));
	output->addString(g_config.getString(ConfigManager::IP));

	output->add<uint16_t>(g_config.getShortNumber(ConfigManager::GAME_PORT));

	output->addByte(0);
	//
	uint8_t size = std::min<size_t>(std::numeric_limits<uint8_t>::max(), account.characters.size());
	output->addByte(size);
	for (uint8_t i = 0; i < size; i++) {
		output->addByte(0);
		output->addString(account.characters[i]);
	}

	//Add premium days
	output->addByte(0);
	if (g_config.getBoolean(ConfigManager::FREE_PREMIUM)) {
		output->addByte(1);
		output->add<uint32_t>(0);
	} else {
		output->addByte(0);
		output->add<uint32_t>(time(nullptr) + (account.premiumDays * 86400));
	}

	send(output);

	disconnect();
}

void ProtocolLogin::getCastingStreamsList(const std::string& password, uint16_t version)
{
	const auto& casts = ProtocolCaster::getLiveCasts();
	std::vector<std::pair<uint32_t, std::string>> castList;

	bool havePassword = !password.empty();

	for (const auto& cast : casts) {
		if (havePassword) {
			if (cast.second->isPasswordProtected() && (cast.second->getLiveCastPassword() == password)) {
				castList.push_back(std::make_pair(cast.second->getSpectatorCount(), cast.first->getName()));
			}
		} else {
			castList.push_back(std::make_pair(cast.second->getSpectatorCount(), cast.first->getName()));
		}
	}

	if (castList.size() == 0) {
		if (havePassword) {
			disconnectClient("No cast avaliable with this password.", version);
		} else {
			disconnectClient("No cast avaliable.", version);
		}

		return;
	}

	std::sort(castList.begin(), castList.end(),
		[](const std::pair<uint32_t, std::string>& lhs, const std::pair<uint32_t, std::string>& rhs) {
		return lhs.first > rhs.first;
	});

	//dispatcher thread
	OutputMessage_ptr output = OutputMessagePool::getInstance()->getOutputMessage(this, false);
	if (output) {
		//Add MOTD
		output->addByte(0x14);

		std::ostringstream ss;
		ss << g_game.getMotdNum() << "\n" << g_config.getString(ConfigManager::MOTD);
		output->addString(ss.str());

		//Add session key
		output->addByte(0x28);
		output->addString("\n" + password);

		//Add char list
		output->addByte(0x64);

		//add worlds

		output->addByte(castList.size());

		uint32_t world = 0;

		for (const auto& it : castList) {
			output->addByte(world); // world id

			uint32_t count = it.first;

			std::stringstream ss;

			if (count == 0)
				ss << "no viewer";
			else if (count == 1)
				ss << count << "viewer";
			else
				ss << count << " viewers";

			output->addString(ss.str());
			output->addString(g_config.getString(ConfigManager::IP));
			output->add<uint16_t>(g_config.getNumber(ConfigManager::LIVE_CAST_PORT));
			output->addByte(0);

			world++;
		}

		world = 0;

		output->addByte(castList.size());

		for (const auto& it : castList) {
			output->addByte(world); // world id

			output->addString(it.second);

			world++;
		}

		output->add<uint16_t>(0x0); //The client expects the number of premium days left.
		OutputMessagePool::getInstance()->send(output);
	}
	getConnection()->close();
}

void ProtocolLogin::onRecvFirstMessage(NetworkMessage& msg)
{
	if (g_game.getGameState() == GAME_STATE_SHUTDOWN) {
		disconnect();
		return;
	}

	msg.skipBytes(2); // client OS
	// OperatingSystem_t operatingSystem = static_cast<OperatingSystem_t>(msg.get<uint16_t>());

	uint16_t version = msg.get<uint16_t>();
	if (version >= 1111) {
		enableCompact();
	}

	msg.skipBytes(17);
	/*
	 * Skipped bytes:
	 * 4 bytes: protocolVersion
	 * 12 bytes: dat, spr, pic signatures (4 bytes each)
	 * 1 byte: 0
	 */

	if (version <= 760) {
		std::ostringstream ss;
		ss << "Only clients with protocol " << g_config.getString(ConfigManager::VERSION_STR) << " allowed!";
		disconnectClient(ss.str(), version);
		return;
	}

	if (!Protocol::RSA_decrypt(msg)) {
		std::cout << "[ProtocolLogin::onRecvFirstMessage] RSA Decrypt Failed" << std::endl;
		disconnect();
		return;
	}

	xtea::key key;
	key[0] = msg.get<uint32_t>();
	key[1] = msg.get<uint32_t>();
	key[2] = msg.get<uint32_t>();
	key[3] = msg.get<uint32_t>();
	enableXTEAEncryption();
	setXTEAKey(std::move(key));

	if (version < g_config.getNumber(ConfigManager::VERSION_MIN) || version > g_config.getNumber(ConfigManager::VERSION_MAX)) {
		std::ostringstream ss;
		ss << "Only clients with protocol " << g_config.getString(ConfigManager::VERSION_STR) << " allowed!";
		disconnectClient(ss.str(), version);
		return;
	}

	if (g_game.getGameState() == GAME_STATE_STARTUP) {
		disconnectClient("Gameworld is starting up. Please wait.", version);
		return;
	}

	if (g_game.getGameState() == GAME_STATE_MAINTAIN) {
		disconnectClient("Gameworld is under maintenance.\nPlease re-connect in a while.", version);
		return;
	}

	BanInfo banInfo;
	auto curConnection = getConnection();
	if (!curConnection) {
		return;
	}

	if (IOBan::isIpBanned(curConnection->getIP(), banInfo)) {
		if (banInfo.reason.empty()) {
			banInfo.reason = "(none)";
		}

		std::ostringstream ss;
		ss << "Your IP has been banned until " << formatDateShort(banInfo.expiresAt) << " by " << banInfo.bannedBy << ".\n\nReason specified:\n" << banInfo.reason;
		disconnectClient(ss.str(), version);
		return;
	}

	std::string accountName = msg.getString();
	std::string password = msg.getString();
	if (accountName.empty()) {
		if (!g_config.getBoolean(ConfigManager::ENABLE_LIVE_CASTING)) {
			dispatchDisconnectClient("Invalid account name.");
		} else {
			g_dispatcher.addTask(createTask(std::bind(&ProtocolLogin::getCastingStreamsList, this, password, version)));
		}
		return;
	}

	if (password.empty()) {
		disconnectClient("Invalid password.", version);
		return;
	}

	auto thisPtr = std::static_pointer_cast<ProtocolLogin>(shared_from_this());
	g_dispatcher.addTask(createTask(std::bind(&ProtocolLogin::getCharacterList, thisPtr, accountName, password, version)));
}
