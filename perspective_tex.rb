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