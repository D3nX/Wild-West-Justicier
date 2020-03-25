module Omega

    class Sprite

        attr_accessor :position, :scale, :origin, :flip
        attr_accessor :angle, :mode, :color
        attr_accessor :width, :height
        attr_accessor :visible

        attr_accessor :movable

        attr_reader :options, :image

        # Options
        # - Standard Gosu options
        # - :reloard => Force the API to reload the image from the hard drive
        def initialize(source, options = {})

            @@images ||= {}

            if source.is_a? String
                if not options[:reload]
                    @@images[source] ||= Gosu::Image.new(source, options)
                else
                    @@images[source] = Gosu::Image.new(source, options)
                end

                @image = @@images[source]
            else
                @image = Gosu::Image.new(source, options)
            end

            @options = options

            @position = Vector3.new(0.0, 0.0, 0.0)
            @scale = Vector2.new(1.0, 1.0)
            @origin = Vector2.new(0.0, 0.0)
            @flip = Vector2.new(false, false)

            @angle = 0.0
            @mode = :default
            @color = Gosu::Color::WHITE

            @width = @image.width
            @height = @image.height

            @visible = true

            @movable = true
        end

        def update; end

        def draw
            @image.draw_rot((@flip.x) ? @position.x + @width * @scale.x - @width*2 * @scale.x * @origin.x : @position.x,
                            (@flip.y) ? @position.y + @height * @scale.y - @height*2 * @scale.y * @origin.y : @position.y,
                            @position.z,
                            @angle,
                            @origin.x,
                            @origin.y,
                            (@flip.x) ? -@scale.x : @scale.x,
                            (@flip.y) ? -@scale.y : @scale.y,
                            @color,
                            @mode) if @visible
        end

        # Utils functions
        def set_center(axe_x, axe_y)
            @position.x = (Omega.window.width - @width*@scale.x) / 2 if axe_x
            @position.y = (Omega.window.height - @height*@scale.y) / 2 if axe_y
            @position.x += @width.to_f*@scale.x*@origin.x
            @position.y += @height.to_f*@scale.y*@origin.y
        end

        def collides?(sprite)
            Omega.log_err("This is not a sprite.") if not sprite.is_a? Sprite

            # puts @position.x
            # puts sprite.x + (sprite.width.to_f*sprite.scale.x) - (sprite.width.to_f*sprite.scale.x*sprite.origin.x)
            if @position.x > sprite.x + (sprite.width.to_f*sprite.scale.x) - (sprite.width.to_f*sprite.scale.x*sprite.origin.x) or
               @position.x + (@width.to_f*@scale.x) + (@width.to_f*@scale.x*@origin.x) < sprite.x - (sprite.width.to_f*sprite.scale.x*sprite.origin.x) or
               @position.y > sprite.y + (sprite.height.to_f*sprite.scale.y) - (sprite.height.to_f*sprite.scale.y*sprite.origin.y) or
               @position.y + (@height.to_f*@scale.y) - (@height.to_f*@scale.y*@origin.y) < sprite.y - (sprite.height.to_f*sprite.scale.y*sprite.origin.y)
                return false
            end

            true
            # false
        end

        def pixel_at(x, y)
            @blob ||= @image.to_blob
			if x < 0 or x >= width or y < 0 or y >= height
				return nil
			else
                return Gosu::Color.new(@blob[(y * @width + x) * 4, 4][3].unpack("H*").first.to_i(16),
                                       @blob[(y * @width + x) * 4, 4][1].unpack("H*").first.to_i(16), 
                                       @blob[(y * @width + x) * 4, 4][2].unpack("H*").first.to_i(16),
                                       @blob[(y * @width + x) * 4, 4][0].unpack("H*").first.to_i(16))
			end
		end

        # Getters & setters

        # Shortcut to postion.x, position.y & position.z
        def x
            @position.x
        end

        def y
            @position.y
        end

        def z
            @position.z
        end

        def x=(v)
            @position.x = v
        end

        def y=(v)
            @position.y = v
        end

        def z=(v)
            @position.z = v
        end
    end

    class SpriteSheet < Sprite
        attr_reader :frame_width, :frame_height, :current_animation, :frames_count, :frames

        attr_accessor :current_frame, :frame_speed

        def initialize(source, width, height, options = {})
            super(source, options)

            @frames = Gosu::Image.load_tiles(@image, width, height, options)
            @frames_count = @frames.size
            @current_frame = 0
            @frame_speed = 0.1

            @width = width
            @height = height

            @animations = {}
            @current_animation = nil

            @pause = false
        end

        def draw(can_add_frame = true)
            if @current_animation != nil
                if @frame_speed != 0 and not @pause and can_add_frame
                    @current_frame += @frame_speed
                    @current_frame %= @animations[@current_animation].size
                end
                
                @frames[@animations[@current_animation][@current_frame.to_i]].draw_rot((@flip.x) ? @position.x + @width * @scale.x - @width*2 * @scale.x * @origin.x : @position.x,
                                                                                        (@flip.y) ? @position.y + @height * @scale.y - @height*2 * @scale.y * @origin.y : @position.y,
                                                                                        @position.z,
                                                                                        @angle,
                                                                                        @origin.x,
                                                                                        @origin.y,
                                                                                        (@flip.x) ? -@scale.x : @scale.x,
                                                                                        (@flip.y) ? -@scale.y : @scale.y,
                                                                                        @color,
                                                                                        @mode)
            else
                @frames[@current_frame].draw_rot((@flip.x) ? @position.x + @width * @scale.x - @width*2 * @scale.x * @origin.x : @position.x,
                                                 (@flip.y) ? @position.y + @height * @scale.y - @height*2 * @scale.y * @origin.y : @position.y,
                                                 @position.z,
                                                 @angle,
                                                 @origin.x,
                                                 @origin.y,
                                                 (@flip.x) ? -@scale.x : @scale.x,
                                                 (@flip.y) ? -@scale.y : @scale.y,
                                                 @color,
                                                 @mode)
            end if @visible
        end

        def add_animation(id, array)
            @animations[id] = array
        end

        def play_animation(id)
            @current_frame = 0
            @current_animation = id
        end

        def stop
            @current_frame = 0
            @current_animation = nil
        end

        def pause
            @pause = true
        end

        def resume
            @pause = false
        end

        def frame
            return @animations[@current_animation][@current_frame.to_i]
        end
    end

end