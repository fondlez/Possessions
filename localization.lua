PossessionsLocale = {}

--deDE localization courtesy of Farook
local locale = GetLocale()
if (locale == "deDE") then
	PossessionsLocale.INV_TITLE_TEXT = "Possessions"
	PossessionsLocale.INV_HELP = "Hilfe1"
	PossessionsLocale.INV_HELP2 = "Hilfe2"
	PossessionsLocale.INV_HELP3 = "Name"
	PossessionsLocale.INV_HELP4 = "Seltenheit"

	PossessionsLocale.TEXT_SEARCH = "Textsuche:"
	PossessionsLocale.TEXT_ALLCHARS = "Alle Charaktere"
	PossessionsLocale.TEXT_ALLLOCS = "Alle Locs"
	PossessionsLocale.TEXT_ALLSLOTS = "Alle Slots"
	PossessionsLocale.TEXT_ALLTYPES = "Alle Typen und Sub-Typen"

	PossessionsLocale.TEXT_PLAYER = "Tragend"
	PossessionsLocale.TEXT_BANK = "Bank"
	PossessionsLocale.TEXT_INVENTORY = "Inventar"
	PossessionsLocale.TEXT_INBOX = "Postfach"
	PossessionsLocale.TEXT_KEYRING = "Schl\195\188sselbund"
	PossessionsLocale.TEXT_PLAYERBAGS = "Inventar Beh\195\164lter" --LOCALIZE ME?
	PossessionsLocale.TEXT_BANKBAGS = "Bank Beh\195\164lter"       --LOCALIZE ME?
	PossessionsLocale.TEXT_GUILDBANK = GUILD.." Bank"

	PossessionsLocale.CFG_LITEMODE = "Lite-MOdus?"
	PossessionsLocale.CFG_FULLTEXT = "Gesamter Text?"
	PossessionsLocale.CFG_GUILDBANK = "Suche "..GUILD.." Bank?"

	PossessionsLocale.ERRORTOOLTIP_L1 = "Unsicheres Item"
	PossessionsLocale.ERRORTOOLTIP_L2 = "itemString:"
	PossessionsLocale.ERRORTOOLTIP_L3 = "Dieses Item ist unsicher.  Um sie ohne das Risiko eines Disconnects betrachten zu k\195\182nnen, musst du es zuerst in der Spielwelt gesehen haben. Dies wurde von Blizzard mit Patch 1.10 eingef\195\188hrt."
	PossessionsLocale.ERRORTOOLTIP_L4 = "Logge mit dem Charakter dieses Gegenstands ein oder du kannst mittels Rechtsklick versuchen, den Server dannach abzufragen.  Es k\195\182nnte sein, dass die Verbindung zum Server unterbrochen wird."
	PossessionsLocale.SAFE_MESSAGE = " ist sicher."
	PossessionsLocale.QUERY_MESSAGE = "Serverabfrage f\195\188r "
	PossessionsLocale.TYPE_TABLE = {
		["Edelsteine"] = {
			"Blau",
			"Rot",
			"Gelb",
			"Violett",
			"Orange",
			"Gr\195\188n",
			"Meta",
			"Einfach",
			"Prismatisch"
		},
		[ARMOR] = {"Stoff","G\195\182tzen","Leder","Buchband","Schwere R\195\188stung","Verschiedenes","Platte","Schild","Buchb\195\164nde"},
		["Verbrauchbar"] = {"Sonstige","Verb\195\164nde","Rolle","Fl\195\164schchen","Elixier","Trank","Verbrauchbar","Essen & Trinken","Gegenstandsverbesserung"},
		["Beh\195\164lter"] = {"Beh\195\164lter", "Verzauberertasche", "Ingenieurstasche", "Edelsteintasche", "Kr\195\164utertasche", "Bergbautasche", "Seelentasche", "Lederertasche"},
		["Schl\195\188ssel"] = {"Schl\195\188ssel"},
		["Verschiedenes"] = {"Festtag","Reagenz","Plunder","Begleiter","Sonstige"} ,
		["Projektil"] = {"Pfeil", "Kugel"},
		["Quest"] = {"Quest"},
		["K\195\182cher"] = {"Munitionsbeutel", "K\195\182cher"},
		["Reagenz"] = {"Reagenz"},
		["Rezept"] = {"Alchimie","Schmiedekunst","Buch","Kochkunst","Verzauberkunst","Ingenieurskunst","Erste Hilfe","Angeln","Juwelenschleifen","Lederverarbeitung","Schneiderei"},
		["Handwerkswaren"] = {"Sonstige","Elementar","Juwelenschleifen","Handwerkswaren","Ger\195\164te","Leder","Verzauberkunst","Sprengstoff","Metall & Stein","Stoffe","Teile","Fleisch","Kr\195\164uter"},
		["Waffe"] = {"Bogen","Armbr\195\188ste","Dolche","Angeln","Faustwaffen","Schusswaffen","Einhand\195\164xte","Einhandstreitkolben","Einhandschwerter","Verschiedenes","Stangenwaffen","St\195\164be","Wurfwaffen","Zweihand\195\164xte","Zweihandstreitkolben","Zweihandschwerter","Zauberst\195\164be"}
	}

