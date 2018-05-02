require 'rubygems'
require 'byebug'
require 'ray'
require 'tmx'

def path_of(resource)
  File.join(File.dirname(__FILE__), "./resources", resource)
end


module RPG

  class Scene < Ray::Scene
    scene_name :rpg_scene

    def setup
      player_img = Ray::Sprite.new path_of('player_sheet.png')
      player_img.sheet_size = [4, 2]
      player_img.sheet_pos = [0, 0]
      @player = player_img
      width, height = window.size.to_a
      @screen_rect = Ray::Rect[0, 0, width, height]


      @player.y = (height / 2) - 25


      @player.x = 30
      @map  = Map.new(path_of "main_map2.tmx")
    end


    def register
      self.loops_per_second = 60
      always do
        if animations.empty? 
          if holding? key(:down)
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

      @map.each_tile {|tile| win.draw tile}


      win.draw @player

    end
  end

  class Map

    def initialize(file)
      @layers = [] 
      @tmx = Tmx.load(file) 
      @tileset = @tmx.tilesets.first
      @tileset_img = path_of @tileset.image
      @tileset_grid = tileset_grid(@tileset)
      @tmx.layers.each do |l|
        layer_to_tiles(l)
      end
    end

    def layer_to_tiles(layer)
      tiles = {}
      layer.data.each_slice(@tmx.width).with_index do |line, y|
        line.each_with_index  do |t, x|
          tiles[[x, y]] = Ray::Sprite.new(@tileset_img, :at => [x * 8, y * 8])
          unless t == 0
           coord_y, coord_x = @tileset_grid[t] 
           tiles[[x, y]].sub_rect = [coord_x, coord_y, 8, 8]
          end
        end
      end
      @layers << tiles 
    end

    def each_layer
      @layers.each { |l| yield l}
    end

    def each_tile
      each_layer do |l|
        l.each {|_,tile| yield tile }
      end
    end

    def solid?(x, y)
      y < 0 || @tiles[[x.to_i / TileSize, y.to_i / TileSize]]
    end

    attr_reader :max_x, :max_y

    private 

    def tileset_grid(tileset)
      grid = {} 
      i = 1
      (tileset.imageheight / 8).times do |y|
        (tileset.imagewidth / 8).times do |x|
          grid[i] = [y * 8, x * 8]
          i += 1

        end
      end
      grid
    end
  end


  class Game < Ray::Game
    def initialize
      super("RPG ")

      Scene.bind(self)
      push_scene :rpg_scene
    end

    def register
      add_hook :quit, method(:exit!)
    end
  end
end

RPG::Game.new.run
