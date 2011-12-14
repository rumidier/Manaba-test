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
    template 'index';
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

sub load_manaba {
    my $yaml = YAML::Tiny->read( config->{manaba} );
    $CONFIG = $yaml->[0];
}

load_manaba();
update('tal');

true;
