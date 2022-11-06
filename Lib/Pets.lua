local addonName, WrathRandomMounter = ...

WrathRandomMounter.itemPets = {
    -- "PetName, Category"
    ["43697"] ={"Toothy", "Crocodile"},
    ["46425"] ={"Snarly", "Crocodile"},
    ["43698"] ={"Muckbreath", "Crocodile"},
    ["46426"] ={"Chuck", "Crocodile"},
    ["13548"] ={"Westfall Chicken", "Chicken"},
    ["12243"] ={"Mechanical Chicken", "Chicken"},
    ["39181"] ={"Miniwing", "Bird"},
    ["61773"] ={"Plump Turkey", "Turkey"},
    ["61472"] ={"Kirin Tor Familiar", "Elemental"},
    ["70613"] ={"Perky Pug", "Dog"},
    ["61991"] ={"Little Fawn", "Deer"},
    ["40990"] ={"Stinker", "Skunk"},
    ["59250"] ={"Giant Sewer Rat", "Rat"},
    ["19772"] ={"Lifelike Toad", "Frog"},
    ["15049"] ={"Lil' Smoky", "Mechanical"},
    ["15048"] ={"Pet Bombling", "Mechanical"},
    ["26010"] ={"Tranquil Mechanical Yeti", "Mechanical"},
    ["10682"] ={"Hyacinth Macaw", "Parrot"},
    ["97779"] ={"Lashtail Hatchling", "Raptor"},
    ["67415"] ={"Gundrak Hatchling", "Raptor"},
    ["67420"] ={"Razzashi Hatchling", "Raptor"},
    ["16450"] ={"Smolderweb Hatchling", "Spider"},
    ["25162"] ={"Disgusting Oozeling", "Ooz"},
    ["15999"] ={"Worg Pup", "Dog"},
    ["43918"] ={"Mojo", "Frog"},
    ["15067"] ={"Sprite Darter Hatchling", "Spirit"},
    ["10683"] ={"Green Wing Macaw", "Parrot"},
    ["67414"] ={"Deviate Hatchling", "Raptor"},
    ["10675"] ={"Black Tabby Cat", "Cat"},
    ["10698"] ={"Emerald Whelpling", "Whelpling"},
    ["10697"] ={"Crimson Whelpling", "Whelpling"},
    ["10695"] ={"Dark Whelpling", "Whelpling"},
    ["10696"] ={"Azure Whelpling", "Whelpling"},
    ["62561"] ={"Strand Crawler", "Crab"},
    ["46599"] ={"Phoenix Hatchling", "Phoenix"},
    ["61357"] ={"Pengu", "Penguin"},
    ["51716"] ={"Nether Ray Fry", "Nether Ray"},
    ["10711"] ={"Snowshoe Rabbit", "Rabbit"},
    ["10709"] ={"Brown Prairie Dog", "Prairie Dog"},
    ["10684"] ={"Senegal", "Parrot"},
    ["10680"] ={"Cockatiel", "Parrot"},
    ["10717"] ={"Crimson Snake", "Snake"},
    ["10688"] ={"Cockroach", "Cockroach"},
    ["10677"] ={"Siamese Cat", "Cat"},
    ["65358"] ={"Calico Cat", "Cat"},
    ["10673"] ={"Bombay Cat", "Cat"},
    ["10685"] ={"Ancona Chicken", "Chicken"},
    ["10713"] ={"Albino Snake", "Snake"},
    ["53316"] ={"Ghostly Skull", "Skull"},
    ["35909"] ={"Red Moth", "Moth"},
    ["35156"] ={"Mana Wyrmling", "Wyrmling"},
    ["35239"] ={"Brown Rabbit", "Rabbit"},
    ["36061"] ={"Blue Dragonhawk Hatchling", "Dragonhawk"},
    ["10678"] ={"Silver Tabby Cat", "Cat"},
    ["10676"] ={"Orange Tabby Cat", "Cat"},
    ["10674"] ={"Cornish Rex Cat", "Cat"},
    ["10703"] ={"Wood Frog", "Frog"},
    ["10704"] ={"Tree Frog", "Frog"},
    ["10679"] ={"White Kitten", "Cat"},
    ["10706"] ={"Hawk Owl", "Owl"},
    ["10707"] ={"Great Horned Owl", "Owl"},
    ["10716"] ={"Brown Snake", "Snack"},
    ["10714"] ={"Black Kingsnake", "Snake"},
    ["17709"] ={"Zergling", "Demon"},
    ["53082"] ={"Mini Tyrael", "Human"},
    ["27241"] ={"Gurky", "Murlock"},
    ["17707"] ={"Panda Cub", "Panda"},
    ["32298"] ={"Netherwhelp", "Whelpling"},
    ["101606"] ={"Murkablo", "Murlock"},
    ["78381"] ={"Mini Thor", "Mechanical"},
    ["24988"] ={"Lurky", "Murlock"},
    ["87344"] ={"Lil' Deathwing", "Whelpling"},
    ["66030"] ={"Grunty", "Murlock"},
    ["52615"] ={"Frosty", "Whelpling"},
    ["40405"] ={"Lucky", "Pig"},
    ["177048"] ={"Mini Diablo", "demon"},
    ["24696"] ={"Murky", "Murlock"},
    ["27570"] ={"Peddlefeet", "Goblin"},
    ["74932"] ={"Frigid Frostling", "Elemental"},
    ["54187"] ={"Clockwork Rocket Bot", "Mechanical"},
    ["39709"] ={"Wolpertinger", "Rabbit"},
    ["40613"] ={"Willy", "demon"},
    ["40634"] ={"Peanut", "Elekk"},
    ["40614"] ={"Egbert", "egg"},
    ["44369"] ={"Pint-Sized Pink Pachyderm", "Elekk"},
    ["28871"] ={"Spirit of Summer", "Elemental"},
    ["61725"] ={"Spring Rabbit", "Rabbit"},
    ["71840"] ={"Toxic Wasteling", "Ooz"},
    ["45890"] ={"Searing Scorchling", "Elemental"},
    ["26529"] ={"Winter Reindeer", "Deer"},
    ["26541"] ={"Winter's Little Helper", "Gnome"},
    ["26533"] ={"Father Winter's Helper", "Gnome"},
    ["42609"] ={"Sinister Squashling", "Punkin"},
    ["62510"] ={"Tirisfal Batling", "Bat"},
    ["62491"] ={"Teldrassil Sproutling", "Trent"},
    ["63712"] ={"Sen'jin Fetish", "Mask"},
    ["62542"] ={"Mulgore Hatchling", "Strider"},
    ["62674"] ={"Mechanopeep", "Mechanical"},
    ["62564"] ={"Enchanted Broom", "Broom"},
    ["62516"] ={"Elwynn Lamb", "Sheep"},
    ["62513"] ={"Durotar Scorpion", "Scorpion"},
    ["62508"] ={"Dun Morogh Cub", "Bear"},
    ["62562"] ={"Ammen Vale Lashling", "Plant"},
    ["69535"] ={"Gryphon Hatchling", "Gryphon"},
    ["69541"] ={"Pandaren Monk", "Human"},
    ["69536"] ={"Wind Rider Cub", "Wind Rider"},
    ["75906"] ={"Lil' XT", "Mechanical"},
    ["69677"] ={"Lil' K.T.", "Mechanical"},
    ["68810"] ={"Spectral Tiger Cub", "Saber"},
    ["49964"] ={"Ethereal Soul-Trader", "Human"},
    ["45125"] ={"Rocket Chicken", "Chicken"},
    ["40549"] ={"Bananas", "Monkey"},
    ["68767"] ={"Tuskarr Kite", "Kite"},
    ["30156"] ={"Hippogryph Hatchling", "Hippogryph"},
    ["45127"] ={"Dragon Kite", "Kite"},
    
}
