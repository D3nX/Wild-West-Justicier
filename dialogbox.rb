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