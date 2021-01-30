#!/usr/bin/env perl
#
#              INGLÊS/ENGLISH
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  http://www.gnu.org/copyleft/gpl.html
#
#
#             PORTUGUÊS/PORTUGUESE
#  Este programa é distribuído na expectativa de ser útil aos seus
#  usuários, porém NÃO TEM NENHUMA GARANTIA, EXPLÍCITAS OU IMPLÍCITAS,
#  COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.  Consulte
#  a Licença Pública Geral GNU para maiores detalhes.
#  http://www.gnu.org/copyleft/gpl.html
#
#  Copyright (C) 2019  Universidade Estadual Paulista "Júlio de Mesquita Filho"
#
#  Universidade Estadual Paulista "Júlio de Mesquita Filho" (UNESP)
#  Faculdade de Ciências Agrárias e Veterinárias (FCAV)
#  Laboratório de Bioinformática (LB)
#
#  Daniel Guariz Pinheiro
#  dgpinheiro@gmail.com
#  http://www.fcav.unesp.br
#
# $Id$

=head1 NAME

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 DESCRIPTION
    
    Arguments:

        -h/--help   Help
        -l/--level  Log level [Default: FATAL] 
            OFF
            FATAL
            ERROR
            WARN
            INFO
            DEBUG
            TRACE
            ALL

=head1 AUTHOR

Daniel Guariz Pinheiro E<lt>dgpinheiro@gmail.comE<gt>

Copyright (C) 2019 Universidade Estadual Paulista "Júlio de Mesquita Filho"

=head1 LICENSE

GNU General Public License

http://www.gnu.org/copyleft/gpl.html


=cut

use strict;
use warnings;
use Readonly;
use Getopt::Long;

use File::Basename;

use vars qw/$LOGGER/;

INIT {
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($FATAL);
    $LOGGER = Log::Log4perl->get_logger($0);
}

my ($level, $indir, $score_threshold);

Usage("Too few arguments") if $#ARGV < 0;
GetOptions( "h|?|help" => sub { &Usage(); },
            "l|level=s"=> \$level,
            "i|indir=s"=> \$indir,
            "t|score_threshold=f"=>\$score_threshold
    ) or &Usage();


if ($level) {
    my %LEVEL = (   
    'OFF'   =>$OFF,
    'FATAL' =>$FATAL,
    'ERROR' =>$ERROR,
    'WARN'  =>$WARN,
    'INFO'  =>$INFO,
    'DEBUG' =>$DEBUG,
    'TRACE' =>$TRACE,
    'ALL'   =>$ALL);
    $LOGGER->logdie("Wrong log level ($level). Choose one of: ".join(', ', keys %LEVEL)) unless (exists $LEVEL{$level});
    Log::Log4perl->easy_init($LEVEL{$level});
}


$LOGGER->logdie("Missing input directory") unless ($indir);
$LOGGER->logdie("Wrong input directory ($indir)") unless (-d $indir);

$score_threshold||=-100;

my %result;

foreach my $distfile (glob("$indir/*.dist")) {
    my $fn = basename($distfile);
    my ($family, $subfamily);
    if ($fn=~/result-hmms-meta\.\d+\.([^\.]+)\.last\.(N\d+)/) {
        $family = $1;
        $subfamily = $2;
#        print STDERR ">$family<>$subfamily<\n";
    } else {
        $LOGGER->logdie("File $fn doesn't have a proper name");
    }
    open(IN, "<", $distfile) or $LOGGER->logdie($!);
    while(<IN>) {
        chomp;
        next if ($_=~/^%/);
        my ($sequence_id, $length, $simple_score, $reverse_score, $evalue) = split(/\s+/, $_);
        #print join(";", $sequence_id, $length, $simple_score, $reverse_score, $evalue),"\n";
        next if ($reverse_score > $score_threshold);
        #print join(";", $sequence_id, $length, $simple_score, $reverse_score, $evalue),"\n";
        unless (exists $result{$sequence_id}) {
            $result{$sequence_id} = {   'score'=>$reverse_score, 
                                        'evalue'=>$evalue,
                                        'family'=>$family,
                                        'subfamily'=>$family.'.'.$subfamily
                                    };
        } else {
            if ($result{$sequence_id}->{'score'} > $reverse_score) {
                $result{$sequence_id} = {   'score'=>$reverse_score, 
                                            'evalue'=>$evalue,
                                            'family'=>$family,
                                            'subfamily'=>$family.'.'.$subfamily
                                        };
            }
        }            
    }
    close(IN);
}

foreach my $sequence_id (sort { $result{$a}->{'subfamily'} cmp $result{$b}->{'subfamily'} } keys %result) {
    print join("\t", $sequence_id, @{$result{$sequence_id}}{'family','subfamily'}),"\n";
}

# Subroutines

sub Usage {
    my ($msg) = @_;
	Readonly my $USAGE => <<"END_USAGE";
Daniel Guariz Pinheiro (dgpinheiro\@gmail.com)
(c)2019 Universidade Estadual Paulista "Júlio de Mesquita Filho"

Usage

        $0	[-h/--help] [-l/--level <LEVEL>]

Argument(s)

        -h      --help              Help
        -l      --level             Log level [Default: FATAL]
        -i      --indir             Input directory
        -t      --score_threshold   Score threshold [Default -100]

END_USAGE
    print STDERR "\nERR: $msg\n\n" if $msg;
    print STDERR qq[$0  ] . q[$Revision$] . qq[\n];
	print STDERR $USAGE;
    exit(1);
}

