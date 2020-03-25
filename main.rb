require_relative "lib/omega"

# Import everything

####
class MenuState < Omega::State

    def load
        @title = "Wild West Justicier"
        @time = 0

        @@song.play(true)
    end

    def update
        @@battleground.pz -= 3
        @@parallax.position.x += 0.5

        @time += 0.05

        if @time > 3 and (Omega::just_pressed(Gosu::KB_ENTER) or Omega::just_pressed(Gosu::KB_X) or Omega::just_pressed(Gosu::GP_0_BUTTON_0))
            $last_map = "farwood"
            $current_map = "farwood"
        
            $last_village = "farwood"
        
            $screenshot = nil
            $take_screenshot = false
            $boss = false
        
            $current_event = 0

            $hero.map = $maps[$current_map]
        
            Omega.set_state(PlayState.new)
        end
    end

    def draw
        Gosu.scale(2.0, 2.0) do

            Gosu.draw_rect(0, 0, $width, $height, Gosu::Color.new(255, 255, 97, 0), 0)

            @@battleground.draw

            @@parallax.draw
        end

        width = $font.text_width(@title) * 3.5
        $font.draw_text("Press X or (A) to play", (Omega.width-width) / 2, 250, 10_000, 3.5, 3.5, Gosu::Color::BLACK) if (@time * 10) % 50 > 25

        twidth = $font.text_width(@title) * 4.5
        $font.draw_text("Wild West Justicier", (Omega.width-twidth) / 2 - 5, 20 + Math.sin(@time + 0.1) * 15 - 5, 10_000, 4.5, 4.5, Gosu::Color.new(255, 178, 68, 0))
        $font.draw_text("Wild West Justicier", (Omega.width-twidth) / 2, 20 + Math.sin(@time) * 15, 10_000, 4.5, 4.5, Gosu::Color::BLACK)
    end

    def self.load_assets
        @@song = Gosu::Song.new("assets/musics/Far_West_-_Main_Menu_Theme.ogg")

        @@battleground ||= PerspectiveTexture.new("assets/ground.png", $width, $height)
        @@battleground.perspective_modifier = 50
        @@battleground.base_perspective = 1.0
        @@battleground.base_scale_x = 1
        @@battleground.repeat = 1
        @@battleground.y = 220
        @@battleground.py = -40

        @@parallax = Omega::Parallax.new([Omega::Sprite.new("assets/background_0.png"), Omega::Sprite.new("assets/background_1.png")])
        @@parallax.per_pixel = true
        @@parallax.position.y = 80
    end

end
####

