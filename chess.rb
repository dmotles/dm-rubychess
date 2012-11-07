# A simple multiplayer Chess game
# Daniel Motles <seltom.dan@gmail.com>
#
# THIS IS MY FIRST RUBY PROGRAM EVER!!!1111 (i.e. please don't judge, rubyists...)
# All requirements should be met... 
#
# Additional "Features" added for fun:
# - Chess pieces have an associated "side", i.e. a White player cannot move black piceces
# - NETWORKED MULTIPLAYER (or a hilariously ghetto attempt at it)!
#   - Start with -listen <PORT> as the server and you can either connect with telnet or use -connect <IP> <PORT> with this code.

require 'socket'
require 'ipaddr'

WHITE = 'w'
BLACK = 'b'

# stdin/out globals (i believe I said not to judge. FIRST RUBY PROGRAM, remember?)
$cur_out = STDOUT
$cur_in = STDIN

# An Exception class that is thrown when one of my chess classes
# are instantiated with invalid inputs
class ChessError < RuntimeError
    attr :err_what

    def initialize( input )
        @err_what = input
    end
end

# Represents a chess square on the board. Based on its position, it
# will place the correct chess piece in itself when its initialized.
class ChessSquare
    attr_accessor :piece
    attr_reader :row, :col

    def initialize( pos )
        col = pos[0].chr
        row = pos[1].chr

        if not ('a'..'h').include?( col ) or not ('0'..'8').include?( row )
            raise ChessError.new( pos + ' is an invalid address for a chess square.' )
        end

        @row = row
        @col = col

        if '1'.eql?( row )
            @piece = init_piece( WHITE )
        elsif '2'.eql?( row )
            @piece = Pawn.new( WHITE, self )
        elsif '7'.eql?( row )
            @piece = Pawn.new( BLACK, self )
        elsif '8'.eql?( row )
            @piece = init_piece( BLACK )
        else
            @piece = nil
        end
    end

    def to_s
        s = ''
        if @piece.nil?
            s = '-'
        else
            s = @piece.to_s
        end
        s
    end

    def empty?
        @piece.nil?
    end

    private

    def init_piece( side )
        p = ''
        if ['a','h'].include?( col )
            p = Rook.new( side, self )
        elsif ['b','g'].include?(col)
            p = Knight.new( side, self )
        elsif ['c','f'].include?(col)
            p = Bishop.new( side, self )
        elsif 'd'.eql?( col )
            p = King.new( side, self )
        elsif 'e'.eql?( col )
            p = Queen.new( side, self )
        end

        p
    end
end


# Superclass for all chess pieces
# This should probably not be directly instantiated. ever.
class ChessPiece
    attr_reader :side, :square
    def initialize( side, square )
        if not [ WHITE, BLACK ].include?( side )
            raise new ChessError.new( side + " is an invalid side! 'w' and 'b' are the only valid sides!" )
        end
        @side = side
        @square = square
    end

    def to_s
        '?'
    end

    def is_white?
        @side == 'w'
    end

    def is_black?
        @side == 'b'
    end

    def move!( side, dest_square )
        if @side.eql?(side)
            @square.piece = nil
            @square = dest_square
            @square.piece = self
            true
        else
            $cur_out.puts "You do not own the #{self.to_s} at #{@square.col}#{@square.row}"
            false
        end
    end
end

# Rook Subclass
# My idea was to actually implement Chess rules at some point but I decided
# to mess with the sockets instead.
class Rook < ChessPiece
    def to_s
        'R'
    end
end

# Pawn Subclass
class Pawn < ChessPiece
    def to_s
        'P'
    end
end

# Knight subclass
class Knight < ChessPiece
    def to_s
        'N'
    end
end

# Bishop subclass
class Bishop < ChessPiece
    def to_s
        'B'
    end
end

# king subclass
class King < ChessPiece
    def to_s
        'K'
    end
end

# Queen subclass
class Queen < ChessPiece
    def to_s
        'Q'
    end
end

