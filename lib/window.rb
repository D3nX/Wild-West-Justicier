module Omega

    # Some default window constant
    DEFAULT_WIDTH  = 640
    DEFAULT_HEIGHT = 480
    DEFAULT_TITLE  = "OmegaEngine - Build #{VERSION}"

    # The window related handles
    @@window = nil
    @@config = nil
    @@needs_cursor = true
    @@just_pressed_key = -1
    @@just_released_key = -1

    # The window class
    class RenderWindow < Gosu::Window

        alias_method :run, :show

        def initialize
            width = DEFAULT_WIDTH
            height = DEFAULT_HEIGHT
            title = DEFAULT_TITLE
            fullscreen = false
            if Omega.config != nil
                width = Omega.config["width"]
                height = Omega.config["height"]
                title = Omega.config["title"]
                fullscreen = Omega.config["fullscreen"]
            end

            Omega.log_err("The configuration file is not correct !") if width == nil or height == nil or
                                                                  title == nil or fullscreen == nil

            super(width, height, fullscreen)
            self.caption = title

            @@window = self

            @joystick_captured = false
        end

        def load; end

        def update
            @joystick_captured = false
            Omega.state.update if Omega.state != nil
        end

        def draw
            Omega.state.draw if Omega.state != nil
            Omega.just_pressed_key = -1
        end

        def button_down(id)

            return if @joystick_captured

            last_pressed_key = Omega.just_pressed_key

            Omega.just_pressed_key = Gosu::GP_0_UP if id == Gosu::GP_0_UP
            Omega.just_pressed_key = Gosu::GP_0_DOWN if id == Gosu::GP_0_DOWN
            Omega.just_pressed_key = Gosu::GP_0_LEFT if id == Gosu::GP_0_LEFT
            Omega.just_pressed_key = Gosu::GP_0_RIGHT if id == Gosu::GP_0_RIGHT

            Omega.just_pressed_key = Gosu::GP_0_BUTTON_0 if id == Gosu::GP_0_BUTTON_0
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_1 if id == Gosu::GP_0_BUTTON_1
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_2 if id == Gosu::GP_0_BUTTON_2
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_3 if id == Gosu::GP_0_BUTTON_3
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_4 if id == Gosu::GP_0_BUTTON_4
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_5 if id == Gosu::GP_0_BUTTON_5
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_6 if id == Gosu::GP_0_BUTTON_6
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_7 if id == Gosu::GP_0_BUTTON_7
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_8 if id == Gosu::GP_0_BUTTON_8
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_9 if id == Gosu::GP_0_BUTTON_9
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_10 if id == Gosu::GP_0_BUTTON_10
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_11 if id == Gosu::GP_0_BUTTON_11
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_12 if id == Gosu::GP_0_BUTTON_12
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_13 if id == Gosu::GP_0_BUTTON_13
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_14 if id == Gosu::GP_0_BUTTON_14
            Omega.just_pressed_key = Gosu::GP_0_BUTTON_15 if id == Gosu::GP_0_BUTTON_15

            @joystick_captured = (last_pressed_key != Omega.just_pressed_key)

            super(id)
            Omega.just_pressed_key = id if not @joystick_captured
            Omega.state.button_down(id)
        end

        def button_up(id)
            super(id)
            Omega.just_released_key = id
            Omega.state.button_up(id)
        end

        private

        def needs_cursor?
            return Omega.needs_cursor?
        end
    end

    # Window related function
    def Omega.run(window, config_file = nil)
        @@config = JSON.parse(File.new(config_file).read) if config_file != nil
        @@window = window.new if window.is_a? Class
        @@window.load
        @@window.show
    end

    def Omega.resize(width, height)
        @@window.width = width
        @@window.height = height
    end

    def Omega.size
        Size.new(@@window.width, @@window.height)
    end

    def Omega.width
        return @@window.width
    end

    def Omega.height
        return @@window.height
    end

    def Omega.config
        @@config
    end

    def Omega.config=(config)
        @@config = config
    end

    def Omega.title
        @@window.caption
    end

    def Omega.title=(title)
        @@window.caption = title
    end

    def Omega.window
        @@window
    end

    def Omega.needs_cursor?
        @@needs_cursor
    end

    def Omega.needs_cursor=(needs_cursor)
        @@needs_cursor = needs_cursor
    end

    def Omega.mouse_position
        Vector2.new(@@window.mouse_x, @@window.mouse_y)
    end

    def Omega.mouse_x=(x)
        @@window.mouse_x = x
    end

    def Omega.mouse_y=(y)
        @@window.mouse_y = y
    end

    def Omega.just_pressed_key=(key)
        @@just_pressed_key = key
    end
    
    def Omega.just_released_key=(key)
        return @@just_released_key = key
    end

    def Omega.just_pressed_key
        return @@just_pressed_key
    end

    def Omega.just_released_key
        return @@just_released_key
    end

    def Omega.just_pressed(key)
        return key == @@just_pressed_key
    end

    def Omega.pressed(key)
        return Gosu.button_down?(key)
    end

    def Omega.just_released(key)
        return key == @@just_released_key
    end

end