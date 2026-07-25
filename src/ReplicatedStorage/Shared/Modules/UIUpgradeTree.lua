-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local NumbersLibs = require(ReplicatedStorage.Shared.Librairies.NumbersLibs);
local Icons = require(ReplicatedStorage.Shared.Modules.Icons);
local u1 = {};

local function emptyFormat(p2) -- Line: 26
    return "";
end;

local function mulFormat(p3) -- Line: 30
    -- upvalues: NumbersLibs (copy)
    return "x" .. NumbersLibs.Short(string.format("%.2f", p3));
end;

local function percentFormat(p4) -- Line: 34
    return string.format("+%g%%", math.round((p4 - 1) * 1000) / 10);
end;

local function activeFormat(p5) -- Line: 42
    return p5 >= 1 and "Active" or "Not Active";
end;

u1.Nodes = {
    TheStart = {
        title = "The Start",
        desc = "The start of the tree.",
        applyBoost = nil,
        maxLevel = 1,
        gradientType = "Oof",
        icon = Icons.Tree,
        unlocks = { "PrismGenerationSpeed", "OofMulti1", "RuneSpeedMulRight1", "PrismMulR3_1" },
        cost = {
            type = "Prism",
            cost = 0
        },

        getCost = function(p6) -- Line: 55, Name: getCost
            return 0 * (p6 + 1);
        end,

        boost = function(p7) -- Line: 57, Name: boost
            return p7;
        end,

        formatBoost = activeFormat
    },
    PrismGenerationSpeed = {
        title = "Prism Generation Speed",
        desc = "Generate Prisms faster.",
        gradientType = "Prism",
        maxLevel = 5,
        icon = Icons.PrismSpeed,
        unlocks = { "MorePrismPlus1" },
        cost = {
            type = "Prism",
            cost = 1
        },

        getCost = function(p8) -- Line: 69, Name: getCost
            return math.floor(1 * 1.8 ^ p8);
        end,

        applyBoost = function(p9, p10, p11) -- Line: 70, Name: applyBoost
            p9.currency("PrismSpeed"):SetMul("UITree_PrismGenerationSpeed", p10 and 1 / p11 or 1);
        end,

        boost = function(p12) -- Line: 73, Name: boost
            return 1 + 0.015 * p12;
        end,

        formatBoost = percentFormat
    },
    MorePrismPlus1 = {
        title = "More Prism Multiplier",
        desc = "Gain more Prisms.",
        gradientType = "Prism",
        maxLevel = 12,
        icon = Icons.PrismMul,
        unlocks = { "PrismMultiLeft" },
        cost = {
            type = "Prism",
            cost = 3
        },

        getCost = function(p13) -- Line: 84, Name: getCost
            return math.floor(3 * 1.35 ^ p13);
        end,

        applyBoost = function(p14, p15, p16) -- Line: 85, Name: applyBoost
            p14.currency("Prism"):SetMul("UITree_MorePrismPlus1", p15 and p16 and p16 or 1);
        end,

        boost = function(p17) -- Line: 88, Name: boost
            return 1 + 0.7 * p17;
        end,

        formatBoost = mulFormat
    },
    PrismMultiLeft = {
        title = "Prism Multi",
        desc = "Gain more Prism.",
        gradientType = "Prism",
        maxLevel = 5,
        icon = Icons.PrismMul,
        unlocks = { "MorePrismPlus2" },
        cost = {
            type = "Prism",
            cost = 45
        },

        getCost = function(p18) -- Line: 99, Name: getCost
            return math.floor(45 * 1.65 ^ p18);
        end,

        applyBoost = function(p19, p20, p21) -- Line: 100, Name: applyBoost
            p19.currency("Prism"):SetMul("UITree_PrismMultiLeft", p20 and p21 and p21 or 1);
        end,

        boost = function(p22) -- Line: 103, Name: boost
            return 1 + 1.6 * p22;
        end,

        formatBoost = mulFormat
    },
    MorePrismPlus2 = {
        title = "More Prism Mul",
        desc = "Gain even more Prism.",
        gradientType = "Prism",
        maxLevel = 20,
        icon = Icons.PrismMul,
        unlocks = { "FasterPrismLeft" },
        cost = {
            type = "Prism",
            cost = 120
        },

        getCost = function(p23) -- Line: 114, Name: getCost
            return math.floor(120 * 1.28 ^ p23);
        end,

        applyBoost = function(p24, p25, p26) -- Line: 115, Name: applyBoost
            p24.currency("Prism"):SetMul("UITree_MorePrismPlus2", p25 and p26 and p26 or 1);
        end,

        boost = function(p27) -- Line: 118, Name: boost
            return 1 + 0.38 * p27;
        end,

        formatBoost = mulFormat
    },
    FasterPrismLeft = {
        title = "Faster Prism",
        desc = "Speed up Prism generation.",
        gradientType = "Prism",
        maxLevel = 6,
        icon = Icons.PrismSpeed,
        unlocks = { "MorePrismFromGuilds" },
        cost = {
            type = "Prism",
            cost = 8500
        },

        getCost = function(p28) -- Line: 129, Name: getCost
            return math.floor(8500 * 1.55 ^ p28);
        end,

        applyBoost = function(p29, p30, p31) -- Line: 130, Name: applyBoost
            p29.currency("PrismSpeed"):SetMul("UITree_FasterPrismLeft", p30 and 1 / p31 or 1);
        end,

        boost = function(p32) -- Line: 133, Name: boost
            return 1 + 0.02 * p32;
        end,

        formatBoost = percentFormat
    },
    RuneSpeedMulRight1 = {
        title = "Rune Speed Mul",
        desc = "Roll runes faster.",
        gradientType = "Rune",
        maxLevel = 6,
        icon = Icons.RuneSpeed,
        unlocks = { "RuneLuckMulRight1" },
        cost = {
            type = "Prism",
            cost = 40
        },

        getCost = function(p33) -- Line: 145, Name: getCost
            return math.floor(40 * 1.65 ^ p33);
        end,

        applyBoost = function(p34, p35, p36) -- Line: 146, Name: applyBoost
            p34.currency("RuneSpeed"):SetMul("UITree_RuneSpeedMulRight1", p35 and 1 / p36 or 1);
        end,

        boost = function(p37) -- Line: 149, Name: boost
            return 1 + 0.05 * p37;
        end,

        formatBoost = mulFormat
    },
    RuneLuckMulRight1 = {
        title = "Rune Luck Mul",
        desc = "Better rune luck.",
        gradientType = "Rune",
        maxLevel = 6,
        icon = Icons.RuneLuck,
        unlocks = { "RuneBulkMulRight1" },
        cost = {
            type = "Prism",
            cost = 120
        },

        getCost = function(p38) -- Line: 160, Name: getCost
            return math.floor(120 * 1.7 ^ p38);
        end,

        applyBoost = function(p39, p40, p41) -- Line: 161, Name: applyBoost
            p39.currency("RuneLuck"):SetMul("UITree_RuneLuckMulRight1", p40 and p41 and p41 or 1);
        end,

        boost = function(p42) -- Line: 164, Name: boost
            return 1 + 0.07 * p42;
        end,

        formatBoost = mulFormat
    },
    RuneBulkMulRight1 = {
        title = "Rune Bulk Mul",
        desc = "Roll more runes at once.",
        gradientType = "Rune",
        maxLevel = 5,
        icon = Icons.RuneBulk,
        unlocks = { "RunePriceDecrease" },
        cost = {
            type = "Prism",
            cost = 350
        },

        getCost = function(p43) -- Line: 175, Name: getCost
            return math.floor(350 * 1.75 ^ p43);
        end,

        applyBoost = function(p44, p45, p46) -- Line: 176, Name: applyBoost
            p44.currency("RuneBulk"):SetMul("UITree_RuneBulkMulRight1", p45 and p46 and p46 or 1);
        end,

        boost = function(p47) -- Line: 179, Name: boost
            return 1 + 0.1 * p47;
        end,

        formatBoost = mulFormat
    },
    RunePriceDecrease = {
        title = "Rune Price Decrease",
        desc = "Cheaper runes.",
        applyBoost = nil,
        gradientType = "Rune",
        maxLevel = 5,
        icon = Icons.RuneDiscount,
        unlocks = { "RuneLuckMulRight2", "RuneCloneFor100k" },
        cost = {
            type = "Prism",
            cost = 1200
        },

        getCost = function(p48) -- Line: 190, Name: getCost
            return math.floor(1200 * 1.8 ^ p48);
        end,

        boost = function(p49) -- Line: 192, Name: boost
            return 1.019 ^ p49;
        end,

        formatBoost = mulFormat
    },
    RuneCloneFor100k = {
        title = "Rune Clone < 1/100k",
        desc = "Clone runes with a BASE CHANCE below 1/100k.",
        applyBoost = nil,
        maxLevel = 1,
        gradientType = "Rune",
        icon = Icons.RuneClone,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 15000000
        },

        getCost = function(p50) -- Line: 203, Name: getCost
            return 15000000;
        end,

        boost = function(p51) -- Line: 205, Name: boost
            return p51;
        end,

        formatBoost = activeFormat
    },
    RuneLuckMulRight2 = {
        title = "Rune Luck Mul",
        desc = "Even better rune luck.",
        gradientType = "Rune",
        maxLevel = 8,
        icon = Icons.RuneLuck,
        unlocks = { "RuneSpeedMulRight2" },
        cost = {
            type = "Prism",
            cost = 3500
        },

        getCost = function(p52) -- Line: 216, Name: getCost
            return math.floor(3500 * 1.8 ^ p52);
        end,

        applyBoost = function(p53, p54, p55) -- Line: 217, Name: applyBoost
            p53.currency("RuneLuck"):SetMul("UITree_RuneLuckMulRight2", p54 and p55 and p55 or 1);
        end,

        boost = function(p56) -- Line: 220, Name: boost
            return 1 + 0.1 * p56;
        end,

        formatBoost = mulFormat
    },
    RuneSpeedMulRight2 = {
        title = "Rune Speed Mul",
        desc = "Roll runes even faster.",
        gradientType = "Rune",
        maxLevel = 8,
        icon = Icons.RuneSpeed,
        unlocks = { "RuneBulkMulRight2" },
        cost = {
            type = "Prism",
            cost = 8000
        },

        getCost = function(p57) -- Line: 231, Name: getCost
            return math.floor(8000 * 1.8 ^ p57);
        end,

        applyBoost = function(p58, p59, p60) -- Line: 232, Name: applyBoost
            p58.currency("RuneSpeed"):SetMul("UITree_RuneSpeedMulRight2", p59 and 1 / p60 or 1);
        end,

        boost = function(p61) -- Line: 235, Name: boost
            return 1 + 0.025 * p61;
        end,

        formatBoost = mulFormat
    },
    RuneBulkMulRight2 = {
        title = "Rune Bulk Mul",
        desc = "Roll even more runes at once.",
        gradientType = "Rune",
        maxLevel = 8,
        icon = Icons.RuneBulk,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 20000
        },

        getCost = function(p62) -- Line: 246, Name: getCost
            return math.floor(20000 * 1.8 ^ p62);
        end,

        applyBoost = function(p63, p64, p65) -- Line: 247, Name: applyBoost
            p63.currency("RuneBulk"):SetMul("UITree_RuneBulkMulRight2", p64 and p65 and p65 or 1);
        end,

        boost = function(p66) -- Line: 250, Name: boost
            return 1 + 0.25 * p66;
        end,

        formatBoost = mulFormat
    },
    OofMulti1 = {
        title = "Oof Multi",
        desc = "Gain more Oof.",
        gradientType = "Oof",
        maxLevel = 10,
        icon = Icons.Oof,
        unlocks = { "RebirthMul" },
        cost = {
            type = "Prism",
            cost = 2
        },

        getCost = function(p67) -- Line: 262, Name: getCost
            return math.floor(2 * 1.55 ^ p67);
        end,

        applyBoost = function(p68, p69, p70) -- Line: 263, Name: applyBoost
            p68.currency("Oof"):SetMul("UITree_OofMulti1", p69 and p70 and p70 or 1);
        end,

        boost = function(p71) -- Line: 266, Name: boost
            return 1 + 0.5 * p71;
        end,

        formatBoost = mulFormat
    },
    RebirthMul = {
        title = "Rebirth Mul",
        desc = "Gain more Rebirths.",
        gradientType = "Rebirth",
        maxLevel = 10,
        icon = Icons.Rebirth,
        unlocks = { "FireMul" },
        cost = {
            type = "Prism",
            cost = 25
        },

        getCost = function(p72) -- Line: 278, Name: getCost
            return math.floor(25 * 1.55 ^ p72);
        end,

        applyBoost = function(p73, p74, p75) -- Line: 279, Name: applyBoost
            p73.currency("Rebirth"):SetMul("UITree_RebirthMul", p74 and p75 and p75 or 1);
        end,

        boost = function(p76) -- Line: 282, Name: boost
            return 1 + 0.25 * p76;
        end,

        formatBoost = mulFormat
    },
    FireMul = {
        title = "Fire Mul",
        desc = "Gain more Fire.",
        gradientType = "Fire",
        maxLevel = 10,
        icon = Icons.Fire,
        unlocks = { "CashMul", "BlazeMul" },
        cost = {
            type = "Prism",
            cost = 100
        },

        getCost = function(p77) -- Line: 294, Name: getCost
            return math.floor(100 * 1.55 ^ p77);
        end,

        applyBoost = function(p78, p79, p80) -- Line: 295, Name: applyBoost
            p78.currency("Fire"):SetMul("UITree_FireMul", p79 and p80 and p80 or 1);
        end,

        boost = function(p81) -- Line: 298, Name: boost
            return 1.1 ^ p81;
        end,

        formatBoost = mulFormat
    },
    BlazeMul = {
        title = "Blaze Mul",
        desc = "Gain more Blaze.",
        gradientType = "Blaze",
        maxLevel = 10,
        icon = Icons.Blaze,
        unlocks = { "FireAndBlazeMul" },
        cost = {
            type = "Prism",
            cost = 350
        },

        getCost = function(p82) -- Line: 310, Name: getCost
            return math.floor(350 * 1.55 ^ p82);
        end,

        applyBoost = function(p83, p84, p85) -- Line: 311, Name: applyBoost
            p83.currency("Blaze"):SetMul("UITree_BlazeMul", p84 and p85 and p85 or 1);
        end,

        boost = function(p86) -- Line: 314, Name: boost
            return 1.08 ^ p86;
        end,

        formatBoost = mulFormat
    },
    FireAndBlazeMul = {
        title = "Fire and Blaze Mul",
        desc = "Gain more Fire and Blaze.",
        gradientType = "Fire",
        maxLevel = 8,
        icon = Icons.FireBlaze,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 1200
        },

        getCost = function(p87) -- Line: 326, Name: getCost
            return math.floor(1200 * 1.55 ^ p87);
        end,

        applyBoost = function(p88, p89, p90) -- Line: 327, Name: applyBoost
            p88.currency("Fire"):SetMul("UITree_FireAndBlazeMul", p89 and p90 and p90 or 1);
            p88.currency("Blaze"):SetMul("UITree_FireAndBlazeMul", p89 and p90 and p90 or 1);
        end,

        boost = function(p91) -- Line: 331, Name: boost
            return 1 + 0.25 * p91;
        end,

        formatBoost = mulFormat
    },
    CashMul = {
        title = "Cash Mul",
        desc = "Gain more Cash.",
        gradientType = "Cash",
        maxLevel = 10,
        icon = Icons.Cash,
        unlocks = { "TierBulkMul" },
        cost = {
            type = "Prism",
            cost = 250
        },

        getCost = function(p92) -- Line: 343, Name: getCost
            return math.floor(250 * 1.55 ^ p92);
        end,

        applyBoost = function(p93, p94, p95) -- Line: 344, Name: applyBoost
            p93.currency("Cash"):SetMul("UITree_CashMul", p94 and p95 and p95 or 1);
        end,

        boost = function(p96) -- Line: 347, Name: boost
            return 1.15 ^ p96;
        end,

        formatBoost = mulFormat
    },
    TierBulkMul = {
        title = "Tier Bulk Mul",
        desc = "Roll more Tiers.",
        gradientType = "Tiers",
        maxLevel = 8,
        icon = Icons.TierBulk,
        unlocks = { "MoreWalkspeed", "TierBulkMul1" },
        cost = {
            type = "Prism",
            cost = 600
        },

        getCost = function(p97) -- Line: 359, Name: getCost
            return math.floor(600 * 1.55 ^ p97);
        end,

        applyBoost = function(p98, p99, p100) -- Line: 360, Name: applyBoost
            p98.currency("TierBulk"):SetMul("UITree_TierBulkMul", p99 and p100 and p100 or 1);
        end,

        boost = function(p101) -- Line: 363, Name: boost
            return 1 + 0.125 * p101;
        end,

        formatBoost = mulFormat
    },
    TierBulkMul1 = {
        title = "Tier Bulk Mul",
        desc = "Roll more Tiers at once.",
        gradientType = "Tiers",
        maxLevel = 8,
        icon = Icons.TierBulk,
        unlocks = { "TierLuckMul1" },
        cost = {
            type = "Prism",
            cost = 1500
        },

        getCost = function(p102) -- Line: 375, Name: getCost
            return math.floor(1500 * 1.55 ^ p102);
        end,

        applyBoost = function(p103, p104, p105) -- Line: 376, Name: applyBoost
            p103.currency("TierBulk"):SetMul("UITree_TierBulkMul1", p104 and p105 and p105 or 1);
        end,

        boost = function(p106) -- Line: 379, Name: boost
            return 1 + 0.25 * p106;
        end,

        formatBoost = mulFormat
    },
    TierLuckMul1 = {
        title = "Tier Luck Mul",
        desc = "Better Tier luck.",
        gradientType = "Tiers",
        maxLevel = 8,
        icon = Icons.TierLuck,
        unlocks = { "NewFireUpgradeForTiers" },
        cost = {
            type = "Prism",
            cost = 3500
        },

        getCost = function(p107) -- Line: 391, Name: getCost
            return math.floor(3500 * 1.55 ^ p107);
        end,

        applyBoost = function(p108, p109, p110) -- Line: 392, Name: applyBoost
            p108.currency("TierLuck"):SetMul("UITree_TierLuckMul1", p109 and p110 and p110 or 1);
        end,

        boost = function(p111) -- Line: 395, Name: boost
            return 1 + 0.33 * p111;
        end,

        formatBoost = mulFormat
    },
    NewFireUpgradeForTiers = {
        title = "New Fire Upgrade for Tiers",
        desc = "Unlocks a new tier luck upgrade in the Fire upgrades.",
        applyBoost = nil,
        maxLevel = 1,
        gradientType = "Tiers",
        icon = Icons.FireUpgrade,
        unlocks = { "TierBulkMul2" },
        cost = {
            type = "Prism",
            cost = 50000
        },

        getCost = function(p112) -- Line: 407, Name: getCost
            return 12000;
        end,

        boost = function(p113) -- Line: 409, Name: boost
            return p113;
        end,

        formatBoost = activeFormat
    },
    TierBulkMul2 = {
        title = "Tier Bulk",
        desc = "Roll more tiers.",
        gradientType = "Tiers",
        maxLevel = 8,
        icon = Icons.TierBulk,
        unlocks = { "TierLuckMul2" },
        cost = {
            type = "Prism",
            cost = 18000
        },

        getCost = function(p114) -- Line: 421, Name: getCost
            return math.floor(18000 * 1.55 ^ p114);
        end,

        applyBoost = function(p115, p116, p117) -- Line: 422, Name: applyBoost
            p115.currency("TierBulk"):SetMul("UITree_TierBulkMul2", p116 and p117 and p117 or 1);
        end,

        boost = function(p118) -- Line: 425, Name: boost
            return 1 + 0.2 * p118;
        end,

        formatBoost = mulFormat
    },
    TierLuckMul2 = {
        title = "Tier Luck Mul",
        desc = "Even better Tier luck.",
        gradientType = "Tiers",
        maxLevel = 10,
        icon = Icons.TierLuck,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 32000
        },

        getCost = function(p119) -- Line: 437, Name: getCost
            return math.floor(32000 * 1.55 ^ p119);
        end,

        applyBoost = function(p120, p121, p122) -- Line: 438, Name: applyBoost
            p120.currency("TierLuck"):SetMul("UITree_TierLuckMul2", p121 and p122 and p122 or 1);
        end,

        boost = function(p123) -- Line: 441, Name: boost
            return 1 + 0.5 * p123;
        end,

        formatBoost = mulFormat
    },
    MoreWalkspeed = {
        title = "More Walkspeed",
        desc = "Run faster.",
        gradientType = "Speed",
        maxLevel = 5,
        icon = Icons.WalkSpeed,
        unlocks = { "WheatConverterSpeedMul" },
        cost = {
            type = "Prism",
            cost = 1800
        },

        getCost = function(p124) -- Line: 453, Name: getCost
            return math.floor(1800 * 1.55 ^ p124);
        end,

        applyBoost = function(p125, p126, p127) -- Line: 454, Name: applyBoost
            p125.currency("WalkSpeed"):SetAdd("UITree_MoreWalkspeed", p126 and p127 and p127 or 0);
        end,

        boost = function(p128) -- Line: 457, Name: boost
            return p128 * 5;
        end,

        formatBoost = function(p129) -- Line: 458, Name: formatBoost
            local v130 = math.floor(p129);

            return "+" .. tostring(v130) .. " WS";
        end
    },
    WheatConverterSpeedMul = {
        title = "Wheat Converter Speed",
        desc = "Convert wheat faster.",
        gradientType = "Wheat",
        maxLevel = 5,
        icon = Icons.BreadSpeed,
        unlocks = { "WheatGenerationSpeedMul" },
        cost = {
            type = "Prism",
            cost = 4000
        },

        getCost = function(p131) -- Line: 469, Name: getCost
            return math.floor(4000 * 1.55 ^ p131);
        end,

        applyBoost = function(p132, p133, p134) -- Line: 470, Name: applyBoost
            p132.currency("BreadConverterSpeed"):SetAdd("UITree_WheatConverterSpeedMul", p133 and p134 and p134 or 0);
        end,

        boost = function(p135) -- Line: 473, Name: boost
            return p135 * 0.1;
        end,

        formatBoost = function(p136) -- Line: 474, Name: formatBoost
            return "-" .. string.format("%.1f", p136) .. "s";
        end
    },
    WheatGenerationSpeedMul = {
        title = "Wheat Generation Speed Mul",
        desc = "Generate wheat faster.",
        gradientType = "Wheat",
        maxLevel = 8,
        icon = Icons.WheatSpeed,
        unlocks = { "BreadMul", "CoinMul" },
        cost = {
            type = "Prism",
            cost = 8500
        },

        getCost = function(p137) -- Line: 485, Name: getCost
            return math.floor(8500 * 1.55 ^ p137);
        end,

        applyBoost = function(p138, p139, p140) -- Line: 486, Name: applyBoost
            p138.currency("Wheat"):SetMul("UITree_WheatGenerationSpeedMul", p139 and p140 and p140 or 1);
        end,

        boost = function(p141) -- Line: 489, Name: boost
            return 1 + 0.0125 * p141;
        end,

        formatBoost = mulFormat
    },
    BreadMul = {
        title = "Bread Mul",
        desc = "Gain more Bread.",
        gradientType = "Bread",
        maxLevel = 8,
        icon = Icons.Bread,
        unlocks = { "MinusOneWheatForBread" },
        cost = {
            type = "Prism",
            cost = 16000
        },

        getCost = function(p142) -- Line: 501, Name: getCost
            return math.floor(16000 * 1.55 ^ p142);
        end,

        applyBoost = function(p143, p144, p145) -- Line: 502, Name: applyBoost
            p143.currency("Bread"):SetMul("UITree_BreadMul", p144 and p145 and p145 or 1);
        end,

        boost = function(p146) -- Line: 505, Name: boost
            return 1.1 ^ p146;
        end,

        formatBoost = mulFormat
    },
    MinusOneWheatForBread = {
        title = "-1 Wheat for Bread",
        desc = "Bread now requires 2 wheat instead of 3.",
        applyBoost = nil,
        maxLevel = 1,
        gradientType = "Bread",
        icon = Icons.BreadWheat,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 60000
        },

        getCost = function(p147) -- Line: 517, Name: getCost
            return 60000;
        end,

        boost = function(p148) -- Line: 519, Name: boost
            return p148;
        end,

        formatBoost = activeFormat
    },
    CoinMul = {
        title = "Coin Mul",
        desc = "Gain more Coin.",
        gradientType = "Coin",
        maxLevel = 8,
        icon = Icons.Coin,
        unlocks = { "OofMulti2" },
        cost = {
            type = "Prism",
            cost = 20000
        },

        getCost = function(p149) -- Line: 531, Name: getCost
            return math.floor(20000 * 1.55 ^ p149);
        end,

        applyBoost = function(p150, p151, p152) -- Line: 532, Name: applyBoost
            p150.currency("Coin"):SetMul("UITree_CoinMul", p151 and p152 and p152 or 1);
        end,

        boost = function(p153) -- Line: 535, Name: boost
            return 1 + 0.5 * p153;
        end,

        formatBoost = mulFormat
    },
    OofMulti2 = {
        title = "Oof Multi",
        desc = "Gain even more Oof.",
        gradientType = "Oof",
        maxLevel = 12,
        icon = Icons.Oof,
        unlocks = { "BetterEnchantsPity", "MoreOfflineExpeditionTime", "PrismMultiCenter" },
        cost = {
            type = "Prism",
            cost = 61200
        },

        getCost = function(p154) -- Line: 547, Name: getCost
            return math.floor(61200 * 1.5 ^ p154);
        end,

        applyBoost = function(p155, p156, p157) -- Line: 548, Name: applyBoost
            p155.currency("Oof"):SetMul("UITree_OofMulti2", p156 and p157 and p157 or 1);
        end,

        boost = function(p158) -- Line: 551, Name: boost
            return 1 + 1 * p158;
        end,

        formatBoost = mulFormat
    },
    BetterEnchantsPity = {
        title = "Better Enchants Pity",
        desc = "Lower the pity counter for noobs.",
        applyBoost = nil,
        gradientType = "Enchant",
        maxLevel = 5,
        icon = Icons.EnchantPity,
        unlocks = { "RuneBulkMultiCenter" },
        cost = {
            type = "Prism",
            cost = 150000
        },

        getCost = function(p159) -- Line: 563, Name: getCost
            return math.floor(150000 * 1.52 ^ p159);
        end,

        boost = function(p160) -- Line: 565, Name: boost
            return p160 * 100;
        end,

        formatBoost = function(p161) -- Line: 566, Name: formatBoost
            return "-" .. tostring(p161) .. " rolls";
        end
    },
    MoreOfflineExpeditionTime = {
        title = "More Offline Expedition Time",
        desc = "Longer offline expeditions.",
        applyBoost = nil,
        gradientType = "Offline",
        maxLevel = 5,
        icon = Icons.ExpeditionTime,
        unlocks = { "BuffEquipmentsMul" },
        cost = {
            type = "Prism",
            cost = 150000
        },

        getCost = function(p162) -- Line: 577, Name: getCost
            return math.floor(150000 * 1.52 ^ p162);
        end,

        boost = function(p163) -- Line: 579, Name: boost
            return p163 * 20;
        end,

        formatBoost = function(p164) -- Line: 38, Name: minutesFormat
            local v165 = math.floor(p164);

            return "+" .. tostring(v165) .. " minutes";
        end
    },
    BuffEquipmentsMul = {
        title = "Buff Equipments Mul",
        desc = "Multiply all equipment boosts.",
        applyBoost = nil,
        gradientType = "Equipment",
        maxLevel = 8,
        icon = Icons.EquipmentMul,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 350000
        },

        getCost = function(p166) -- Line: 591, Name: getCost
            return math.floor(350000 * 1.52 ^ p166);
        end,

        boost = function(p167) -- Line: 593, Name: boost
            return 1 + 0.225 * p167;
        end,

        formatBoost = mulFormat
    },
    PrismMultiCenter = {
        title = "Prism Multi",
        desc = "Gain more Prism.",
        gradientType = "Prism",
        maxLevel = 8,
        icon = Icons.PrismMul,
        unlocks = { "FasterPrismCenter" },
        cost = {
            type = "Prism",
            cost = 350000
        },

        getCost = function(p168) -- Line: 605, Name: getCost
            return math.floor(350000 * 1.74 ^ p168);
        end,

        applyBoost = function(p169, p170, p171) -- Line: 606, Name: applyBoost
            p169.currency("Prism"):SetMul("UITree_PrismMultiCenter", p170 and p171 and p171 or 1);
        end,

        boost = function(p172) -- Line: 609, Name: boost
            return 1.35 ^ p172;
        end,

        formatBoost = mulFormat
    },
    FasterPrismCenter = {
        title = "Faster Prism",
        desc = "Speed up Prism generation.",
        gradientType = "Prism",
        maxLevel = 6,
        icon = Icons.PrismSpeed,
        unlocks = { "MorePrismCenter" },
        cost = {
            type = "Prism",
            cost = 700000
        },

        getCost = function(p173) -- Line: 621, Name: getCost
            return math.floor(700000 * 1.74 ^ p173);
        end,

        applyBoost = function(p174, p175, p176) -- Line: 622, Name: applyBoost
            p174.currency("PrismSpeed"):SetMul("UITree_FasterPrismCenter", p175 and 1 / p176 or 1);
        end,

        boost = function(p177) -- Line: 625, Name: boost
            return 1.09 ^ p177;
        end,

        formatBoost = percentFormat
    },
    MorePrismCenter = {
        title = "More Prism",
        desc = "Earn more Prism.",
        gradientType = "Prism",
        maxLevel = 15,
        icon = Icons.PrismPlus,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 1250000
        },

        getCost = function(p178) -- Line: 637, Name: getCost
            return math.floor(1250000 * 1.64 ^ p178);
        end,

        applyBoost = function(p179, p180, p181) -- Line: 638, Name: applyBoost
            p179.currency("Prism"):SetMul("UITree_MorePrismCenter", p180 and p181 and p181 or 1);
        end,

        boost = function(p182) -- Line: 641, Name: boost
            return 1.18 ^ p182;
        end,

        formatBoost = mulFormat
    },
    RuneBulkMultiCenter = {
        title = "Rune Bulk Multi",
        desc = "Roll more runes at once.",
        gradientType = "Rune",
        maxLevel = 10,
        icon = Icons.RuneBulk,
        unlocks = { "RuneSpeedMultiCenter" },
        cost = {
            type = "Prism",
            cost = 350000
        },

        getCost = function(p183) -- Line: 653, Name: getCost
            return math.floor(350000 * 1.75 ^ p183);
        end,

        applyBoost = function(p184, p185, p186) -- Line: 654, Name: applyBoost
            p184.currency("RuneBulk"):SetMul("UITree_RuneBulkMultiCenter", p185 and p186 and p186 or 1);
        end,

        boost = function(p187) -- Line: 657, Name: boost
            return 1 + 0.25 * p187;
        end,

        formatBoost = mulFormat
    },
    RuneSpeedMultiCenter = {
        title = "Rune Speed Multi",
        desc = "Roll runes faster.",
        gradientType = "Rune",
        maxLevel = 10,
        icon = Icons.RuneSpeed,
        unlocks = { "RuneLuckMultiCenter", "RuneCloneForNoobinial" },
        cost = {
            type = "Prism",
            cost = 600000
        },

        getCost = function(p188) -- Line: 669, Name: getCost
            return math.floor(600000 * 1.75 ^ p188);
        end,

        applyBoost = function(p189, p190, p191) -- Line: 670, Name: applyBoost
            p189.currency("RuneSpeed"):SetMul("UITree_RuneSpeedMultiCenter", p190 and 1 / p191 or 1);
        end,

        boost = function(p192) -- Line: 673, Name: boost
            return 1 + 0.02 * p192;
        end,

        formatBoost = mulFormat
    },
    RuneLuckMultiCenter = {
        title = "Rune Luck Multi",
        desc = "Better rune luck.",
        gradientType = "Rune",
        maxLevel = 10,
        icon = Icons.RuneLuck,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 900000
        },

        getCost = function(p193) -- Line: 685, Name: getCost
            return math.floor(900000 * 1.75 ^ p193);
        end,

        applyBoost = function(p194, p195, p196) -- Line: 686, Name: applyBoost
            p194.currency("RuneLuck"):SetMul("UITree_RuneLuckMultiCenter", p195 and p196 and p196 or 1);
        end,

        boost = function(p197) -- Line: 689, Name: boost
            return 1 + 0.325 * p197;
        end,

        formatBoost = mulFormat
    },
    RuneCloneForNoobinial = {
        title = "Rune Clone for Noobinial",
        desc = "Clone runes that are \'Noobinial\' tier (doesnt work for prism runes).",
        applyBoost = nil,
        maxLevel = 1,
        gradientType = "Rune",
        icon = Icons.RuneClone,
        unlocks = { "UnlockPrismUpgradeTree" },
        cost = {
            type = "Prism",
            cost = 600000
        },

        getCost = function(p198) -- Line: 701, Name: getCost
            return 600000;
        end,

        boost = function(p199) -- Line: 703, Name: boost
            return p199;
        end,

        formatBoost = activeFormat
    },
    UnlockPrismUpgradeTree = {
        title = "Unlock Prism Upgrade Tree",
        desc = "Unlock a new upgrade tree. The Prism Upgrade Tree.",
        icon = "rbxassetid://80336805058262",
        applyBoost = nil,
        maxLevel = 1,
        gradientType = "Rune",
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 1
        },

        getCost = function(p200) -- Line: 715, Name: getCost
            return 500000000;
        end,

        boost = function(p201) -- Line: 717, Name: boost
            return p201;
        end,

        formatBoost = activeFormat
    },
    PrismMulR3_1 = {
        title = "Prism Mul",
        desc = "Gain more Prism.",
        requiredPrestige = 13,
        gradientType = "Prism",
        maxLevel = 10,
        icon = Icons.PrismMul,
        unlocks = { "MeatMulR3_1" },
        cost = {
            type = "Prism",
            cost = 15000000000000
        },

        getCost = function(p202) -- Line: 730, Name: getCost
            return math.floor(15000000000000 * 1.42 ^ p202);
        end,

        applyBoost = function(p203, p204, p205) -- Line: 731, Name: applyBoost
            p203.currency("Prism"):SetMul("UITree_PrismMulR3_1", p204 and p205 and p205 or 1);
        end,

        boost = function(p206) -- Line: 734, Name: boost
            return 1 + 0.1 * p206;
        end,

        formatBoost = mulFormat
    },
    MeatMulR3_1 = {
        title = "Meat Mul",
        desc = "Gain more Meat.",
        gradientType = "Oof",
        maxLevel = 8,
        icon = Icons.Meat,
        unlocks = { "SwordDamageMulR3", "PrismMulR3_2" },
        cost = {
            type = "Prism",
            cost = 21000000000000
        },

        getCost = function(p207) -- Line: 745, Name: getCost
            return math.floor(21000000000000 * 1.5 ^ p207);
        end,

        applyBoost = function(p208, p209, p210) -- Line: 746, Name: applyBoost
            p208.currency("Meat"):SetMul("UITree_MeatMulR3_1", p209 and p210 and p210 or 1);
        end,

        boost = function(p211) -- Line: 749, Name: boost
            return 1 + 0.15 * p211;
        end,

        formatBoost = mulFormat
    },
    SwordDamageMulR3 = {
        title = "Sword Damage Mul",
        desc = "Deal more Sword damage.",
        gradientType = "Oof",
        maxLevel = 12,
        icon = Icons.SwordDamage,
        unlocks = { "SwordsLuckMulR3" },
        cost = {
            type = "Prism",
            cost = 47000000000000
        },

        getCost = function(p212) -- Line: 760, Name: getCost
            return math.floor(47000000000000 * 1.34 ^ p212);
        end,

        applyBoost = function(p213, p214, p215) -- Line: 761, Name: applyBoost
            p213.currency("SwordDamage"):SetMul("UITree_SwordDamageMulR3", p214 and p215 and p215 or 1);
        end,

        boost = function(p216) -- Line: 764, Name: boost
            return 1 + 0.05 * p216;
        end,

        formatBoost = mulFormat
    },
    SwordsLuckMulR3 = {
        title = "Swords Luck Mul",
        desc = "Better swords luck.",
        gradientType = "Oof",
        maxLevel = 8,
        icon = Icons.SwordLuck,
        unlocks = { "BonesMulR3" },
        cost = {
            type = "Prism",
            cost = 95000000000000
        },

        getCost = function(p217) -- Line: 775, Name: getCost
            return math.floor(95000000000000 * 1.55 ^ p217);
        end,

        applyBoost = function(p218, p219, p220) -- Line: 776, Name: applyBoost
            p218.currency("SwordsLuck"):SetMul("UITree_SwordsLuckMulR3", p219 and p220 and p220 or 1);
        end,

        boost = function(p221) -- Line: 779, Name: boost
            return 1 + 0.025 * p221;
        end,

        formatBoost = mulFormat
    },
    BonesMulR3 = {
        title = "Bones Mul",
        desc = "Gain more Bones.",
        gradientType = "Oof",
        maxLevel = 10,
        icon = Icons.Bones,
        unlocks = { "MeatMulR3_2", "SoulsMulR3" },
        cost = {
            type = "Prism",
            cost = 110000000000000
        },

        getCost = function(p222) -- Line: 790, Name: getCost
            return math.floor(110000000000000 * 1.42 ^ p222);
        end,

        applyBoost = function(p223, p224, p225) -- Line: 791, Name: applyBoost
            p223.currency("Bones"):SetMul("UITree_BonesMulR3", p224 and p225 and p225 or 1);
        end,

        boost = function(p226) -- Line: 794, Name: boost
            return 1 + 0.4 * p226;
        end,

        formatBoost = mulFormat
    },
    MeatMulR3_2 = {
        title = "Meat Mul",
        desc = "Gain even more Meat.",
        gradientType = "Oof",
        maxLevel = 9,
        icon = Icons.Meat,
        unlocks = { "FasterMeatConversion" },
        cost = {
            type = "Prism",
            cost = 130000000000000
        },

        getCost = function(p227) -- Line: 805, Name: getCost
            return math.floor(130000000000000 * 1.46 ^ p227);
        end,

        applyBoost = function(p228, p229, p230) -- Line: 806, Name: applyBoost
            p228.currency("Meat"):SetMul("UITree_MeatMulR3_2", p229 and p230 and p230 or 1);
        end,

        boost = function(p231) -- Line: 809, Name: boost
            return 1 + 0.125 * p231;
        end,

        formatBoost = mulFormat
    },
    FasterMeatConversion = {
        title = "Faster Meat Conversion",
        desc = "Convert Meat to Bones faster.",
        gradientType = "Oof",
        maxLevel = 5,
        icon = Icons.FasterBones,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 150000000000000
        },

        getCost = function(p232) -- Line: 820, Name: getCost
            return math.floor(150000000000000 * 1.6 ^ p232);
        end,

        applyBoost = function(p233, p234, p235) -- Line: 821, Name: applyBoost
            p233.currency("MeatConverterSpeed"):SetAdd("UITree_FasterMeatConversion", p234 and p235 and p235 or 0);
        end,

        boost = function(p236) -- Line: 824, Name: boost
            return p236 * 0.1;
        end,

        formatBoost = function(p237) -- Line: 825, Name: formatBoost
            return "-" .. string.format("%.1f", p237) .. "s";
        end
    },
    SoulsMulR3 = {
        title = "Souls Mul",
        desc = "Gain more Souls.",
        gradientType = "Oof",
        maxLevel = 11,
        icon = Icons.Souls,
        unlocks = { "SandMulR3" },
        cost = {
            type = "Prism",
            cost = 190000000000000
        },

        getCost = function(p238) -- Line: 835, Name: getCost
            return math.floor(190000000000000 * 1.38 ^ p238);
        end,

        applyBoost = function(p239, p240, p241) -- Line: 836, Name: applyBoost
            p239.currency("Souls"):SetMul("UITree_SoulsMulR3", p240 and p241 and p241 or 1);
        end,

        boost = function(p242) -- Line: 839, Name: boost
            return 1 + 0.215 * p242;
        end,

        formatBoost = mulFormat
    },
    SandMulR3 = {
        title = "Sand Mul",
        desc = "Gain more Sand.",
        gradientType = "Oof",
        maxLevel = 8,
        icon = Icons.Sand,
        unlocks = { "ShovelDamageMulR3" },
        cost = {
            type = "Prism",
            cost = 220000000000000
        },

        getCost = function(p243) -- Line: 850, Name: getCost
            return math.floor(220000000000000 * 1.48 ^ p243);
        end,

        applyBoost = function(p244, p245, p246) -- Line: 851, Name: applyBoost
            p244.currency("Sand"):SetMul("UITree_SandMulR3", p245 and p246 and p246 or 1);
        end,

        boost = function(p247) -- Line: 854, Name: boost
            return 1 + 0.145 * p247;
        end,

        formatBoost = mulFormat
    },
    ShovelDamageMulR3 = {
        title = "Shovel Damage Mul",
        desc = "Deal more Shovel damage.",
        gradientType = "Oof",
        maxLevel = 12,
        icon = Icons.ShovelDamage,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 270000000000000
        },

        getCost = function(p248) -- Line: 865, Name: getCost
            return math.floor(270000000000000 * 1.3 ^ p248);
        end,

        applyBoost = function(p249, p250, p251) -- Line: 866, Name: applyBoost
            p249.currency("ShovelDamage"):SetMul("UITree_ShovelDamageMulR3", p250 and p251 and p251 or 1);
        end,

        boost = function(p252) -- Line: 869, Name: boost
            return 1 + 0.1 * p252;
        end,

        formatBoost = mulFormat
    },
    PrismMulR3_2 = {
        title = "Prism Mul",
        desc = "Gain even more Prism.",
        gradientType = "Prism",
        maxLevel = 9,
        icon = Icons.PrismMul,
        unlocks = { "CoinMulR3", "FasterPrismR3" },
        cost = {
            type = "Prism",
            cost = 30000000000000
        },

        getCost = function(p253) -- Line: 880, Name: getCost
            return math.floor(30000000000000 * 1.45 ^ p253);
        end,

        applyBoost = function(p254, p255, p256) -- Line: 881, Name: applyBoost
            p254.currency("Prism"):SetMul("UITree_PrismMulR3_2", p255 and p256 and p256 or 1);
        end,

        boost = function(p257) -- Line: 884, Name: boost
            return 1 + 0.1 * p257;
        end,

        formatBoost = mulFormat
    },
    CoinMulR3 = {
        title = "Coin Mul",
        desc = "Gain more Coins.",
        gradientType = "Cash",
        maxLevel = 11,
        icon = Icons.Coin,
        unlocks = { "BreadMulR3", "RuneLuckMulR3" },
        cost = {
            type = "Prism",
            cost = 43000000000000
        },

        getCost = function(p258) -- Line: 895, Name: getCost
            return math.floor(43000000000000 * 1.38 ^ p258);
        end,

        applyBoost = function(p259, p260, p261) -- Line: 896, Name: applyBoost
            p259.currency("Coin"):SetMul("UITree_CoinMulR3", p260 and p261 and p261 or 1);
        end,

        boost = function(p262) -- Line: 899, Name: boost
            return 1 + 0.5 * p262;
        end,

        formatBoost = mulFormat
    },
    BreadMulR3 = {
        title = "Bread Mul",
        desc = "Gain more Bread.",
        gradientType = "Wheat",
        maxLevel = 7,
        icon = Icons.Bread,
        unlocks = { "WheatMulR3" },
        cost = {
            type = "Prism",
            cost = 95000000000000
        },

        getCost = function(p263) -- Line: 910, Name: getCost
            return math.floor(95000000000000 * 1.55 ^ p263);
        end,

        applyBoost = function(p264, p265, p266) -- Line: 911, Name: applyBoost
            p264.currency("Bread"):SetMul("UITree_BreadMulR3", p265 and p266 and p266 or 1);
        end,

        boost = function(p267) -- Line: 914, Name: boost
            return 1 + 0.75 * p267;
        end,

        formatBoost = mulFormat
    },
    WheatMulR3 = {
        title = "Wheat Mul",
        desc = "Gain more Wheat.",
        gradientType = "Wheat",
        maxLevel = 10,
        icon = Icons.Wheat,
        unlocks = { "OofMulR3" },
        cost = {
            type = "Prism",
            cost = 110000000000000
        },

        getCost = function(p268) -- Line: 925, Name: getCost
            return math.floor(110000000000000 * 1.42 ^ p268);
        end,

        applyBoost = function(p269, p270, p271) -- Line: 926, Name: applyBoost
            p269.currency("Wheat"):SetMul("UITree_WheatMulR3", p270 and p271 and p271 or 1);
        end,

        boost = function(p272) -- Line: 929, Name: boost
            return 1 + 0.65 * p272;
        end,

        formatBoost = mulFormat
    },
    OofMulR3 = {
        title = "Oof Mul",
        desc = "Gain more Oof.",
        gradientType = "Oof",
        maxLevel = 12,
        icon = Icons.Oof,
        unlocks = { "TierBulkMulR3" },
        cost = {
            type = "Prism",
            cost = 190000000000000
        },

        getCost = function(p273) -- Line: 940, Name: getCost
            return math.floor(190000000000000 * 1.31 ^ p273);
        end,

        applyBoost = function(p274, p275, p276) -- Line: 941, Name: applyBoost
            p274.currency("Oof"):SetMul("UITree_OofMulR3", p275 and p276 and p276 or 1);
        end,

        boost = function(p277) -- Line: 944, Name: boost
            return 1 + 2.1 * p277;
        end,

        formatBoost = mulFormat
    },
    TierBulkMulR3 = {
        title = "Tier Bulk Mul",
        desc = "Roll more Tiers.",
        gradientType = "Tiers",
        maxLevel = 8,
        icon = Icons.TierBulk,
        unlocks = { "TierLuckMulR3" },
        cost = {
            type = "Prism",
            cost = 390000000000000
        },

        getCost = function(p278) -- Line: 955, Name: getCost
            return math.floor(390000000000000 * 1.48 ^ p278);
        end,

        applyBoost = function(p279, p280, p281) -- Line: 956, Name: applyBoost
            p279.currency("TierBulk"):SetMul("UITree_TierBulkMulR3", p280 and p281 and p281 or 1);
        end,

        boost = function(p282) -- Line: 959, Name: boost
            return 1 + 0.87 * p282;
        end,

        formatBoost = mulFormat
    },
    TierLuckMulR3 = {
        title = "Tier Luck Mul",
        desc = "Better Tier luck.",
        gradientType = "Tiers",
        maxLevel = 11,
        icon = Icons.TierLuck,
        unlocks = { "TierBulkPlusR3" },
        cost = {
            type = "Prism",
            cost = 390000000000000
        },

        getCost = function(p283) -- Line: 970, Name: getCost
            return math.floor(390000000000000 * 1.33 ^ p283);
        end,

        applyBoost = function(p284, p285, p286) -- Line: 971, Name: applyBoost
            p284.currency("TierLuck"):SetMul("UITree_TierLuckMulR3", p285 and p286 and p286 or 1);
        end,

        boost = function(p287) -- Line: 974, Name: boost
            return 1 + 0.78 * p287;
        end,

        formatBoost = mulFormat
    },
    TierBulkPlusR3 = {
        title = "Tier Bulk Plus",
        desc = "Roll additional Tiers.",
        gradientType = "Tiers",
        maxLevel = 5,
        icon = Icons.TierBulk,
        unlocks = { "TierLuckMulR3_2" },
        cost = {
            type = "Prism",
            cost = 400000000000000
        },

        getCost = function(p288) -- Line: 985, Name: getCost
            return math.floor(400000000000000 * 1.62 ^ p288);
        end,

        applyBoost = function(p289, p290, p291) -- Line: 986, Name: applyBoost
            p289.currency("TierBulk"):SetAdd("UITree_TierBulkPlusR3", p290 and p291 and p291 or 0);
        end,

        boost = function(p292) -- Line: 989, Name: boost
            return p292 * 2;
        end,

        formatBoost = function(p293) -- Line: 990, Name: formatBoost
            local v294 = math.floor(p293);

            return "+" .. tostring(v294);
        end
    },
    TierLuckMulR3_2 = {
        title = "Tier Luck Mul",
        desc = "Even better Tier luck.",
        gradientType = "Tiers",
        maxLevel = 12,
        icon = Icons.TierLuck,
        unlocks = { "UnlockPrismRune2" },
        cost = {
            type = "Prism",
            cost = 451000000000000
        },

        getCost = function(p295) -- Line: 1000, Name: getCost
            return math.floor(451000000000000 * 1.29 ^ p295);
        end,

        applyBoost = function(p296, p297, p298) -- Line: 1001, Name: applyBoost
            p296.currency("TierLuck"):SetMul("UITree_TierLuckMulR3_2", p297 and p298 and p298 or 1);
        end,

        boost = function(p299) -- Line: 1004, Name: boost
            return 1 + 1.15 * p299;
        end,

        formatBoost = mulFormat
    },
    RuneLuckMulR3 = {
        title = "Rune Luck Mul",
        desc = "Better rune luck.",
        gradientType = "Rune",
        maxLevel = 9,
        icon = Icons.RuneLuck,
        unlocks = { "RuneSpeedMulR3" },
        cost = {
            type = "Prism",
            cost = 49000000000000
        },

        getCost = function(p300) -- Line: 1015, Name: getCost
            return math.floor(49000000000000 * 1.45 ^ p300);
        end,

        applyBoost = function(p301, p302, p303) -- Line: 1016, Name: applyBoost
            p301.currency("RuneLuck"):SetMul("UITree_RuneLuckMulR3", p302 and p303 and p303 or 1);
        end,

        boost = function(p304) -- Line: 1019, Name: boost
            return 1 + 0.1 * p304;
        end,

        formatBoost = mulFormat
    },
    RuneSpeedMulR3 = {
        title = "Rune Speed Mul",
        desc = "Roll runes faster.",
        gradientType = "Rune",
        maxLevel = 7,
        icon = Icons.RuneSpeed,
        unlocks = { "RuneBulkMulR3" },
        cost = {
            type = "Prism",
            cost = 140000000000000
        },

        getCost = function(p305) -- Line: 1030, Name: getCost
            return math.floor(140000000000000 * 1.55 ^ p305);
        end,

        applyBoost = function(p306, p307, p308) -- Line: 1031, Name: applyBoost
            p306.currency("RuneSpeed"):SetMul("UITree_RuneSpeedMulR3", p307 and 1 / p308 or 1);
        end,

        boost = function(p309) -- Line: 1034, Name: boost
            return 1 + 0.1 * p309;
        end,

        formatBoost = mulFormat
    },
    RuneBulkMulR3 = {
        title = "Rune Bulk Mul",
        desc = "Roll more runes at once.",
        gradientType = "Rune",
        maxLevel = 10,
        icon = Icons.RuneBulk,
        unlocks = { "RunePriceDecrease2" },
        cost = {
            type = "Prism",
            cost = 270000000000000
        },

        getCost = function(p310) -- Line: 1045, Name: getCost
            return math.floor(270000000000000 * 1.37 ^ p310);
        end,

        applyBoost = function(p311, p312, p313) -- Line: 1046, Name: applyBoost
            p311.currency("RuneBulk"):SetMul("UITree_RuneBulkMulR3", p312 and p313 and p313 or 1);
        end,

        boost = function(p314) -- Line: 1049, Name: boost
            return 1 + 0.1 * p314;
        end,

        formatBoost = mulFormat
    },
    RunePriceDecrease2 = {
        title = "Rune Price Decrease",
        desc = "Cheaper runes.",
        applyBoost = nil,
        gradientType = "Rune",
        maxLevel = 5,
        icon = Icons.RuneDiscount,
        unlocks = { "MinionLuckMulR3" },
        cost = {
            type = "Prism",
            cost = 310000000000000
        },

        getCost = function(p315) -- Line: 1060, Name: getCost
            return math.floor(310000000000000 * 1.68 ^ p315);
        end,

        boost = function(p316) -- Line: 1062, Name: boost
            return 1.019 ^ p316;
        end,

        formatBoost = mulFormat
    },
    MinionLuckMulR3 = {
        title = "Minion Luck Mul",
        desc = "Better minion capsule luck.",
        gradientType = "Rune",
        maxLevel = 12,
        icon = Icons.CapsuleLuck,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 360000000000000
        },

        getCost = function(p317) -- Line: 1073, Name: getCost
            return math.floor(360000000000000 * 1.28 ^ p317);
        end,

        applyBoost = function(p318, p319, p320) -- Line: 1074, Name: applyBoost
            p318.currency("MinionCapsuleLuck"):SetMul("UITree_MinionLuckMulR3", p319 and p320 and p320 or 1);
        end,

        boost = function(p321) -- Line: 1077, Name: boost
            return 1 + 0.025 * p321;
        end,

        formatBoost = mulFormat
    },
    FasterPrismR3 = {
        title = "Faster Prism",
        desc = "Generate Prisms faster.",
        gradientType = "Prism",
        maxLevel = 8,
        icon = Icons.PrismSpeed,
        unlocks = { "LowerAlmightyPity" },
        cost = {
            type = "Prism",
            cost = 67000000000000
        },

        getCost = function(p322) -- Line: 1088, Name: getCost
            return math.floor(67000000000000 * 1.5 ^ p322);
        end,

        applyBoost = function(p323, p324, p325) -- Line: 1089, Name: applyBoost
            p323.currency("PrismSpeed"):SetMul("UITree_FasterPrismR3", p324 and 1 / p325 or 1);
        end,

        boost = function(p326) -- Line: 1092, Name: boost
            return 1 + 0.1 * p326;
        end,

        formatBoost = mulFormat
    },
    LowerAlmightyPity = {
        title = "Lower Almighty Pity",
        desc = "Lower the pity counter for noobs.",
        applyBoost = nil,
        gradientType = "Enchant",
        maxLevel = 5,
        icon = Icons.EnchantPity,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 130000000000000
        },

        getCost = function(p327) -- Line: 1103, Name: getCost
            return math.floor(130000000000000 * 1.62 ^ p327);
        end,

        boost = function(p328) -- Line: 1105, Name: boost
            return p328 * 100;
        end,

        formatBoost = function(p329) -- Line: 1106, Name: formatBoost
            return "-" .. tostring(p329) .. " rolls";
        end
    },
    UnlockPrismRune2 = {
        title = "Prism Rune Unlock",
        desc = "Unlock the 2nd Prism Rune !!",
        requiredPrestige = 14,
        applyBoost = nil,
        gradientType = "Prism",
        maxLevel = 1,
        icon = Icons.UnlockPrismRune,
        unlocks = { "UnlockExtremeExpedtion" },
        cost = {
            type = "Prism",
            cost = 3.5e16
        },

        getCost = function() -- Line: 1117, Name: getCost
            return 3.5e16;
        end,

        boost = function(p330) -- Line: 1119, Name: boost
            return p330;
        end,

        formatBoost = activeFormat
    },
    UnlockExtremeExpedtion = {
        title = "Extreme Expedition",
        desc = "Unlock Extreme Expedition !!",
        requiredPrestige = 14,
        applyBoost = nil,
        gradientType = "Prism",
        maxLevel = 1,
        icon = Icons.UnlockExtremeExpedition,
        unlocks = { "UnlockSunStromRuneNoobinial" },
        cost = {
            type = "Prism",
            cost = 5.5e16
        },

        getCost = function() -- Line: 1131, Name: getCost
            return 5.5e16;
        end,

        boost = function(p331) -- Line: 1133, Name: boost
            return p331;
        end,

        formatBoost = activeFormat
    },
    UnlockSunStromRuneNoobinial = {
        title = "Sunstorm Prism rune",
        desc = "Unlock Noobinials runes in the Sunstorm Prism rune !!",
        requiredPrestige = 14,
        applyBoost = nil,
        gradientType = "Prism",
        maxLevel = 1,
        icon = Icons.UnlockNoobinialRunes,
        unlocks = {},
        cost = {
            type = "Prism",
            cost = 3.5e17
        },

        getCost = function() -- Line: 1145, Name: getCost
            return 3.5e17;
        end,

        boost = function(p332) -- Line: 1147, Name: boost
            return p332;
        end,

        formatBoost = activeFormat
    }
};

function u1.GetRequirements(p333) -- Line: 1155
    -- upvalues: u1 (copy)
    local v334 = {};

    for i, v in u1.Nodes do
        if v.unlocks then
            for _, v2 in v.unlocks do
                if v2 == p333 then
                    table.insert(v334, i);
                end;
            end;
        end;
    end;

    return v334;
end;

function u1.IsNodeUnlocked(p335, p336) -- Line: 1169
    -- upvalues: u1 (copy)
    local v337 = u1.GetRequirements(p335);

    if #v337 == 0 then
        return true;
    end;

    for _, v in v337 do
        if p336(v) >= 1 then
            return true;
        end;
    end;

    return false;
end;

return u1;