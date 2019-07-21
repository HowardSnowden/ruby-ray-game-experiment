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
    # need to derive map size

    def setup
      @map_music  = music(path_of('FFVII_main_theme.ogg'))
      @map_music.looping = true
      @map_music.pitch = 0.5
      @map_music.play 

      @map  = Map.new(path_of "main_map2.tmx")

      @player = Player.new((@map.max_x / 2), (@map.max_y/2))
      @camera = Ray::View.new @player.pos, window.size 

      @half_size = window.size / 2 
    end


    def register
      self.loops_per_second = 30
      always do
        if animations.empty? 
          if holding? key(:down) 
            @player.move(:down, self)
          elsif holding? key(:up)
            @player.move(:up, self)
          elsif holding? key(:right)  
            @player.move(:right, self)
          elsif holding? key(:left) 
            @player.move(:left, self)
          end
        end

        p_max_x =  [@player.x, @half_size.w].max
        p_max_y =  [@player.y, @half_size.y].max

        camera_x =[p_max_x, @map.max_x - @half_size.w ].min
        camera_y =[p_max_y, @map.max_y - @half_size.h].min

        @camera.center = [camera_x, camera_y] 
      end
    end

    def render(win)

      win.with_view @camera do 

        @map.each_tile(@camera) do |tile|
          win.draw tile 
        end
        win.draw @player.player

      end
    end
  end

  class Player
    require 'forwardable'
    extend Forwardable
    attr_accessor :player
    def_delegators :@player, :x, :y, :pos
    ANIMATION_DURATION = 0.3

    def initialize(pos_x, pos_y)
      player_img = Ray::Sprite.new path_of('player_sheet.png')
      player_img.sheet_size = [4, 2]
      player_img.sheet_pos = [0, 0]
      @player = player_img
      @player.x = pos_x
      @player.y =  pos_y 
    end

    def move(dir, scene)
      flip_x = false
      case dir
      when :down
        from, to = [[0, 0], [0, 1]]
        of = [0, 21]
      when :up
        from, to = [[1, 0], [1, 1]]
        of = [0, -21]
      when :left
        from, to = [[2, 0], [3, 0]]
        of = [-21, 0]
      when :right
        flip_x = true
        from, to = [[2, 0], [3, 0]]
        of = [21, 0]
      end
      @player.flip_x  = flip_x 
      scene.animations << scene.sprite_animation(:from => from, :to => to,
                                     :duration => ANIMATION_DURATION).start(@player) 
      scene.animations << scene.translation(:of => of, :duration => ANIMATION_DURATION).start(@player)
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
      @max_x *= 8
      @max_y *= 8 
    end

    def layer_to_tiles(layer)
      tiles = {}
      layer.data.each_slice(@tmx.width).with_index do |line, y| 
        @max_y = y 
        line.each_with_index  do |t, x|
          @max_x = x

          unless t == 0
            tiles[[x, y]] = Ray::Sprite.new(@tileset_img, :at => [x * 8, y * 8])

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

    def each_tile(camera)
      vx, vy = [80, 60] #tiles
      cx, cy = [camera.x / 8, camera.y / 8].map(&:to_i)
      each_layer do |l|
        ((cx - vx)..(cx + vx)).each do |x|
          ((cy - vy)..(cy + vy)).each do |y|

            yield l[[x, y]] if l[[x, y]]


          end
        end
      end
    end

    def visible?(x, y)
      #y < 0 || @tiles[[x.to_i / TileSize, y.to_i / TileSize]]
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
