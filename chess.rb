class ChessPiece
    attr_accessor :side

    def initialize( row )
        if( row < 4 ):
            @side = 'w'
        else
            @side = 'b'
        end
    end
end

class King < ChessPiece
    def to_s
        return 'K'
    end
end

class Queen < ChessPiece
    def to_s
        return 'Q'
    end
end

class Knight < ChessPiece
    def to_s
        return 'N'
    end
end

class Bishop < ChessPiece
    def to_s
        return 'B'
    end
end

class Rook < ChessPiece
    def to_s
        return 'R'
    end
end

class Pawn < ChessPiece
    def to_s
        return 'P'
    end
end

class ChessBoard
    def initialize
        @board = Array.new( 8 ) { |i| init_row(i) }
    end

    def board
        @board
    end

    def to_s
        s = String.new
        @board.each { |index| 
            s += index.to_s
        }
        s
    end

    def move!( col, row, target_col, target_row )
        # move piece hurr
    end

    private

    def init_row( row )
        if ( row == 1 or row == 8 ):
            return [
                'a' => Rook.new(row),
                'b' => Knight.new(row),
                'c' => Bishop.new(row),
                'd' => King.new(row),
                'e' => Queen.new(row),
                'f' => Bishop.new(row),
                'g' => Knight.new(row),
                'h' => Rook.new(row)
            ]
        elsif ( row == 2 or row == 7 ):
            newrow = Hash.new
            ('a'..'h').each { |letter|
                newrow[ letter ] = Pawn.new(row)
            }
            return newrow
        else
            newrow = Hash.new
            ('a'..'h').each { |letter|
                newrow[ letter ] = nil
            }
            return newrow
        end
    end
end


cb = ChessBoard.new
