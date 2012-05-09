SetScriptTitle("ServerTest#005")
SetScriptInfo("(c) by MAP94")

AddEventListener("OnPlayerJoinTeam", "OnPlayerJoinTeam")
AddEventListener("OnDie", "OnDie")
AddEventListener("OnCanSpawn", "OnCanSpawn")

SetGametype("ZOMB")

--[[
sv_gametype tdm
sv_teambalance_time 0
sv_scorelimit 0
sv_max_clients 4
sv_tournament_mode 1
add_vote "Start" lua StartRound
]]

CanSpawn = false

function OnCanSpawn()
    if (CanSpawn == false) then
        AbortSpawn()
    end
    CanSpawn = false
end

function OnDie()
    local Id = DieGetVictimID()
    if (IsDummy(Id) == true) then
        Kills = Kills + 1
        Id = 128 - Id
        Killed[Zombies[Id]["type"]] = Killed[Zombies[Id]["type"]] + 1
        Zombies[Id]["dietick"] = iTick
        Num = GetLeftZombies()
        if (Num == 0) then
            NextWaveCountDown = 500
            SendBroadcast("Wave exterminated")
        end
        SendChat(-1, 0, Num .. " Zombies left!")
    else
        Players[Id]["dietick"] = iTick
        Players[Id]["lifes"] = Players[Id]["lifes"] - 1
        if (Players[Id]["lifes"] > 0) then
            SendChatTarget(Id, Players[Id]["lifes"] .. " Lifes left")
        elseif (Players[Id]["lifes"] == 0) then
            SendChat(-1, 0, GetPlayerName(Id) .. " is dead. Rest in peace!")
        end
        CheckPlayersLife()
    end
end

function CheckPlayersLife()
    local NumLifes = 0
    for i = 0, PlayerCount - 1 do
        if (GetPlayerName(i) ~= nil and GetPlayerTeam(i) == 0) then
            NumLifes = NumLifes + Players[i]["lifes"]
        end
    end
    if (NumLifes == 0 and RoundStarted == true) then
        for i = 0, MaxClients do
            CharacterKill(i)
        end
        Win()
        RoundStarted = false
    end
end

function GetLeftZombies()
    return (Waves[WaveNum][1] - Killed[1]) + (Waves[WaveNum][2] - Killed[2]) + (Waves[WaveNum][3] - Killed[3]) + (Waves[WaveNum][4] - Killed[4])
end

function GetLeftZombiesToSpawn()
    return (Waves[WaveNum][1] - Spawned[1]) + (Waves[WaveNum][2] - Spawned[2]) + (Waves[WaveNum][3] - Spawned[3]) + (Waves[WaveNum][4] - Spawned[4])
end

function OnPlayerJoinTeam()
    if (IsDummy(GetJoinTeamClientID()) == false and GetSelectedTeam() == -1) then
        Players[GetJoinTeamClientID()]["lifes"] = 0
        CheckPlayersLife()
    end
    if ((GetSelectedTeam() == 0 and RoundStarted == false) or GetSelectedTeam() == -1) then
        return
    end
    AbortTeamJoin()
end

function StartRound()
    NextWaveCountDown = 500
    WaveNum = 0
    --kill everything
    RoundStarted = true
    for i = 1, NumZombies do
        Reset (i)
    end
    for i = 0, PlayerCount - 1 do
        Players[i]["lifes"] = -1
    end
    for i = 0, MaxClients do
        CharacterKill(i)
    end
    Kills = 0
    Killed[1] = 0
    Killed[2] = 0
    Killed[3] = 0
    Killed[4] = 0
    Spawned[1] = 0
    Spawned[2] = 0
    Spawned[3] = 0
    Spawned[4] = 0
    for i = 0, PlayerCount - 1 do
        SetPlayerTeam(i, 0)
        Players[i]["lifes"] = 3
        Players[i]["dietick"] = iTick + 5
    end
