package pf::web::constants;

=head1 NAME

pf::web::constants - Constants for the captive portal

=head1 DESCRIPTION

This file is splitted by packages and refering to the constant requires you to
specify the package.

=cut

use strict;
use warnings;

use Readonly;

=head1 SUBROUTINES

=over

=item to_hash

Return all the WEB constants in an hash. This is to ease consumption by
Template Toolkit.

=cut

sub to_hash {
    no strict 'refs';

    # Lists all the entries of the WEB package then for each of them:
    my %constants;
    foreach (keys %WEB::) {
        # don't keep non scalar (hashes, lists) because using $
        next if not defined ${"WEB::$_"};
        # don't keep regex
        next if ref(${"WEB::$_"}) eq 'Regexp';
        $constants{$_} = ${"WEB::$_"};
    }
    return %constants;
}

=back

=head1 WEB

=cut

package WEB;
use pfconfig::cached_array;

tie our @uri_filters, 'pfconfig::cached_array', 'resource::URI_Filters';

=head2 URLs

=cut

# normal flow
Readonly::Scalar our $URL_ACCESS                => '/access';
Readonly::Scalar our $URL_AUTHENTICATE          => '/authenticate';
Readonly::Scalar our $URL_AUP                   => '/aup';
Readonly::Scalar our $URL_BILLING               => '/billing';
Readonly::Scalar our $URL_BILLING_CHILD         => '/billing/(.*)';
Readonly::Scalar our $URL_CAPTIVE_PORTAL        => '/captive-portal';
Readonly::Scalar our $URL_ENABLER               => '/enabler';
Readonly::Scalar our $URL_WISPR                 => '/wispr';
Readonly::Scalar our $URL_OAUTH2                => '/oauth2/auth';
Readonly::Scalar our $URL_OAUTH2_FACEBOOK       => '/oauth2/facebook';
Readonly::Scalar our $URL_OAUTH2_GITHUB         => '/oauth2/github';
Readonly::Scalar our $URL_OAUTH2_GOOGLE         => '/oauth2/google';
Readonly::Scalar our $URL_OAUTH2_LINKEDIN       => '/oauth2/linkedin';
Readonly::Scalar our $URL_OAUTH2_WIN_LIVE       => '/oauth2/windowslive';
Readonly::Scalar our $URL_OAUTH2_TWITTER        => '/oauth2/twitter';
Readonly::Scalar our $URL_REMEDIATION           => '/remediation';
Readonly::Scalar our $URL_RELEASE               => '/release';
Readonly::Scalar our $URL_STATUS                => '/status';
Readonly::Scalar our $URL_STATUS_LOGIN          => '/status/login';
Readonly::Scalar our $URL_STATUS_LOGOUT         => '/status/logout';
Readonly::Scalar our $URL_NODE_MANAGER          => '/node/manager/(.+)';
Readonly::Scalar our $URL_SAML_REDIRECT         => '/saml/redirect';
Readonly::Scalar our $URL_SAML                  => '/saml/(.+)';

# guest related
Readonly::Scalar our $URL_SIGNUP                => '/signup';
Readonly::Scalar our $URL_EMAIL_ACTIVATION      => '/activate/email(.*)';
Readonly::Scalar our $URL_EMAIL_ACTIVATION_LINK => '/activate/email';
Readonly::Scalar our $URL_SMS_ACTIVATION        => '/activate/sms';
Readonly::Scalar our $URL_PREREGISTER           => '/preregister';
Readonly::Scalar our $URL_ADMIN_MANAGE_GUESTS   => '/guests/manage';

Readonly::Scalar our $URL_GAMING_REGISTRATION   => '/gaming-registration';
Readonly::Scalar our $URL_DEVICE_REGISTRATION   => '/device-registration';

# External Captive Portal detection constant
Readonly::Scalar our $REQ_CISCO                 => 'ap_mac';
Readonly::Scalar our $REQ_MAC                   => 'mac';
Readonly::Scalar our $REQ_ARUBA                 => 'apname';
Readonly::Scalar our $REQ_CISCO_PORTAL          => '/cep(.*)';
Readonly::Scalar our $REQ_RUCKUS                => 'sip';
Readonly::Scalar our $REQ_AEROHIVE              => 'RADIUS-NAS-IP';

# External Captive Portal URL detection constant
Readonly::Scalar our $EXT_URL_XIRRUS            => '^/Xirrus::AP_http';
Readonly::Scalar our $EXT_URL_MERAKI            => '^/Meraki::AP_http';


# Provisioning engine
Readonly::Scalar our $URL_WIRELESS_PROFILE => '/wireless-profile.mobileconfig';
Readonly::Scalar our $URL_ANDROID_PROFILE  => '/profile.xml';
Readonly::Scalar our $URL_TLS_GENERATION   => '/tlsprofile';

=head2 Apache Config related

=over

=item Aliases for static content

URI => filesystem component

Filesystem portion is prefixed by $install_dir before installing into
Apache config.

=cut

Readonly::Hash our %CAPTIVE_PORTAL_STATIC_ALIASES => (
    '/common/'      => '/html/common/',
    '/content/'     => '/html/captive-portal/content/',
    '/favicon.ico'  => '/html/common/favicon.ico',
);

