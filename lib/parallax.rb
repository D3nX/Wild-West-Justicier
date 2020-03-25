module Omega
    
    class Parallax

        attr_accessor :position, :sprites
        attr_accessor :scale
        attr_accessor :width, :height
        attr_accessor :per_pixel

        def initialize(sprites)
            @sprites = sprites
            @width = sprites[0].width
            @height = sprites[0].height
            @position = Omega::Vector3.new(0, 0, 0)
            @scale = Omega::Vector2.new(1, 1)
            @per_pixel = true
        end

        def draw(borders = 1)
            offset = 1.0
            @sprites.each do |spr|
                x = @position.x*offset % (@width*@scale.x)
                x = x.to_i if @per_pixel
                spr.image.draw(x, @position.y, @position.z, @scale.x, @scale.y)
                borders.times do |b|
                    spr.image.draw(x-@width*@scale.x*(b+1), @position.y, @position.z, @scale.x, @scale.y)
                    spr.image.draw(x+@width*@scale.x*(b+1), @position.y, @position.z, @scale.x, @scale.y)
                end
                offset += 0.1
            end
        end
    end

end