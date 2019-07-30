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
      @enemies = [] 
      10.times do  
        @enemies << Enemy.new((@map.max_x / rand(1..4)) - rand(1..100), (@map.max_y/2 - rand(1..4)) + rand(1..100)) 
      end
      @camera = Ray::View.new @player.pos, window.size 

      @half_size = window.size / 2 
    end

    def register
     @player.register self
    
     always do 
      @player.update
      @enemies.map(&:update)
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
        win.draw @player.sprite
        @enemies.map {|v| win.draw v.sprite }

      end
    end
  end

  class Player
    include Ray::Helper
    require 'forwardable'
    extend Forwardable
    attr_reader :sprite, :window
    def_delegators :@sprite, :x, :y, :pos
    ANIMATION_DURATION = 0.3 
    MOVESPEED = 5

    def initialize(pos_x, pos_y)
      player_img = Ray::Sprite.new path_of('player_sheet.png')
      player_img.sheet_size = [4, 2]
      player_img.sheet_pos = [0, 0]
      @sprite = player_img
      @sprite.x = pos_x
      @sprite.y =  pos_y 
      @animations = {}
      [:up, :down, :left, :right].each  do |v|
        @animations[v]  = move_animations(v)
        @animations[v].pause
      end
    end
   def register(scene)
      @window = scene.window
      self.event_runner = scene.event_runner

      @animations.each do |key, animation|
        animation.event_runner = event_runner
        on :animation_end, animation do 
          animation.start @sprite
        end
      end
   end

    def update 
      
      if holding? :left
        @animations[:left].resume if @animations[:left].paused?
       @sprite.flip_x = false 

        @animations[:left].update
        @sprite.x -= MOVESPEED 
      elsif  holding? :right 
        @animations[:right].resume if @animations[:right].paused?
        @animations[:right].update
        @sprite.flip_x = true
        @sprite.x += MOVESPEED 
      elsif  holding? :up
        @animations[:up].resume if @animations[:up].paused?
        @animations[:up].update

        @sprite.y -= MOVESPEED 
      elsif holding? :down
        @animations[:down].resume if @animations[:down].paused?
        @animations[:down].update
        @sprite.y += MOVESPEED 
      else
        @animations.each do |key, animation|
          animation.pause unless animation.paused?
        end
      end 

    end

    def move_animations(dir)
      case dir
      when :down
        from, to = [[0, 0], [0, 1]]
      when :up
        from, to = [[1, 0], [1, 1]]
      when :left
        from, to = [[2, 0], [3, 0]]
      when :right
        from, to = [[2, 0], [3, 0]]
      end
      sprite_animation(:from => from, :to => to,
                             :duration => ANIMATION_DURATION).start(@sprite)
    end
  end

  class Enemy
    include Ray::Helper
    require 'forwardable'
    extend Forwardable
    attr_accessor :sprite
    def_delegators :@sprite, :x, :y, :pos
    ANIMATION_DURATION = 0.3
    MOVESPEED = 3  

    def initialize(pos_x, pos_y)
      player_img = Ray::Sprite.new path_of('enemy_sheet.png')
      player_img.sheet_size = [4, 1]
      player_img.sheet_pos = [0, 0]
      @sprite = player_img
      @route_pos = 0
      @patrol_route = %w{u-10 s-5 d-10 s-10 d-5} 
      @sprite.x = pos_x
      @sprite.y =  pos_y 
      @animations = {}
      [:up, :down, :left, :right].each  do |v|
        @animations[v]  = move_animations(v)
        @animations[v].pause
      end
     
    end

    def register(scene)
      @window = scene.window
      self.event_runner = scene.event_runner

      @animations.each do |key, animation|
        animation.event_runner = event_runner
        on :animation_end, animation do 
          animation.start @sprite
        end
      end
  
    end

   def update
     patrol  
   end

   def patrol
     @route = @patrol_route[@route_pos]
     route = @route.split('-') 
     @movements ||= route[1].to_i
     @dir = route[0]
     @movements -= 1 unless @movements == 0
     @route_pos += 1 if @movements == 0
     @route_pos = 0  unless @patrol_route[@route_pos]
     
     if @dir == 'u'
      @animations[:up].resume if @animations[:up].paused?
      @animations[:up].update
      @animations[:down].pause
      @sprite.y -= MOVESPEED 
     
     elsif @dir == 'd'
       @animations[:down].resume if @animations[:down].paused?
       @animations[:down].update
       @animations[:up].pause
       @sprite.y += MOVESPEED 

     elsif @dir == 's'
       @animations.each do |key, animation|
         animation.pause unless animation.paused?
       end
     end
 
     @movements = nil if @movements == 0
   end

    def move_animations(dir)
      case dir
      when :down
        from, to = [[0, 0], [0, 0]]
      when :up
        from, to = [[1, 0], [1, 0]]
      when :left
        from, to = [[2, 0], [3, 0]]
      when :right
        flip_x = true
        from, to = [[2, 0], [3, 0]]
      end
      sprite_animation(:from => from, :to => to,
         :duration => ANIMATION_DURATION).start(@sprite) 
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