else
	PossessionsLocale.INV_TITLE_TEXT = "Possessions"
	PossessionsLocale.INV_HELP = "Help1"
	PossessionsLocale.INV_HELP2 = "Help2"
	PossessionsLocale.INV_HELP3 = "Name"
	PossessionsLocale.INV_HELP4 = "Rarity"

	PossessionsLocale.TEXT_SEARCH = "Search Text:"
	PossessionsLocale.TEXT_ALLCHARS = "All chars"
	PossessionsLocale.TEXT_ALLLOCS = "All locs"
	PossessionsLocale.TEXT_ALLSLOTS = "All slots"
	PossessionsLocale.TEXT_ALLTYPES = "All types and subtypes"

	PossessionsLocale.TEXT_PLAYER = "Wearing"
	PossessionsLocale.TEXT_BANK = "Bank"
	PossessionsLocale.TEXT_INVENTORY = "Inventory"
	PossessionsLocale.TEXT_INBOX = "Inbox"
	PossessionsLocale.TEXT_KEYRING = "Keyring"
	PossessionsLocale.TEXT_PLAYERBAGS = "Inventory Bags"
	PossessionsLocale.TEXT_BANKBAGS = "Bank Bags"
	PossessionsLocale.TEXT_GUILDBANK = "Guild Bank"

	PossessionsLocale.CFG_LITEMODE = "Lite Mode?"
	PossessionsLocale.CFG_FULLTEXT = "Search All Text?"
	PossessionsLocale.CFG_GUILDBANK = "Include Guild Bank?"

	--Thanks AtlasLoot!
	PossessionsLocale.ERRORTOOLTIP_L1 = "Unsafe Item"
	PossessionsLocale.ERRORTOOLTIP_L2 = "itemString:"
	PossessionsLocale.ERRORTOOLTIP_L3 = "This item is unsafe.  To view this item without the risk of disconnection, you need to have first seen it in the game world. This is a restriction enforced by Blizzard since Patch 1.10."
	PossessionsLocale.ERRORTOOLTIP_L4 = "Log into the character with the item or you can right-click to attempt to query the server.  You may be disconnected."
	PossessionsLocale.SAFE_MESSAGE = " is safe."
	PossessionsLocale.QUERY_MESSAGE = "Server queried for "
	PossessionsLocale.TYPE_TABLE = {
		["Gem"] = {
			"Blue",
			"Red",
			"Yellow",
			"Purple",
			"Orange",
			"Green",
			"Meta",
			"Simple",
			"Prismatic"
		},
		["Armor"] = {"Cloth","Idols","Leather","Librams","Mail","Miscellaneous","Plate","Shields","Totems"},
		["Consumable"] = {"Other","Bandage","Scroll","Flask","Elixir","Potion","Consumable","Food & Drink","Item Enhancement"},
		["Container"] = {"Bag", "Enchanting Bag", "Engineering Bag", "Gem Bag", "Herb Bag", "Mining Bag", "Soul Bag", "Leatherworking Bag"},
		["Key"] = {"Key"},
		["Miscellaneous"] = {"Holiday","Reagent","Junk","Pet","Other"} ,
		["Projectile"] = {"Arrow", "Bullet"},
		["Quest"] = {"Quest"},
		["Quiver"] = {"Ammo Pouch", "Quiver"},
		["Reagent"] = {"Reagent"},
		["Recipe"] = {"Alchemy","Blacksmithing","Book","Cooking","Enchanting","Engineering","First Aid","Fishing","Jewelcrafting","Leatherworking","Tailoring"},
		["Trade Goods"] = {"Other","Elemental","Jewelcrafting","Trade Goods","Devices","Leather","Enchanting","Explosives","Metal & Stone","Cloth","Parts","Meat","Herb"},
		["Weapon"] = {"Bows","Crossbows","Daggers","Fishing Poles","Fist Weapons","Guns","One-Handed Axes","One-Handed Maces","One-Handed Swords","Miscellaneous","Polearms","Staves","Thrown","Two-Handed Axes","Two-Handed Maces","Two-Handed Swords","Wands"}
	}
end