=item CAPTIVE_PORTAL_RESOURCES

Web portal resources that needs to be served by the captive-portal Catalyst Engine.

All URLs defined using constants starting with 'URL' are considered a web portal resource

=cut

my @captive_portal_resources = _captive_portal_resources_parser();
foreach ( @captive_portal_resources ) { s{([^/])$}{$1\$} }; # add $ to non-slash ending URLs
my $captive_portal_resources = join('|', @captive_portal_resources);
Readonly::Scalar our $CAPTIVE_PORTAL_RESOURCES => qr/ ^(?: $captive_portal_resources ) /xo; # eXtended pattern, compile Once

=item CAPTIVE_PORTAL_STATIC_RESOURCES

Web portal static resources that needs to be served by Apached without further processing.

All URLs matching one of the 'CAPTIVE_PORTAL_STATIC_ALIASES' path are considered a web portal static resource

=cut

my @captive_portal_static_ressources = keys %CAPTIVE_PORTAL_STATIC_ALIASES;
foreach ( @captive_portal_static_ressources ) { s{([^/])$}{$1\$} }; # add $ to non-slash ending URLs
my $captive_portal_static_resources = join('|', @captive_portal_static_ressources);
Readonly::Scalar our $CAPTIVE_PORTAL_STATIC_RESOURCES => qr/ ^(?: $captive_portal_static_resources ) /xo; # eXtended pattern, compile Once

=item LOCALES

Supported locales must be generated on the server and also have their binary catalog (.mo) under
/usr/local/pf/conf/locale/. Notice that a PacketFence translation generated for a two-letter language
code (ex: fr) will be used for any locale matching the language code (ex: fr_FR and fr_CA).

=cut

Readonly::Array our @LOCALES =>
  (
   qw(de_DE en_US es_ES fr_FR fr_CA he_IL it_IT nl_NL pl_PL pt_BR)
  );

=item ALLOWED_RESOURCES_PROFILE_FILTER

Build a regex that will decide what is considered a local ressource
(allowed to Apache's further processing).

URL ending with / will only be anchored at the beginning (^/path/) otherwise
an ending anchor is also installed (^/file$).

Anything else should be redirected. This happens in L<pf::web::dispatcher>.

=cut

my @components_profile_filter =  _clean_urls_match_filter();
# add $ to non-slash ending URLs
foreach (@components_profile_filter) { s{([^/])$}{$1\$} };
my $allow_profile = join('|', @components_profile_filter);
Readonly::Scalar our $ALLOWED_RESOURCES_PROFILE_FILTER => qr/ ^(?: $allow_profile ) /xo if($allow_profile ne ''); # eXtended pattern, compile Once

=item EXTERNAL_PORTAL_PARAM

Build a regex that will decide what is considered as a external portal var parameter.

This parameter should be something that contain the mac or ip address of the switch.

=cut

my @components_req =  _clean_urls_match_req();
foreach (@components_req) { s{([^/])$}{$1\$} };
my $allow_req = join('|', @components_req);
Readonly::Scalar our $EXTERNAL_PORTAL_PARAM => qr/ ^(?: $allow_req ) /xo; # eXtended pattern, compile Once

=item EXTERNAL_PORTAL_URL

Build a regex that will decide what is considered as a external portal URL.

This URL should point to a module in pf::Switch that can extract the mac or ip of the switch from the URL.

=cut

my @components_url =  _clean_urls_match_ext_url();
foreach (@components_url) { s{([^/])$}{$1\$} };
my $allow_url = join('|', @components_url);
Readonly::Scalar our $EXTERNAL_PORTAL_URL => qr/ ^(?: $allow_url ) /xo; # eXtended pattern, compile Once

=item _captive_portal_resources_parser

Return a regex that would match all the captive portal allowed clean URLs

=cut

sub _captive_portal_resources_parser {
    my %consts = pf::web::constants::to_hash();
    my @urls;
    foreach (keys %consts) {
        # keep only constants matching ^URL
        push @urls, $consts{$_} if (/^URL/);
    }
    return (@urls);
}

=item _clean_urls_match_filter

Return a regex that would match all the portal profile uri: filter

=cut

sub _clean_urls_match_filter {
    return @uri_filters;
}

=item _clean_urls_match_mod_perl

Return a regex that would match all the captive portal allowed clean URLs

=cut

sub _clean_urls_match_req {
    my %consts = pf::web::constants::to_hash();
    my @urls;
    foreach (keys %consts) {
        # keep only constants matching ^URL
        push @urls, $consts{$_} if (/^REQ/);
    }
    return (@urls);
}

=item _clean_urls_match_ext_url

Return a regex that would match all the captive portal allowed clean URLs

=cut

sub _clean_urls_match_ext_url {
    my %consts = pf::web::constants::to_hash();
    my @urls;
    foreach (keys %consts) {
        # keep only constants matching ^URL
        push @urls, $consts{$_} if (/^EXT_URL/);
    }
    return (@urls);
}

=back

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

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

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
