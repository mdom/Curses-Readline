package Curses::Readline;

use strict;
use warnings;
use parent 'Exporter';
use Curses;

our @EXPORT_OK = 'curses_readline';

sub curses_readline {
    my ($prefix) = @_;
    $prefix //= ':';

    my $buffer        = '';
    my $cursor_pos    = 0;
    my $buffer_offset = 0;

    my ( $lines, $columns );
    getmaxyx( $lines, $columns );
    move( $lines + 1, $columns );
    addstring( $lines - 1, 0, ":" );

    my $half_width = int( $columns / 2 );

    while (1) {

        ## cursor_pos and buffer_offset are zero-based, columns
        ## start at one!
        if ( $cursor_pos + 1 >= $columns ) {
            $buffer_offset += $half_width - 1;
            $cursor_pos = length($buffer) - $buffer_offset;
        }
        elsif ( $cursor_pos < 0 ) {
            if ( $buffer_offset != 0 ) {
                $buffer_offset -= $half_width - 1;
                $cursor_pos = $half_width - 2;
            }
            else {
                $cursor_pos = 0;
            }
        }

        addstring( $lines - 1, 0,
            "$prefix" . substr( $buffer, $buffer_offset, $columns - 1 ) );
        clrtoeol;
        move( $lines - 1, $cursor_pos + 1 );
        refresh;

        my $c = getch;
        if ( $c eq "\cG" ) {
            $buffer = undef;
            last;
        }
        elsif ( $c eq "\n" ) {
            last;
        }
        elsif ( $c eq KEY_LEFT ) {
            $cursor_pos--;
        }
        elsif ( $c eq KEY_RIGHT ) {
            next if $cursor_pos == length($buffer) - $buffer_offset;
            $cursor_pos++;
        }
        elsif ( $c eq KEY_HOME || $c eq "\cA" ) {
            $cursor_pos    = 0;
            $buffer_offset = 0;
        }
        elsif ( $c eq "\cK" ) {
            substr( $buffer, $buffer_offset + $cursor_pos ) = '';
        }
        elsif ( $c eq KEY_END || $c eq "\cE" ) {
            my $l = length($buffer);
            if ( $l >= $columns ) {
                $buffer_offset = $l - $columns + 2;
                $cursor_pos    = $columns - 2;
            }
            else {
                $cursor_pos = $l;
            }
        }
        elsif ( $c eq KEY_BACKSPACE ) {
            next if $buffer_offset == 0 && $cursor_pos == 0;
            $cursor_pos--;
            substr( $buffer, $buffer_offset + $cursor_pos, 1 ) = '';
        }
        elsif ( $c eq "\cD" ) {
            substr( $buffer, $buffer_offset + $cursor_pos, 1 ) = '';
        }
        else {
            substr( $buffer, $buffer_offset + $cursor_pos, 0 ) = $c;
            $cursor_pos++;
        }
    }
    move( $lines - 1, 0 );
    clrtoeol;
    return $buffer;
}

1;