####
class BattleState < Omega::State

    def load
        # Add a pannel
        @@pannel = Pannel.new(2, $height - 72, 80, 60, 3)
        @@pannel.front_color = Gosu::Color.new(255, 178, 68, 0)
        @@pannel.text_color = Gosu::Color::BLACK
        @@pannel.selector_color = Gosu::Color.new(255, 255, 97, 0)
        @@pannel.position.z = 10_000

        @@pannel.add_choices("attack", "Attack")
        @@pannel.add_choices("defense", "Defense")
        @@pannel.add_choices("dynamite", "Dynam.")
        @@pannel.selector_style = "text_color"

        # Add a bar
        @atb_bar = Omega::Rectangle.new($width - 105, @@pannel.position.y + @@pannel.height - 10, 100, 10)
        @atb_bar.color = Gosu::Color.new(255, 255, 97, 0)
        @atb_bar.position.z = 10_000

        @atb_level = 0

        speed = rand(1.5..4)/10.0
        @enemies_atb_speeds = [speed, speed / 2].shuffle
        @enemies_atb_levels = [0, 0]
        @enemies_hp = [25, 25]

        @event = nil

        @time = 0

        @camera = Omega::Camera.new
        @camera.scale = Omega::Vector2.new(2, 2)

        @selector_mask = Omega::Sprite.new("assets/selector.png")

        @galloping_sound_instance = nil

        # Intro stuff
        @ball_shot = Gosu::Image.new("assets/ball_shot.png")
        @intro_time = 50

        @@battleground.pz = 0
        
        if not $boss
            # Play music
            @@battle_theme.play(true)
        else
            # Play boss music
            @@boss_theme.play(true)
            
            for i in (0..1500).step(10)
                @@battleground.add_sprite("assets/cave_wall.png", Omega::Vector3.new(-75, 0, -i), Omega::Vector2.new(1.0, 1.0))

                @@battleground.add_sprite("assets/cave_wall.png", Omega::Vector3.new(75, 0, -i), Omega::Vector2.new(1.0, 1.0))

                @@battleground.add_sprite("assets/black_wall.png", Omega::Vector3.new(0, -25, -i), Omega::Vector2.new(2.0, 1.0))
            end

            @enemies_atb_speeds = [0.6, 0.8]
            @enemies_atb_levels = [0, 0]
            @enemies_hp = [35, 35]

            @@bandit_horse = Omega::SpriteSheet.new("assets/meltons_riding.png", 48, 74)
            @@bandit_horse.scale = Omega::Vector2.new(1.2, 1.2)
            @@bandit_horse.position = Omega::Vector3.new(0, $height - @@horse.height*@@horse.scale.y + 15, 200)
            @@bandit_horse.add_animation("run", [0, 1])
            @@bandit_horse.play_animation("run")
        end
    end

    def update

        if @intro_time <= 0
            # Managing visuals
            @@battleground.pz -= 3

            if not @@horse.flip.x
                @@parallax.position.x += 0.05
            else
                @@parallax.position.x -= 0.05
            end

            if not @@horse.flip.x
                @@parallax.position.x -= (@@battleground.add_x - 25) * 0.03
                @@battleground.add_x -= (@@battleground.add_x - 25) * 0.08
            else
                @@parallax.position.x -= (@@battleground.add_x + 25) * 0.03
                @@battleground.add_x -= (@@battleground.add_x + 25) * 0.08
            end

            @@pannel.change_choice("dynamite", "Dynam. (#{$hero.dynamites})")

            if not @galloping_sound_instance or (@galloping_sound_instance and not @galloping_sound_instance.playing?)
                @galloping_sound_instance = $sounds["galloping"].play()
            end

            # Atb managing
            @atb_level += 0.5 if not $hero.defending
            @atb_level = @atb_level.clamp(0, 100)
            @atb_bar.width = @atb_level

            @enemies_atb_levels.size.times do |eid|
                @enemies_atb_levels[eid] += @enemies_atb_speeds[eid]
                @enemies_atb_levels[eid] = @enemies_atb_levels[eid].clamp(0, 100)

                if @enemies_atb_levels[eid] >= 100
                    @event = "enemy #{eid}"
                    @time = 10

                    @enemies_atb_levels[eid] = 0

                    @camera.shake(10, -5, 5)

                    $sounds["gun"].play()

                    return
                end
            end if not @event

            # Player inputs
            if not @event
                if not $hero.defending
                    if Omega::just_pressed(Gosu::KB_RIGHT) or Omega::just_pressed(Gosu::GP_0_RIGHT)
                        @@horse.flip.x = true
                    elsif Omega::just_pressed(Gosu::KB_LEFT) or Omega::just_pressed(Gosu::GP_0_LEFT)
                        @@horse.flip.x = false
                    end

                    if @@pannel.pressed_choice == "attack"
                        if @atb_level == 100
                            @atb_level = 0
                            @event = "player_shot #{((@@horse.flip.x) ? 1 : 0)}"
                            @camera.shake(10, -5, 5)

                            @time = 10

                            $sounds["gun"].play()
                        end
                    elsif @@pannel.pressed_choice == "defense" and @atb_level >= 50
                        $hero.defending = true
                        @atb_level -= 50
                    elsif @@pannel.pressed_choice == "dynamite"
                        if @atb_level == 100
                            if $hero.dynamites > 0
                                @atb_level = 0
                                @event = "player_shot everyone"
                                @camera.shake(10, -5, 5)

                                @time = 10

                                $sounds["explosion"].play()

                                $hero.dynamites -= 1

                                @atb_level = 0
                            end
                        end
                    end
                end
            elsif @event.include?("enemy")

                if @time == 10
                    enemy_id = @event.split(" ")[1].to_i

                    attack = rand(1..4)
                    attack = (attack / 3).to_i.clamp(1, 4) if $hero.defending
                    $hero.hp -= attack
                    $hero.hp = $hero.hp.clamp(0, $hero.max_hp)

                    $hero.defending = false

                    @time -= 1
                else
                    @time -= 1
                    @event = nil if @time <= 0
                end
                
            elsif @event.include?("player_shot")

                if @time == 10
                    enemy_id = @event.split(" ")[1].to_i

                    # puts enemy_id

                    if @event.split(" ")[1] == "everyone"
                        attack = 8

                        @enemies_hp[0] -= attack
                        @enemies_hp[1] -= attack

                        @enemies_hp[0] = @enemies_hp[0].clamp(0, 40)
                        @enemies_hp[1] = @enemies_hp[1].clamp(0, 40)
                    else
                        attack = $hero.level * rand(7..10)
                        @enemies_hp[enemy_id] -= attack

                        @enemies_hp[enemy_id] = @enemies_hp[enemy_id].clamp(0, 25)

                        # puts "Enemy #{enemy_id} HP : #{@enemies_hp[enemy_id]}"
                    end

                    @time -= 1
                else
                    @time -= 1
                    @event = nil if @time <= 0
                end

            end

            if @enemies_hp.sum == 0
                if not $boss
                    $hero.money += (@enemies_atb_speeds.sum * 20).to_i * 3
                    Omega.set_state(PlayState.new)
                else
                    Omega.set_state(MenuState.new)
                end
            end

            if $hero.hp <= 0
                $hero.hp = $hero.max_hp
                if $current_event == 3
                    $boss = false
                    $hero.dynamites = 12
                end
                $current_map = $last_village

                $hero.position.x = $towns_enter_positions[$current_map][0] * 10
                $hero.position.y = $towns_enter_positions[$current_map][1] * 10

                Omega.set_state(PlayState.new)
            end
        else
            @intro_time -= 1
        end
    end

    def draw
        if @intro_time <= 0
            @camera.draw($width, $height) do
                Gosu.draw_rect(0, 0, $width, $height, Gosu::Color.new(255, 255, 97, 0), 0)
                @@parallax.draw
                @@battleground.draw

                @@horse.x = ($width - @@horse.width*@@horse.scale.x) / 2 + @@battleground.add_x 
                @@horse.draw

                if @time > 0
                    if @event.include?("enemy")
                        @@horse_mask.position = @@horse.position
                        @@horse_mask.flip.x = @@horse.flip.x
                        @@horse_mask.current_frame = @@horse.current_frame
                        @@horse_mask.draw
                    end
                end

                # Bandit drawing

                # Bandit 0
                @@bandit_horse.color = Gosu::Color::WHITE

                if @enemies_hp[0] <= 0
                    @@bandit_horse.color = Gosu::Color::BLACK
                    @enemies_atb_levels[0] = 0
                end

                @@bandit_horse.x = ($width - @@horse.width*@@horse.scale.x) / 2 - 100 + @@battleground.add_x * 0.8
                @@bandit_horse.flip.x = true
                @@bandit_horse.draw
                draw_bar(@@bandit_horse.x.clamp(3, $width-63), @@bandit_horse.y - 10, @enemies_atb_levels[0], 60, 8)

                if @time > 0
                    if @event.include?("player_shot") and (@event.split(" ")[1].to_i == 0 or @event.split(" ")[1] == "everyone")
                        @@bandit_horse_mask.position = @@bandit_horse.position
                        @@bandit_horse_mask.flip.x = @@bandit_horse.flip.x
                        @@bandit_horse_mask.draw
                    end
                end

                # Bandit 1
                @@bandit_horse.color = Gosu::Color::WHITE
        
                if @enemies_hp[1] <= 0
                    @@bandit_horse.color = Gosu::Color::BLACK
                    @enemies_atb_levels[1] = 0
                end

                @@bandit_horse.x = ($width - @@horse.width*@@horse.scale.x) / 2 + 160 + @@battleground.add_x * 0.8
                @@bandit_horse.flip.x = false
                @@bandit_horse.draw(false)
                draw_bar(@@bandit_horse.x.clamp(3, $width-63), @@bandit_horse.y - 10, @enemies_atb_levels[1], 60, 8)

                if @time > 0
                    if @event.include?("player_shot") and (@event.split(" ")[1].to_i == 1 or @event.split(" ")[1] == "everyone")
                        @@bandit_horse_mask.position = @@bandit_horse.position
                        @@bandit_horse_mask.flip.x = @@bandit_horse.flip.x
                        @@bandit_horse_mask.current_frame = @@bandit_horse.current_frame
                        @@bandit_horse_mask.draw
                    end
                end

                # Drawing target
                center = Omega::Vector2.new((@@bandit_horse.width*@@bandit_horse.scale.x - @@target.width) / 2, (@@bandit_horse.height*@@bandit_horse.scale.y - @@target.height) / 2 - 20)
                if not @@horse.flip.x
                    @@target.position = Omega::Vector3.new(($width - @@horse.width*@@horse.scale.x) / 2 - 100 + @@battleground.add_x * 0.8 + center.x, @@bandit_horse.y + center.y, 10_000)
                else
                    @@target.position = Omega::Vector3.new(($width - @@horse.width*@@horse.scale.x) / 2 + 160 + @@battleground.add_x * 0.8 + center.x, @@bandit_horse.y + center.y, 10_000)
                end
                @@target.draw

                # Drawing ui
                @@pannel.draw

                # Drawing selector mask
                if @atb_level < 100 or $hero.defending or @event
                    @selector_mask.position.x = @@pannel.position.x + 3
                    @selector_mask.position.y = @@pannel.position.y + 3
                    @selector_mask.position.z = 10_000
                    @selector_mask.draw
                end # Attack

                if @atb_level < 50 or $hero.defending or @event
                    @selector_mask.position.x = @@pannel.position.x + 3
                    @selector_mask.position.y = @@pannel.position.y + @selector_mask.height + 6
                    @selector_mask.position.z = 10_000
                    @selector_mask.draw
                end # Defense

                if @atb_level < 100 or $hero.defending or @event
                    @selector_mask.position.x = @@pannel.position.x + 3
                    @selector_mask.position.y = @@pannel.position.y + @selector_mask.height * 2 + 9
                    @selector_mask.position.z = 10_000
                    @selector_mask.draw
                end # Dynamite

                # Drawing atb
                draw_bar(@atb_bar.position.x, @atb_bar.position.y, @atb_level, 100, 10)

                # Drawing texts
                $font.draw_text("X        D         A", @atb_bar.position.x - 2, @atb_bar.position.y - 15, 10_000, 1.0, 1.0, Gosu::Color::BLACK)
                $font.draw_text("#{$hero.hp}/#{$hero.max_hp} HP", $width - 140, 2, 10_000, 2.0, 2.0, Gosu::Color::BLACK)
            end
        else
            if @intro_time % 16 == 0
                $screenshot.insert(@ball_shot, rand(0..$screenshot.width-@ball_shot.width * 2) + rand(40), rand(0..$screenshot.height-@ball_shot.height * 2) + rand(40))
                $sounds["gun"].play()
            end

            if @intro_time > 10
                $screenshot.draw(0, 0, 10_000)
            else
                scale = 1.0 + (1.0 - @intro_time.clamp(0, 10)/10.0) * 2.0
                $screenshot.draw((Omega.width - $screenshot.width*scale) / 2, (Omega.height - $screenshot.height*scale) / 2, 10_000, scale, scale)
            end
        end
    end

    def self.load_assets
        @@battleground ||= PerspectiveTexture.new("assets/ground.png", $width, $height)
        @@battleground.perspective_modifier = 50
        @@battleground.base_perspective = 1.0
        @@battleground.base_scale_x = 1
        @@battleground.repeat = 1
        @@battleground.y = 220

        @@battleground.py = -40

        @@parallax = Omega::Parallax.new([Omega::Sprite.new("assets/background_0.png"), Omega::Sprite.new("assets/background_1.png")])
        @@parallax.per_pixel = true
        @@parallax.position.y = 80

        # Hero horse
        @@horse = Omega::SpriteSheet.new("assets/jo_riding_battle.png", 48, 60)
        @@horse.scale = Omega::Vector2.new(2.5, 2.5)
        @@horse.position = Omega::Vector3.new(0, $height - @@horse.height*@@horse.scale.y, 200)
        @@horse.add_animation("run", [0, 1])
        @@horse.play_animation("run")

        @@horse_mask = Omega::SpriteSheet.new("assets/jo_riding_battle_mask.png", 48, 60)
        @@horse_mask.scale = Omega::Vector2.new(2.5, 2.5)
        @@horse_mask.position = Omega::Vector3.new(0, $height - @@horse.height*@@horse.scale.y, 200)
        @@horse_mask.add_animation("run", [0, 1])
        @@horse_mask.play_animation("run")

        # Bandit horse
        @@bandit_horse = Omega::SpriteSheet.new("assets/bandit_riding.png", 48, 74)
        @@bandit_horse.scale = Omega::Vector2.new(1.2, 1.2)
        @@bandit_horse.position = Omega::Vector3.new(0, $height - @@horse.height*@@horse.scale.y + 15, 200)
        @@bandit_horse.add_animation("run", [0, 1])
        @@bandit_horse.play_animation("run")

        @@bandit_horse_mask = Omega::SpriteSheet.new("assets/bandit_riding_mask.png", 48, 74)
        @@bandit_horse_mask.scale = Omega::Vector2.new(1.2, 1.2)
        @@bandit_horse_mask.position = Omega::Vector3.new(0, $height - @@horse.height*@@horse.scale.y + 15, 200)
        @@bandit_horse_mask.add_animation("run", [0, 1])
        @@bandit_horse_mask.play_animation("run")

        # Target
        @@target = Omega::Sprite.new("assets/target.png")

        @@battle_theme = Gosu::Song.new("assets/musics/Far_West_-_Battle_Theme.ogg")
        @@boss_theme = Gosu::Song.new("assets/musics/Far_West_-_Boss_Theme.ogg")
    end

    def draw_bar(x, y, width, max_width, height)
        Gosu.draw_rect(x - 3, y - 3, max_width + 6, height + 6, Gosu::Color::BLACK, 10_000)

        Gosu.draw_rect(x, y, (max_width / 100.0) * width, height, Gosu::Color.new(255, 255, 97, 0), 10_000)
    end

