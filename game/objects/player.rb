require_relative '../modules/sprite_movement.rb'
module ZombieMage
  class Player
    include Ray::Helper
    require 'forwardable'
    extend Forwardable
    attr_reader :sprite, :window, :current_direction, :status, :ammo
    attr_accessor :stamina
    def_delegators :@sprite, :x, :y, :pos
    ANIMATION_DURATION = 0.1
    MOVESPEED = 2 
    OutOfBreathSpeed = 1 
    include SpriteMovement

    def initialize(pos_x, pos_y, map)
      player_img = Ray::Sprite.new path_of('player_sheet2.png')
      player_img.sheet_size = [4, 2]
      player_img.sheet_pos = [0, 0]
      @gunfire = music(path_of('gfire.wav'))
      @stamina  = 100 
      @map = map
      @sprite = player_img
      @sprite.x = pos_x
      @sprite.y =  pos_y 
      @status = :alive
      @ammo = 10 
      
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

      on :key_press, key(:space) do 
        fire_projectile!
      end

      on :enemy_collision do 
        die
      end

      on :key_press do 
        if @status == :dead
          scene.pop_scene
          scene.push_scene(:main_scene)

        end
      end
    end

    def update  
      return if status == :dead
      if holding?(:left) 
        move_left
        @status = :moving
      elsif  holding?(:right)  
        move_right
        @status = :moving
      elsif  holding?(:up) 
        move_up 
        @status = :moving
      elsif holding?(:down) 
        move_down
        @status = :moving
      else
        @status = :standing
        @animations.each do |key, animation|
          animation.pause unless animation.paused?
        end
      end 
    end

    def out_of_breath?
      @stamina <  1.0
    end

    def fire_projectile!
      if @ammo > 0 
       @gunfire.play
       @scene.projectiles << Projectile.new(@sprite.x, @sprite.y, @map, current_direction)
       @ammo -= 1
      end
    end

    def current_speed
      out_of_breath? ? OutOfBreathSpeed : MOVESPEED
    end
    
    def die
      @animations[:left].resume if @animations[:left].paused?
      @sprite.angle =  70
      @status = :dead
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
end

