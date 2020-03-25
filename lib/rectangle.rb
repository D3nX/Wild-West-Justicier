module Omega

    class Rectangle
        attr_accessor :position, :width, :height, :color

        def initialize(x, y, width, height)
            @position = Omega::Vector3.new(x, y, 0)
            @color = Gosu::Color.new(255, 255, 255)
            @width = width
            @height = height
        end

        def collides?(rect)
            if @position.x > rect.position.x + rect.width or
                @position.x + @width < rect.position.x or
                @position.y > rect.position.y + rect.height or
                @position.y + @height < rect.position.y
                return false
            end
            return true
        end

        def draw
            Gosu.draw_rect(@position.x, @position.y, @width, @height, @color, @position.z)
        end
    end

end