end
####

####
class PlayState < Omega::State

    def load

        reset_npcs()

        # puts $current_map

        $hero.map = $maps[$current_map]

        @camera = Omega::Camera.new
        @camera.scale = Omega::Vector2.new(6, 6)
        @camera.follow($hero, 1.0)

        $songs[$songs_to_use[$last_map]].stop()
        $songs[$songs_to_use[$current_map]].play(true) if $songs_to_use[$current_map] and $songs[$songs_to_use[$current_map]]

        # 
        #@dialog_box.parse("Konnor : Hey Larry ! I am heading for the Melton Brothers. Have you seen these brigands ?", 23)
        #@dialog_box.active = true
    end

    def update
        if not @@dialog_box.active
            reset_npcs() if @@can_reset_npcs

            $hero.update(@@dialog_box)

            if $take_screenshot
                $screenshot = Gosu.render(640, 480) { draw() }
                $take_screenshot = false
    
                Omega.set_state(BattleState.new)
            end
        end

        @@dialog_box.update
    end

    def draw
        @camera.draw($width/@camera.scale.x.to_f, $height/@camera.scale.y.to_f, $maps[$current_map].width, $maps[$current_map].height) do
            $maps[$current_map].draw(@camera.position, @camera.scale, $width, $height)

            @npcs.each do |npc|
                npc.update(@@dialog_box)
                npc.draw
            end

            $hero.draw
        end

        $font.draw_text("#{$hero.money} $", 5, 5, 10_000, 5.0, 5.0, Gosu::Color::BLACK)


        $font.draw_text("#{$maps_name[$current_map]}", Omega.width - $font.text_width("#{$maps_name[$current_map]}") * 4 - 5, 5, 10_000, 4.0, 4.0, Gosu::Color::BLACK) if $maps_name[$current_map]

        @@dialog_box.draw
    end

    def reset_npcs
        @npcs = []

        npc_id = 0
        $maps[$current_map].layers["objects"].each do |tile|
            if tile.type.include?("npc")
                @npcs << NPC.new(@map, "./assets/#{tile.type}.png")
                @npcs[-1].position = tile.position
                
                @npcs[-1].dialog = $dialogs[$current_event][$current_map.to_sym][:dialogs][npc_id]
                @npcs[-1].commands = $dialogs[$current_event][$current_map.to_sym][:commands][npc_id]

                @npcs[-1].dialog ||= []
                @npcs[-1].commands ||= []

                npc_id += 1
            end
        end

        @@can_reset_npcs = false
    end

    # Static stuff
    def self.load_assets
        $maps = {}

        @@can_reset_npcs = false

        @@dialog_box = DialogBox.new("")
        @@dialog_box.y = Omega.height - @@dialog_box.height

        $songs_to_use.each do |name, v|
            $maps[name] = Omega::Map.new("./assets/tileset.png", 10)
            $maps[name].load_layer("solid", "./assets/" + name + "_solid.csv")
            $maps[name].load_layer("objects", "./assets/" + name + "_objects.csv")

            $maps[name].set_type(1, "wall")
            $maps[name].set_type(68, "wall")
            $maps[name].set_type(69, "wall")
            $maps[name].set_type(70, "wall")
            $maps[name].set_type(73, "wall")
            $maps[name].set_type(74, "wall")
            $maps[name].set_type(0, "town")
            $maps[name].set_type(2, "town")

            $maps[name].set_type(57, "hotel")

            for i in 12..55
                $maps[name].set_type(i, "wall")
            end
            
            npc = 0
            for i in 7..9
                $maps[name].set_drawable(i, false)
                $maps[name].set_type(i, "npc_#{i-7}")

                npc = i-7
            end

            $maps[name].set_drawable(75, false)
            $maps[name].set_type(75, "npc_#{npc+1}")
        end

    end

    def self.run_command(command)
        args = command.split(" ")
        return if args.size == 0

        if args[0] == "next_event"
            $current_event += 1
            @@can_reset_npcs = true
        elsif args[0] == "add_dyn"
            count = args[1].to_i
            $hero.dynamites = count
        elsif args[0] == "boss"
            $take_screenshot = true # It will launch battle

            $boss = true
        end
    end

