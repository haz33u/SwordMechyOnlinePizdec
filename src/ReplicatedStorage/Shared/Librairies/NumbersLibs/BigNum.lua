-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local u1 = {};

function u1.short(p2, u3) -- Line: 2
    -- upvalues: u1 (copy)
    if typeof(p2) ~= "table" then
        p2 = u1.convert(p2);
    end;

    local v4 = u1.errorcorrection(p2);
    local v5 = u3 and (10 ^ u3 or 100) or 100;
    v4[1] = math.round(v4[1] * v5) / v5;

    local function fmt(p6) -- Line: 12
        -- upvalues: u3 (copy)
        if u3 then
            return string.format("%." .. u3 .. "f", p6);
        end;

        return math.floor(p6 * 100) / 100;
    end;

    local v7 = v4[2];
    local v8 = v4[1];
    local v9 = math.fmod(v7, 3);
    local v10 = math.floor(v7 / 3) - 1;

    if v10 <= -1 then
        local v11 = u1.bnumtofloat(v4) * 100;

        return math.floor(v11) / 100;
    end;

    local u12 = { "", "U", "D", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No" };
    local u13 = { "", "De", "Vt", "Tg", "qg", "Qg", "sg", "Sg", "Og", "Ng" };
    local u14 = { "", "Ce", "Du", "Tr", "Qa", "Qi", "Se", "Si", "Ot", "Ni" };
    local v15 = { "", "Mi", "Mc", "Na", "Pi", "Fm", "At", "Zp", "Yc", "Xo", "Ve", "Me", "Due", "Tre", "Te", "Pt", "He", "Hp", "Oct", "En", "Ic", "Mei", "Dui", "Tri", "Teti", "Pti", "Hei", "Hp", "Oci", "Eni", "Tra", "TeC", "MTc", "DTc", "TrTc", "TeTc", "PeTc", "HTc", "HpT", "OcT", "EnT", "TetC", "MTetc", "DTetc", "TrTetc", "TeTetc", "PeTetc", "HTetc", "HpTetc", "OcTetc", "EnTetc", "PcT", "MPcT", "DPcT", "TPCt", "TePCt", "PePCt", "HePCt", "HpPct", "OcPct", "EnPct", "HCt", "MHcT", "DHcT", "THCt", "TeHCt", "PeHCt", "HeHCt", "HpHct", "OcHct", "EnHct", "HpCt", "MHpcT", "DHpcT", "THpCt", "TeHpCt", "PeHpCt", "HeHpCt", "HpHpct", "OcHpct", "EnHpct", "OCt", "MOcT", "DOcT", "TOCt", "TeOCt", "PeOCt", "HeOCt", "HpOct", "OcOct", "EnOct", "Ent", "MEnT", "DEnT", "TEnt", "TeEnt", "PeEnt", "HeEnt", "HpEnt", "OcEnt", "EnEnt", "Hect", "MeHect" };

    if v4[2] == (1 / 0) then
        return v4[1] < 0 and "-Infinity" or "Infinity";
    end;

    if v10 == 0 then
        local v16 = v8 * 10 ^ v9;
        local v17;

        if u3 then
            v17 = string.format("%." .. u3 .. "f", v16);
        else
            v17 = math.floor(v16 * 100) / 100;
        end;

        return v17 .. "k";
    end;

    if v10 == 1 then
        local v18 = v8 * 10 ^ v9;
        local v19;

        if u3 then
            v19 = string.format("%." .. u3 .. "f", v18);
        else
            v19 = math.floor(v18 * 100) / 100;
        end;

        return v19 .. "M";
    end;

    if v10 == 2 then
        local v20 = v8 * 10 ^ v9;
        local v21;

        if u3 then
            v21 = string.format("%." .. u3 .. "f", v20);
        else
            v21 = math.floor(v20 * 100) / 100;
        end;

        return v21 .. "B";
    end;

    local u22 = "";

    local function suffixpart(p23) -- Line: 48
        -- upvalues: u22 (ref), u12 (copy), u13 (copy), u14 (copy)
        local v24 = math.floor(p23 / 100);
        local v25 = math.fmod(p23, 100);
        local v26 = math.floor(v25 / 10);
        local v27 = math.fmod(v25, 10) / 1;
        u22 = u22 .. u12[math.floor(v27) + 1];
        u22 = u22 .. u13[v26 + 1];
        u22 = u22 .. u14[v24 + 1];
    end;

    local function suffixpart2(p28) -- Line: 61
        -- upvalues: u22 (ref), u12 (copy), u13 (copy), u14 (copy)
        if p28 > 0 then
            p28 = p28 + 1;
        end;

        if p28 > 1000 then
            p28 = math.fmod(p28, 1000);
        end;

        local v29 = math.floor(p28 / 100);
        local v30 = math.fmod(p28, 100);
        local v31 = math.floor(v30 / 10);
        local v32 = math.fmod(v30, 10) / 1;
        u22 = u22 .. u12[math.floor(v32) + 1];
        u22 = u22 .. u13[v31 + 1];
        u22 = u22 .. u14[v29 + 1];
    end;

    if v10 >= 1000 then
        for i = #v15, 0, -1 do
            if 10 ^ (i * 3) <= v10 then
                suffixpart2(math.floor(v10 / 10 ^ (i * 3)) - 1);
                u22 = u22 .. v15[i + 1];
                v10 = math.fmod(v10, 10 ^ (i * 3));
            end;
        end;

        local v33 = v8 * 10 ^ v9;
        local v34;

        if u3 then
            v34 = string.format("%." .. u3 .. "f", v33);
        else
            v34 = math.floor(v33 * 100) / 100;
        end;

        return v34 .. u22;
    end;

    local v35 = math.floor(v10 / 100);
    local v36 = math.fmod(v10, 100);
    local v37 = math.floor(v36 / 10);
    local v38 = math.fmod(v36, 10) / 1;
    u22 = u22 .. u12[math.floor(v38) + 1];
    u22 = u22 .. u13[v37 + 1];
    u22 = u22 .. u14[v35 + 1];
    local v39 = v8 * 10 ^ v9;
    local v40;

    if u3 then
        v40 = string.format("%." .. u3 .. "f", v39);
    else
        v40 = math.floor(v39 * 100) / 100;
    end;

    return v40 .. u22;
end;

function u1.strtobnum(p41) -- Line: 96
    local v42 = string.find(p41, "e");
    local v43 = {};
    local v44 = string.sub(p41, 1, v42 - 1);
    local v45 = tonumber(v44);
    local v46 = string.sub(p41, v42 + 1);
    v43[1], v43[2] = v45, tonumber(v46);

    return v43;
end;

function u1.bnumtofloat(p47) -- Line: 102
    -- upvalues: u1 (copy)
    return tonumber(u1.bnumtostr(p47));
end;

function u1.convert(u48) -- Line: 107
    -- upvalues: u1 (copy)
    if tonumber(u48) == nil then
        local success, _ = pcall(function() -- Line: 110
            -- upvalues: u1 (ref), u48 (copy)
            return u1.strtobnum(u48);
        end);

        return not success and "0" or u1.strtobnum(u48);
    end;

    if type(u48) == "number" and (tonumber(u48) == (1 / 0) or tonumber(u48) == (-1 / 0)) then
        return { 1, 1.797693e308 };
    end;

    if tonumber(u48) == (1 / 0) or tonumber(u48) == (-1 / 0) then
        return u1.strtobnum(u48);
    end;

    local v49 = tonumber(u48);

    if tostring(v49) == "nil" then
        return u1.strtobnum(u48);
    end;

    return u1.floattobnum((tonumber(u48)));
end;

function u1.new(p50, p51) -- Line: 136
    return { p50, p51 };
end;

function u1.floattobnum(p52) -- Line: 141
    -- upvalues: u1 (copy)
    local v53 = tostring(p52);
    local v54 = string.find(v53, "+");

    if v54 then
        return u1.strtobnum(string.sub(v53, 1, v54 - 1) .. string.sub(v53, v54 + 1));
    end;

    if string.find(v53, "e") then
        return u1.strtobnum(v53);
    end;

    return u1.errorcorrection(u1.strtobnum(v53 .. "e0"));
end;

function u1.bnumtostr(p55) -- Line: 154
    return tostring(p55[1]) .. "e" .. tostring(p55[2]);
end;

function u1.errorcorrection(p56) -- Line: 159
    if p56[1] == 0 then
        return { 0, 0 };
    end;

    local v57 = p56[1] < 0 and "-" or "+";

    if v57 == "-" then
        p56[1] = p56[1] * -1;
    end;

    local v58;

    if p56[2] < 0 then
        p56[2] = p56[2] * -1;
        v58 = "-";
    else
        v58 = "+";
    end;

    if math.fmod(p56[2], 1) > 0 then
        p56[1] = p56[1] * 10 ^ (1 - math.fmod(p56[2], 1));
        p56[2] = math.floor(p56[2]) + 1;
    end;

    if v58 == "-" then
        p56[2] = p56[2] * -1;
    end;

    local v59 = math.log10(p56[1]);
    local v60 = math.floor(v59);
    p56[1] = p56[1] / 10 ^ v60;
    p56[2] = p56[2] + v60;
    p56[2] = math.floor(p56[2]);

    if v57 == "-" then
        p56[1] = p56[1] * -1;
    end;

    return p56;
end;

function u1.div(p61, p62) -- Line: 200
    -- upvalues: u1 (copy)
    local v63 = u1.errorcorrection(p61);
    local v64 = u1.errorcorrection(p62);
    local v65 = u1.new(0, 0);
    v65[1] = v63[1] / v64[1];
    v65[2] = v63[2] - v64[2];

    return u1.errorcorrection(v65);
end;

function u1.mul(p66, p67) -- Line: 211
    -- upvalues: u1 (copy)
    local v68 = u1.errorcorrection(p66);
    local v69 = u1.errorcorrection(p67);
    local v70 = u1.new(0, 0);
    v70[1] = v68[1] * v69[1];
    v70[2] = v68[2] + v69[2];

    return u1.errorcorrection(v70);
end;

function u1.log10(p71) -- Line: 222
    -- upvalues: u1 (copy)
    local v72 = p71[2] + math.log10(p71[1]);

    return u1.errorcorrection(u1.new(v72, 0));
end;

local function isZero(p73) -- Line: 228
    return p73[1] == 0;
end;

function u1.cmp(p74, p75) -- Line: 232
    -- upvalues: u1 (copy)
    local v76 = u1.errorcorrection(p74);
    local v77 = u1.errorcorrection(p75);

    if v76[1] == 0 and v77[1] == 0 then
        return 0;
    end;

    if v76[1] == 0 then
        return v77[1] > 0 and -1 or 1;
    end;

    if v77[1] == 0 then
        return v76[1] > 0 and 1 or -1;
    end;

    local v78 = v76[1] < 0;

    return v78 == (v77[1] < 0) and (v76[2] == v77[2] and (v76[1] == v77[1] and 0 or (v78 and (v76[1] < v77[1] and 1 or -1) or (v76[1] < v77[1] and -1 or 1))) or (v78 and (v76[2] < v77[2] and 1 or -1) or (v76[2] < v77[2] and -1 or 1))) or (v78 and -1 or 1);
end;

function u1.eq(p79, p80) -- Line: 272
    -- upvalues: u1 (copy)
    return u1.cmp(p79, p80) == 0;
end;

function u1.le(p81, p82) -- Line: 276
    -- upvalues: u1 (copy)
    return u1.cmp(p81, p82) == -1;
end;

function u1.me(p83, p84) -- Line: 280
    -- upvalues: u1 (copy)
    return u1.cmp(p83, p84) == 1;
end;

function u1.leq(p85, p86) -- Line: 284
    -- upvalues: u1 (copy)
    return u1.cmp(p85, p86) <= 0;
end;

function u1.geq(p87, p88) -- Line: 288
    -- upvalues: u1 (copy)
    return u1.cmp(p87, p88) >= 0;
end;

function u1.add(p89, p90) -- Line: 292
    -- upvalues: u1 (copy)
    local v91 = u1.errorcorrection(p89);
    local v92 = u1.errorcorrection(p90);
    local v93 = u1.new(0, 0);
    local v94 = v92[2] - v91[2];

    if v94 > 20 then
        return v92;
    end;

    if v94 < -20 then
        return v91;
    end;

    v93[2] = v91[2];
    v93[1] = v91[1] + v92[1] * 10 ^ v94;

    return u1.errorcorrection(v93);
end;

function u1.sub(p95, p96) -- Line: 310
    -- upvalues: u1 (copy)
    local v97 = u1.errorcorrection(p95);
    local v98 = u1.errorcorrection(p96);
    local v99 = u1.new(0, 0);
    local v100 = v98[2] - v97[2];

    if v100 > 20 then
        v99 = u1.new(v97[1] * -1, v98[2]);
    else
        if v100 < -20 then
            return v97;
        end;

        v99[2] = v97[2];
        v99[1] = v97[1] - v98[1] * 10 ^ v100;
    end;

    return u1.errorcorrection(v99);
end;

function u1.pow(p101, p102) -- Line: 328
    -- upvalues: u1 (copy)
    if p101[1] < 0 then
        return { 1, 0 };
    end;

    local v103 = u1.errorcorrection(p101);
    local v104 = u1.errorcorrection(p102);

    if v103[1] == 0 and (v104[1] == 0 and v104[2] == 0) then
        return { 0.5, 0 };
    end;

    if v104[1] == 0 and v104[2] == 0 then
        return { 1, 0 };
    end;

    if v103[1] == 0 then
        return { 0, 0 };
    end;

    local v105 = v104[1] < 0;
    local v106 = v105 and { -v104[1], v104[2] } or v104;
    local v107 = u1.bnumtofloat(u1.log10(v103)) * u1.bnumtofloat(v106);
    local v108 = math.floor(v107);
    local v109 = u1.errorcorrection({ 10 ^ (v107 - v108), v108 });

    if v105 then
        v109 = u1.div({ 1, 0 }, v109);
    end;

    return u1.errorcorrection(v109);
end;

function u1.sqrt(p110) -- Line: 367
    -- upvalues: u1 (copy)
    local v111 = u1.errorcorrection(p110);

    return u1.pow(v111, { 5, -1 });
end;

function u1.log(p112) -- Line: 373
    -- upvalues: u1 (copy)
    local v113 = u1.bnumtofloat({ 2.718281828045905, 0 });
    local v114 = (p112[2] + math.log10(p112[1])) / math.log10(v113);

    return u1.errorcorrection(u1.new(v114, 0));
end;

function u1.rand(p115, p116) -- Line: 381
    -- upvalues: u1 (copy)
    local v117 = u1.convert(math.random());
    local v118 = u1.mul(v117, u1.sub(p115, p116));

    return u1.add(v118, p116);
end;

function u1.abs(p119) -- Line: 390
    return { math.abs(p119[1]), p119[2] };
end;

function u1.floor(p120) -- Line: 395
    -- upvalues: u1 (copy)
    if p120[2] > 15 then
        return p120;
    end;

    local convert = u1.convert;
    local v121 = u1.bnumtofloat(p120);

    return convert((math.floor(v121)));
end;

function u1.meeq(p122, p123) -- Line: 403
    -- upvalues: u1 (copy)
    return (u1.me(p122, p123) or u1.eq(p122, p123)) and true or false;
end;

function u1.leeq(p124, p125) -- Line: 411
    -- upvalues: u1 (copy)
    return (u1.le(p124, p125) or u1.eq(p124, p125)) and true or false;
end;

return u1;