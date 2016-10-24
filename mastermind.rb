class GameBoard
  @@COLORS = "ROYGBP".chars

  def self.random_code
    code = []
    4.times do code << @@COLORS[rand(0...@@COLORS.size)] end

    #p code #for debugging purposes
    return code
  end
  def self.valid_input?(input)
    input.size == 4 && input.chars.all? { |char| char.match(/[ROYGBP]/) != nil } ? true : false
  end

  def initialize(player, code = nil)
    @code = code ||= GameBoard.random_code
    @player = player
    @turn = 1
    @guess_row = []
    @hints_recieved = []
    @board = {row1: [".", ".", ".", "."],
              row2: [".", ".", ".", "."],
              row3: [".", ".", ".", "."],
              row4: [".", ".", ".", "."],
              row5: [".", ".", ".", "."],
              row6: [".", ".", ".", "."],
              row7: [".", ".", ".", "."],
              row8: [".", ".", ".", "."],
              row9: [".", ".", ".", "."],
              row10: [".", ".", ".", "."],
              row11: [".", ".", ".", "."],
              row12: [".", ".", ".", "."]}
  end
  def start_loop
    if @player == "guesser"
      show_board
      while game_over? == false
        if guess(gets.chomp.upcase) == true
          show_board
        else
          puts 'Choose 4 colors'
          puts 'Your options are: (R)ed, (O)range, (Y)ellow, (G)reen, (B)lue, and (P)urple'
          puts 'Duplicates are allowed'
        end
      end
    else
      @possible_inputs = []

      @@COLORS.each do |r|
        @@COLORS.each do |g|
          @@COLORS.each do |b|
            @@COLORS.each do |y|
              @possible_inputs << "#{r}#{g}#{b}#{y}".split(//)
            end
          end
        end
      end
      @all_possible_inputs = @possible_inputs.map {|x| x}
      @peg_combos = [[0,0],[1,0],[2,0],[3,0],[4,0],[0,1],[1,1],[2,1],[3,1],[0,2],[1,2],[2,2],[0,3],[1,3],[0,4]]

      while game_over? == false
        #guess(GameBoard.random_code.join)
        perfect_guess
        show_board
        sleep 0.5
      end
    end
  end
  def guess(input)
    @current_row = "row#{@turn}".to_sym
    success = false
    if GameBoard.valid_input?(input)
      @board[@current_row] = input.chars
      show_hint
      success = true
      if @all_possible_inputs
        @all_possible_inputs.select! {|e| e != input.split(//)}
      end
    end
    @turn += 1 unless success == false #turn incremented here
    success ? (return true) : (return false)
  end
  def clever_guess #not used
    if @turn == 1
      guess("RROO")
    else
      @previous_row = @turn - 2
      last_hint_recieved = @hints_recieved[@previous_row]

      @possible_inputs.select! {|pi| give_hint(pi) != last_hint_recieved}
      puts 'Possibilities left: ' + @possible_inputs.length.to_s
      guess(@possible_inputs[rand(0...@possible_inputs.length)].join)
    end
  end
  def very_clever_guess
    if @turn == 1
      guess("RROO")
    else
      @previous_row = @turn - 2
      last_hint_recieved = @hints_recieved[@previous_row]

      @possible_inputs.select! {|pi| give_hint(pi) != last_hint_recieved}
      puts 'Possibilities left: ' + @possible_inputs.length.to_s

      #TODO base guess on previous best guess

      case last_hint_recieved[0]
      when 0
        i = rand(0..3)
        j = rand(0..3)
        k = rand(0..3)
        l = rand(0..3)
        while i == j
          j = rand(0..3)
        end
        while j == k
          k = rand(0..3)
        end
        while k == l
          l = rand(0..3)
        end
        better_guesses = @possible_inputs.select {|pi| pi[i] != @board[@current_row][i]}
        better_guesses.select! {|pi| pi[j] != @board[@current_row][j]}
        better_guesses.select! {|pi| pi[k] != @board[@current_row][k]}
        better_guesses.select! {|pi| pi[k] != @board[@current_row][l]}
        better_guesses != [] ? guess(better_guesses[rand(0...better_guesses.length)].join) : guess(@possible_inputs[rand(0...@possible_inputs.length)].join)
      when 1
        i = rand(0..3)
        better_guesses = @possible_inputs.select {|pi| pi[i] == @board[@current_row][i]}
        better_guesses != [] ? guess(better_guesses[rand(0...better_guesses.length)].join) : guess(@possible_inputs[rand(0...@possible_inputs.length)].join)
      when 2
        loop_success = false
        while loop_success == false
          i = rand(0..3)
          j = rand(0..3)
          while i == j
            j = rand(0..3)
          end
          better_guesses = @possible_inputs.select {|pi| pi[i] == @board[@current_row][i]}
          better_guesses.select! {|pi| pi[j] == @board[@current_row][j]}
          if better_guesses != []
            guess(better_guesses[rand(0...better_guesses.length)].join)
            loop_success = true
          end
        end
      else
        loop_success = false
        while loop_success == false
          i = rand(0..3)
          j = rand(0..3)
          k = rand(0..3)
          while i == j
            j = rand(0..3)
          end
          while j == k
            k = rand(0..3)
          end
          better_guesses = @possible_inputs.select {|pi| pi[i] == @board[@current_row][i]}
          better_guesses.select! {|pi| pi[j] == @board[@current_row][j]}
          better_guesses.select! {|pi| pi[k] == @board[@current_row][k]}
          if better_guesses != []
            guess(better_guesses[rand(0...better_guesses.length)].join)
            loop_success = true
          end
        end
      end
    end
  end
  def perfect_guess
    if @turn < 9
      very_clever_guess
    else
      maximums = []
      combined_values = []
      best_guess = nil

      @previous_row = @turn - 2
      last_hint_recieved = @hints_recieved[@previous_row]

      @possible_inputs.select! {|pi| give_hint(pi) != last_hint_recieved}
      puts 'Possibilities left: ' + @possible_inputs.length.to_s

      i = 1
      @all_possible_inputs.each do |pi|
        not_rm = []
        hint_outcomes = {}
        #find number of eliminated for each possible outcome of an unguessed combo
        @possible_inputs.each do |pie|
          key = give_hint(pi, pie) #if pie was code then what hint would pi give?
          if hint_outcomes[key].nil?
            hint_outcomes[key] = []
          end
          hint_outcomes[key] << pie
        end
        #find worst case scenario for each combo
        @peg_combos.each do |combo|
          #longer length means less eliminated outcomes for that scenario
          hint_outcomes[combo] ? not_rm << hint_outcomes[combo].length : not_rm << 0
        end
        min_elim = @possible_inputs.length - not_rm.sort[-1]
        maximums << min_elim
        combined_values << [pi, min_elim]
        if i % 130 == 0 then print "* " end
        i += 1
      end

      best_guess_value = maximums.sort[0]
      list_of_best_guesses = combined_values.select { |e| e[1] == best_guess_value }
      puts 'Number of equally useful guesses: ' + list_of_best_guesses.length.to_s
      list_of_best_guesses.each do |g|
        g_array = g[0..3][0]
        @possible_inputs.each do |j|
          if j == g_array
            best_guess = best_guess ||= g_array
          end
        end
      end
      
      best_guess != nil ? guess(best_guess.join) : very_clever_guess
    end
  end
  def find_exact_matches(guess_to_check, code)
    perfect_guesses = 0
    incorrect_guesses = []
    unguessed = []

    i = 0
    #Counts number of perfect guesses
    #Creates an an array of incorrect guesses
    #Creates an array of missed matches
    guess_to_check.each do |char|
      char == code[i] ? perfect_guesses += 1 : incorrect_guesses << char && unguessed << code[i]
      i += 1
    end
    found_matches = {perfect: perfect_guesses, incorrect: incorrect_guesses, unguessed: unguessed}
  end
  def number_of_good_guesses(incorrect_guesses, unguessed)
    good_guesses = 0
    #counts number of good guesses
    incorrect_guesses.each do |g|
      if unguessed.any? {|char| char == g}
        good_guesses += 1
        index = unguessed.index(g)
        unguessed.delete_at(index)
      end
    end
    good_guesses
  end
  def give_hint(input = @board[@current_row], code = @code)
    matches = find_exact_matches(input, code)

    perfect_guesses = matches[:perfect]
    incorrect_guesses = matches[:incorrect]
    unguessed = matches[:unguessed]

    good_guesses = number_of_good_guesses(incorrect_guesses, unguessed)
    hint = [perfect_guesses, good_guesses]
    #returned value
    hint
  end
  def show_hint
    @hints_recieved << give_hint
    perfect_guesses = @hints_recieved[@turn-1][0]
    good_guesses = @hints_recieved[@turn-1][1]

    if perfect_guesses == 4
      @win = true
      @guess_row << " Congratulations you guessed the code!"
    else
      @guess_row << " Perfect guesses: #{perfect_guesses} Good guesses: #{good_guesses}"
    end
  end
  def show_board
    i = 0
    @board.keys.each do |row|
      print "\n #{@board[row].join(" ")}"
      if @board[row][0] != "."
        print @guess_row[i]
      end
      i += 1
    end
    print "\n"
  end
  def game_over?
    #check if player won
    if @win == true
      puts " Game Over: You win!"
      return true
    end
    #check if player lost
    if @turn > 12
      puts " Game Over: You ran out of attempts!"
      return true
    else
      return false
    end
  end
end

gb = nil

puts "Would you like to play as mastermind or guesser (M/G)?"
while user_input = gets.chomp.upcase
  case user_input
  when "M"
    puts "Enter your code:"
    while user_input = gets.chomp.upcase
      if GameBoard.valid_input?(user_input)
        gb = GameBoard.new("mastermind", user_input)
        break
      else
        puts 'Choose 4 colors'
        puts 'Your options are: (R)ed, (O)range, (Y)ellow, (G)reen, (B)lue, and (P)urple'
        puts 'Duplicates are allowed'
      end
    end
    break
  when "G"
    gb = GameBoard.new("guesser")
    break
  else
    puts "Please type either (M) or (G)"
  end
end

gb.start_loop