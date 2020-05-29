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

#ifndef FS_ProtocolCaster_H
#define FS_ProtocolCaster_H

#include "protocolgame.h"

class ProtocolCaster : public ProtocolGame
{
	public:
		ProtocolCaster(Connection_ptr connection);

		void logout(bool displayEffect, bool forced) override;

		typedef std::unordered_map<Player*, ProtocolCaster*> LiveCastsMap;
		typedef std::vector<ProtocolGame*> CastSpectatorVec;

		/** \brief Adds a spectator from the spectators vector.
		 *  \param spectatorClient pointer to the \ref ProtocolSpectator object representing the spectator
		 */
		void addSpectator(ProtocolGame* spectatorClient);

		/** \brief Removes a spectator from the spectators vector.
		 *  \param spectatorClient pointer to the \ref ProtocolSpectator object representing the spectator
		 */
		void removeSpectator(ProtocolGame* spectatorClient);

		/** \brief Starts the live cast.
		 *  \param password live cast password(optional)
		 *  \returns bool type indicating whether starting the cast was successful
		*/
		bool startLiveCast(const std::string& password = "");

		/** \brief Stops the live cast and disconnects all spectators.
		 *  \returns bool type indicating whether stopping the cast was successful
		*/
		bool stopLiveCast();

		/** \brief Provides access to the spectator vector.
		 *  \returns const reference to the spectator vector
		 */
		const CastSpectatorVec& getLiveCastSpectators() const {
			return m_spectators;
		}

		/** \brief Provides information about spectator count.
		 */
		size_t getSpectatorCount() const {
			return m_spectators.size();
		}

		bool isLiveCaster() const {
			return m_isLiveCaster;
		}

		/** \brief Adds a new live cast to the list of available casts
		 *  \param player pointer to the casting \ref Player object
		 *  \param client pointer to the caster's \ref ProtocolGame object
		 */
		void registerLiveCast();

		/** \brief Removes a live cast from the list of available casts
		 *  \param player pointer to the casting \ref Player object
		 */
		void unregisterLiveCast();

		/** \brief Update live cast info in the database.
		 *  \param player pointer to the casting \ref Player object
		 *  \param client pointer to the caster's \ref ProtocolGame object
		 */
		void updateLiveCastInfo();

		/** \brief Clears all live casts. Used to make sure there aro no live cast db rows left should a crash occur.
		 *  \warning Only supposed to be called once.
		 */
		static void clearLiveCastInfo();

		/** \brief Finds the caster's \ref ProtocolGame object
		 *  \param player pointer to the casting \ref Player object
		 *  \returns A pointer to the \ref ProtocolGame of the caster
		 */
		static ProtocolCaster* getLiveCast(Player* player) {
			const auto it = m_liveCasts.find(player);
			return it != m_liveCasts.end() ? it->second : nullptr;
		}

		/** \brief Gets the live cast name/login
		 *  \returns A const reference to a string containing the live cast name/login
		 */
		const std::string& getLiveCastName() const {
			return m_liveCastName;
		}
		/** \brief Gets the live cast password
		 *  \returns A const reference to a string containing the live cast password
		 */
		const std::string& getLiveCastPassword() const {
			return m_liveCastPassword;
		}
		/** \brief Check if the live cast is password protected
		 */
		bool isPasswordProtected() const {
			return !m_liveCastPassword.empty();
		}
		/** \brief Allows access to the live cast map.
		 *  \returns A const reference to the live cast map.
		 */
		static const LiveCastsMap& getLiveCasts() {
			return m_liveCasts;
		}

		static uint8_t getMaxLiveCastCount() {
			//return std::numeric_limits<int8_t>::max();
			return MAX_CAST_COUNT;
		}

		/** \brief Allows spectators to send text messages to the caster
		*   and then get broadcast to the rest of the spectators
		*  \param text string containing the text message
		*/
		void broadcastSpectatorMessage(const std::string& name, const std::string& text) {
			if (getConnection() && player) {
				sendChannelMessage(name, text, TALKTYPE_CHANNEL_Y, CHANNEL_CAST);
			}
		}

	protected:
		//proxy functions

		void writeToOutputBuffer(const NetworkMessage& msg, bool broadcast = true) override {
			ProtocolGame::writeToOutputBuffer(msg);

			if (!m_isLiveCaster)
				return;

			if (!broadcast)
				return;

			for (auto& spectator : m_spectators) {
				spectator->writeToOutputBuffer(msg, broadcast);
			}
		}

