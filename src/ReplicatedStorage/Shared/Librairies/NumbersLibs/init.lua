-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

game:GetService("ReplicatedStorage");
game:GetService("Players");
game:GetService("ServerScriptService");
game:GetService("MarketplaceService");
game:GetService("BadgeService");
local BigNum = require(script.BigNum);
local u48 = {
    x = BigNum,

    new = function(p1, p2) -- Line: 12, Name: new
        -- upvalues: BigNum (copy)
        return BigNum.new(p1, p2);
    end,

    convert = function(p3) -- Line: 15, Name: convert
        -- upvalues: BigNum (copy)
        return BigNum.convert(p3);
    end,

    add = function(p4, p5) -- Line: 19, Name: add
        -- upvalues: BigNum (copy)
        local v6 = typeof(p4) == "table" and p4 and p4 or BigNum.convert(p4);
        local v7 = typeof(p5) == "table" and p5 and p5 or BigNum.convert(p5);

        return BigNum.bnumtostr(BigNum.add(v6, v7));
    end,

    sub = function(p8, p9) -- Line: 24, Name: sub
        -- upvalues: BigNum (copy)
        local v10 = typeof(p8) == "table" and p8 and p8 or BigNum.convert(p8);
        local v11 = typeof(p9) == "table" and p9 and p9 or BigNum.convert(p9);

        return BigNum.bnumtostr(BigNum.sub(v10, v11));
    end,

    mul = function(...) -- Line: 29, Name: mul
        -- upvalues: BigNum (copy)
        local v12 = { 1, 0 };

        for _, v in ipairs({ ... }) do
            local v13 = typeof(v) == "table" and v and v or BigNum.convert(v);
            v12 = BigNum.mul(v12, v13);
        end;

        return BigNum.bnumtostr(v12);
    end,

    div = function(p14, p15) -- Line: 40, Name: div
        -- upvalues: BigNum (copy)
        local v16 = typeof(p14) == "table" and p14 and p14 or BigNum.convert(p14);
        local v17 = typeof(p15) == "table" and p15 and p15 or BigNum.convert(p15);

        return BigNum.bnumtostr(BigNum.div(v16, v17));
    end,

    pow = function(p18, p19) -- Line: 45, Name: pow
        -- upvalues: BigNum (copy)
        local v20 = typeof(p18) == "table" and p18 and p18 or BigNum.convert(p18);
        local v21 = typeof(p19) == "table" and p19 and p19 or BigNum.convert(p19);

        return BigNum.bnumtostr(BigNum.pow(v20, v21));
    end,

    log = function(p22) -- Line: 50, Name: log
        -- upvalues: BigNum (copy)
        local v23 = typeof(p22) == "table" and p22 and p22 or BigNum.convert(p22);

        return BigNum.bnumtostr(BigNum.log(v23));
    end,

    log10 = function(p24) -- Line: 54, Name: log10
        -- upvalues: BigNum (copy)
        local v25 = typeof(p24) == "table" and p24 and p24 or BigNum.convert(p24);

        return BigNum.bnumtostr(BigNum.log(v25));
    end,

    eq = function(p26, p27, p28) -- Line: 60, Name: eq
        -- upvalues: BigNum (copy)
        local v29 = typeof(p26) == "table" and p26 and p26 or BigNum.convert(p26);
        local v30 = typeof(p28) == "table" and p28 and p28 or BigNum.convert(p28);

        if p27 == "<" then
            return BigNum.le(v29, v30);
        end;

        if p27 == "<=" then
            return BigNum.leeq(v29, v30);
        end;

        if p27 == "=" then
            return BigNum.eq(v29, v30);
        end;

        if p27 == ">=" then
            return BigNum.meeq(v29, v30);
        end;

        if p27 == ">" then
            return BigNum.me(v29, v30);
        end;

        warn("No " .. p27 .. " in Equalities");

        return nil;
    end,

    floor = function(p31) -- Line: 76, Name: floor
        -- upvalues: BigNum (copy)
        local v32 = typeof(p31) == "table" and p31 and p31 or BigNum.convert(p31);

        return BigNum.bnumtostr(BigNum.floor(v32));
    end,

    toFloat = function(p33) -- Line: 80, Name: toFloat
        -- upvalues: BigNum (copy)
        local v34 = typeof(p33) == "table" and p33 and p33 or BigNum.convert(p33);

        return BigNum.bnumtofloat(v34);
    end,

    lbEncode = function(p35) -- Line: 90, Name: lbEncode
        -- upvalues: BigNum (copy)
        if p35 == nil then
            return 0;
        end;

        local v36 = typeof(p35);

        if v36 == "number" then
            if p35 == 0 then
                return 0;
            end;

            if p35 == p35 and (p35 ~= (1 / 0) and (p35 ~= (-1 / 0) and (p35 < 1e300 and p35 > 0))) then
                local v37 = math.log(p35) / 9.999999505838704e-8;

                return math.floor(v37);
            end;
        elseif v36 == "string" then
            local v38 = tonumber(p35);

            if v38 and (v38 == v38 and (v38 ~= (1 / 0) and (v38 ~= (-1 / 0) and (v38 > 0 and v38 < 1e300)))) then
                local v39 = math.log(v38) / 9.999999505838704e-8;

                return math.floor(v39);
            end;
        end;

        local v40 = BigNum.convert(p35);

        if typeof(v40) ~= "table" or (v40[1] == 0 or v40[1] < 0) then
            return 0;
        end;

        local v41 = v40[2] * 2.302585092994046 + math.log(v40[1]);

        if v41 ~= v41 or (v41 == (1 / 0) or v41 <= 0) then
            return v41 == (1 / 0) and 9.223372036854775e18 or 0;
        end;

        local v42 = math.floor(v41 / 9.999999505838704e-8);
        local v43 = v42 > 9.223372036854775e18 and 9.223372036854775e18 or v42;

        return v43 < 0 and 0 or v43;
    end,

    lbDecode = function(p44) -- Line: 123, Name: lbDecode
        -- upvalues: BigNum (copy)
        local v45 = tonumber(p44);

        if not v45 or v45 == 0 then
            return 0;
        end;

        if v45 < 7000000000 then
            return 1.0000001 ^ v45;
        end;

        local v46 = v45 * 4.3429446044209946e-8;
        local v47 = math.floor(v46);

        return BigNum.bnumtostr(BigNum.errorcorrection({ 10 ^ (v46 - v47), v47 }));
    end
};
local u49 = { 1, 100 };

