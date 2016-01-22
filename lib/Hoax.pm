package Hoax;
use Dancer ':syntax';
use Class::Load qw{:all};
#use JSON qw{ encode_json };

our $VERSION = '0.1';

sub run{
    my ($package,$function) = splice @_, 0, 2;
    my $rv;
    eval qq{\$rv = $package::$function(\@_)}
       or do { return qq{ERROR: $@ $!'} };

    return $rv;
}

any '/*/**' => sub{
    my ($pkg,$path) = splat;
    my $package = qq{Hoax::$pkg};
    my $function = join '_', @$path;
    my $rv;

    try_load_class( $package )
        or send_error( qq{$package is not found}, 404 );
    $rv = run($package, $function, {params}, request);


    return defined $rv && ref($rv) ? to_json($rv) : $rv;
};


any qr{.*} => sub {
    status 400; 
    return error(q{ '/package/function' required} );
};

true;
