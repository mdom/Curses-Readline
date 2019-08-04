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

@input = ( qr/^:@/, 'q' );

$rc = curses_readline();
is( $rc, '' );

@input =
  ( 'a', 'b', 'c', 'd', 'e', 'f', qr/^:abcdef@/, KEY_LEFT, qr/^:abcde\@f/,
    'q' );

$rc = curses_readline();
is( $rc, 'abcdef' );

done_testing;

1;
