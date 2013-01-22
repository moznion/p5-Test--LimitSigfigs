#!perl

use strict;
use warnings;
use utf8;
use Test::LimitSigfigs;

BEGIN {
    use Test::Exception;
    use Test::More tests => 9;
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

    $got = Test::LimitSigfigs::_limit_value( $target, 1 );
    $expected = '100';
    is( $got, $expected,
        'Limiting sigfigs is smaller than integer digits - 1' );

    $got = Test::LimitSigfigs::_limit_value( $target, 2 );
    $expected = '120';
    is( $got, $expected,
        'Limiting sigfigs is smaller than integer digits - 2' );

    $target   = '125';
    $got      = Test::LimitSigfigs::_limit_value( $target, 2 );
    $expected = '130';
    is( $got, $expected,
        'Limiting sigfigs is smaller than integer digits - 3' );

    $target   = '1994';
    $got      = Test::LimitSigfigs::_limit_value( $target, 2 );
    $expected = '2000';
    is( $got, $expected,
        'Limiting sigfigs is smaller than integer digits - 4' );
};

subtest 'Only decimal part - 1' => sub {
    $target = '0.12345';

    $expected = '0.12345';
    $got = Test::LimitSigfigs::_limit_value( $target, 5 );
    is( $got, $expected, 'Normal' );

    $expected = '0.123450';
    $got = Test::LimitSigfigs::_limit_value( $target, 6 );
    is( $got, $expected, 'Limiting sigfigs is bigger than decimal digits' );

    $expected = '0.1235';
    $got = Test::LimitSigfigs::_limit_value( $target, 4 );
    is( $got, $expected, 'Limiting sigfigs is smaller than decimal digits' );

    $target = '0.99';
    $got = Test::LimitSigfigs::_limit_value( $target, 1 );
    $expected = '1';
    is( $got, $expected );
};

subtest 'Only decimal part - 2' => sub {
    $target = '0.0012345';

    $expected = '0.0012345';
    $got = Test::LimitSigfigs::_limit_value( $target, 5 );
    is( $got, $expected, 'Normal' );

    $expected = '0.00123450';
    $got = Test::LimitSigfigs::_limit_value( $target, 6 );
    is( $got, $expected, 'Limiting sigfigs is bigger than decimal digits' );

    $expected = '0.001235';
    $got = Test::LimitSigfigs::_limit_value( $target, 4 );
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

    $expected = '123.457';
    $got = Test::LimitSigfigs::_limit_value( $target, 6 );
    is( $got, $expected, 'Limiting sigfigs is smaller than all of digits' );

    $expected = '123';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Limiting sigfigs equals integer digits' );

    $expected = '120';
    $got = Test::LimitSigfigs::_limit_value( $target, 2 );
    is( $got, $expected, 'Limiting sigfigs is smaller than integer digits' );

    $target   = '125.4567';
    $expected = '130';
    $got      = Test::LimitSigfigs::_limit_value( $target, 2 );
    is( $got, $expected, 'Limiting sigfigs is smaller than integer digits' );

    $target   = '125.5';
    $expected = '126';
    $got      = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected );

    $target   = '125.95';
    $expected = '126.0';
    $got      = Test::LimitSigfigs::_limit_value( $target, 4 );
    is( $got, $expected );

    $target   = '125.995';
    $expected = '126.00';
    $got      = Test::LimitSigfigs::_limit_value( $target, 5 );
    is( $got, $expected );

};

subtest 'Combination of integer and decimal part - 2' => sub {
    $target = '123.004567';

    $expected = '123.004567';
    $got = Test::LimitSigfigs::_limit_value( $target, 9 );
    is( $got, $expected, 'Normal' );

    $expected = '123.0045670';
    $got = Test::LimitSigfigs::_limit_value( $target, 10 );
    is( $got, $expected, 'Limiting sigfigs is bigger than all of digits' );

    $expected = '123.00457';
    $got = Test::LimitSigfigs::_limit_value( $target, 8 );
    is( $got, $expected, 'Limiting sigfigs is smaller than all of digits' );

    $expected = '123';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Limiting sigfigs equals integer digits' );

    $expected = '120';
    $got = Test::LimitSigfigs::_limit_value( $target, 2 );
    is( $got, $expected, 'Limiting sigfigs is smaller than integer digits' );

    $target   = '125.004567';
    $expected = '130';
    $got      = Test::LimitSigfigs::_limit_value( $target, 2 );
    is( $got, $expected, 'Limiting sigfigs is smaller than integer digits' );

    $expected = '125';
    $got = Test::LimitSigfigs::_limit_value( $target, 3 );
    is( $got, $expected, 'Limiting sigfigs is smaller than integer digits' );
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

subtest 'In case of zero' => sub {
    $target = '0';

    $expected = '0';
    $got = Test::LimitSigfigs::_limit_value( $target, 1 );
    is( $got, $expected, 'Limiting sigfigs zero - 1' );

    $expected = '0.0';
    $got = Test::LimitSigfigs::_limit_value( $target, 2 );
    is( $got, $expected, 'Limiting sigfigs zero - 2' );

    $expected = '0.0000';
    $got = Test::LimitSigfigs::_limit_value( $target, 5 );
    is( $got, $expected, 'Limiting sigfigs zero - 3' );
};

subtest 'Exceptional' => sub {
    $target = '1';
    dies_ok { Test::LimitSigfigs::_limit_value( $target, 0 ) }
    'Number of limiting digits is zero.';
};

done_testing;
