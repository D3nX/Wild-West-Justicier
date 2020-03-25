# Omega Engine - by D3nX
# Under MIT Licence
# "The Omega Engine is a Gosu based game framework that claim
# "to be fully open source and help everyone to developp faster
# and more efficiently game in ruby"
# Build 0.1

# Importing gosu & json gem
require 'gosu'
require 'json'

module Omega
    extend Gosu

    # Informations constants
    VERSION = "0.1"
    LICENCE = "MIT"

    # Structs
    Vector2 = Struct.new(:x, :y)
    Vector3 = Struct.new(:x, :y, :z)
    Size = Struct.new(:width, :height)

    Rectangle = Struct.new(:x, :y, :width, :height, :z, :color)

    Font = Gosu::Font.new(150)

    # Basic global functions
    def Omega.log_inf(msg)
        puts "OmegaEngine - Build[#{VERSION}][Log]: #{msg}"
    end

    def Omega.log_err(msg)
        raise "OmegaEngine - Build[#{VERSION}][Error]: #{msg}"
    end

    def Omega.distance(vec1, vec2)
        return Gosu.distance(vec1.x, vec1.y, vec2.x, vec2.y)
    end

    # Classes
    require_relative "window"
    require_relative "state"
    require_relative "sprite"
    require_relative "input"
    require_relative "renderer"
    require_relative "utils"
    require_relative "assets"
    require_relative "map"
    require_relative "camera"
    require_relative "rectangle"
    require_relative "parallax"
    require_relative "music_sample"
end