end

MaxClients = 128 - 1
NumZombies = 12
--create 12 dummies
Zombies = {}
PlayerCount = 4

ZOMBIE_STATE_SPAWNED = 1
ZOMBIE_STATE_EXPLORATING = 2
ZOMBIE_STATE_CHASING = 3

iTick = 0
GTime = 0
function Tick(Time, ServerTick)
    iTick = iTick+1
    GTime = Time

    if (iTick % 50 == 0) then
        CheckPlayersLife()
    end
    for i = 0, PlayerCount - 1 do
        if (CharacterIsAlive(i) == false and (Players[i]["lifes"] > 0 or RoundStarted == false) and Players[i]["dietick"] < iTick - 5) then
            CanSpawn = true --workaround
            CharacterSpawn(i)
            CanSpawn = false --workaround
        end
        if (Players[i]["lifes"] == 0 and GetPlayerTeam(i) == 0 and RoundStart == true) then
            SetPlayerTeam(i, -1)
        end
    end
    if (RoundStarted == false) then
        return
    end
    if (NextWaveCountDown == 500) then
        SendChat(-1, 0, "Next wave in 10 seconds!")
    end
    if (NextWaveCountDown > 0) then
        NextWaveCountDown = NextWaveCountDown - 1
    end
    if (NextWaveCountDown == 1) then
        Killed[1] = 0
        Killed[2] = 0
        Killed[3] = 0
        Killed[4] = 0
        Spawned[1] = 0
        Spawned[2] = 0
        Spawned[3] = 0
        Spawned[4] = 0
        WaveNum = WaveNum + 1
        local Msg = ""
        if (Waves[WaveNum][1] ~= 0) then
            Msg = Msg .. " | " .. Waves[WaveNum][1] .. " YoungZombies"
        end
        if (Waves[WaveNum][2] ~= 0) then
            Msg = Msg .. " | " .. Waves[WaveNum][2] .. " Zombies"
        end
        if (Waves[WaveNum][3] ~= 0) then
            Msg = Msg .. " | " .. Waves[WaveNum][3] .. " ElderZombies"
        end
        if (Waves[WaveNum][4] ~= 0) then
            Msg = Msg .. " | " .. Waves[WaveNum][4] .. " MegaZombies"
        end
        SendBroadcast("Wave " .. WaveNum .. " :" .. Msg)
    end
    if (WaveNum == 0 or NextWaveCountDown > 0) then
        return
    end
    for i = 1, NumZombies do
        local x, y = GetCharacterPos(128 - i)
        if (CharacterIsAlive(128 - i) == false and Zombies[i]["dietick"] < iTick - 5) then
            if (GetLeftZombiesToSpawn() ~= 0) then
                Reset(i)
                CanSpawn = true --workaround
                CharacterSpawn(128 - i)
                CanSpawn = false --workaround
                Zombies[i]["x"], Zombies[i]["y"] = GetCharacterPos(128 - i)
                if (Spawned[1] ~= Waves[WaveNum][1]) then
                    Spawned[1] = Spawned[1] + 1
                    ZombieSpawnSet(i, 1)
                elseif (Spawned[2] ~= Waves[WaveNum][2]) then
                    Spawned[2] = Spawned[2] + 1
                    ZombieSpawnSet(i, 2)
                elseif (Spawned[3] ~= Waves[WaveNum][3]) then
                    Spawned[3] = Spawned[3] + 1
                    ZombieSpawnSet(i, 3)
                elseif (Spawned[4] ~= Waves[WaveNum][4]) then
                    Spawned[4] = Spawned[4] + 1
                    ZombieSpawnSet(i, 4)
                end
            end
        elseif (x ~= nil and y ~= nil) then
            CharacterSetInputHook(128 - i, 0)
            CharacterSetInputFire(128 - i, 0)
            CharacterSetInputTarget(128 - i, Zombies[i]["tarx"], Zombies[i]["tary"])
            if (Zombies[i]["state"] == ZOMBIE_STATE_SPAWNED) then
                CheckClostestHuman(i)
                Zombies[i]["state"] = ZOMBIE_STATE_EXPLORATING
            elseif (Zombies[i]["state"] == ZOMBIE_STATE_EXPLORATING) then
                Move(i)
                Seek(i)
            elseif (Zombies[i]["state"] == ZOMBIE_STATE_CHASING) then
                x, y = GetCharacterPos(Zombies[i]["target"])
                if (Zombies[i]["target"] == -1 or x == nil) then
                    Zombies[i]["state"] = ZOMBIE_STATE_EXPLORATING
                else
                    Fire(i)
                    WeaponCheck(i)
                    Follow(i)
                end
            end
            CharacterPredictedInput(128 - i)
            CharacterDirectInput(128 - i)
        end
    end
