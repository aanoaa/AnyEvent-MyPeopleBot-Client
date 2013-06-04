package AnyEvent::MyPeopleBot::Client;
# Abstract: MyPeopleBot API in an event loop

use Moose;
use namespace::autoclean;

use AnyEvent;
use AnyEvent::HTTP::ScopedClient;

has apikey => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub profile {
    my ($self, $buddyId, $cb) = @_;

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/profile/buddy.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            { buddyId => $buddyId },
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

sub buddys {
    my ($self, $groupId, $cb) = @_;

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/group/members.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            { groupId => $groupId },
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

sub send {
    my ($self, $id, $msg, $cb) = @_;

    my $which = $id =~ /^B/ ? 'buddy' : 'group';
    my %params = (
        $which . 'Id' => $id,
        content       => $msg,
    );

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/$which/send.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            \%params,
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

sub exit {
    my ($self, $groupId, $cb) = @_;

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/group/exit.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            { groupId => $groupId },
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 SYNOPSIS

    use AnyEvent::HTTPD;
    use AnyEvent::Mepeople::Client;
    my $client = AnyEvent::MyPeopleBot::Client->new(
        apikey => 'xxxx',
    );

    my $httpd = AnyEvent::HTTPD->new(port => 8080);
    $httpd->reg_cb(
        '/' => sub {
            my $action  = $req->parm('action');
            my $buddyId = $req->parm('buddyId');
            my $groupId = $req->parm('groupId');
            my $content = $req->parm('content');

            $req->respond({ content => [ 'text/plain', "AnyEvent::MyPeopleBot::Client" ]});
            if ($action =~ /^sendFrom/) {
                $client->send($buddyId || $groupId, 'hi', sub {
                    my $json = shift;
                    print "$json\n";
                });
            }
        }
    );

    $httpd->run;

=cut
