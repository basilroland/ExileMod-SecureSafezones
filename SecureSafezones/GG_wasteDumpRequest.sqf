/**
 * ExileServer_system_trading_network_wasteDumpRequest
 *
 * Exile Mod
 * www.exilemod.com
 * © 2015 Exile Mod Team
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
 * MODIFIED BY GR8's Anti Steal
 */

private["_sessionID","_parameters","_vehicleNetID","_mode","_vehicleObject","_playerObject","_cargo","_revenue","_playerMoney","_respectGain","_playerRespect","_responseCode","_ownerGroup","_vehicleOwner"];
_sessionID = _this select 0;
_parameters = _this select 1;
_vehicleNetID = _parameters select 0;
_mode = _parameters select 1;
try
{
	_vehicleObject = objectFromNetId _vehicleNetID;
	if (isNull _vehicleObject) then
	{
		throw 6;
	};
	if (_vehicleObject getVariable ["ExileMutex", false]) then
	{
		throw 12;
	};
	_vehicleObject setVariable ["ExileMutex", true];
	_playerObject = _sessionID call ExileServer_system_session_getPlayerObject;
	if (isNull _playerObject) then
	{
		throw 1;
	};
	if !(alive _playerObject) then
	{
		throw 2;
	};
	_vehicleOwner = _vehicleObject getVariable ['GR8owner', objNull];
	_ownerGroup = units group _vehicleOwner;
	if ((GG_vehicleDump) && !(_playerObject in _ownerGroup)) then {
		throw 6;
	};
	if !((owner _vehicleObject) isEqualTo (owner _playerObject)) then
	{
		throw 6;
	};
	_cargo = _vehicleObject call ExileClient_util_containerCargo_list;
	_revenue = _cargo call ExileClient_util_gear_calculateTotalSellPrice;
	clearBackpackCargoGlobal _vehicleObject;
	clearItemCargoGlobal _vehicleObject;
	clearMagazineCargoGlobal _vehicleObject;
	clearWeaponCargoGlobal _vehicleObject;
	if (_mode isEqualTo 2) then
	{
		_revenue = _revenue + ([(typeOf _vehicleObject)] call ExileClient_util_gear_calculateTotalSellPrice);
		_vehicleObject call ExileServer_object_vehicle_remove;
		deleteVehicle _vehicleObject;
	}
	else
	{
		_vehicleObject call ExileServer_object_vehicle_database_update;
	};
	_playerMoney = _playerObject getVariable ["ExileMoney", 0];
    _playerMoney = _playerMoney + _revenue;
    _playerObject setVariable ["ExileMoney", _playerMoney];
    _respectGain = _revenue * getNumber (configFile >> "CfgSettings" >> "Respect" >> "tradingRespectFactor");
    _playerRespect = _playerObject getVariable ["ExileScore", 0];
    _playerRespect = floor (_playerRespect + _respectGain);
    _playerObject setVariable ["ExileScore", _playerRespect];
    format["setAccountMoneyAndRespect:%1:%2:%3", _playerMoney, _playerRespect, (getPlayerUID _playerObject)] call ExileServer_system_database_query_fireAndForget;
    [_sessionID, "wasteDumpResponse", [0, str _playerMoney, str _playerRespect]] call ExileServer_system_network_send_to;
	
	_recycleLog = format[
	"PLAYER: %1:%7 %2 POPTABS AND %3 RESPECT | PLAYER TOTAL MONEY: %4 | RECYCLED ITEM: %5 WITH %6 CARGO FOR ",
	_playerObject,
	_revenue,
	_respectGain,
	_playerMoney,
	_vehicleObject,
	_cargo,
	(getPlayerUID _playerObject)
	];
	['A3_EXILE_RECYCLELOG_BIG',_recycleLog] call FNC_A3_CUSTOMLOG;
}
catch
{
	_responseCode = _exception;
	[_sessionID, "wasteDumpResponse", [_responseCode, "", ""]] call ExileServer_system_network_send_to;
};
if (!isNull _vehicleObject) then
{
	_vehicleObject setVariable ["ExileMutex", false];
};
true
