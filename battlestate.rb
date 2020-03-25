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