end
function TickDefered(Time, ServerTick)

end
function PostTick(Time, ServerTick)

end

function Normalize(x, y)
    local l = 1 / math.sqrt(x*x + y*y)
	return x*l, y*l
end
function NormalizeX(x, y)
    local l = 1 / math.sqrt(x*x + y*y)
	return x*l
end
function NormalizeY(x, y)
    local l = 1 / math.sqrt(x*x + y*y)
	return y*l
end
function pack(...)
  return arg
end
function Distance(x1, y1, x2, y2)
    if (x1 == nil or y1 == nil or x2 == nil or y2 == nil) then
        return 0
    end
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

function Seek(i)
    local x, y = GetCharacterPos(128 - i)
	local Chars = pack(EntityFind(x, y, 500, 64, 4))
	local mindist = nil
	for z = 1, #Chars do
		if(EntityGetCharacterId(Chars[z]) ~= 128 - i and GetPlayerTeam(EntityGetCharacterId(Chars[z])) ~= GetPlayerTeam(128 - i)) then
            local xhuman, yhuman = GetCharacterPos(EntityGetCharacterId(Chars[z]))
            local dist = Distance(xhuman, yhuman, x, y);
            local b = IntersectLine(x, y, xhuman, yhuman)
            if((mindist == nil or dist < mindist) and b == 0) then
                Zombies[i]["target"] = EntityGetCharacterId(Chars[z]);
                Zombies[i]["state"] = ZOMBIE_STATE_CHASING;
            end
        end
    end
end

function Fire(i)
    local x, y = GetCharacterPos(128 - i)
    local xhuman, yhuman = GetCharacterPos(Zombies[i]["target"])
    local Ammo, Got = CharacterGetAmmo(128 - i, CharacterGetActiveWeapon(128 - i))
	if (iTick - Zombies[i]["pressedtick"] < Zombies[i]["attackspeed"] or (Ammo == 0 and CharacterGetActiveWeapon(128 - i) ~= 0) or Zombies[i]["allowedfire"] == false) then
        CharacterSetInputFire(128 - i, 0)
		return
    end
	local tarx, tary = xhuman - x, yhuman - y
	local b = IntersectLine(x, y, xhuman, yhuman)
	if (b == 0) then
        Zombies[i]["tarx"] = tarx * 32
        Zombies[i]["tary"] = tary * 32
        CharacterSetInputTarget(tarx * 32, tary * 32)
        CharacterSetInputFire(128 - i, iTick % 64)
		Zombies[i]["pressedtick"] = iTick
	end
end