end
####

####
class Hero < Omega::SpriteSheet

    attr_accessor :max_hp, :hp
    attr_accessor :dynamites, :level
    attr_accessor :defending
    attr_accessor :map
    attr_accessor :money
    attr_accessor :can_interact

    def initialize
        super("assets/jo_spritesheet.png", 16, 15)

        add_animation("down", [0])
        add_animation("right", [1])
        add_animation("left", [2])
        add_animation("up", [3])

        @position = Omega::Vector3.new(0, 90, 10_000)

        @tile_rectangle = Omega::Rectangle.new(0, 0, 10, 10)
        @rectangle = Omega::Rectangle.new(0, 0, 8, 8)

        @map = nil

        @max_hp = 60
        @hp = @max_hp
        @dynamites = 0
        @level = 1
        @defending = false

        @money = 25

        @can_interact = false

        @steps = 0
        reset_steps()
    end

    def update(dialog_box)
        # Save last position
        @last_position = @position.clone

        # Check player inputs
        if Omega::pressed(Gosu::KB_RIGHT) or Omega::pressed(Gosu::GP_0_RIGHT)
            @position.x += 1
            play_animation("right")

            @steps -= 1
        elsif Omega::pressed(Gosu::KB_LEFT) or Omega::pressed(Gosu::GP_0_LEFT)
            @position.x -= 1
            play_animation("left")

            @steps -= 1
        end

        if Omega::pressed(Gosu::KB_UP) or Omega::pressed(Gosu::GP_0_UP)
            @position.y -= 1
            play_animation("up")

            @steps -= 1
        elsif Omega::pressed(Gosu::KB_DOWN) or Omega::pressed(Gosu::GP_0_DOWN)
            @position.y += 1
            play_animation("down")

            @steps -= 1
        end

        # Check collision
        @rectangle.position = Omega::Vector3.new(@position.x + (@width - @rectangle.width)/2, @position.y + (@height - @rectangle.height)/2, 10_000)

        px = (@position.x/@map.tile_size).to_i
        py = (@position.y/@map.tile_size).to_i

        tiles_to_check = []

        tiles_to_check << @map.tile_at("solid", px, py - 1)
        tiles_to_check << @map.tile_at("solid", px + 1, py - 1)
        tiles_to_check << @map.tile_at("solid", px + 2, py - 1)

        tiles_to_check << @map.tile_at("solid", px, py)
        tiles_to_check << @map.tile_at("solid", px + 1, py)
        tiles_to_check << @map.tile_at("solid", px + 2, py)

        tiles_to_check << @map.tile_at("solid", px, py + 1)
        tiles_to_check << @map.tile_at("solid", px + 1, py + 1)
        tiles_to_check << @map.tile_at("solid", px + 2, py + 1)

        tiles_to_check << @map.tile_at("solid", px, py + 2)
        tiles_to_check << @map.tile_at("solid", px + 1, py + 2)
        tiles_to_check << @map.tile_at("solid", px + 2, py + 2)

        @can_interact = false

        tiles_to_check.each do |tile|
            next if not tile
            @tile_rectangle.position = tile.position
            if @tile_rectangle.collides?(@rectangle)
                if tile.type == "wall"
                    @position = @last_position
                elsif tile.type == "town"
                    town = nil
                    town ||= $towns["#{px},#{py}"]
                    town ||= $towns["#{px+1},#{py}"]
                    town ||= $towns["#{px},#{py+1}"]
                    town ||= $towns["#{px+1},#{py+1}"]
                    if town
                        reset_steps()
                        if $locked_places[$current_event] and $locked_places[$current_event][$towns.key(town)]
                            dialog_box.parse_array($locked_places[$current_event][$towns.key(town)], 23)
                            dialog_box.active = true

                            if @current_animation == "down" or @current_animation == "right"
                                @position.x = ($towns.key(town).split(",")[0].to_i - 2) * @map.tile_size
                            elsif @current_animation == "up"
                                @position.y = ($towns.key(town).split(",")[1].to_i + 1.1) * @map.tile_size
                            end
                        else
                            $last_map = $current_map.clone
                            $current_map = town

                            $last_village = town.clone

                            @position.x = $towns_enter_positions[$current_map][0] * @map.tile_size
                            @position.y = $towns_enter_positions[$current_map][1] * @map.tile_size
                            Omega.set_state(PlayState.new)
                        end
                    end
                elsif tile.type == "hotel"
                    if Omega::just_pressed(Gosu::KB_X) or Omega::just_pressed(Gosu::GP_0_BUTTON_0)
                        if @money > 15
                            dialog_box.parse_array(["The hotel is 15$. Hopefully you have enough money and get all your HP back."], 23)
                            dialog_box.active = true

                            @money -= 15
                            @hp = @max_hp
                        else
                            dialog_box.parse_array(["The hotel is 15$. Sadly you don't have enough money."], 23)
                            dialog_box.active = true
                        end
                    else
                        @can_interact = true
                    end
                end
            end
        end

        if $maps_type[$current_map] == "village" and (@position.x + @width / 2 < 0 or @position.x + @width / 2 > $maps[$current_map].width or @position.y + @height / 2 > $maps[$current_map].height)

            if @position.x + @width / 2 < 0
                @position.x = $towns_exit_positions[$current_map][0] * @map.tile_size
                @position.y = $towns_exit_positions[$current_map][1] * @map.tile_size
            elsif @position.x + @width / 2 > $maps[$current_map].width
                @position.x = ($towns_exit_positions[$current_map][0] + 2) * @map.tile_size
                @position.y = $towns_exit_positions[$current_map][1] * @map.tile_size
            else
                @position.x = $towns_exit_positions[$current_map][0] * @map.tile_size
                @position.y = $towns_exit_positions[$current_map][1] * @map.tile_size
            end

            $last_map = $current_map.clone
            $current_map = "world_map"

            Omega.set_state(PlayState.new)
        end

        # Check steps
        if @steps <= 0
            reset_steps()
            $take_screenshot = true if $maps_type[$current_map] == "dangerous" # It will launch battle
        end
    end

    def draw
        super()

        if @can_interact
            $font.draw_text("Interact", $hero.position.x + (@width-$font.text_width("Interact")*0.5) / 2, $hero.position.y - 10, 10_000, 0.5, 0.5, Gosu::Color::BLACK)
        end
        # @rectangle.draw
    end

    def reset_steps
        @steps = rand(300..400)
    end

