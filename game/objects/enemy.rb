require_relative '../modules/sprite_movement.rb'
module ZombieMage
  class Enemy
    include Ray::Helper
    require 'forwardable'
    extend Forwardable
    attr_accessor :sprite, :status, :id
    def_delegators :@sprite, :x, :y, :pos
    ANIMATION_DURATION = 0.2
    MOVESPEED = 1 
    include SpriteMovement

    def initialize(pos_x, pos_y, map, id: nil)
      @id = id
      @map = map
      player_img = Ray::Sprite.new path_of('enemy_sheet.png')
      player_img.sheet_size = [4, 1]
      player_img.sheet_pos = [0, 0]
      @status = :alive
      @sprite = player_img
      @route_pos = 0
      #@patrol_route = %w{u-15 s-15 d-15 r-15 l-15} 
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
        move_down
      elsif node.y < @sprite.y 
        move_up
      else

      end
      if node.x  > @sprite.x
        move_right
      elsif node.x < @sprite.x 
        move_left
      else
      end
    end

    def current_speed
      MOVESPEED
    end

    def update(player)
      return false if self.status  == :dead
      move_towards(player) 
      if @sprite.collide? player.sprite
        raise_event :enemy_collision 
      end
      self
    end

    def die
      @sprite.angle = 70
      self.status = :dead 
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
end
