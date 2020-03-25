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