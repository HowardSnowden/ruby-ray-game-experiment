module ZombieMage
  class Projectile
    include Ray::Helper
    require 'forwardable'
    extend Forwardable
    def_delegators :x, :y, :pos
    MOVESPEED = 4
    attr_reader :sprite, :window


    def initialize(pos_x, pos_y, map, direction)
     
      @sprite = Ray::Sprite.new(map.projectile_image)
      @map = map
      @sprite.x = pos_x
      @sprite.y =  pos_y 
      @direction  =  direction
    end

    def update(enemies)
      @sprite.pos  =  movements[@direction]
    end

    def collide_with_enemy?(enemies)
      collision =  false
      enemies.each do |e|
        collision =  e.sprite.collide?(@sprite)
        if collision
          e.die 
          break
        end
      end
      return collision 
    end

    def movements
      {up: Ray::Vector2[@sprite.x, (@sprite.y - MOVESPEED)], 
       down: Ray::Vector2[@sprite.x, (@sprite.y +  MOVESPEED)], 
       left:  Ray::Vector2[@sprite.x - MOVESPEED, @sprite.y], 
       right: Ray::Vector2[@sprite.x + MOVESPEED, @sprite.y] 
      }
    end

    def off_map?
      movements[@direction].x  >  @map.max_x || movements[@direction].y > @map.max_y
    end

  end
end
