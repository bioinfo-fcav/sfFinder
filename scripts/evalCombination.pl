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
use FileHandle;

use vars qw/$LOGGER/;


INIT {
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($FATAL);
    $LOGGER = Log::Log4perl->get_logger($0);
}

my ($level, $infile, $qfile, $outfile);

Usage("Too few arguments") if $#ARGV < 0;
GetOptions( "h|?|help" => sub { &Usage(); },
            "l|level=s"=> \$level,
            "i|infile=s"=> \$infile,
            "q|qfile=s"=>\$qfile,
            "o|outfile=s"=>\$outfile
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


$LOGGER->logdie("Missing input file") unless ($infile);
$LOGGER->logdie("Wrong input file ($infile)") unless (-e $infile);

$LOGGER->logdie("Missing queried file") unless ($qfile);
$LOGGER->logdie("Wrong queried file ($qfile)") unless (-e $qfile);

my $fhout;

if ($outfile) {
    $fhout = FileHandle->new;
    $fhout->open(">$outfile");
} else {
    $fhout = \*STDOUT;
}

my %query;
open(QF, "<", $qfile) or $LOGGER->logdie($!);
while(<QF>) {
    chomp;
    if ($_=~/^>(\S+)/) {
        $query{$1}=undef;
    }
}
close(QF);


open(IN, "<", $infile) or $LOGGER->logdie($!);
my $header_line=<IN>;
chomp($header_line);
my @header=split(/\t/, $header_line);
print { $fhout } join("\t", $header[0], 'Code', @header[1..$#header]),"\n";
while(<IN>) {
    chomp;
    my %data;
    @data{@header} = split(/\t/, $_);
    
    delete($query{$data{$header[0]}});
    my $code;

    if  ($data{'Family.x'} eq $data{'Family.y'}) {
        if ($data{'Subfamily.x'} eq $data{'Subfamily.y'}) {
            $code='f11s11';
        } else {
            $code='f11s12';
        }
    } else {
        if ($data{'Family.x'} eq 'NA') {
            $code='f01s01';
        } elsif ($data{'Family.y'} eq 'NA') {
            $code='f10s10';
        } else {
            $code='f12s12';
        }
    }
    print { $fhout } join("\t", $data{$header[0]}, $code, @data{@header[1..$#header]}),"\n";
}
foreach my $q (keys %query) {
    print { $fhout } join("\t", $q, 'f00s00', ('NA') x $#header),"\n";
} 

close(IN);

$fhout->close();

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
        -i      --infile            Input file (Output from mergeR.R of both sfMapper.sh results - with diamond and hmmscore)
        -q      --qfile             Queried fasta file
        -o      --outfile           Output file [Default: STDOUT]

END_USAGE
    print STDERR "\nERR: $msg\n\n" if $msg;
    print STDERR qq[$0  ] . q[$Revision$] . qq[\n];
	print STDERR $USAGE;
    exit(1);
}

