module SpriteMovement

  def move_left 
    @animations[:left].resume if @animations[:left].paused?
    @sprite.flip_x = false 
    @animations[:left].update
    new_coords =  Ray::Rect.new(@sprite.x - current_speed, @sprite.y, @sprite.sprite_width, @sprite.sprite_height)
    @sprite.x -= current_speed unless @map.will_collide?(new_coords, self)
    @current_direction = :left
  end

  def move_right
    @animations[:right].resume if @animations[:right].paused?
    @animations[:right].update
    @sprite.flip_x = true
    new_coords = Ray::Rect.new(@sprite.x  + current_speed, @sprite.y, @sprite.sprite_width, @sprite.sprite_height)
    @sprite.x += current_speed  unless @map.will_collide?(new_coords, self)
    @current_direction = :right
  end

  def move_up
    @animations[:up].resume if @animations[:up].paused?
    @animations[:up].update
    new_coords =  Ray::Rect.new(@sprite.x, @sprite.y - current_speed, @sprite.sprite_width, @sprite.sprite_height)
    @sprite.y -= current_speed   unless @map.will_collide?(new_coords, self)
    @current_direction = :up
  end

  def move_down
    @animations[:down].resume if @animations[:down].paused?
    @animations[:down].update
    new_coords = Ray::Rect.new(@sprite.x, @sprite.y + current_speed, @sprite.sprite_width, @sprite.sprite_height)
    @sprite.y += current_speed  unless @map.will_collide?(new_coords, self)
    @current_direction = :down
  end



end