function u48.Short(p50, p51, p52) -- Line: 140
    -- upvalues: BigNum (copy), u49 (copy), u48 (copy)
    local v53 = tonumber(p50);

    if v53 and (v53 ~= 0 and math.abs(v53) < 1) then
        local v54 = string.format("%." .. 2 .. "f", v53):gsub("(%..-)0+$", "%1"):gsub("%.$", "");
        local v55 = tonumber(v54) == 0 and "0" or v54;

        if p51 then
            v55 = v55 .. " " .. p51 or v55;
        end;

        return v55;
    end;

    local v56 = BigNum.convert(p50);

    if v56[2] >= u49[2] then
        return u48.toScientific(p50, p51, false);
    end;

    local v57 = BigNum.short(v56, p52);

    if p51 then
        v57 = v57 .. " " .. p51 or v57;
    end;

    return v57;
end;

function u48.toScientific(p58, p59, p60, p61) -- Line: 160
    -- upvalues: BigNum (copy), u48 (copy)
    local v62 = BigNum.convert(p58);
    local v63 = p60 and string.format("%.2f", v62[1]) or (p61 and string.format("%.0f", v62[1]) or string.format("%.1f", v62[1]));
    local v64 = u48.Short(v62[2], nil, 3);
    local v65 = string.format("%se%s", v63, v64);

    if p59 then
        v65 = v65 .. " " .. p59 or v65;
    end;

    return v65;
end;

return u48;