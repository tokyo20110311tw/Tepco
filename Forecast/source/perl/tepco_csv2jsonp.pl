#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use JSON;
use LWP::UserAgent;
use Encode;
use File::Copy qw/move/;

# jsonp 出力先指定
my $jsonp = './forecast.json';


my $uri = 'http://www.tepco.co.jp/forecast/html/images/juyo-j.csv';
my $header_of_peek = 'ピーク時供給力(万kW),時台,供給力情報更新日,供給力情報更新時刻';
my $header_of_forecast = 'DATE,TIME,当日実績(万kW),前日実績(万kW)';

my $res = LWP::UserAgent->new->get($uri);
my $csv = Encode::decode('cp932',$res->content);
$csv =~s/\r//g;
my @lines = split(/\n/,$csv);

# 最初の行は必ず UPDATE …だといいなぁ
my $update_string = shift @lines;
$update_string =~s/ UPDATE$//;

my $ds = 0;
my $peek;
my @data = ();
foreach my $line (@lines) {
	next unless $line;
	if ($line eq $header_of_peek) {
		$ds = 1;
	}
	elsif ($ds == 1) {
		my @array = split(/,/,$line);
		$peek = {
			kw => $array[0],
			hour => $array[1],
			update => $array[2].' '.$array[3],
		};
		$ds = 0;
	}
	elsif ($line eq $header_of_forecast) {
		$ds = 2;
	}
	elsif ($ds == 2) {
		my @array = split(/,/,$line);
		push @data,{
			datetime => $array[0].' '.$array[1],
			today => $array[2],
			yesterday => $array[3],
		};
	}
}

my $json = JSON->new->utf8->encode({
	update => $update_string,
	peek => $peek,
	data => \@data,
});

my $tmp = $jsonp.'.tmp';
open(my $fh,'>',$tmp) or die $!;
print $fh 'callback(',$json,');';
close($fh);

move($tmp,$jsonp);

