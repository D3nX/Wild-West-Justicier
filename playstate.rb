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