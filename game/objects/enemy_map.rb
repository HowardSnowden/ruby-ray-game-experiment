require_relative 'object_map'
require_relative 'enemy'
module ZombieMage
  class EnemyMap < ObjectMap
    attr_accessor :map
    def initialize(tmx, map) 
      @map = map
      super(tmx)
    end
   
    def types
      ['Enemy']
    end

    def render_object(object, index=nil)
      return unless object.width  > 0
      @objects << Enemy.new(object.x, object.y, @map,  id: index)
    end
  end
end
