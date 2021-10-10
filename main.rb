require 'rubygems'
require 'byebug'
require 'ray'
require 'tmx'
require './game/scenes/main_scene.rb'
Dir[File.join(__dir__, './game/objects', '*.rb')].each { |file| require file }

def path_of(resource)
  File.join(File.dirname(__FILE__), "./resources", resource)
end



module ZombieMage 
  
 
  class Game < Ray::Game
    attr_accessor :projectile_image
    def initialize
      super("ZombieMage ")
      MainScene.bind(self)
      push_scene :main_scene
    end

    def register
      add_hook :quit, method(:exit!)

    end
  end
end

ZombieMage::Game.new.run
