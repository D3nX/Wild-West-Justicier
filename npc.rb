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