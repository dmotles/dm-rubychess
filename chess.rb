WHITE = 'w'
BLACK = 'b'

class ChessError < RuntimeError
    attr :err_what

    def initialize( input )
        @err_what = input
    end
end

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
            puts "You do not own the #{self.to_s} at #{@square.col}#{@square.row}"
            false
        end
    end
end

class Rook < ChessPiece
    def to_s
        'R'
    end
end

class Pawn < ChessPiece
    def to_s
        'P'
    end
end

class Knight < ChessPiece
    def to_s
        'N'
    end
end

class Bishop < ChessPiece
    def to_s
        'B'
    end
end

class King < ChessPiece
    def to_s
        'K'
    end
end

class Queen < ChessPiece
    def to_s
        'Q'
    end
end

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

    def has_white_pieces?
        has_white = false
        @board.each do |k,v|
            if not v.empty? and v.piece.is_white?
                has_white = true
                break
            end

        end
        has_white
    end

    def has_black_pieces?
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
            puts "There is no piece at #{target}"
            false
        end
        # move piece hurr
    end
end


def prompt(side)
    printf "(Player %s) Enter a move: " , ( side == WHITE ) ? "WHITE" : "BLACK"
    input = gets
end

cb = ChessBoard.new
cur_side = WHITE

puts '',cb.to_s,''
until cb.empty?
    move = prompt(cur_side)
    match = move.match(/^\s*(?:([a-h][1-8])\s+([a-h][1-8])|(quit)|(exit))\s*$/)
    if match.nil? or (match.captures.size < 2)
        if not match.nil? and (match[1].eql?('quit') or match[1].eql?('exit'))
            puts Goodbye!
            break
        else
            puts "Unrecognized move! Please enter the position you want to move from to where like 'c2 b4'."
        end
    else
        if cb.move_piece!( cur_side, match[1], match[2] ) #success!
            if cur_side == WHITE
                cur_side = BLACK
            else
                cur_side = WHITE
            end
            puts '',cb.to_s,''
        else #failure :(
            puts "Invalid move. Try again."
        end
    end
end