function Follow(i)
    local x, y = GetCharacterPos(128 - i)
    local xhuman, yhuman = GetCharacterPos(Zombies[i]["target"])
	local dirx, diry = Normalize(x - xhuman, y - yhuman)
	local dist = Distance(x, y, xhuman, yhuman)
	local tarx, tary = xhuman - x, yhuman - y
	local b = IntersectLine(x, y, xhuman, yhuman)
	if (dist > 200 and b == 0) then
        Zombies[i]["tarx"] = tarx * 32
        Zombies[i]["tary"] = tary * 32
        CharacterSetInputTarget(128 - i, tarx, tary)
		if (Zombies[i]["allowedhook"]) then
			CharacterSetInputHook(128 - i, 2)
        end
	end
	if (b == 0) then
		Zombies[i]["viewtick"] = iTick
    end
	if ((dist > 500 and b == 1) or (dist < 500 and b == 1 and iTick - Zombies[i]["viewtick"] > 50)) then
		Zombies[i]["state"] = ZOMBIE_STATE_EXPLORATING
    end
	if (x == Zombies[i]["x"] and iTick - Zombies[i]["movetick"] > 10) then
		if (Zombies[i]["nexttry"] == 0) then
			CharacterSetInputJump(128 - i, 1)
			Zombies[i]["nexttry"] = Zombies[i]["nexttry"] + 1;
		elseif (Zombies[i]["nexttry"] == 1) then
			CharacterSetInputJump(128 - i, 1)
			Zombies[i]["nexttry"] = Zombies[i]["nexttry"] + 1;
		elseif (Zombies[i]["nexttry"] == 2) then
			Zombies[i]["direction"] = -Zombies[i]["direction"]
			Zombies[i]["nexttry"] = 0
		end
		Zombies[i]["movetick"] = iTick;
	elseif (x == Zombies[i]["x"]) then
		Zombies[i]["nexttry"] = 0
    else
        CharacterSetInputJump(128 - i, 0)
    end

	if(dirx > 0) then
		Zombies[i]["direction"] = -1
	else
		Zombies[i]["direction"] = 1
    end

    CharacterSetInputDirection(128 - i, Zombies[i]["direction"])

	Zombies[i]["x"] = x
	Zombies[i]["y"] = y
end

function WeaponCheck(i)
	if(Zombies[i]["allowedchangeweapon"] == false) then
		return
    end
    local x, y = GetCharacterPos(128 - i)
    local xhuman, yhuman = GetCharacterPos(Zombies[i]["target"])
	local dist = Distance(x, y, xhuman, yhuman)
	local WantedWeapon = {}
	WantedWeapon[0] = 1
	WantedWeapon[1] = 1
	WantedWeapon[2] = 1
	WantedWeapon[3] = 1
	WantedWeapon[4] = 1
	if (dist > 400 and dist <= 500) then
		WantedWeapon[0] = 4;
		WantedWeapon[1] = 3;
		WantedWeapon[2] = 1;
		WantedWeapon[3] = 2;
	elseif (dist > 200 and dist <= 400) then
		WantedWeapon[0] = 3;
		WantedWeapon[1] = 2;
		WantedWeapon[2] = 4;
		WantedWeapon[3] = 1;
	elseif (dist > 50 and dist <= 200) then
		WantedWeapon[0] = 2;
		WantedWeapon[1] = 1;
		WantedWeapon[2] = 3;
		WantedWeapon[3] = 0;
		WantedWeapon[4] = 4;
	elseif (dist <= 50) then
		WantedWeapon[0] = 0;
	end
	for w = 0, 4 do
        local Ammo, Got = CharacterGetAmmo(128 - i, WantedWeapon[w])
		if(Got and (Ammo > 0 or WantedWeapon[w] == 0 or Ammo == -1)) then
            if (Zombies[i]["type"] == 1 and WantedWeapon[w] == 1) then
                WantedWeapon[w] = 0
            end
            if (Zombies[i]["type"] == 2 and WantedWeapon[w] > 1) then
                WantedWeapon[w] = 0
            end
			CharacterSetInputWeapon(128 - i, WantedWeapon[w] + 1)
			break
		end
	end
end

