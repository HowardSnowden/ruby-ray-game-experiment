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
    attr_accessor :projectiles
    # need to derive map size

    def setup
      @map_music  = music(path_of('FFVII_main_theme.ogg'))
      @map_music.looping = true
      @map_music.pitch = 0.5
      @map_music.play 
      @projectiles = []

      @map  = Map.new(path_of "main_map2.tmx")



      @player = Player.new((@map.max_x / 2), (@map.max_y/2), @map)
      @enemies = [] 
      30.times do  
        @enemies << Enemy.new((@map.max_x / rand(1..4)) - rand(1..100), (@map.max_y/2 - rand(1..4)) + rand(1..100)) 
      end
      @camera = Ray::View.new @player.pos, window.size 

      @half_size = window.size / 2 
    end

    def register
      @player.register self

      always do 
        @player.update
        @enemies = @enemies.select {|v| v.status == :alive}.map {|m| m.update(Ray::Vector2.new(@player.x, @player.y)) }
        @projectiles = @projectiles.map {|m| m.update(@enemies) }.compact
        
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
        projectiles.map {|v| win.draw v.sprite }
        


      end
    end
  end

  class Projectile
    include Ray::Helper
    require 'forwardable'
    extend Forwardable
    def_delegators :x, :y, :pos
    ANIMATION_DURATION = 0.3 
    MOVESPEED = 30
    attr_reader :sprite, :window

    def initialize(pos_x, pos_y, map, direction)
      @sprite = Ray::Polygon.rectangle([2, 2, 5, 5], Ray::Color.red)
      @map = map
      @sprite.x = pos_x
      @sprite.y =  pos_y 
      @direction  =  direction
    end

    def update(enemies)
      unless off_map?(@direction)
       enemy_collision = collide_with_enemy?(enemies)
       unless enemy_collision
         move(@direction)  
       else
         enemy_collision.die
         return remove_self
       end
      else
       return remove_self
      end
      return self
    end

    def collide_with_enemy?(enemies)
      enemies.each do |e|
        return e if @sprite.pos.inside? e.sprite
      end
      return false
    end

    def remove_self
      nil
    end

    def move(dir)
      case dir
      when :up
        @sprite.y -= MOVESPEED 
      when :down
        @sprite.y += MOVESPEED 
      when :left
        @sprite.x -= MOVESPEED 
      when :right
        @sprite.x += MOVESPEED 
      end
    end

    def off_map?(direction)
      case direction
      when :up
       (@sprite.y + MOVESPEED) > @map.max_y
      when :down
        (@sprite.y - MOVESPEED) <= 0
      when :left
        (@sprite.x - MOVESPEED)  <= 0
      when :right
        (@sprite.x + MOVESPEED ) >=  @map.max_x
      else 
        false
      end
    end

  end

  class Player
    include Ray::Helper
    require 'forwardable'
    extend Forwardable
    attr_reader :sprite, :window, :current_direction
    def_delegators :@sprite, :x, :y, :pos
    ANIMATION_DURATION = 0.3 
    MOVESPEED = 5

    def initialize(pos_x, pos_y, map)
      player_img = Ray::Sprite.new path_of('player_sheet.png')
      player_img.sheet_size = [4, 2]
      player_img.sheet_pos = [0, 0]
      @map = map
      @sprite = player_img
      @sprite.x = pos_x
      @sprite.y =  pos_y 
      @current_direction = :down
      @animations = {}
      [:up, :down, :left, :right].each  do |v|
        @animations[v]  = move_animations(v)
        @animations[v].pause
      end
    end
    def register(scene)
      @window = scene.window
      @scene = scene 
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
        @sprite.x -= MOVESPEED unless @map.will_collide?(@sprite.rect, {x: -MOVESPEED + 2})
        @current_direction = :left
      elsif  holding? :right 
        @animations[:right].resume if @animations[:right].paused?
        @animations[:right].update
        @sprite.flip_x = true
        @sprite.x += MOVESPEED  unless @map.will_collide?(@sprite.rect, {x: MOVESPEED - 2})
        @current_direction = :right
      elsif  holding? :up
        @animations[:up].resume if @animations[:up].paused?
        @animations[:up].update

        @sprite.y -= MOVESPEED   unless @map.will_collide?(@sprite.rect, {y: -MOVESPEED + 2})
        @current_direction = :up
      elsif holding? :down
        @animations[:down].resume if @animations[:down].paused?
        @animations[:down].update
        @sprite.y += MOVESPEED   unless @map.will_collide?(@sprite.rect, {y: MOVESPEED - 2})
        @current_direction = :down
      elsif holding? :space
        fire_projectile!
      else
        @animations.each do |key, animation|
          animation.pause unless animation.paused?
        end
      end 
    end

    def fire_projectile!
      @scene.projectiles << Projectile.new(@sprite.x, @sprite.y, @map, current_direction)
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
    attr_accessor :sprite, :status
    def_delegators :@sprite, :x, :y, :pos
    ANIMATION_DURATION = 0.3
    MOVESPEED = 2 

    def initialize(pos_x, pos_y)
      player_img = Ray::Sprite.new path_of('enemy_sheet.png')
      player_img.sheet_size = [4, 1]
      player_img.sheet_pos = [0, 0]
      @status = :alive
      @sprite = player_img
      @route_pos = 0
      @patrol_route = %w{u-15 s-15 d-15 r-15 l-15} 
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

    def move_towards(node)
      if node.y  > @sprite.y
        move('d')
      elsif node.y < @sprite.y 
        move('u')
      else
         move('s')
      end
     if node.x  > @sprite.x
        move('r')
      elsif node.x < @sprite.x 
        move('l')
      else
         move('s')
      end
    end

    def update(player_pos)
      move_towards(player_pos) 
      self
    end

    def die
      self.status = :dead 
    end

    def move(dir)
      if dir == 'u'
        @animations[:up].resume if @animations[:up].paused?
        @animations[:up].update
        @animations[:down].pause
        @sprite.y -= MOVESPEED 
      elsif dir == 'd'
        @animations[:down].resume if @animations[:down].paused?
        @animations[:down].update
        @animations[:up].pause
        @sprite.y += MOVESPEED 
      elsif dir == 'l'
        @animations[:left].resume if @animations[:left].paused?
        @animations[:left].update
        @animations[:right].pause
        @sprite.flip_x = false
        @sprite.x -= MOVESPEED 
      elsif dir == 'r'
        @animations[:right].resume if @animations[:right].paused?
        @animations[:right].update
        @animations[:left].pause
        @sprite.flip_x = true
        @sprite.x += MOVESPEED 
      elsif dir == 's'
        @animations.each do |key, animation|
          animation.pause unless animation.paused?
        end
      end
    end

    def patrol
      @route = @patrol_route[@route_pos]
      route = @route.split('-') 
      @movements ||= route[1].to_i
      @dir = route[0]
      @movements -= 1 unless @movements == 0
      @route_pos += 1 if @movements == 0
      @route_pos = 0  unless @patrol_route[@route_pos]
      move(@dir)
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
        from, to = [[2, 0], [3, 0]]
      end
      sprite_animation(:from => from, :to => to,
                       :duration => ANIMATION_DURATION).start(@sprite) 
    end

  end


  class ObjectMap 
    include Ray::Helper
    attr_reader :objects
    def initialize(tmx)
      @object_groups =  tmx.object_groups
      @objects = []
      self.each_object do |object|
        render_object(object)
      end
    end 

    def each_group
      @object_groups.each {|v| yield v }
    end

    def each_object
      each_group do |group|
        group.objects.each do |object|
          yield object 
        end
      end
    end

    def each 
      @objects.each {|v| yield v }
    end

    def render_object(object)
      return unless object.width  > 0
      boundary = Ray::Rect.send(:[], *[object.x, object.y, object.width, object.height])

      @objects << boundary
    end

  end


  class Map 
    attr_reader :object_map    

    def initialize(file)
      @layers = [] 
      @tmx = Tmx.load(file) 
      @tileset = @tmx.tilesets.first
      @tileset_img = path_of @tileset.image
      @tileset_grid = tileset_grid(@tileset) 
      @object_map = ObjectMap.new(@tmx)

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

    def will_collide?(player, vectors={})
      collides = false
      player.x +=  vectors[:x].to_i 
      player.y += vectors[:y].to_i 

      @object_map.each do |obj|
        collides = true if player.collide?(obj)
      end
      collides
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
