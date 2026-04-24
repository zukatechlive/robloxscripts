return (function(...)local X3, _;
do
	local U = math.floor;
	local T9 = math.random;
	local MM = table.remove;
	local x = string.char;
	local nW = string.byte;
	local CO = string.len;
	local v4 = math.floor;
	local cG = 0x4c958000;
	local y = 0X2685;
	local JL = 4294967296;
	local zC = 0xde;
	local function D(U, T9)
		local MM, x = 0b0, 0X1;
		while U > 0b0 or T9 > 0B0 do
			local nW = U % 0b10;
			local CO = T9 % 2;
			if nW ~= CO then
				MM = MM + x;
			end;
			U = v4(U / 0B10);
			T9 = v4(T9 / 0X2);
			x = x * 0X2;
		end;
		return MM;
	end;
	local lH = 0x0;
	local Pc = 0B1;
	local t7 = {};
	local GW = {};
	local L = {};
	for U = 0B1, 0b100000000, 1 do
		L[U] = U;
	end;
	repeat
		local U = T9(0B1, #L);
		local nW = MM(L, U);
		GW[nW] = x(nW - 0B1);
	until #L == 0x0;
	local function RE()
		lH = (lH * cG + y) % JL;
		Pc = (Pc * 0b101001 + 0x13) % 0B11101111 + 0X1;
		return U((lH + Pc * 0X100_03) % JL);
	end;
	local function w()
		if #t7 == 0B0 then
			local T9 = RE();
			local MM = T9 % 0X100;
			local x = U(T9 / 0X100) % 0x100;
			local nW = U(T9 / 0x10000) % 0x100;
			local CO = U(T9 / 0X10000_00) % 0b1000_00000;
			t7 = {
					MM,
					x,
					nW,
					CO,
				};
		end;
		return MM(t7);
	end;
	local I6 = {};
	X3 = setmetatable({}, { __index = I6, __metatable = nil });
	function _(U, T9)
		local MM = I6;
		if not MM[T9] then
			t7 = {};
			lH = T9 % JL;
			Pc = T9 % 0XEF + 1;
			local x = CO(U);
			local v4 = zC;
			local cG = {};
			local y = GW;
			for T9 = 0B1, x, 0x1 do
				local MM = nW(U, T9);
				local x = w();
				local CO = D(MM, D(x, v4)) % 256;
				cG[T9] = y[CO + 0x1];
				v4 = ((v4 + CO) + 0B1000011) % 0x100;
			end;
			MM[T9] = table.concat(cG);
		end;
		return T9;
	end;
end;
local U = X3[_("29\246\204\004\226\172M\144", -770595805)];
local T9 = X3[_(" \159\\?\005", -155259523)];
local function MM()
	return U, T9;
end;
if rawget(_G, X3[_("D\168|\193\2072\163\161k\000\2488\n\2115B", -0X4AA39548)]) ~= nil then
	rawset(_G, X3[_("p:| O\198\163%\006X\248\176G\188:\143", -0X749AE936)], MM);
end;
if rawget(_G, X3[_("\196!\227z\006\247\185e\021I\227c\"\028>", -0X33D267A5)]) ~= nil then
	rawset(_G, X3[_("5\243c\219F\237\185\171\021?\236\005O\1720", -1753141502)], MM);
end;
local x = getrawmetatable(game);
local nW = rawget(x, X3[_("9F\228\206k.\139PD6", -0X366F6CDF)]);
if nW and (iscclosure and not iscclosure(nW)) then
	warn(X3[_(")dP\137\164-\130\216x\142\138\r\255\136\173\026!\214\207y\201\242\1647\022\233\175\007\230\142\\\186WL\253\184\153\133\160\011\224\180}\144\2193\158r\233\160\001\208\1747\003\246_0", -0X7FEEFFDE)]);
end;
local CO = {};
local function v4(U)
	if CO[U] then
		return;
	end;
	CO[U] = true;
	if islclosure and islclosure(U[X3[_("\178.Ij\146\210\244\134\005\157", -1676068814)]]) then
		warn(X3[_("\181)\223|\137\022\131\2495\164\138V \201\155\015C\155%\202\219\"\173/Y\137\232,\232\001F", -659639971)], U:GetFullName());
	end;
end;
local cG = setmetatable({}, { [X3[_("*\231\237\210\234\211\145", -1023965713)]] = function(U, T9)
			warn(X3[_("\196\232\221\029\137\226\140\149\143R\139\145\221C\1633Li?\188\132", -0X122D245B)] .. (T9  .. X3[_("\017\139\162\182\021/\215\220", -0X6D53DAA8)]));
			return function()
 
			end;
		end, [X3[_("H\203\235\251}B\169\172m\174", -869230495)]] = function()
 
		end, [X3[_("\213\143gZ\177\157", -0X6182C306)]] = function()
			warn(X3[_("\020\186P\187\164$\130\231x\222\139\245\221M\163\217\006X0K\133)\175\029\237eT#1\246", -0X7A22F446)]);
			return nil;
		end });
if rawget(_G, X3[_("\158+\234\255\168{\254\187\001", -461715211)]) ~= nil then
	rawset(_G, X3[_("9\241j\019\133\137\240\177L", -0X44408882)], cG);
end;
if rawget(_G, X3[_("\232\201\004f\197\239\177\135\251", -0X7753EEA8)]) ~= nil then
	rawset(_G, X3[_("\'\228\139\025\232\249\176A\012", -444740869)], cG);
end;
local y = http_request or request;
local function JL(U)
	local T9 = U and U[X3[_("SBo", -1865604710)]] or X3[_("", -471414835)];
	for MM, x in ipairs({ X3[_("D\011\143\016j\173\001\206.\143", -594495199)], X3[_("\200\199\001(G;M\204\253`\189\001\149\171", -0X767CECFA)] }) do
		if T9:find(x, 0X1, true) then
			return y(U);
		end;
	end;
	warn(X3[_("\216\186Q\001\164\002\1405\142\236\132:)\162\158\218}ok", -0X48989132)], T9);
	return { [X3[_("\023\215\227Io\203\144\135y\167", -489372247)]] = 0B110010011, [X3[_("DLW\183", -2024927588)]] = X3[_("", -0X6C91D924)] };
end;
http_request = JL;
request = JL;end)(...) -- anti webhook and exec spoofer
