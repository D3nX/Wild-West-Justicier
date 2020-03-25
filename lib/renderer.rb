=begin
module Omega

    @@render_objects = []
    @@render_frames = {}

    def Omega.renderer_add(object)
        return if @@render_objects.include?(object)
        @@render_objects << object
    end

    def Omega.renderer_make(object)

        return if @@render_objects.include?(object)

        tmp = {}
        @@render_objects.each do |r_obj|
            tmp[r_obj.z.to_s] = [] if tmp[r_obj.z.to_s] == nil
            tmp[r_obj.z.to_s] << r_obj
        end
        
        tmp.each do |z, imgs|
            @@render_frames[z] = Gosu.render(Omega.size.width, Omega.size.height) do
                imgs.each do |object|
                    object.render if !object.movable
                end
            end
        end

        p @@render_frames.size
    end

    def Omega.renderer_draw
        @@render_frames.each { |z, img| img.draw(0, 0, z.to_i) }
        @@render_objects.each do |object|
            object.render if object.movable
        end
    end
    
    def Omega.renderer_clear
        @@render_objects.clear
    end

end
=end