module ZombieMage
  class MainScene < Ray::Scene
    scene_name :main_scene
    attr_accessor :projectiles
    
    def setup
      @map_music  = music(path_of('FFVII_main_theme.ogg'))
      @map_music.looping = true
      @map_music.pitch = 0.5
      @map_music.play 
      @projectiles = []
      @map  = Map.new(path_of("main_map2.tmx"))
      @player = Player.new((@map.max_x / 2), (@map.max_y/2), @map)
      @map.load
      @camera = Ray::View.new @player.pos, window.size 
      @half_size = window.size / 2 
    end

    def register
      @player.register self
      @map.enemies.each {|v| v.register self }
      on :over_projectile_limit do 
        @projectiles.shift
      end
      @loop_count = 0
      always do 
        @projectiles.delete_if {|v| v.off_map?  || v.collide_with_enemy?(@map.enemies) }
        if @loop_count == 100 
          @loop_count = 0
        else  
         @loop_count += 1
        end
        if @loop_count % 5 == 0  
         if @player.status == :moving
          @player.stamina -= 1 unless @player.stamina < 1 
         elsif @player.status == :standing
          @player.stamina += 1 unless @player.stamina >= 100
         end
        end

        @player.update
        @map.enemies.each {|m| m.update(@player) }
        @projectiles.each {|m| m.update(@enemies) }

        p_max_x =  [@player.x, @half_size.w].max
        p_max_y =  [@player.y, @half_size.y].max

        camera_x =[p_max_x, @map.max_x - @half_size.w ].min
        camera_y =[p_max_y, @map.max_y - @half_size.h].min

        @camera.center = [camera_x, camera_y] 
        
        raise_event :over_projectile_limit if @projectiles.size > 5
      end
    end

    def clean_up
      @map_music.stop
      @player = nil
      @camera = nil
      @map = nil
      @projectiles = nil
      @map_music = nil
    end

    def render(win)
      win.with_view @camera do 
        win.draw @map.render(@camera)
        win.draw @player.sprite
        @map.enemies.map {|v| win.draw v.sprite }
        projectiles.map {|v| win.draw v.sprite }
       end
        t = text "Stamina: #{@player.stamina.to_s} Ammo: #{@player.ammo.to_s}", :size => 20, at: [window.size.x - 275, 0] 
        win.draw t
    end
  end
end

