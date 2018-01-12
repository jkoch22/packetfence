package pf::api::queue_cluster;

=head1 NAME

pf::api::queue_cluster -

=cut

=head1 DESCRIPTION

pf::api::queue_cluster

=cut

use strict;
use warnings;
use pf::cluster qw($cluster_enabled);
use Moo;
use List::Util qw(shuffle);
use CHI;
our $CHI_CACHE = CHI->new(driver => 'RawMemory', datastore => {});

=head2 queue

The queue to submit to

=cut

has queue => (
    is      => 'rw',
    default => 'general',
);

=head2 local_client

The local queue client

=cut

has local_client => (
    is => 'rw',
    builder => 1,
    lazy => 1,
);

=head2 _build_local_client

Build the local client

=cut

sub _build_local_client {
    my ($self) = @_;
    require pf::pfqueue::producer::redis;
    return pf::pfqueue::producer::redis->new;
}

=head2 call

=cut

sub call {
    my ($self) = @_;
    die "call not implemented\n";
}

sub notify {
    my ($self, $method, @args) = @_;
    if ($cluster_enabled) {
        $self->cluster_notify($method, @args);
    } else {
        $self->local_notify($method, @args);
    }
    return;
}

=head2 local_notify

local_notify

=cut

sub local_notify {
    my ($self, $method, @args) = @_;
    $self->local_client->submit($self->queue, api => [$method, @args]);
    return;
}

sub cluster_notify {
    my ($self, $method, @args) = @_;
    foreach my $server ($self->servers) {
        if ($server->{host} eq $pf::cluster::host_id) {
            return $self->local_notify($method, @args);
        }

        if ($self->server_notify($server, $method, @args)) {
            last;
        }
    }
    return; 
}

=head2 server_notify

Sends a queue notify request to a server

=cut

sub server_notify {
    my ($self, $server, $method, @args) = @_;
    return $self->do_jsonrpc_notify($server, queue_submit => $self->queue, api => [$method, @args]);
}

=head2 mark_server_as_down

Mark server as down

=cut

sub mark_server_as_down {
    my ($server) = @_;
    $CHI_CACHE->set($server->{management_ip}, 1, {expires_in => 60});
}

=head2 is_server_down

Checks if server is down

=cut

sub is_server_down {
    my ($server) = @_;
    return $CHI_CACHE->get($server->{management_ip});
}

sub notify_delayed {
    my ($self, $delay, $method, @args) = @_;
    if ($cluster_enabled) {
        $self->cluster_notify_delayed($delay, $method, @args);
    } else {
        $self->local_notify_delayed($delay, $method, @args);
    }
    return;
}

=head2 cluster_notify_delayed

Sends a queue notify delayed request to a server

=cut

sub cluster_notify_delayed {
    my ($self, $delay, $method, @args) = @_;
    foreach my $server ($self->servers) {
        if ($server->{host} eq $pf::cluster::host_id) {
            return $self->local_notify_delayed($delay, $method, @args);
        }

        if ($self->server_notify_delayed($server, $delay, $method, @args)) {
            last;
        }
    }
    return; 
}

=head2 server_notify_delayed

server_notify_delayed

=cut

sub server_notify_delayed {
    my ($self, $server, $delay, $method, @args) = @_;
    return $self->do_jsonrpc_notify($server, queue_submit_delayed => $self->queue, $delay, api => [$method, @args]);
}

=head2 do_jsonrpc_notify

do_jsonrpc_notify

=cut

sub do_jsonrpc_notify {
    my ($self, $server, $method, @args) = @_;
    require pf::api::jsonrpcclient;
    my $apiclient = pf::api::jsonrpcclient->new(host => $server->{management_ip}, proto => 'https');
    my $results = $apiclient->notify($method, @args);
    unless ($results) {
        pf::log::get_logger->error("Failed to call $method ");
        mark_server_as_down($server);
    }

    return $results;
}


=head2 local_notify_delayed

calls the pf api ignoring the return value with a delay

=cut

sub local_notify_delayed {
    my ($self, $delay, $method, @args) = @_;
    $self->client->submit_delayed($self->queue, 'api', $delay, [$method, @args]);
    return;
}

=head2 servers

servers

=cut

sub servers {
    shuffle grep {!is_server_down($_)} pf::cluster::enabled_servers();
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2018 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
