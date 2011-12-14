package Manaba_test;
use Dancer ':syntax';

our $VERSION = '0.1';

use 5.010;
use YAML::Tiny;
use Web::Scraper;
use URI;
use Data::Dumper;

my $CONFIG;
my $SCRAPERS = {
    daum => scraper {
        process(
            'div.episode_list > div.inner_wrap > div.scroll_wrap > ul > li',
            'items[]',
            scraper {
                process 'a.img', link  => '@href';
                process 'a.img', title => '@title';
            }
        );
    },
    naver => scraper {
        process(
            'table.viewList tr td.title',
            'items[]',
            scraper {
                process 'a', link => '@href';
            }
       );
    },
    nate => scraper {
        process(
            'div.wrap_carousel div.thumbPage div.thumbSet dd',
            'items[]',
            scraper {
                process 'a',   link  => '@href';
                process 'img', title => '@alt';
            }
       );
    }
};

get '/' => sub {
    my $webtoon = $CONFIG->{webtoon};

    my @items = map {
        my $item = $webtoon->{$_};

        $item->{id}     = $_;
        $item->{first}  = q{} unless $item->{first};
        $item->{last}   = q{} unless $item->{last};

        $item;
    } sort keys %$webtoon;

    my $ptr = 0;
    my @rows;
    while ( $items[$ptr] ) {
        my @cols;
        for my $i ( 0 .. 9 ) {
            last unless $items[$ptr];
            push @cols, $items[$ptr];
            ++$ptr;
        }
        push @rows, \@cols;
    }

    template 'index' => {
        rows => \@rows,
    };
};

get '/update/:id?' => sub {
    my $id = param( 'id' );

    if ($id) {
        update($id);
    }
    else {
        update_all();
    }

    redirect '/';
};

sub update {
    my $id = shift;
    return unless $id;

    my $webtoon = $CONFIG->{webtoon};
    return unless $webtoon;

    my $site_name = $webtoon->{$id}{site};
    return unless $site_name;

    my $scraper = $SCRAPERS->{ $site_name };
    return unless $scraper;

    my $site = $CONFIG->{site};
    return unless $site;

    my $start_url = sprintf(
        $site->{ $site_name }{ 'start_url' },
        $webtoon->{$id}{ 'code' },
    );

    my $items = $scraper->scrape( URI->new( $start_url ) )->{items};
    my @links = map { $_->{link} } @$items;

    given ( $site_name ) {
#        update_daum_link($id, @links)  when 'daum';
        update_naver_link($id, @links) when 'naver';
#        update_nate_link($id, @links)  when 'nate';
    }
}

sub update_all {
    my $webtoons = $CONFIG->{webtoon};

    for my $id ( keys %$webtoons ) {
        update($id);
    }
}

sub load_manaba {
    my $yaml = YAML::Tiny->read( config->{manaba} );
    $CONFIG = $yaml->[0];
}

sub update_naver_link {
    my ( $id, @links ) = @_;

    my $webtoon = $CONFIG->{webtoon};
    return unless $webtoon;

    my $site = $CONFIG->{site};
    return unless $site;

    my $webtoon_url = $site->{ $webtoon->{$id}{site} }{webtoon_url};
    return unless $webtoon_url;

    my @chapters = sort {
        my $page_no_a = 0;
        my $page_no_b = 0;

        $page_no_a = $1 if $a =~ m/^(\d+)$/;
        $page_no_b = $1 if $b =~ m/^(\d+)$/;

        $page_no_a <=> $page_no_b;
    } map {
        m{no=(\d+)};
    } @links;

    $webtoon->{$id}{first} = sprintf( $webtoon_url, $webtoon->{$id}{code}, 1);
    $webtoon->{$id}{last}  = sprintf( $webtoon_url, $webtoon->{$id}{code}, $chapters[-1] );
}

load_manaba();
update();

true;
