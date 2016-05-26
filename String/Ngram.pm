package String::Ngram;

use strict;
use warnings;
#use Data::Dumper;
use utf8;
use Text::MeCab;
use Encode qw/encode_utf8 decode_utf8/;

sub new {
	my ($class, @args) = @_;
	my %args = ref $args[0] eq 'HASH' ? %{$args[0]} : @args;
	my $self = {%args};

	$self->{mecab} = Text::MeCab->new({%args});
	$self->{head} = [];
	$self->{phrase} = [];

	return bless $self, $class;
}

=head makedic(:HASH, :Str, :Int)
:Int は Ngram の N
=cut
sub makedic {
	my $self = shift;

	my $dic = shift;
	my $sentence = shift;
	my $times = shift;

	my $node = $self->{mecab}->parse($sentence);

	my ($words, $keys) = ([], []);

	# 先頭のフレーズを保存
	push @{$self->{head}}, $node->surface;

	while ($node->surface) {
		push @$words, $node->surface;
		$node = $node->next;
	}

	my $loops = $times - 1;
	
	foreach my $i (0 .. @$words - ($loops + 1)) {
		$keys->[$_] = $words->[$i + $_] for 0..$loops;
		deeppush($dic, $keys, 0, $loops);
	}
}

=head generate(:HASH, :Int)
:Int は ループ回数
=cut

sub generate {
	my $self = shift;

	my $dic = shift;
	my $times = shift;
	my $size = @{$self->headlist};

	my $prefix = $self->headlist->[int rand $size];
	my $sentense = $prefix;
	my $suffix = "";

	# 先頭の単語を基に文章を生成する。
	my $key = $prefix;

	for (1..$times) {
		next unless ($dic->{$key});
		($sentense, $suffix) = random_phrase($dic, $sentense, $key);
		$key = $suffix;
	}

	return $sentense;
}

sub headlist {
	my $self = shift;
	return $self->{head};
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