class GameWindow < Hasu::Window
  SPRITE_SIZE = 128
  WINDOW_X = 1024
  WINDOW_Y = 768
attr_reader :score
  def initialize

    @score = 0
    super(WINDOW_X, WINDOW_Y, false)
    @ui = UI.new

    @background_sprite = Gosu::Image.new(self, 'images/background.png', true)
    @koala_sprite = Gosu::Image.new(self, 'images/koala.png', true)
    @enemy_sprite = Gosu::Image.new(self, 'images/enemy.png', true)
    @flag_sprite = Gosu::Image.new(self, 'images/flag.png', true)
    @font = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @flag = {x: WINDOW_X - SPRITE_SIZE, y: WINDOW_Y - SPRITE_SIZE}
#Un son du jeu angrybirds sera joué à chaque fois que le hero ramasse un object.
    @sound_collect = Gosu::Sample.new("musics/Bonus.wav")
    @sound_Nocollect = Gosu::Sample.new("musics/Dmg.wav")
    @music = Gosu::Song.new(self, "musics/angry.wav")
    @lose_sprite = Gosu::Image.new(self, 'images/flag.png', true)
    @items = []

    reset
  end


class Object
  attr_reader :x, :y
WindowWidth = 1024
attr_reader :type
  def initialize(type)
    @type = type
    @image = if type == :egg
#Nous avons des d'objets qui apparaissent au fil du temps, 2 pour être précis : les goldeneggs et les cages.
               Gosu::Image.new('images/egg.png')
             elsif type == :cage
               Gosu::Image.new('images/cage.png')
             end
# Ces objects sont en mouvement et il faudra donc les attraper pour gagner des points, leur vitesse de deplacement est variable.
    @velocity = Gosu::random(0.8, 3.3)

    #Les objects ne peuvent pas depasser de la fenêtre.
    @x = rand * (WindowWidth - @image.width)
    # Les objects apparraitront de façon aléatoir dans la fenêtre.
    @y = rand * (768 - @image.width)


  end

  def update
    @y += @velocity
  end

  def draw
    @image.draw(@x, @y, 1)
  end

end


def update
#3 objects apparaitront
#Les goldeneggs auront plus de chance d'apparaitre car ils soint moins précieux que les cages.
  unless @items.size >= 3
    r = rand
    if r < 0.030
      @items.push(Object.new(:egg))
    elsif r < 0.045
      @items.push(Object.new(:cage))
    end
  end
  @disparution = rand(10..200)
  @items.each(&:update)
  @items.reject! {|item| item.y > WINDOW_Y }
  collect_objects(@items)

  @player[:x] += @speed if button_down?(Gosu::Button::KbRight)
  @player[:x] -= @speed if button_down?(Gosu::Button::KbLeft)
  @player[:y] += @speed if button_down?(Gosu::Button::KbDown)
  @player[:y] -= @speed if button_down?(Gosu::Button::KbUp)
  @player[:x] = normalize(@player[:x], WINDOW_X - SPRITE_SIZE)
  @player[:y] = normalize(@player[:y], WINDOW_Y - SPRITE_SIZE)
  handle_enemies
  handle_quit
  if winning?
    reinit
  end
  if loosing?

    reset
  end
end


#Contact avec l'object du type goldeneggs ou cages
def collect_objects(objects)
    objects.reject! do |object|
      dist_x = @player[:x] - object.x
      dist_y = @player[:y] - object.y
      dist = Math.sqrt(dist_x * dist_x + dist_y * dist_y)
      #40 pixels feront l'affaire en terme de largeur et de contact avec le hero.
      if dist < 40 then
       collision(object.type)
        true
      else
        false
      end
    end
  end


  private

  def reset
    @high_score = 0
    @enemies = []
    @speed = 3
    @music.stop
    @score = 0
    @music.play
    reinit
  end

  def reinit
    @speed += 1
    @player = {x: 0, y: 0}
    @enemies.push({x: 500 + rand(100), y: 200 + rand(300)})
    high_score
  end

  def high_score
    unless File.exist?('hiscore')
      File.new('hiscore', 'w')
    end
    @new_high_score = [@enemies.count, File.read('hiscore').to_i].max
    File.write('hiscore', @new_high_score)
  end

  def collision?(a, b)
    (a[:x] - b[:x]).abs < SPRITE_SIZE / 2 &&
    (a[:y] - b[:y]).abs < SPRITE_SIZE / 2
  end


  def loosing?
    @enemies.any? do |enemy|
      collision?(@player, enemy)
    end
  end

  def winning?
    collision?(@player, @flag)
  end


#Affichage du score en haut à gauche en rouge avec une police perso.
class UI

  def initialize
    @font = Gosu::Font.new(35, name: "txt/mfn-icons")
  end

  def draw(score:)
    @font.draw("Score: #{score}", 10, 10, 3, 1.0, 1.0, 0xffff0000)
  end

end


def lose
 @lose_sprite = {x: WINDOW_X/2, y: WINDOW_Y/2}

end
  def draw

    @font.draw("Level #{@enemies.length}", WINDOW_X - 100, 10, 3, 1.0, 1.0, Gosu::Color::GREEN)

    @koala_sprite.draw(@player[:x], @player[:y], 2)
    @enemies.each do |enemy|
      @enemy_sprite.draw(enemy[:x], enemy[:y], 2)
    end
    @flag_sprite.draw(@flag[:x], @flag[:y], 1)
    (0..8).each do |x|
      (0..8).each do |y|
        @background_sprite.draw(x * SPRITE_SIZE, y * SPRITE_SIZE, 0)
        @items.each(&:draw)
      end
    end
    @ui.draw(score: @score)
  end
#Le ramassage des objects donnent des points via cette partie
def collision(type)
    case type
    when :cage
      @score += 50
      @sound_collect.play
    when :egg
     @score += 10
     @sound_Nocollect.play
    end

    true
  end


  def random_mouvement
    (rand(3) - 1)
  end

  def normalize(v, max)
    if v < 0
      0
    elsif v > max
      max
    else
      v
    end
  end

  def handle_quit
    if button_down? Gosu::KbEscape
      close
    end
  end

#gestion des ennemies
  def handle_enemies
    @enemies = @enemies.map do |enemy|
      enemy[:timer] ||= 0
      if enemy[:timer] == 0
        enemy[:result_x] = random_mouvement
        enemy[:result_y] = random_mouvement
        enemy[:timer] = 50 + rand(50)
      end
      enemy[:timer] -= 1

      new_enemy = enemy.dup
      new_enemy[:x] += new_enemy[:result_x] * @speed
      new_enemy[:y] += new_enemy[:result_y] * @speed
      new_enemy[:x] = normalize(new_enemy[:x], WINDOW_X - SPRITE_SIZE)
      new_enemy[:y] = normalize(new_enemy[:y], WINDOW_Y - SPRITE_SIZE)
      unless collision?(new_enemy, @flag)
        enemy = new_enemy
      end
      enemy
    end
  end
end
