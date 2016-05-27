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
	$self->{dictionary} = {};

	return bless $self, $class;
}

sub toplist { $_[0]->{top} }
sub dictionary { $_[0]->{dictionary} }

=head makedic(:HASHREF, :Str, :Int)
:Int は Ngram の N
=cut
sub makedic {
	my $self = shift;

	my $sentence = shift;
	my $times = shift;

	my $node = $self->{mecab}->parse($sentence);

	my ($words, $keys) = ([], []);

	# 先頭のフレーズを保存
	push @{$self->{top}}, $node->surface;

	while ($node->surface) {
		push @$words, $node->surface;
		$node = $node->next;
	}

	my $loops = $times - 1;
	
	foreach my $i (0 .. @$words - ($loops + 1)) {
		$keys->[$_] = $words->[$i + $_] for 0..$loops;
		deeppush($self->dictionary, $keys, 0, $loops);
	}
}

=head generate(:HASHREF, :Int)
:Int は ループ回数
=cut

sub generate {
	my $self = shift;

	my $times = shift;
	my $size = @{$self->toplist};

	my $prefix = $self->toplist->[int rand $size];
	my $sentense = $prefix;
	my $suffix = "";

	# 先頭の単語を基に文章を生成する。
	my $key = $prefix;

	for (1..$times) {
		next unless ($self->dictionary->{$key});
		($sentense, $suffix) = random_phrase($self->{dictionary}, $sentense, $key);
		$key = $suffix;
	}

	return $sentense;
}

sub savefile {
	my $self = shift;
	my $path = shift;
	my $data = {
		dictionary => $self->{dictionary},
		toplist => $self->{top}
	};
	nstore($data, $path);
}

sub loadfile {
	my $self = shift;
	my $path = shift;
	my $data = retrieve($path);
	$self->{dictionary} = $data->{dictionary};
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