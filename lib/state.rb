module Omega

    # State related variable
    @@current_state = nil

    # The state class
    class State

        def load
            @list_obj = []
        end

        def update
            @list_obj.each { |obj| obj.update }
        end

        def draw
            @list_obj.each { |obj| obj.draw }
        end

        def add(obj)
            @list_obj << obj
        end

        def button_down(id); end

        def button_up(id); end

    end

    # State related function
    def Omega.set_state(state)
        @@current_state = state if state.is_a? State
        @@current_state.load if @@current_state != nil
    end

    def Omega.state
        return @@current_state
    end

end