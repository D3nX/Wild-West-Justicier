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