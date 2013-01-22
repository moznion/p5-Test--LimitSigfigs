package Test::LimitSigfigs;

use warnings;
use strict;
use utf8;
use Carp;
use Test::Builder;
use parent qw/Exporter/;

use vars qw/ $VERSION @EXPORT /;

BEGIN {
    $VERSION = '0.01';
    @EXPORT  = qw//;            # TODO implement.
}

my $test_builder           = Test::Builder->new;
my $default_num_of_sigfigs = 8; # TODO it should be considered.

sub import {
    my ($self) = shift;
    my $pack = caller;
    my $found = grep /num_of_sigfigs/, @_;

    if ($found) {
        my ( $key, $value ) = splice @_, 0, 2;

        if ( $value < 0 ) {
            croak 'Value of limit number of significant figures'
              . ' mest be a number greater than or equal to zero.';
        }
        unless ( $key eq 'num_of_sigfigs' ) {
            croak 'Test::LimitSigfigs option must be specified first.';
        }
        $default_num_of_sigfigs = $value;
    }

    $test_builder->exported_to($pack);
    $test_builder->plan(@_);
    $self->export_to_level( 1, $self, $_ ) for @EXPORT;
}

sub _separate_each_section {
    my ($value) = @_;

    my ( $num_section, $exponent ) = ( '', '' );

    # For exponent notation
    ( $num_section, $exponent ) = $value =~ m/(\d*\.?\d*)(e[\+\-]\d*)/;
    $num_section = $value unless $num_section;

    # Separate integer and decimal part
    my ( $integer_part, $decimal_part ) = $num_section =~ m/(\d*)\.?(\d*)?/;

    return ( $integer_part, $decimal_part, $exponent );
}

sub _round_only_integer {
    my ( $integer_part, $integer_digits, $num_of_sigfigs ) = @_;

    my $limited_value = substr( $integer_part, 0, $num_of_sigfigs );

    # Round off
    my $next_digit = substr( $integer_part, $num_of_sigfigs, 1 );
    if ($next_digit) {
        $limited_value++ if $next_digit > 4;
    }

    $limited_value .= '0' x ( $integer_digits - $num_of_sigfigs );
    return $limited_value;
}

sub _limit_sigfigs_zero {
    my ($num_of_sigfigs) = @_;

    my $limited_value = '0';
    if ( $num_of_sigfigs > 1 ) {
        $limited_value .= '.' . ( '0' x ( $num_of_sigfigs - 1 ) );
    }
    return $limited_value;
}

sub _limit_value {
    my ( $value, $num_of_sigfigs ) = @_;

    if ( $num_of_sigfigs <= 0 ) {
        croak 'Value of number of sigfigs must be '
          . 'a number greater than or equal to zero.';
    }

    # In case of only zero
    return _limit_sigfigs_zero($num_of_sigfigs) if $value == '0';

    # Separate each section.
    # Like so: {$integer_part}.{$decimal_part}[eE]{$exponent}
    my ( $integer_part, $decimal_part, $exponent ) =
      _separate_each_section($value);

    my ( $integer_digits, $limited_value ) = ( 0, 0 );

    # Integer Part
    if ($integer_part) {
        $integer_digits = length($integer_part);

        # Integer digits greater than limiting sigfigs digits.
        if ( $integer_digits > $num_of_sigfigs ) {
            return _round_only_integer( $integer_part, $integer_digits,
                $num_of_sigfigs );
        }

        $limited_value = substr( $integer_part, 0, $num_of_sigfigs );
    }

    # Decimal Part
    my $valid_decimal_digits = 0;
    if ($decimal_part) {
        my ( $zero_part, $valid_decimal_part ) = ( '', $decimal_part );

        # When integer part equals zero.
        unless ($integer_part) {
            ( $zero_part, $valid_decimal_part ) = $decimal_part =~ m/(0*)(\d*)/;
        }

        $valid_decimal_digits = length($valid_decimal_part);

        my $limited_decmal_part;
        my $limit_decimal_digits = $num_of_sigfigs - $integer_digits;
        if ($limit_decimal_digits > 0) {
            $limited_decmal_part = substr( $valid_decimal_part, 0, $limit_decimal_digits );

            if ( $valid_decimal_digits > $limit_decimal_digits ) {
                my $next_digit =
                substr( $valid_decimal_part, $limit_decimal_digits, 1 );
                if ($next_digit) {
                    my $limited_decimal_length = length($limited_decmal_part);
                    $limited_decmal_part++ if $next_digit > 4;
                    if (length($limited_decmal_part) > $limited_decimal_length) {
                        $limited_decmal_part =~ s/^\d//;
                        $limited_decmal_part = '0E0' if $limited_decmal_part eq '0';
                        $limited_value++;
                    }
                }
            }
        }
        elsif ($limit_decimal_digits == 0) {
            my $next_digit = substr( $valid_decimal_part, 0, 1 );
            if ($next_digit) {
                $limited_value++ if $next_digit > 4;
            }
        }

        if ($limited_decmal_part) {
            $limited_decmal_part = '0' if $limited_decmal_part eq '0E0';
            $limited_value .= '.' . $zero_part . $limited_decmal_part;
        }
    }

    # Append zero to be suitable for specified sigfigs.
    my $remnant = $num_of_sigfigs - $integer_digits - $valid_decimal_digits;
    if ($remnant) {
        $limited_value .= '.' unless $decimal_part;
        $limited_value .= ( '0' x $remnant );
    }

    # Append exponent section.
    $limited_value .= $exponent if $exponent;

    return $limited_value;
}

sub _check {
    my ( $x, $y, $num_of_sigfigs ) = @_;

    my $is_array = 0;

    if ( $num_of_sigfigs < 0 ) {
        croak 'Value of limit number of significant digits '
          . 'must be a number greater than or equal to zero.';
    }
    $num_of_sigfigs = int($num_of_sigfigs);

    my ( $ok, $diag ) = ( 1, '' );

    if ( ref $x eq 'ARRAY' || ref $y eq 'ARRAY' ) {
        $is_array = 1;
        unless ( scalar(@$x) == scalar(@$y) ) {
            $ok = 0;
            $diag =
                'Got length of an array is '
              . scalar(@$x)
              . ', but expected length of an array is '
              . scalar(@$y);

            return ( $ok, $diag );
        }
    }

    if ($is_array) {
        for my $i ( 0 .. $#$x ) {
            ( $ok, $diag ) = _check( $x->[$i], $y->[$i], $num_of_sigfigs );
            unless ($ok) {
                $diag .= ', number of element is ' . $i . ' in array';
                last;
            }
        }
    }
    else {
        $ok = ();    #TODO this is core.
    }

    return ( $ok, $diag );
}

sub sigfigs_ok_by($$$;$) {
    my ( $x, $y, $num_of_sigfigs, $test_name ) = @_;

    my ( $ok, $diag ) = _check( $x, $y, $num_of_sigfigs );
    return $test_builder->ok( $ok, $test_name ) || $test_builder->diag($diag);
}

sub sigfigs_ok($$;$) {
    my ( $x, $y, $test_name ) = @_;

    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        limit_sigfigs_ok_by( $x, $y, $default_num_of_sigfigs, $test_name );
    }
}
1;

__END__

=head1 NAME

Test::LimitSigfigs - [One line description of module's purpose here]


=head1 VERSION

This document describes Test::LimitSigfigs version 0.0.1


=head1 SYNOPSIS

    use Test::LimitSigfigs;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Test::LimitSigfigs requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-limitsigfigs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, moznion C<< <moznion@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
