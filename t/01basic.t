#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use Test::More;
use Curses::Readline 'curses_readline';
use Curses;

my $columns = 10;
my $rows    = 1;

my $rc;
my @input;
my $buffer = ' ' x 100;

{
    no warnings 'redefine';

    *Curses::Readline::getmaxyx = sub {
        $_[0] = $rows;
        $_[1] = $columns;
    };

    *Curses::Readline::clrtoeol = sub {
    };

    *Curses::Readline::addstring = sub {
        $buffer = ' ' x 100;
        substr( $buffer, $_[1], 0 ) = $_[2];
    };

    *Curses::Readline::getch = sub {
        my $val = shift @input;
        if ( ref($val) eq 'Regexp' ) {
            like( $buffer, $val );
            return shift @input;
        }
        return $val;
    };

    *Curses::Readline::move = sub {
        $buffer =~ s/@//;
        substr( $buffer, $_[1], 0 ) = '@';
    };
}

@input = ( qr/^:@/, "\n" );

is( curses_readline(), '' );

@input = ( 'abcdef', qr/^:abcdef@/, KEY_LEFT, qr/^:abcde\@f/, '12', "\n" );

is( curses_readline(), 'abcde12f' );

@input = ( 'The quick brown fox jumps over the lazy dog', "\n" );

is( curses_readline(), 'The quick brown fox jumps over the lazy dog' );

done_testing;

1;