function ZombieSpawnSet(i, zombielevel)
    Zombies[i]["type"] = zombielevel
    SetPlayerName(128 - i, Names[zombielevel])
	if(zombielevel == 1) then
        CharacterSetAmmo(128 - i, 0, -1)
        CharacterSetAmmo(128 - i, 1, 0)
		CharacterSetInputWeapon(128 - i, 1)
        Zombies[i]["allowedchangeweapon"] = true
        Zombies[i]["attackspeed"] = 25
        Zombies[i]["allowedhook"] = false

		--str_format(skin_name,sizeof(skin_name),"zombie1");
	end
	if(zombielevel == 2) then
        CharacterSetAmmo(128 - i, 0, 0)
        CharacterSetAmmo(128 - i, 1, 10)
		CharacterSetInputWeapon(128 - i, 2)
        Zombies[i]["allowedchangeweapon"] = true
        Zombies[i]["attackspeed"] = 12
        Zombies[i]["allowedhook"] = false
		--str_format(skin_name,sizeof(skin_name),"zombie2");
	end
	if(zombielevel == 3) then
        CharacterSetAmmo(128 - i, 0, -1)
        CharacterSetAmmo(128 - i, 1, 10)
		CharacterSetInputWeapon(128 - i, 2)
        Zombies[i]["allowedchangeweapon"] = true
        Zombies[i]["attackspeed"] = 6
        Zombies[i]["allowedhook"] = true
		--str_format(skin_name,sizeof(skin_name),"zombie3");
	end
	if(zombielevel == 4) then
        CharacterIncreaseHealth(128 - i, 50, 60)
        CharacterIncreaseArmor(128 - i, 60, 60)
        CharacterSetAmmo(128 - i, 0, -1)
        CharacterSetAmmo(128 - i, 1, 0)
		CharacterSetInputWeapon(128 - i, 1)
        Zombies[i]["allowedchangeweapon"] = false
        Zombies[i]["attackspeed"] = 3
        Zombies[i]["allowedhook"] = true
		--str_format(skin_name,sizeof(skin_name),"zombie4");
	end
end

function Move(i)
    local x, y = GetCharacterPos(128 - i)
    if(x == Zombies[i]["x"] and iTick - Zombies[i]["movetick"] > 25) then
		if(Zombies[i]["nexttry"] == 0 and (CharacterGetCoreJumped(128 - i) == nil or CharacterGetCoreJumped(128 - i) >= 2)) then
			return
        end
		if (Zombies[i]["nexttry"] == 0) then
			CharacterSetInputJump(128 - i, 1)
			Zombies[i]["nexttry"] = Zombies[i]["nexttry"] + 1
		elseif (Zombies[i]["nexttry"] == 1) then
			CharacterSetInputJump(128 - i, 1)
			Zombies[i]["nexttry"] = Zombies[i]["nexttry"] + 1
		elseif (Zombies[i]["nexttry"] == 2) then
			Zombies[i]["direction"] = -Zombies[i]["direction"]
			Zombies[i]["nexttry"] = 0
		end
		Zombies[i]["movetick"] = iTick;
	elseif(x ~= Zombies[i]["x"]) then
		Zombies[i]["nexttry"] = 0
    else
        CharacterSetInputJump(128 - i, 0)
    end

    CharacterSetInputDirection(128 - i, Zombies[i]["direction"])

	Zombies[i]["x"] = x
	Zombies[i]["y"] = y
end

function CheckClostestHuman(i)
    local x, y = GetCharacterPos(128 - i)
	local Chars = pack(EntityFind(x, y, 3000, 64, 4))
	local mindist = nil
	for z = 1, #Chars do
		if(EntityGetCharacterId(Chars[z]) ~= 128 - i and GetPlayerTeam(EntityGetCharacterId(Chars[z])) ~= GetPlayerTeam(128 - i)) then
            local xhuman, yhuman = GetCharacterPos(EntityGetCharacterId(Chars[z]))
            local dist = Distance(xhuman, yhuman, x, y);
            if(mindist == nil or dist < mindist) then
                if(xhuman > x) then
                    Zombies[i]["direction"] = 1;
                else
                    Zombies[i]["direction"] = -1;
                end
            end
        end
	end
	if(Zombies[i]["direction"] == Zombies[i]["direction"]) then
		Zombies[i]["direction"] = 1;
    end
