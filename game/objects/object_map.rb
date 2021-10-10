module ZombieMage
  class ObjectMap 
    include Ray::Helper
    attr_reader :objects
    def initialize(tmx)
      @object_groups =  tmx.object_groups
      @objects = []
      self.each_object do |object, i|
        render_object(object,i) if self.types.include?(object.type)
      end
    end 

    def each_group
      @object_groups.each {|v| yield v }
    end

    def each_object
      each_group do |group|
        group.objects.each.with_index do |object, i|
          yield(object, i) 
        end
      end
    end

    def types
      ['small tree', 'tree', 'Building']
    end

    def each 
      @objects.each {|v| yield v }
    end

    def render_object(object, index)
      return unless object.width  > 0
      boundary = Ray::Rect.send(:[], *[object.x, object.y, object.width, object.height])
      @objects << boundary
    end

  end
end
