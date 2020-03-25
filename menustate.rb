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