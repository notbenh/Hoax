#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Hoax;
use Dancer::Test;
use JSON;
 
subtest expected_failures => sub{
    for my $url (qw{/ /SomePkg}){
        response_status_is [GET => $url], 400, qq{GET $url is an error};
    }
};

subtest quick_example => sub{
    {
        package Hoax::SomePkg;
        use strict;
        use warnings;
        sub kitten {
            return { kitten => 'cute' } 
        };

    }

    response_status_is [GET => '/SomePkg/kitten'], 200, qq{GET /SomePkg/kitten is cute};
    my $expect = <<END;
{
   "kitten" : "cute"
}
END
    response_content_is [GET => '/SomePkg/kitten'], $expect, qq{reply is correct JSON};
};

subtest mimic_application => sub{
    {
        package Hoax::Random;
        use strict;
        use warnings;
        # TODO it sure would be nice to auto-JSON and auto-un-JSON all this stuff
        our $random_value = int( rand(10) );
        sub value {
            my ($param, $request) = @_;

            if( $request->method eq 'PUT' || $request->method eq 'POST' ){
                my $content = JSON::from_json($request->body);
                $random_value = $content->{value}; # set the value
            }

            return $random_value;
        };
    }
    response_status_is [GET => '/Random/value'], 200, qq{GET /Random/value is 200};
    my $pre = dancer_response GET => '/Random/value';
    my $number = $pre->content;
    like $number, qr{\d+}, q{yup that's a number};

    my $data = { headers => ['Content-Type' => 'application/json'],
                 body => to_json( { value => 99 } ),
               };
    response_status_is [ POST => '/Random/value', $data ], 200, qq{GET /Random/value is 200};
    my $post = dancer_response GET => '/Random/value';
    is $post->content, 99, q{able to overwrite the value in the object};



};

done_testing();
