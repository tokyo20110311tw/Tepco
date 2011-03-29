#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use JSON;
use LWP::UserAgent;
use Spreadsheet::ParseExcel;
use Encode;
use File::Copy qw/move/;

# jsonp 出力先指定
my $jsonp = './group.jsonp';

my $base_uri = 'http://www.tepco.co.jp/images/';
my @pref = qw/tochigi ibaraki gunma chiba kanagawa tokyo saitama yamanashi numazu/;

my $ua = LWP::UserAgent->new;
my $excel = Spreadsheet::ParseExcel->new();
my %hash = ();

foreach my $pref (@pref) {
	my $xls = $ua->get($base_uri.$pref.'.xls')->content;
	my $book = $excel->Parse(\$xls);
	my $sheet = $book->{Worksheet}->[0];

	my @row = $sheet->{MinRow} .. $sheet->{MaxRow};
	my @col = $sheet->{MinCol} .. $sheet->{MaxCol};

	foreach my $row ( @{ $sheet->{Cells} }[ @row ] ) {
		my @cellvalue = map {
			$_ = $_->Value() if ref $_;
			$_ = '' if not defined $_;
			$_;
		} @$row[ @col ];
		next if ($cellvalue[0] eq '都県' or $cellvalue[0]!~/県$/ and $cellvalue[0]!~/都$/);
		$hash{$cellvalue[0]}{$cellvalue[1]}{$cellvalue[2]}{$cellvalue[3]}{$cellvalue[4]} = 1;
	}
}
my $json = JSON->new->utf8->encode(\%hash);

my $tmp = $jsonp.'.tmp';
open(my $fh,'>',$tmp) or die $!;
print $fh 'callback(',$json,');';
close($fh);

move($tmp,$jsonp);
