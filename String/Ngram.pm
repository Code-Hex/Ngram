package String::Ngram;

use strict;
use warnings;
#use Data::Dumper;
use utf8;

use Text::MeCab;
use Storable qw/nstore retrieve/;
use Encode qw/encode_utf8 decode_utf8/;

sub new {
	my ($class, @args) = @_;
	my %args = ref $args[0] eq 'HASH' ? %{$args[0]} : @args;
	my $self = {%args};

	$self->{mecab} = Text::MeCab->new({%args});
	$self->{top} = [];
	$self->{dict} = {};

	return bless $self, $class;
}

# for Ngram
sub toplist { $_[0]->{top} }
sub dict { $_[0]->{dict} }

=head makedict(:HASHREF, :Str, :Int)
:Int は Ngram の N
=cut
sub makedict {
	my $self = shift;

	my $sentence = shift;
	my $times = shift;

	my $node = $self->{mecab}->parse($sentence);

	my ($words, $keys) = ([], []);

	# 先頭のフレーズを保存
	push @{$self->{top}}, $node->surface;

	# かっこは閉じる
	my ($kakko, $flag, $f2) = ("", 0, "");
	while ($node->surface) {
		$f2 = (split /,/, $node->feature)[1];
		if ($flag == 1) {
			$kakko .= $node->surface;
			if ($f2 eq encode_utf8 "括弧閉") {
				push @$words, $kakko;
				($flag, $kakko) = (0, "");
			}
		} elsif ($f2 eq encode_utf8 "括弧開") {
			$flag = 1;
			$kakko = $node->surface;
		} else {

			push @$words, $node->surface if $f2 ne encode_utf8 "括弧閉";
		}
		$node = $node->next;
	}

	my $loops = $times - 1;
	my $limit = @$words - ($loops + 1);
	
	foreach my $i (0 .. $limit) {
		$keys->[$_] = $words->[$i + $_] for 0..$loops;
		deeppush($self->dict, $keys, 0, $loops);
	}

	foreach my $i ($limit + 1 .. @$words - 3) {
		$keys = [];
		$keys->[$_] = $words->[$i + $_] for 0..@$words - $i - 1;
		deeppush($self->dict, $keys, 0, @$words - $i - 1);
	}
}

=head generate(:HASHREF, :Int)
:Int は ループ回数
=cut
sub generate {
	my $self = shift;

	my $size = @{$self->toplist};

	my $prefix = $self->toplist->[int rand $size];
	my $sentense = $prefix;
	my $suffix = "";

	# 先頭の単語を基に文章を生成する。
	my $key = $prefix;

	while ($self->dict->{$key}) {
		($sentense, $suffix) = random_phrase($self->{dict}, $sentense, $key);
		last if encode_utf8($suffix) =~ /[。！？!?]$/;
		$key = $suffix;
	}

	return $sentense;
}


sub savefile {
	my $self = shift;
	my $path = shift;
	my $data = {
		dict => $self->{dict},
		toplist => $self->{top}
	};
	nstore($data, $path);
}

sub loadfile {
	my $self = shift;
	my $path = shift;
	my $data = retrieve($path);
	$self->{dict} = $data->{dict};
	$self->{top} = $data->{toplist};
}

sub deeppush {
	my ($node, $keys, $count, $loops) = @_;

	push @{$node->{list}}, $keys->[$count]; # 重複する単語は確率が上がる

	if (@$keys - 2 > $count) {
		$node->{$keys->[$count]} ||= {};
		deeppush($node->{$keys->[$count]}, $keys, ++$count);
	} else {
		push @{$node->{$keys->[$count]}}, $keys->[++$count];
	}
}

sub random_phrase {
	my ($node, $phrase, $word) = @_;

	if (ref $node eq 'ARRAY') {
		my $size = @$node;
		my $suffix = $node->[int rand $size];

		$phrase .= $suffix;

		return ($phrase, $suffix);
	} else {
		my $size = @{$node->{list}};
		my $suffix = $node->{list}->[int rand $size];

		$phrase .= $suffix;

		return random_phrase($node->{$suffix}, $phrase, $suffix);
	}
}

1;