require 'rubygems'
require 'ray'
Dir.glob(File.join('./rpg', '**', '*.rb'), &method(:require))
# NB: this tests Ray::ImageTarget, there's no other reason to use it.

module RPG
  class Scene < Ray::Scene
    scene_name :rpg_scene

    def setup
     # @map = RPG::Map.new
     # @map.to_s
      player_img = Ray::Sprite.new "player_sheet.png"
     
      player_img.sheet_size = [4, 2]
      player_img.sheet_pos = [0, 0]
 

      @player = player_img


      width, height = window.size.to_a

      @screen_rect = Ray::Rect[0, 0, width, height]

      @player.y = (height / 2) - 25
      

      @player.x = 30
      

     
    end


    def register
      self.loops_per_second = 60

      on :point_gained do |by|
        @scores[by] += 1
    
      end

      always do
       if animations.empty? 
        if holding? key(:down)
          # @player.y += 4
          # @player.y -= 4 unless @player.inside? @screen_rect
           animations << sprite_animation(:from => [0, 0], :to => [0, 1],
                                         :duration => 0.3).start(@player) 
           animations << translation(:of => [0, 10], :duration => 0.3).start(@player)
        elsif holding? key(:up)
             animations << sprite_animation(:from => [1, 0], :to => [1, 1],
                                         :duration => 0.3).start(@player) 
             animations << translation(:of => [0, -10], :duration => 0.3).start(@player)
        elsif holding? key(:right) 
             @player.flip_x = true 
        	   animations << sprite_animation(:from => [2, 0], :to => [3, 0],
                                         :duration => 0.3).start(@player) 
             animations << translation(:of => [10, 0], :duration => 0.3).start(@player)
        elsif holding? key(:left)
             @player.flip_x = false 
        	   animations << sprite_animation(:from => [2, 0], :to => [3, 0],
                                         :duration => 0.3).start(@player) 
             animations << translation(:of => [-10, 0], :duration => 0.3).start(@player)
        end

       end


       
      end
    end

    def render(win)
      win.clear Ray::Color.black

      win.draw @player
   
    end
  end

  class Game < Ray::Game
    def initialize
      super("RPG
")

      Scene.bind(self)
      push_scene :rpg_scene
    end

    def register
      add_hook :quit, method(:exit!)
    end
  end
end

RPG::Game.new.run