# Represents chess board. Holds hash of chess squares.
class ChessBoard
    COLRANGE = 'a'..'h'
    ROWRANGE = 1..8
    def initialize
        @board = Hash.new
        COLRANGE.each do |col|
            ROWRANGE.each do |row|
                pos = col + row.to_s
                @board[ pos ] = ChessSquare.new( pos )
            end
        end
    end

    def board
        @board
    end

    def to_s
        s = '  '
        COLRANGE.each do |col|
            s << '%-2s' % col
        end

        s << "\n"

        ROWRANGE.each do |row|
            s << '%-2s' % row
            COLRANGE.each do |col|
                pos = col + row.to_s
                s << '%-2s' % @board[pos].to_s
            end
            s << "\n"
        end

        s
    end

    def empty?
        empty = true
        @board.each do |k,v|
            if not v.empty?
                empty = false
                break
            end
        end
        empty
    end

    def has_white_pieces? # not used.. was going to be used for real chess rules
        has_white = false
        @board.each do |k,v|
            if not v.empty? and v.piece.is_white?
                has_white = true
                break
            end

        end
        has_white
    end

    def has_black_pieces? # not used.. same as above
        has_black = false
        @board.each do |k,v|
            if not v.empty? and v.piece.is_black?
                has_black = true
                break
            end
        end
        has_black
    end


    def move_piece!( side, target, dest )
        if not @board[ target ].empty?
            @board[target].piece.move!( side, @board[dest] )
        else
            $cur_out.puts "There is no piece at #{target}"
            false
        end
        # move piece hurr
    end
end

$cb = ChessBoard.new

# Connection Variables
$listen_mode = false
connect_mode = false
port = 0
address = 'localhost'
$sock = nil

def prompt(side)
    if side == WHITE
        $cur_out.printf "(Player %s) Enter a move: " , "WHITE"
        input = $cur_in.gets
    else
        $cur_out.printf "(Player %s) Enter a move: " , "BLACK"
        input = $cur_in.gets
    end
end

def display_board
    puts '',$cb.to_s,''
    $sock.puts '',$cb.to_s,'' if $listen_mode
end




# Basic arg parsing (THERE HAS TO BE A BETTER WAY)
ARGV.each do |arg|
    if '-listen'.eql?(arg) and not connect_mode
        $listen_mode = true
    elsif '-connect'.eql?(arg) and not $listen_mode
        connect_mode = true
    elsif not arg.match( /^\d+$/ ).nil?
        $port = arg
        puts "Using #{arg} as the port number." if connect_mode or $listen_mode
    else
        address = arg
        puts "Using #{arg} as the target connection address." if connect_mode
    end
end

if connect_mode
    #IM SO LAZY
    #This is why the top comment says use telnet... I SAID NO JUDGING. FIRST. RUBY. PROGRAM.
    exec("/usr/bin/env", "telnet", address, $port )
elsif $listen_mode
    puts "Starting Chess in SERVER Mode!"
    server = TCPServer.new( $port )
    saddr = server.addr
    puts "Instruct client to connect to #{saddr.join(':')}"
    $sock = server.accept
    puts "Connection recieved! Starting game!"
end


######################
# Main Game Loop
######################
cur_side = WHITE

display_board()
$sock.puts "Please wait while the other side makes a move... STANDBY FOR GOD SAKES DONT TYPE ANYTHING." if $listen_mode
until $cb.empty?
    move = prompt(cur_side)
    match = move.match(/^\s*(?:([a-h][1-8])\s+([a-h][1-8])|(quit)|(exit))\s*$/)

    # YUCK YUCK YUCK THIS BLOCK IS SOOOOOOooooo UGLY
    if match.nil?
        $cur_out.puts "Invalid Move! Reminder: Please enter both the square you are moving FROM and square you are moving TO. EX:c2 b4."
    else
        if match[2].nil?
            if match[3].eql?('quit') or match[4].eql?('exit')
                if $listen_mode
                    if cur_side == BLACK
                        puts "Goodbye! The client has decided to end the game."
                        $sock.puts "Goodbye! Closing connection"
                    else
                        puts "Goodbye!"
                        $sock.puts "Goodbye! The server has decided to end the game! Closing connection."
                    end
                    $sock.close
                else
                    puts "Goodbye!"
                end
                exit
            else
                $cur_out.puts "Invalid Move! Reminder: Valid columns are a through h and valid rows are 1 thru 8. You need a target and destination square."
            end
        elsif $cb.move_piece!( cur_side, match[1], match[2] ) #success!
            display_board
            if cur_side == WHITE
                cur_side = BLACK
                if $listen_mode
                    $cur_in = $sock
                    $cur_out = $sock
                    puts "Please wait while the other side makes a move... STANDBY FOR GOD SAKES DONT TYPE ANYTHING."
                end
            else
                cur_side = WHITE
                if $listen_mode
                    $cur_in = STDIN
                    $cur_out = STDOUT
                    $sock.puts "Please wait while the other side makes a move... STANDBY FOR GOD SAKES DONT TYPE ANYTHING."
                end
            end
        else #failure :(
            $cur_out.puts "Move failed. Try again."
        end
    end
end