end
####

####
class NPC < Omega::SpriteSheet

    attr_accessor :map, :dialog, :commands

    def initialize(map, path)
        super(path, 16, 28)
        add_animation("run", [0, 1])
        play_animation("run")

        @dialog = []
        @commands = []

        @frame_speed = 0.03

        @position.z = 10_000
        @scale = Omega::Vector2.new(0.5, 0.5)

        @time = 0
        
    end

    def update(dialog_box)
        if not dialog_box.active
            if self.collides?($hero) and @time == 0
                $hero.can_interact = true
                if Omega::just_pressed(Gosu::KB_X) or Omega::just_pressed(Gosu::GP_0_BUTTON_0)
                    @time = 10
                    dialog_box.parse_array(@dialog, 23)
                    dialog_box.active = true

                    if @commands.size > 0
                        @commands.each do |c|
                            PlayState.run_command(c)
                        end
                        @commands = []
                    end
                end
            end
            @time -= 1 if @time > 0
        end
    end

    def draw
        super()
    end

end
####

####
class DialogBox

    attr_accessor :x, :y
    attr_accessor :active, :scale
    attr_accessor :width, :height
    attr_accessor :current_text_to_parse

    def initialize(text)
        @@dialog_box ||= Gosu::Image.new("assets/dialogbox.png")

        @current_character = 0.0
        @current_block = 0
        @current_size = 0
        @x = 0
        @y = 1
        @width = @@dialog_box.width
        @height = @@dialog_box.height

        @block_size = 6

        @scale = 1

        @active = false

        @text_scale = 3

        @snd_channel = nil

        @current_text_to_parse = 0
        @text_to_parse = []
        @text_to_parse_ml = 0

        # We first parse the text for make sure it's not too long
        parse(text, 75)
    end

    def update
        return if not @active
        if Omega::just_pressed(Gosu::KB_X) or Omega::just_pressed(Gosu::GP_0_BUTTON_0)
            @current_size = 0
            @texts[@current_block...(@current_block+@block_size).clamp(0, @texts.size)].each { |text| @current_size += text.size }

            if @current_character.to_i >= @current_size
                @current_block += @block_size
                if @current_block > @texts.size
                    if @current_text_to_parse < @text_to_parse.size-1
                        @current_text_to_parse += 1
                        parse(@text_to_parse[@current_text_to_parse], @text_to_parse_ml)
                    else
                        @current_text_to_parse = 0
                        @text_to_parse = []
                        @text_to_parse_ml = 0

                        @active = false
                        @current_block -= @block_size
                    end
                else
                    @current_character = 0
                end
            else
                @current_character = @current_size
            end
        end
    end

    def draw

        return if not @active and @scale <= 0.4

        @scale -= 0.1 if @scale > 0.4 and not @active
        @scale += 0.1 if @scale < 1.0 and @active

        @scale = @scale.clamp(0.4, 1.0)

        @current_block = 0 if @scale.to_i == 1 and not @active

        Gosu.translate((Omega.width - @@dialog_box.width*@scale) / 2, 0) do
            Gosu.scale(@scale, @scale) do
                @@dialog_box.draw(@x, @y, 10_000_000)

                if @current_character < @current_size
                    @current_character += 1
                    if not @snd_channel or (@snd_channel and not @snd_channel.playing?)
                        @snd_channel = $sounds["talk"].play(0.4)
                    end
                end

                size = 0
                y = 10
                passed = false
                arr_end = (@current_block+@block_size).clamp(0, @texts.size)
                @texts[@current_block...arr_end].each do |text|
                    size += text.size
                    if @current_character >= size
                        $font.draw_text(text, @x + 12, @y + y, 10_000_000, @text_scale, @text_scale, Gosu::Color::BLACK)
                    elsif @current_character.to_i <= size and not passed
                        $font.draw_text(text[0...(@current_character.to_i - size)], @x + 12, @y + y, 10_000_000, @text_scale, @text_scale, Gosu::Color::BLACK)
                        passed = true
                    end
                    y += $font.height * @text_scale + 5
                end
            end
        end
    end

    def parse(text, max_length)
        @texts = [""]
        text.gsub("\n", "").split(" ").each do |word|
            if @texts[-1].size >= max_length and word.size > 1
                @texts << ""
            end
            @texts[-1] += word + " "
        end
        @current_character = 0.0
        @current_block = 0

        @current_size = 0
        @texts[@current_block...(@current_block+@block_size).clamp(0, @texts.size)].each { |text| @current_size += text.size }
    end

    def parse_array(text_array, max_length)
        @text_to_parse = text_array
        @text_to_parse_ml = max_length
        @current_text_to_parse = 0

        parse(@text_to_parse[@current_text_to_parse], @text_to_parse_ml)
    end

