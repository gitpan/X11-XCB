package X11::XCB::Connection;

use Mouse;

extends qw/Mouse::Object X11::XCB/;

sub BUILD {
    shift->_connect_and_attach_struct;
}

# free struct
*DESTROY = \&X11::XCB::DESTROY;

has 'display' => (is => 'rw', isa => 'Str', default => '');

=head1 NAME

X11::XCB::Connection - connection to the X server

=head1 METHODS

=head2 atom

Returns a new C<X11::XCB::Atom> assigned to this connection.

=cut
sub atom {
    my $self = shift;
    require X11::XCB::Atom;

    return X11::XCB::Atom->new(_conn => $self, @_);
}

=head2 color

Returns a new C<X11::XCB::Color> assigned to this connection.

=cut
sub color {
    my $self = shift;
    require X11::XCB::Color;

    return X11::XCB::Color->new(_conn => $self, @_);
}


=head2 root

Returns a new C<X11::XCB::Window> representing the X11 root window.

=cut
sub root {
    my $self = shift;
    require X11::XCB::Window;
    require List::Util;

    my $screens = $self->screens;
    my $width = List::Util::sum map { $_->rect->width } @{$screens};
    my $height = List::Util::sum map { $_->rect->height } @{$screens};

    return X11::XCB::Window->new(
        _conn => $self,
        _mapped => 1, # root window is always mapped
        parent => 0,
        id => $self->get_root_window(),
        rect => X11::XCB::Rect->new(x => 0, y => 0, width => $width, height => $height),

        # FIXME: is this correct for the root win?
        class => X11::XCB::WINDOW_CLASS_INPUT_OUTPUT(),
    );
}

=head2 input_focus

Returns the X11 input focus (a window ID).

=cut
sub input_focus {
    my $self = shift;

    my $cookie = $self->get_input_focus();
    my $reply = $self->get_input_focus_reply($cookie->{sequence});

    return $reply->{focus};
}

=head2 screens

Returns an arrayref of L<X11::XCB::Screen>s.

=cut
sub screens {
    my $self = shift;
    require X11::XCB::Screen;

    my $cookie = $self->xinerama_query_screens;
    my $screens = $self->xinerama_query_screens_reply($cookie->{sequence});

    # If Xinerama is not available, fall back to the X root window dimensions
    if (@{$screens->{screen_info}} == 0) {
        my $cookie = $self->get_geometry($self->get_root_window());
        my $geom = $self->get_geometry_reply($cookie->{sequence});
        return [ X11::XCB::Screen->new(rect => X11::XCB::Rect->new($geom)) ];
    }

    my @result;
    for my $geom (@{$screens->{screen_info}}) {
        my $rect = X11::XCB::Rect->new(
                x => $geom->{x_org},
                y => $geom->{y_org},
                width => $geom->{width},
                height => $geom->{height}
        );
        push @result, X11::XCB::Screen->new(rect => $rect);
    }

    return \@result;
}

1
# vim:ts=4:sw=4:expandtab
