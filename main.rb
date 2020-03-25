require_relative "lib/omega"
Dir["./*.rb"].each {|file| require_relative(file) if not file.include?("main.rb") }

# Import everything
Gosu::enable_undocumented_retrofication

class Array
    def sum
        inject(0) { |sum, x| sum + x }
    end
end

class Game < Omega::RenderWindow
    $width = 320
    $height = 240
    $font = Gosu::Font.new(10, {:name => "assets/SuperLegendBoy.ttf"})
    $hero = Hero.new
    $maps = {}

    $last_map = "farwood"
    $current_map = "farwood"

    $last_village = "farwood"

    $screenshot = nil
    $take_screenshot = false
    $boss = false

    $current_event = 0

    $dialogs = [
        # Event 0
        {
            "santa_fill":{
                "dialogs": [["Larry : Hi Konnor ! I suppose you are here for asking me some informations right ?",
                            "Konnor : Yeah... I heard the Melton brothers rob again a bank. I am heading for them.",
                            "Larry : Ah yeah I heard that too.. The town is called as I remember Narrow Roost...",
                            "Konnor : Where it is ?",
                            "Larry : Well I don't know at all for being honest...",
                            "Larry : But the woman next to me might help you, she came from Narrow Roost.",
                            "Konnor : Alright, thanks for the informations."],
                            ["Konnor : Hi miss, might I ask you some help ?",
                            "Jenna : How can a \"miss\" like me could help you sherif ?",
                            "Konnor : Well, I'm searching the Melton brothers...",
                            "Jenna : Oh... They are in Narrow Roost in the south...",
                            "Jenna : That's why I'm here today, I fled the town with my money before they could take it."],
                            ["John : Puh... Don't dare stare at me stranger."]],
                "commands": [[], ["next_event"], []]
            },
            "farwood":{
                "dialogs": [["Mc. Williams : Make the Melton learn a good lesson this time ! JUSTICE must be done !",
                             "Konnor : Sure. Don't worry.",
                             "Mc. Williams : I know there is someone in a town at the north east of here where there is someone",
                             "Mc. Williams : that might be able to help you if you need some informations about the Meltons."],
                            ["Murphy : Good luck cowboy.", "Konnor : Thanks."],
                            ["Antonio : Mphh? What have youuuu ?", "Konnor : Don't talk to me when you're drunk Antonio."],
                            ["Gabriella : C'mon Konnor, kick their ass once for all !", "Konnor : Don't worry señorita."],
                           ],
                "commands": [[]]
            }
        },
        # Event 1
        {
            "santa_fill":{
                "dialogs": [["Larry : Good luck on your journey, Sherif."],
                            ["Jenna : Have a nice travel cowboy !"],
                            ["John : Puh... Don't dare stare at me stranger."]],
                "commands": [[], [], []]
            },
            "narrow_roost":{
                "dialogs": [["George : The Meltons stole us again our money ! They will pay it !"],
                            ["Lucy : These brothers will never stop !"],
                            ["Leon : Well huh.. Forget about the Meltons, just take a tour in our hotel !", "Leon : It's cozy over here."],
                            ["Douglas : I was closing the chest and then... THEY APPEARED ! AND THEY SHOT EVERYWHERE",
                             "Konnor : Do you know where they are gone ?",
                             "Douglas : Well... When they fled with the money, I heard them saying they were going to Farwood...",
                             "Douglas : Isn't that a town situated inside of a valley ?",
                             "Konnor : FAR WOOD !? This is my home town.",
                             "Konnor : I need to stop them right now.",
                             "Douglas : Good luck sherif."],
                            ["Victor : Meh... I am the bodyguard of this bank. At least, for what is still inside of it...", "Victor : I lost all my money, and now I might lose my job because of these idiots..."]],
                "commands": [[], [], [], ["next_event"]]
            },
            "farwood":{
                "dialogs": [["Mc. Williams : Make the Melton learn a good lesson this time ! JUSTICE must be done !",
                            "Konnor : Sure. Don't worry."],
                            ["Murphy : Good luck cowboy.", "Konnor : Thanks."],
                            ["Antonio : Mphh? What have youuuu ?", "Konnor : Don't talk to me when you're drunk Antonio."],
                            ["Gabriella : C'mon Konnor, kick their ass once for all !", "Konnor : Don't worry señorita."],
                           ],
                "commands": [[]]
            }
        },
        # Event 2
        {
            "santa_fill":{
                "dialogs": [["Larry : Good luck on your journey, Sherif."],
                            ["Jenna : Have a nice travel cowboy !"],
                            ["John : Puh... Don't dare stare at me stranger."]],
                "commands": [[], [], []]
            },
            "narrow_roost":{
                "dialogs": [["George : The Meltons stole us again our money ! They will pay it !"],
                            ["Lucy : These brothers will never stop !"],
                            ["Leon : Well huh.. Forget about the Meltons, just take a tour in our hotel !", "Leon : It's cozy over here."],
                            ["Douglas : Good luck sherif.",
                             "Douglas : They are waiting you at Farwood..."],
                            ["Victor : Meh... I am the bodyguard of this bank. At least, for what is still inside of it...", "Victor : I lost all my money, and now I might lose my job because of these idiots..."]],
                "commands": [[], [], [], []]
            },
            "farwood":{
                "dialogs": [["Mc. Williams : KONNOR ! They took everything !",
                            "Konnor : Damn it !"],
                            ["Murphy : They'll never stop... Kick their ass quickly cow boy."],
                            ["Antonio : HEY ! GUESS WHAT ! The.. (hiccups) The Meltons brothers...", "Antonio : THEY TOOK A LOT OF MONEY ! Even mine (hiccups)...", "Antonio : How will a I live without (hiccups) a glass of whisky..."],
                            ["Gabriella : Konnor ! They attacked us again... This time the bank have no money anymore...",
                             "Konnor : (sigh) Don't worry, JUSTICE will be done against those thugs. But I need to know where they are...",
                             "Gabriella : They were talking about their secret hideout when leaving the bank...",
                             "Gabriella : I heard it's somewhere in the north of Narrow Roost. I think it's a cave...",
                             "Konnor : Well I should be able to find them with these informations. Thank you for your help señorita.",
                             "Gabriella : Also, take this with you.",
                             "Konnor received 12 dynamites",
                             "Gabriella : With this you should be able to pass through the desert without problems.",
                             "Gabriella : But don't use all of them yet, you should keep them for the Meltons brothers.",
                             "Konnor : Thank you my lady.",
                             "Gabriella : No hay problema, cowboy. JUSTICE shall be done."],
                           ],
                "commands": [[], [], [], ["next_event", "add_dyn 12"]]
            },
        },
        # Event 3
        {
            "santa_fill":{
                "dialogs": [["Larry : Good luck on your journey, Sherif."],
                            ["Jenna : Have a nice travel cowboy !"],
                            ["John : Puh... Don't dare stare at me stranger."]],
                "commands": [[], [], []]
            },
            "narrow_roost":{
                "dialogs": [["George : The Meltons stole us again our money ! They will pay it !"],
                            ["Lucy : These brothers will never stop !"],
                            ["Leon : Well huh.. Forget about the Meltons, just take a tour in our hotel !", "Leon : It's cozy over here."],
                            ["Douglas : Good luck sherif.",
                                "Douglas : They are waiting you at Farwood..."],
                            ["Victor : Meh... I am the bodyguard of this bank. At least, for what is still inside of it...", "Victor : I lost all my money, and now I might lose my job because of these idiots..."]],
                "commands": [[], [], [], []]
            },
            "farwood":{
                "dialogs": [["Mc. Williams : Let make them pay for it !"],
                            ["Murphy : They'll never stop... Kick their ass quickly cow boy."],
                            ["Antonio : Save our money ! Please make JUSTICE ! (hiccups)"],
                            ["Gabriella : I'm waiting for you here cowboy."]],
                "commands": [[], [], [], []]
            },
            "meltons_cave":{
                "dialogs": [["Konnor : Ah finally that's where they were hiding them !",
                             "??? : Who's there ?",
                             "??? : AY CARAMBA ! This is... Sherif Konnor !",
                             "Konnor : Yes, misters ! I am here for JUSTICE TO BE DONE !",
                             "Konnor : Surrender now or get killed !",
                             "Meltons brothers : NEVER ! Let's flee until we lost him !",
                             "Konnor : Don't even think about it ! JUSTICE SHALL BE DONE !"]],
                "commands": [["boss"]]
            }
        }
    ]

    $locked_places = [
        # Event 0
        {
            "21,21" => ["Two big guys prevents you from passing."],
            "21,14" => ["The cave is locked by a rock."]
        },
        # Event 1
        {
            "21,14" => ["The cave is locked by a rock."]
        },
        # Event 2
        {
            "21,14" => ["The cave is locked by a rock."]
        },
        # Event 3
        {
            
        },
    ]

    $sounds = {
        "gun" => Gosu::Sample.new("assets/gun.wav"),
        "galloping" => Gosu::Sample.new("assets/galloping.wav"),
        "talk" => Gosu::Sample.new("assets/talk.wav"),
        "explosion" => Gosu::Sample.new("assets/explosion.wav")
    }

    $songs = {
        "map_theme" => Gosu::Song.new("assets/musics/Far_West_-_Map_Theme.ogg"),
        "village_theme_2" => Gosu::Song.new("assets/musics/Far_West_-Town_Theme.ogg"),
        "cave" => Gosu::Song.new("assets/musics/Far_West_-_Cave_Theme.ogg")
    }

    $songs_to_use = {
        "world_map" => "map_theme",
        "santa_fill" => "village_theme_2",
        "narrow_roost" => "village_theme_2",
        "farwood" => "village_theme_2",
        "meltons_cave" => "cave"
    }

    $towns = {
        "18,4" => "santa_fill",
        "21,21" => "narrow_roost",
        "4,13" => "farwood",
        "21,14" => "meltons_cave"
    }

    $towns_enter_positions = {
        "santa_fill" => [1, 9],
        "narrow_roost" => [1, 6],
        "farwood" => [1, 9],
        "meltons_cave" => [10, 33]
    }

    $towns_exit_positions = {
        "santa_fill" => [17, 3.9],
        "narrow_roost" => [20, 20.9],
        "farwood" => [2.9, 13],
        "meltons_cave" => [21, 15.1]
    }

    $maps_type = {
        "world_map" => "dangerous",
        "santa_fill" => "village",
        "narrow_roost" => "village",
        "farwood" => "village",
        "meltons_cave" => "village"
    }

    $maps_name = {
        "world_map" => "World Map",
        "santa_fill" => "Santa Fill",
        "narrow_roost" => "Narrow Roost",
        "farwood" => "Farwood",
        "meltons_cave" => "Meltons Cave"
    }

    def load
        # Static stuff
        MenuState.load_assets
        PlayState.load_assets
        BattleState.load_assets
        # Set state
        Omega.set_state(MenuState.new)
    end

end

Omega.run(Game, "config.json")
