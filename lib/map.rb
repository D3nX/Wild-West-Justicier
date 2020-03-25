module Omega

    class Map
        attr_accessor :layers, :width, :height
        attr_accessor :light_max_dist
        attr_accessor :position
        attr_accessor :tileset
        attr_reader :tile_size

        def initialize(tileset_path, tile_size)
            @tile_size = tile_size

            @layers = {}

            @position = Vector3.new(0, 0, 0)
            @width = 0
            @height = 0

            @tileset = Omega::SpriteSheet.new(tileset_path, @tile_size, @tile_size, :tileable => true)
            @types = Array.new(@tileset.frames_count) { "solid" }
            @drawable = Array.new(@tileset.frames_count) { true }

            @light_max_dist = 200

            @decoration_imgs = {}
            @decoration_positions = {}

            @layers_indexed = {}
        end

        def load_layer(name, path, &block)
            @layers[name] = []

            x, y = 0, 0
            f = File.open(path, "r").each_line do |line|
                line.split(",").each do |i|
                    tile = nil
                    if i.to_i != -1
                        tile = Tile.new(x, y, i.to_i, @tileset, @types)
                        @layers[name] << tile
                        @width = x if x > @width
                        @height = y if y > @height
                    end
                    yield tile if block
                    x += @tile_size
                end
                x = 0
                y += @tile_size
            end
            f.close

            if @layers.size == 1
                @width += @tile_size
                @height += @tile_size
            end

            @layers_indexed[name] = Array.new(@width/@tile_size) { Array.new(@height/@tile_size) }
            @layers[name].each do |tile|
                @layers_indexed[name][tile.position.x/@tile_size][tile.position.y/@tile_size] = tile
            end
        end

        def set_image(id, image)
            @tileset[id] = image
        end

        def set_type(id, type)
            @types[id] = type
        end

        def set_drawable(id, drawable)
            @drawable[id] = drawable
        end

        def set_tile(layer, x, y, tileset_id)
            i = 0
            @layers[layer].each do |tile|
                if tile.position.x == x and tile.position.y == y
                    @layers[layer][i] = Tile.new(x, y, tileset_id, @tileset, @types)
                    @layers_indexed[layer][x/@tile_size][y/@tile_size] = @layers[layer][i]
                    return
                end
                i += 1
            end

            # Since we do not found any tile at x and y, we gonna to add a new tile
            @layers[layer] << Tile.new(x, y, tileset_id, @tileset, @types)
            @layers_indexed[layer][x/@tile_size][y/@tile_size] = @layers[layer][-1]
        end

        def delete_tile_from_position(layer, x, y)
            @layers[layer].each do |tile|
                if tile.position.x == x and tile.position.y == y
                    @layers[layer].delete(tile)
                    break
                end
            end
        end

        def delete_tile(layer, tile)
            @layers[layer].delete(tile)
            @layers_indexed[layer][tile.position.x/@tile_size][tile.position.y/@tile_size] = nil
        end

        def add_decoration(name, img)
            @decoration_imgs[name] = img
        end

        def set_decoration(name, pos)
            @decoration_positions[name] ||= []
            @decoration_positions[name] << pos
        end

        def get_decoration(name)
            return @decoration_imgs[name]
        end

        def tile_at(layer, tile_x, tile_y)
            if tile_x >= 0 and tile_y >= 0
                return @layers_indexed[layer][tile_x][tile_y]
            else
                return nil
            end
        rescue
            return nil
        end

        def draw(cam_pos, scale, width = Omega.width, height = Omega.height, light_pos = nil, optimize = false, center = false)
       
            w = width
            h = height


            @layers.each do |layer, tiles|
                # OLD RENDERING METHOD

                tiles.each do |tile|
                    tile.position.z = @position.z
                    next if not @drawable[tile.id]
                    if (tile.position.x + @tile_size >= -cam_pos.x and tile.position.x < -cam_pos.x + w and
                        tile.position.y + @tile_size >= -cam_pos.y and tile.position.y < -cam_pos.y + h)
                        # c = 255
                        # c = (255.0 / @light_max_dist) * (@light_max_dist-Omega.distance(Vector2.new(@position.x + tile.position.x, @position.y + tile.position.y), light_pos)).clamp(5, 1000) if light_pos
                        # next if c <= 10
                        # tile.color = Gosu::Color.new(255, c, c, c)
                        tile.draw
                    end
                end

            end

            @decoration_positions.each do |k, positions|
                positions.each do |pos|
                    if @decoration_imgs[k].is_a? Gosu::Image
                        width = @decoration_imgs[k].width
                        height = @decoration_imgs[k].height
                        if (@position.x + pos.x + width >= cam_pos.x - (Omega.window.width * 0.3) and @position.y + pos.x < cam_pos.x + (Omega.window.width * 0.3) and
                            @position.x + pos.y + height >= cam_pos.y - ((Omega.window.height+add_draw_height) * 0.45) and @position.y + pos.y < cam_pos.y + ((Omega.window.height+add_draw_height) * 0.2))
                            @decoration_imgs[k].draw(@position.x + pos.x, @position.y + pos.y, 0)
                        end
                    else
                        width = @decoration_imgs[k][0].width
                        height = @decoration_imgs[k][0].height
                        if (@position.x + pos.x + width >= cam_pos.x - (Omega.window.width * 0.3) and @position.x + pos.x < cam_pos.x + (Omega.window.width * 0.3) and
                            @position.y + pos.y + height >= cam_pos.y - ((Omega.window.height+add_draw_height) * 0.45) and @position.y + pos.y < cam_pos.y + ((Omega.window.height+add_draw_height) * 0.2))
                            @decoration_imgs[k][(Gosu.milliseconds / 100.0) % @decoration_imgs[k].size].draw(@position.x + pos.x, @position.y + pos.y, 0)
                        end
                    end
                end
            end if false
        end
    end

    class Tile
    
        attr_accessor :position, :id, :color, :debug
        attr_reader :tileset
    
        def initialize(x, y, id, tileset, types)
            @position = Vector3.new(x, y, 0)
            @id = id
            @color = Gosu::Color::WHITE
    
            @tileset = tileset
            @types = types
            @type = "solid"
    
            @debug = false
        end
    
        def draw
            @tileset.current_frame = @id
            @tileset.position = @position
            @tileset.color = @color

            @tileset.draw

            @tileset.color = Gosu::Color::WHITE
        end
    
        def type
            return @types[@id]
        end
    
    end

end