end



--Init
function Reset(i)
    Zombies[i]["x"] = 0
    Zombies[i]["y"] = 0
    Zombies[i]["tarx"] = 0
    Zombies[i]["tary"] = 0
    Zombies[i]["nexttry"] = 0
    Zombies[i]["direction"] = 0
    Zombies[i]["state"] = ZOMBIE_STATE_SPAWNED
    Zombies[i]["allowedfire"] = true
    Zombies[i]["allowedchangeweapon"] = false
    Zombies[i]["allowedhook"] = false
    Zombies[i]["attackspeed"] = 0
    Zombies[i]["target"] = -1
    Zombies[i]["viewtick"] = 0
    Zombies[i]["movetick"] = 0
    Zombies[i]["pressedtick"] = 0
    Zombies[i]["type"] = 0
    Zombies[i]["dietick"] = 0
end

Killed = {}
Killed[1] = 0
Killed[2] = 0
Killed[3] = 0
Killed[4] = 0

Spawned = {}
Spawned[1] = 0
Spawned[2] = 0
Spawned[3] = 0
Spawned[4] = 0

Waves = {}
Waves[1] = {}
Waves[1][1] = 5
Waves[1][2] = 0
Waves[1][3] = 0
Waves[1][4] = 0

Waves[2] = {}
Waves[2][1] = 10
Waves[2][2] = 0
Waves[2][3] = 0
Waves[2][4] = 0

Waves[3] = {}
Waves[3][1] = 20
Waves[3][2] = 0
Waves[3][3] = 0
Waves[3][4] = 0

Waves[4] = {}
Waves[4][1] = 10
Waves[4][2] = 0
Waves[4][3] = 0
Waves[4][4] = 1

Waves[5] = {}
Waves[5][1] = 0
Waves[5][2] = 10
Waves[5][3] = 0
Waves[5][4] = 0

Waves[6] = {}
Waves[6][1] = 0
Waves[6][2] = 15
Waves[6][3] = 0
Waves[6][4] = 0

Waves[7] = {}
Waves[7][1] = 0
Waves[7][2] = 20
Waves[7][3] = 0
Waves[7][4] = 0

Waves[8] = {}
Waves[8][1] = 0
Waves[8][2] = 10
Waves[8][3] = 0
Waves[8][4] = 2

Waves[9] = {}
Waves[9][1] = 0
Waves[9][2] = 0
Waves[9][3] = 15
Waves[9][4] = 0

Waves[10] = {}
Waves[10][1] = 0
Waves[10][2] = 0
Waves[10][3] = 20
Waves[10][4] = 0

Waves[11] = {}
Waves[11][1] = 0
Waves[11][2] = 0
Waves[11][3] = 30
Waves[11][4] = 0

Waves[12] = {}
Waves[12][1] = 0
Waves[12][2] = 0
Waves[12][3] = 10
Waves[12][4] = 3

Waves[13] = {}
Waves[13][1] = 0
Waves[13][2] = 0
Waves[13][3] = -1
Waves[13][4] = 0
WaveNum = 0

Kills = 0

Players = {}
for i = 0, PlayerCount - 1 do
    Players[i] = {}
    Players[i]["lifes"] = 3
    Players[i]["dietick"] = 0
end

NextWaveCountDown = 500
RoundStarted = false

Names = {}
Names[1] = "Young Zombie"
Names[2] = "Zombie"
Names[3] = "Elder Zombie"
Names[4] = "Mega Zombie"

for i = 1, NumZombies do
    DummyCreate(128 - i)

    Zombies[i] = {}
    Reset(i)
    SetPlayerTeam(128 - i, 1)
end