end
####

####
module Omega

    class Map
        attr_accessor :layers, :width, :height
        attr_accessor :light_max_dist
        attr_accessor :position
        attr_accessor :tileset
        attr_reader :tile_size

        def initialize(tileset_path, tile_size)
            @tile_size = tile_size

            @layers = {}

            @position = Vector3.new(0, 0, 0)
            @width = 0
            @height = 0

            @tileset = Omega::SpriteSheet.new(tileset_path, @tile_size, @tile_size, :tileable => true)
            @types = Array.new(@tileset.frames_count) { "solid" }
            @drawable = Array.new(@tileset.frames_count) { true }

            @light_max_dist = 200

            @decoration_imgs = {}
            @decoration_positions = {}

            @layers_indexed = {}
        end

        def load_layer(name, path, &block)
            @layers[name] = []

            x, y = 0, 0
            f = File.open(path, "r").each_line do |line|
                line.split(",").each do |i|
                    tile = nil
                    if i.to_i != -1
                        tile = Tile.new(x, y, i.to_i, @tileset, @types)
                        @layers[name] << tile
                        @width = x if x > @width
                        @height = y if y > @height
                    end
                    yield tile if block
                    x += @tile_size
                end
                x = 0
                y += @tile_size
            end
            f.close

            if @layers.size == 1
                @width += @tile_size
                @height += @tile_size
            end

            @layers_indexed[name] = Array.new(@width/@tile_size) { Array.new(@height/@tile_size) }
            @layers[name].each do |tile|
                @layers_indexed[name][tile.position.x/@tile_size][tile.position.y/@tile_size] = tile
            end
        end

        def set_image(id, image)
            @tileset[id] = image
        end

        def set_type(id, type)
            @types[id] = type
        end

        def set_drawable(id, drawable)
            @drawable[id] = drawable
        end

        def set_tile(layer, x, y, tileset_id)
            i = 0
            @layers[layer].each do |tile|
                if tile.position.x == x and tile.position.y == y
                    @layers[layer][i] = Tile.new(x, y, tileset_id, @tileset, @types)
                    @layers_indexed[layer][x/@tile_size][y/@tile_size] = @layers[layer][i]
                    return
                end
                i += 1
            end

            # Since we do not found any tile at x and y, we gonna to add a new tile
            @layers[layer] << Tile.new(x, y, tileset_id, @tileset, @types)
            @layers_indexed[layer][x/@tile_size][y/@tile_size] = @layers[layer][-1]
        end

        def delete_tile_from_position(layer, x, y)
            @layers[layer].each do |tile|
                if tile.position.x == x and tile.position.y == y
                    @layers[layer].delete(tile)
                    break
                end
            end
        end

        def delete_tile(layer, tile)
            @layers[layer].delete(tile)
            @layers_indexed[layer][tile.position.x/@tile_size][tile.position.y/@tile_size] = nil
        end

        def add_decoration(name, img)
            @decoration_imgs[name] = img
        end

        def set_decoration(name, pos)
            @decoration_positions[name] ||= []
            @decoration_positions[name] << pos
        end

        def get_decoration(name)
            return @decoration_imgs[name]
        end

        def tile_at(layer, tile_x, tile_y)
            if tile_x >= 0 and tile_y >= 0
                return @layers_indexed[layer][tile_x][tile_y]
            else
                return nil
            end
        rescue
            return nil
        end

        def draw(cam_pos, scale, width = Omega.width, height = Omega.height, light_pos = nil, optimize = false, center = false)
       
            w = width
            h = height


            @layers.each do |layer, tiles|
                # OLD RENDERING METHOD

                tiles.each do |tile|
                    tile.position.z = @position.z
                    next if not @drawable[tile.id]
                    if (tile.position.x + @tile_size >= -cam_pos.x and tile.position.x < -cam_pos.x + w and
                        tile.position.y + @tile_size >= -cam_pos.y and tile.position.y < -cam_pos.y + h)
                        # c = 255
                        # c = (255.0 / @light_max_dist) * (@light_max_dist-Omega.distance(Vector2.new(@position.x + tile.position.x, @position.y + tile.position.y), light_pos)).clamp(5, 1000) if light_pos
                        # next if c <= 10
                        # tile.color = Gosu::Color.new(255, c, c, c)
                        tile.draw
                    end
                end

            end

            @decoration_positions.each do |k, positions|
                positions.each do |pos|
                    if @decoration_imgs[k].is_a? Gosu::Image
                        width = @decoration_imgs[k].width
                        height = @decoration_imgs[k].height
                        if (@position.x + pos.x + width >= cam_pos.x - (Omega.window.width * 0.3) and @position.y + pos.x < cam_pos.x + (Omega.window.width * 0.3) and
                            @position.x + pos.y + height >= cam_pos.y - ((Omega.window.height+add_draw_height) * 0.45) and @position.y + pos.y < cam_pos.y + ((Omega.window.height+add_draw_height) * 0.2))
                            @decoration_imgs[k].draw(@position.x + pos.x, @position.y + pos.y, 0)
                        end
                    else
                        width = @decoration_imgs[k][0].width
                        height = @decoration_imgs[k][0].height
                        if (@position.x + pos.x + width >= cam_pos.x - (Omega.window.width * 0.3) and @position.x + pos.x < cam_pos.x + (Omega.window.width * 0.3) and
                            @position.y + pos.y + height >= cam_pos.y - ((Omega.window.height+add_draw_height) * 0.45) and @position.y + pos.y < cam_pos.y + ((Omega.window.height+add_draw_height) * 0.2))
                            @decoration_imgs[k][(Gosu.milliseconds / 100.0) % @decoration_imgs[k].size].draw(@position.x + pos.x, @position.y + pos.y, 0)
                        end
                    end
                end
            end if false
        end
    end

    class Tile
    
        attr_accessor :position, :id, :color, :debug
        attr_reader :tileset
    
        def initialize(x, y, id, tileset, types)
            @position = Vector3.new(x, y, 0)
            @id = id
            @color = Gosu::Color::WHITE
    
            @tileset = tileset
            @types = types
            @type = "solid"
    
            @debug = false
        end
    
        def draw
            @tileset.current_frame = @id
            @tileset.position = @position
            @tileset.color = @color

            @tileset.draw

            @tileset.color = Gosu::Color::WHITE
        end
    
        def type
            return @types[@id]
        end
    
    end

