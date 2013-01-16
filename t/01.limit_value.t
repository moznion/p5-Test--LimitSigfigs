#!perl

use strict;
use warnings;
use utf8;
use Test::LimitSigfigs;

BEGIN {
    use Test::Exception;
    use Test::More tests => 8;
}

my ( $target, $expected, $got );

subtest 'Only integer part' => sub {
    $target = '123';

    $expected = '123';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Normal' );

    $got = Test::LimitSigfigs::_limit_value( $target, 4 );
    $expected = '123.0';
    is( $got, $expected, 'Limiting sigfigs is bigger than integer digits' );

    dies_ok { Test::LimitSigfigs::_limit_value( $target, 2 ) }
    'Limiting sigfigs is smaller than integer digits';
};

subtest 'Only decimal part - 1' => sub {
    $target = '0.1234';

    $expected = '0.1234';
    $got = Test::LimitSigfigs::_limit_value( $target, 4 );
    is( $got, $expected, 'Normal' );

    $expected = '0.12340';
    $got = Test::LimitSigfigs::_limit_value( $target, 5 );
    is( $got, $expected, 'Limiting sigfigs is bigger than decimal digits' );

    $expected = '0.123';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Limiting sigfigs is smaller than decimal digits' );
};

subtest 'Only decimal part - 2' => sub {
    $target = '0.001234';

    $expected = '0.001234';
    $got = Test::LimitSigfigs::_limit_value( $target, 4 );
    is( $got, $expected, 'Normal' );

    $expected = '0.0012340';
    $got = Test::LimitSigfigs::_limit_value( $target, 5 );
    is( $got, $expected, 'Limiting sigfigs is bigger than decimal digits' );

    $expected = '0.00123';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Limiting sigfigs is smaller than decimal digits' );
};

subtest 'Combination of integer and decimal part - 1' => sub {
    $target = '123.4567';

    $expected = '123.4567';
    $got = Test::LimitSigfigs::_limit_value( $target, 7 );
    is( $got, $expected, 'Normal' );

    $expected = '123.45670';
    $got = Test::LimitSigfigs::_limit_value( $target, 8 );
    is( $got, $expected, 'Limiting sigfigs is bigger than all of digits' );

    $expected = '123.456';
    $got = Test::LimitSigfigs::_limit_value( $target, 6 );
    is( $got, $expected, 'Limiting sigfigs is smaller than all of digits' );

    $expected = '123';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Limiting sigfigs equals integer digits' );

    dies_ok { Test::LimitSigfigs::_limit_value( $target, 2 ) }
    'Limiting sigfigs is smaller than integer digits';
};

subtest 'Combination of integer and decimal part - 2' => sub {
    $target = '123.004567';

    $expected = '123.004567';
    $got = Test::LimitSigfigs::_limit_value( $target, 9 );
    is( $got, $expected, 'Normal' );

    $expected = '123.0045670';
    $got = Test::LimitSigfigs::_limit_value( $target, 10 );
    is( $got, $expected, 'Limiting sigfigs is bigger than all of digits' );

    $expected = '123.00456';
    $got = Test::LimitSigfigs::_limit_value( $target, 8 );
    is( $got, $expected, 'Limiting sigfigs is smaller than all of digits' );

    $expected = '123';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Limiting sigfigs equals integer digits' );

    dies_ok { Test::LimitSigfigs::_limit_value( $target, 2 ) }
    'Limiting sigfigs is smaller than integer digits';
};

subtest 'Big number as exponent notation' => sub {
    $target = '1.23e+15';

    $expected = '1.23e+15';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Normal' );

    $expected = '1.2e+15';
    $got = Test::LimitSigfigs::_limit_value( $target, 2 );
    is( $got, $expected, 'Limiting sigfigs is smaller than all of digits' );

    $expected = '1.230e+15';
    $got = Test::LimitSigfigs::_limit_value( $target, 4 );
    is( $got, $expected, 'Limiting sigfigs is bigger than all of digits' );

    $expected = '1e+15';
    $got = Test::LimitSigfigs::_limit_value( $target, 1 );
    is( $got, $expected, 'Limiting sigfigs equals integer digits' );

};

subtest 'Small number as exponent notation' => sub {
    $target = '1.23e-15';

    $expected = '1.23e-15';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Normal' );

    $expected = '1.2e-15';
    $got = Test::LimitSigfigs::_limit_value( $target, 2 );
    is( $got, $expected, 'Limiting sigfigs is smaller than all of digits' );

    $expected = '1.230e-15';
    $got = Test::LimitSigfigs::_limit_value( $target, 4 );
    is( $got, $expected, 'Limiting sigfigs is bigger than all of digits' );

    $expected = '1e-15';
    $got = Test::LimitSigfigs::_limit_value( $target, 1 );
    is( $got, $expected, 'Limiting sigfigs equals integer digits' );
};

subtest 'Exceptional' => sub {
    $target   = '0';

    dies_ok {Test::LimitSigfigs::_limit_value( $target, 1 )}
    'Target of limiting is zero.';

    $target = '1';
    dies_ok {Test::LimitSigfigs::_limit_value( $target, 0 )}
    'Number of limiting digits is zero.';
};

done_testing;