		/*
		void sendChannelMessage(const std::string& author, const std::string& text, SpeakClasses type, uint16_t channel) override {
			ProtocolGame::sendChannelMessage(author, text, type, channel);
			
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendChannelMessage(author, text, type, channel);
			}
		}
		void sendChannelEvent(uint16_t channelId, const std::string& playerName, ChannelEvent_t channelEvent) override {
			ProtocolGame::sendChannelEvent(channelId, playerName, channelEvent);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendChannelEvent(channelId, playerName, channelEvent);
			}
		}
		void sendChannel(uint16_t channelId, const std::string& channelName, const UsersMap* channelUsers, const InvitedMap* invitedUsers) override {
			ProtocolGame::sendChannel(channelId, channelName, channelUsers, invitedUsers);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendChannel(channelId, channelName, channelUsers, invitedUsers);
			}
		}
		
		void sendIcons(uint16_t icons) override {
			ProtocolGame::sendIcons(icons);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendIcons(icons);
			}
		}
		void sendDistanceShoot(const Position& from, const Position& to, uint8_t type) override {
			ProtocolGame::sendDistanceShoot(from, to, type);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendDistanceShoot(from, to, type);
			}
		}
		void sendMagicEffect(const Position& pos, uint8_t type) override {
			ProtocolGame::sendMagicEffect(pos, type);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendMagicEffect(pos, type);
			}
		}
		void sendCreatureHealth(const Creature* creature) override {
			ProtocolGame::sendCreatureHealth(creature);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureHealth(creature);
			}
		}
		void sendSkills() override {
			ProtocolGame::sendSkills();
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendSkills();
			}
		}
		void sendCreatureTurn(const Creature* creature, uint32_t stackpos) override {
			ProtocolGame::sendCreatureTurn(creature, stackpos);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureTurn(creature, stackpos);
			}
		}
		void sendCreatureSay(const Creature* creature, SpeakClasses type, const std::string& text, const Position* pos = nullptr) override {
			ProtocolGame::sendCreatureSay(creature, type, text, pos);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureSay(creature, type, text, pos);
			}
		}
		void sendCancelWalk() override {
			ProtocolGame::sendCancelWalk();
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCancelWalk();
			}
		}
		
		void sendChangeSpeed(const Creature* creature, uint32_t speed) override {
			ProtocolGame::sendChangeSpeed(creature, speed);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendChangeSpeed(creature, speed);
			}
		}
		void sendCreatureVisible(const Creature* creature, bool visible) override {
			ProtocolGame::sendCreatureVisible(creature, visible);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureVisible(creature, visible);
			}
		}
		void sendCreatureOutfit(const Creature* creature, const Outfit_t& outfit) override {
			ProtocolGame::sendCreatureOutfit(creature, outfit);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureOutfit(creature, outfit);
			}
		}
		void sendStats() override {
			ProtocolGame::sendStats();
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendStats();
			}
		}
		void sendBasicData() override {
			ProtocolGame::sendBasicData();
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendBasicData();
			}
		}
		void sendTextMessage(const TextMessage& message) override {
			ProtocolGame::sendTextMessage(message);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendTextMessage(message);
			}
		}
		void sendCreatureWalkthrough(const Creature* creature, bool walkthrough) override {
			ProtocolGame::sendCreatureWalkthrough(creature, walkthrough);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureWalkthrough(creature, walkthrough);
			}
		}
		void sendCreatureShield(const Creature* creature) override {
			ProtocolGame::sendCreatureShield(creature);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureShield(creature);
			}
		}
		void sendCreatureSkull(const Creature* creature) override {
			ProtocolGame::sendCreatureSkull(creature);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureSkull(creature);
			}
		}
		void sendCreatureType(uint32_t creatureId, uint8_t creatureType) override {
			ProtocolGame::sendCreatureType(creatureId, creatureType);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureType(creatureId, creatureType);
			}
		}
		void sendCreatureHelpers(uint32_t creatureId, uint16_t helpers) override {
			ProtocolGame::sendCreatureHelpers(creatureId, helpers);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureHelpers(creatureId, helpers);
			}
		}
		void sendShop(Npc* npc, const ShopInfoList& itemList) override {
			ProtocolGame::sendShop(npc, itemList);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendShop(npc, itemList);
			}
		}
		void sendCloseShop() override {
			ProtocolGame::sendCloseShop();
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCloseShop();
			}
		}
		void sendSaleItemList(const std::list<ShopInfo>& shop) override {
			ProtocolGame::sendSaleItemList(shop);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendSaleItemList(shop);
			}
		}
		void sendTradeItemRequest(const Player* player, const Item* item, bool ack) override {
			ProtocolGame::sendTradeItemRequest(player, item, ack);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendTradeItemRequest(player, item, ack);
			}
		}
		void sendCloseTrade() override {
			ProtocolGame::sendCloseTrade();
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCloseTrade();
			}
		}
		void sendCreatureLight(const Creature* creature) override {
			ProtocolGame::sendCreatureLight(creature);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureLight(creature);
			}
		}
		void sendWorldLight(const LightInfo& lightInfo) override {
			ProtocolGame::sendWorldLight(lightInfo);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendWorldLight(lightInfo);
			}
		}
		void sendCreatureSquare(const Creature* creature, SquareColor_t color) override {
			ProtocolGame::sendCreatureSquare(creature, color);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCreatureSquare(creature, color);
			}
		}
		void sendSpellCooldown(uint8_t spellId, uint32_t time) override {
			ProtocolGame::sendSpellCooldown(spellId, time);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendSpellCooldown(spellId, time);
			}
		}
		void sendSpellGroupCooldown(SpellGroup_t groupId, uint32_t time) override {
			ProtocolGame::sendSpellGroupCooldown(groupId, time);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendSpellGroupCooldown(groupId, time);
			}
		}
		//tiles
		void sendAddTileItem(const Position& pos, uint32_t stackpos, const Item* item) override {
			ProtocolGame::sendAddTileItem(pos, stackpos, item);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendAddTileItem(pos, stackpos, item);
			}
		}
		void sendUpdateTileItem(const Position& pos, uint32_t stackpos, const Item* item) override {
			ProtocolGame::sendUpdateTileItem(pos, stackpos, item);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendUpdateTileItem(pos, stackpos, item);
			}
		}
		void sendRemoveTileThing(const Position& pos, uint32_t stackpos) override {
			ProtocolGame::sendRemoveTileThing(pos, stackpos);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendRemoveTileThing(pos, stackpos);
			}
		}
		void sendUpdateTile(const Tile* tile, const Position& pos) override {
			ProtocolGame::sendUpdateTile(tile, pos);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendUpdateTile(tile, pos);
			}
		}
		void sendAddCreature(const Creature* creature, const Position& pos, int32_t stackpos, bool isLogin) override {
			ProtocolGame::sendAddCreature(creature, pos, stackpos, isLogin);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendAddCreature(creature, pos, stackpos, isLogin);
			}
		}
		void sendMoveCreature(const Creature* creature, const Position& newPos, int32_t newStackPos,
			const Position& oldPos, int32_t oldStackPos, bool teleport) override {
			ProtocolGame::sendMoveCreature(creature, newPos, newStackPos, oldPos, oldStackPos, teleport);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendMoveCreature(creature, newPos, newStackPos, oldPos, oldStackPos, teleport);
			}
		}
		//containers
		void sendAddContainerItem(uint8_t cid, uint16_t slot, const Item* item) override {
			ProtocolGame::sendAddContainerItem(cid, slot, item);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendAddContainerItem(cid, slot, item);
			}
		}
		void sendUpdateContainerItem(uint8_t cid, uint16_t slot, const Item* item) override {
			ProtocolGame::sendUpdateContainerItem(cid, slot, item);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendUpdateContainerItem(cid, slot, item);
			}
		}
		void sendRemoveContainerItem(uint8_t cid, uint16_t slot, const Item* lastItem) override {
			ProtocolGame::sendRemoveContainerItem(cid, slot, lastItem);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendRemoveContainerItem(cid, slot, lastItem);
			}
		}
		void sendContainer(uint8_t cid, const Container* container, bool hasParent, uint16_t firstIndex) override {
			ProtocolGame::sendContainer(cid, container, hasParent, firstIndex);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendContainer(cid, container, hasParent, firstIndex);
			}
		}
		void sendCloseContainer(uint8_t cid) override {
			ProtocolGame::sendCloseContainer(cid);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendCloseContainer(cid);
			}
		}
		//inventory
		void sendInventoryItem(slots_t slot, const Item* item) override {
			ProtocolGame::sendInventoryItem(slot, item);
			if (!m_isLiveCaster)
				return;
			for (auto& spectator : m_spectators) {
				spectator->sendInventoryItem(slot, item);
			}
		}
		*/
	private:

		void releaseProtocol() override;

		void disconnectClient(const std::string& message) override;

		void parsePacket(NetworkMessage& msg) override;

		void parseSay(NetworkMessage& msg) override;

		static LiveCastsMap m_liveCasts; ///< Stores all available casts.

		bool m_isLiveCaster; ///< Determines if this \ref ProtocolGame object is casting

		///< list of spectators \warning This variable should only be accessed after locking \ref liveCastLock
		CastSpectatorVec m_spectators;

		// just to name spectators with a number
		uint32_t m_spectatorsCount;

		///< Live cast name that is also used as login
		std::string m_liveCastName;
		///< Password used to access the live cast
		std::string m_liveCastPassword;
};

#endif