end
####

####
class PerspectiveTexture

    attr_accessor :image
    attr_accessor :x, :y, :z
    attr_accessor :add_x
    attr_accessor :px, :py, :pz, :pheight
    attr_accessor :middle, :base_perspective, :base_scale_x, :perspective_modifier, :repeat
    attr_accessor :surface_width, :surface_height
    attr_accessor :transparent_when_near

    Line = Struct.new(:image, :position)

    def initialize(path, swidth, sheight)
		@image = Gosu::Image.new(path)
		
		y = 0
		@lines = []
		@image.height.times do
			@lines << Gosu.render(@image.width, 1) do
				@image.draw(0, y, 0)
			end
			y -= 1
        end

        @transparent_when_near = false
        
        @vertical_lines = {}
        
        @middle = 0.5

        @surface_width = swidth
        @surface_height = sheight

        @base_perspective = 1
        @base_scale_x = 0.5
        @perspective_modifier = @surface_height

        @px = 0
        @py = 0
        @pz = 0

        @pheight = 0

        @x = 0
        @y = 0
        @z = 0

        @repeat = 0

        @add_x = 0

        @sprites = {}
    end
    
    def draw
        y = 0
        # tmp = []
        for i in 0...@lines.size
            line = @lines[(i+@pz.to_i) % @lines.size]
            perspective = @base_perspective + (y.to_f / @perspective_modifier)

            width = line.width*(perspective+@base_scale_x)
            x = @x + (@surface_width - width)*@middle + (@px - @x) * perspective + @add_x * perspective
            line.draw(x, @y + y + @py * perspective, @z + 10 * perspective, perspective+@base_scale_x, perspective + @py.abs * 0.1)

            @repeat.to_i.times do |i|
                line.draw(x + (i+1) * width, @y + y + @py * perspective, @z + 10 * perspective, perspective+@base_scale_x, perspective + @py.abs * 0.1)
                line.draw(x - (i+1) * width, @y + y + @py * perspective, @z + 10 * perspective, perspective+@base_scale_x, perspective + @py.abs * 0.1)
            end

            ## SPRITE DRAWING
            if @sprites[(i+@pz.to_i)]
                @sprites[(i+@pz.to_i)].each do |sprite|
                    last_pos = sprite.position.clone
                    last_scale = sprite.scale.clone

                    dist = @lines.size - i
                    min_dist = 50
                    if dist < min_dist and @transparent_when_near
                        sprite.color = Gosu::Color.new((255/min_dist.to_f) * dist, sprite.color.red, sprite.color.green, sprite.color.blue)
                    else
                        sprite.color = Gosu::Color.new(255, sprite.color.red, sprite.color.green, sprite.color.blue)
                    end

                    # puts sprite.scale
                    sprite.scale = Omega::Vector2.new((@base_scale_x + perspective)*sprite.scale.x, (@base_scale_x + perspective)*sprite.scale.y)
                    sprite.position.x = @x + (@surface_width - sprite.width*sprite.scale.x)*@middle + (@px - @x)*perspective + sprite.position.x*sprite.scale.x + @add_x * perspective
                    sprite.position.y = (@y + y) - (sprite.height-sprite.position.y) * sprite.scale.y + @py * perspective
                    sprite.position.z = @z + 10 * perspective
                    sprite.draw

                    sprite.position = last_pos
                    sprite.scale = last_scale

                end
            end

            ## VERTICAL LINE DRAWING
            if @vertical_lines[(i+@pz)]
                px = (@base_scale_x + perspective)
                @vertical_lines[(i+@pz)].each do |sprite|
                    last_pos = sprite.position.clone
                    last_scale = sprite.scale.clone

                    dist = @lines.size - i
                    min_dist = 50
                    if dist < min_dist
                        sprite.color = Gosu::Color.new((255/min_dist.to_f) * dist, sprite.color.red, sprite.color.green, sprite.color.blue)
                    else
                        sprite.color = Gosu::Color.new(255, sprite.color.red, sprite.color.green, sprite.color.blue)
                    end

                    # sprite.scale = Omega::Vector2.new(@px * 0.1 * perspective, perspective * sprite.scale.y)
                    sprite.scale = Omega::Vector2.new(px, px*sprite.scale.y)
                    sprite.position.x = @x + (@surface_width - sprite.width*sprite.scale.x)*@middle + (@px - @x)*perspective + sprite.position.x*sprite.scale.x + @add_x * perspective
                    sprite.position.y = (@y + y) - (sprite.height-sprite.position.y) * sprite.scale.y + @py * perspective
                    sprite.position.z = @z + 10 * perspective
                    sprite.scale.x *= last_scale.x
                    sprite.draw

                    sprite.position = last_pos
                    sprite.scale = last_scale
                end
            end

            y += perspective
        end

        @pheight = y
    end

    def add_sprite(image, position, scale)
        @sprites[position.z] ||= []
        @sprites[position.z] << Omega::Sprite.new(image)
        @sprites[position.z][-1].position = Omega::Vector3.new(position.x, position.y, 0)
        @sprites[position.z][-1].scale = scale
    end

    def add_vertical_lines(image_lines, position, scale, repeat = 0)
        x = 0
        image.width.times do |i|
            @vertical_lines[position.z+i] ||= []
            @vertical_lines[position.z+i] << Omega::Sprite.new(Gosu.render(1, image.height) { image.draw(x, 0, 0) })
            @vertical_lines[position.z+i][-1].position = Omega::Vector3.new(position.x, position.y, 0)
            @vertical_lines[position.z+i][-1].scale = scale
            x -= 1
        end
    end

