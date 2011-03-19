package X11::XCB::Event::ClientMessage;

use Moose;

# XXX: the following are filled in by XS
has [ 'response_type', 'sequence', 'window', 'type' ] => (is => 'ro', isa => 'Int');
has 'data' => (is => 'ro', isa => 'Str');

__PACKAGE__->meta->make_immutable;

1
# vim:ts=4:sw=4:expandtab
