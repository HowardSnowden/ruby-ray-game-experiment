require_relative 'enemy_map'
module ZombieMage
  class Map 
    attr_reader :object_map, :projectile_image, :enemies
    include Ray::Helper

    def initialize(file)
      @layers = [] 
       @tmx = Tmx.load(file) 
      @tileset = @tmx.tilesets.first
      @tileset_img = path_of @tileset.image
      @tileset_grid = tileset_grid(@tileset) 
      @object_map = ObjectMap.new(@tmx)
      @enemies =  EnemyMap.new(@tmx, self).objects
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

    def load
      texture  = Ray::Image.new [@max_x, @max_y]
      image_target(texture) do |target|
        each_layer do |l|
          (0..(@max_x / 8)).each do |x|
            (0..(@max_y / 8)).each do |y|
              target.draw  l[[x, y]] if l[[x, y]]
              target.update
            end
          end
        end
      end 
      @texture = Ray::Sprite.new(texture)
      @projectile_image = Ray::Image.new([6, 6])
      drawable =  Ray::Polygon.rectangle([4, 4, 4, 4], Ray::Color.white)
      image_target @projectile_image do |targ|
        targ.draw drawable
        targ.update
      end

    end

    def each_layer
      @layers.each { |l| yield l}
    end

    def will_collide?(new_pos, player)
      collides = false
      @object_map.each do |obj|
        collides = true  if new_pos.collide?(obj)
        break if collides
      end
      if player.is_a?(ZombieMage::Enemy) 
        @enemies.select{|v| v.id != player.id }.each do |o|
          collides = true  if new_pos.collide?(o.sprite)
         break if collides
        end
      end
      collides
    end

   def render(camera)
     @texture
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

end