end
####

####
class Pannel < Omega::Rectangle

    attr_accessor :back_color, :front_color, :text_color, :selector_color
    attr_accessor :choices, :active, :current_choice
    attr_accessor :marks
    attr_accessor :selector_style

    def initialize(x, y, width, height, border = 4)
        super(x, y, width, height)
        @border = border
        @back_color = Gosu::Color::BLACK
        @front_color = Gosu::Color::BLUE
        @text_color = Gosu::Color::WHITE
        @selector_color = Gosu::Color::YELLOW

        @current_choice = 0

        @choices = {}

        @marks = {}

        @time = 0

        @pressed_choice = nil

        @active = true

        @selector_style = "shining"
    end

    def draw
        
        @pressed_choice = nil
        return if not @active

        @time += 0.1
        @time %= 360

        # Drawing back window
        @color = @back_color
        super
        Gosu.draw_rect(@position.x+@border, @position.y+@border, @width - @border*2, @height - @border*2, @front_color, @position.z)

        # Drawing the choices
        return if @choices.size == 0
        button_height = (@height - @border) / @choices.size.to_f

        i = 0
        y = 0
        @choices.each do |k, c|
            $font.draw_text("#{c}#{@marks[k]}", @position.x + (@width - $font.text_width("#{c}#{@marks[k]}"))/2, @position.y + y + (button_height-$font.height+@border)/2, @position.z, 1.0, 1.0, @text_color)

            Gosu.draw_rect(@position.x, @position.y + y, @width, @border, @back_color, @position.z)

            if k == @choices.keys[@current_choice]
                case @selector_style
                when "shining"
                Gosu.draw_rect(@position.x + @border,
                               @position.y + y + @border,
                               @width - @border*2,
                               button_height - @border,
                               Gosu::Color.new((Math.cos(@time)+2)*64, @selector_color.red, @selector_color.green, @selector_color.blue),
                               @position.z)
                when "text_color"
                $font.draw_text("#{c}#{@marks[k]}", @position.x + (@width - $font.text_width("#{c}#{@marks[k]}"))/2, @position.y + y + (button_height-$font.height+@border)/2, @position.z, 1.0, 1.0, @selector_color)
                end
            end

            i += 1
            y += button_height
        end

        # Managing input
        if Omega::just_pressed(Gosu::KB_DOWN) or Omega::just_pressed(Gosu::GP_0_DOWN)
            @current_choice += 1
            @current_choice = @choices.size - 1 if @current_choice >= @choices.keys.size
            # $sounds["cursor_move"].play
        elsif Omega::just_pressed(Gosu::KB_UP) or Omega::just_pressed(Gosu::GP_0_UP)
            @current_choice -= 1
            @current_choice = 0 if @current_choice < 0
            # $sounds["cursor_move"].play
        end

        if Omega::just_pressed(Gosu::KB_ENTER) or Omega::just_pressed(Gosu::KB_X) or Omega::just_pressed(Gosu::GP_0_BUTTON_0)
            # $sounds["cursor_move"].play
            @pressed_choice = @choices.keys[@current_choice]
        else
            @pressed_choice = nil
        end
    end

    def add_choices(id, choice)
        @choices[id] = choice
        @current_choice = 0
    end

    def set_marks(id, value)
        @marks[id] = value
    end

    def reset_marks
        @marks = {}
    end

    def change_choice(id, choice)
        @choices[id] = choice
    end

    def delete_choice(id)
        @choices.delete(id)
    end

    def reset_choices
        @choices = {}
        @current_choice = 0
    end

    def pressed_choice
        return @pressed_choice
    end

end
####

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
        Omega.set_state(PlayState.new)
    end

end

Omega.run(Game, "config.json")