module Omega
    class Assets
        (Dir["assets/*.png"] + Dir["assets/*.jpg"]).each do |f|
            name = "TEX_" + f.split("/")[1].gsub(".", "_").gsub(" ", "_").downcase
            eval("#{name} = Gosu::Image.new(\"#{f}\")")
        end

        (Dir["assets/*.ogg"] + Dir["assets/*.mp3"]).each do |f|
            name = "MUS_" + f.split("/")[1].gsub(".", "_").gsub(" ", "_").downcase
            eval("#{name} = Gosu::Song.new(\"#{f}\")")
        end
    end
end if false