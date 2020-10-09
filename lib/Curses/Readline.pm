package Curses::Readline;

use 5.010;
use strict;
use warnings;
use parent 'Exporter';
use Curses;

our @EXPORT_OK = 'curses_readline';

our $VERSION = '0.9';

sub curses_readline {
    my ( $prefix, $line, $column ) = @_;
    $prefix //= ':';

    my $buffer        = '';
    my $buffer_offset = 0;

    my ( $lines, $columns );
    getmaxyx( $lines, $columns );

    my $max_columns = $columns;

    ## TODO lenght() is wrong for non-ascii characters;
    ## to compute display length, just insert it into a pad and
    ## check how much the cursor moved.

    my $left_pad  = length($prefix);
    my $right_pad = 1;                 # for cursor

    my $max_display  = $max_columns - $left_pad - $right_pad;
    my $half_display = int( $max_display / 2 );

    while (1) {

        my $substr_start = 0;

		if ( $buffer_offset < 0 )  {
			$buffer_offset = 0;
		}

        if ( $buffer_offset > $max_display ) {
            $substr_start =
              int( $buffer_offset / $half_display ) * $half_display -
              $half_display - 1 -
              ( $half_display % 2 );
        }

        my $cursor_pos = $buffer_offset - $substr_start;

        addstring( $lines - 1, 0,
            $prefix . substr( $buffer, $substr_start, $max_display ) );
        clrtoeol;

        move( $lines - 1, $cursor_pos + $left_pad );

        my $c = getchar();

        if ( $c eq "\cG" ) {
            $buffer = undef;
            last;
        }
        elsif ( $c eq "\n" ) {
            last;
        }
        elsif ( $c eq KEY_LEFT ) {
            $buffer_offset--;
        }
        elsif ( $c eq KEY_RIGHT ) {
            next if $buffer_offset == length($buffer);
            $buffer_offset++;
        }
        elsif ( $c eq KEY_HOME || $c eq "\cA" ) {
            $buffer_offset = 0;
        }
        elsif ( $c eq "\cK" ) {
            substr( $buffer, $buffer_offset ) = '';
        }
        elsif ( $c eq KEY_END || $c eq "\cE" ) {
            $buffer_offset = length($buffer);
        }
        elsif ( $c eq KEY_BACKSPACE ) {
            next if $buffer_offset == 0;
            substr( $buffer, $buffer_offset - 1, 1 ) = '';
            $buffer_offset--;
        }
        elsif ( $c eq "\cD" ) {
            substr( $buffer, $buffer_offset, 1 ) = '';
        }
        else {
            substr( $buffer, $buffer_offset, 0 ) = $c;
            $buffer_offset++;
        }
    }
    move( $lines - 1, 0 );
    clrtoeol;
    refresh;
    return $buffer;
}

1;

__END__

=pod

=head1 NAME

Curses::Readline - Readline library for curses

=head1 SYNOPSIS

	use Curses::Readline qw(curses_readline);
	use Curses;

	initscr;
	curses_readline;
	endwin;

=head1 DESCRIPTION

This library provides a way to query a user for a line with
readline-like key bindings in a curses windows. It behaves similar to
the command line in mutt or vi.

The prompt is displayed on the last line of the curses window, which
will be emptied on a call to I<curses_readline()>.

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Mario Domgoergen C<< <mario@domgoergen.com> >>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
