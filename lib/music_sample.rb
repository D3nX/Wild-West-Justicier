module Omega
    class MusicSample

        attr_reader :volume, :speed, :loop, :pan

        def initialize(path, volume = 1.0, speed = 1.0, do_loop = false, pan = 0)
            @volume = volume
            @speed = speed
            @loop = do_loop
            @pan = 0
            @sample = Gosu::Sample.new(path)

            @channel = nil
        end

        def play
            @channel = @sample.play_pan(@pan, @volume, @speed, @loop)
        end

        def pause
            @channel.pause
        end

        def resume
            @channel.resume
        end

        def stop
            @channel.stop
        end

        def playing?
            @channel.playing?
        end

        def paused?
            @channel.paused?
        end

        # Setters

        def volume=(vol)
            @volume = vol
            @channel.volume = @volume if @channel
        end

        def speed=(spd)
            @speed = spd
            @channel.speed = @speed if @channel
        end

    end
end