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

my ($level, $infile, $outbasename);

Usage("Too few arguments") if $#ARGV < 0;
GetOptions( "h|?|help" => sub { &Usage(); },
            "l|level=s"=> \$level,
            "i|infile=s"=>\$infile,
            "o|outbasename=s"=>\$outbasename
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

$LOGGER->logdie("Missing output basename") unless ($outbasename);
$LOGGER->logdie("Wrong output directory (".dirname($outbasename).")") unless (-d dirname($outbasename));
if (-d $outbasename) {
    if ($outbasename!~/\/$/) {
        $outbasename.='/';
    }
}
    
for my $rmfile (glob("$outbasename*.fa")) {
    unlink($rmfile);
}

open(IN,"<", $infile) or die $LOGGER->logdie($!);

while(<IN>){
    chomp;
    my $line = $_;
    if ($line =~/^>?([^_]+)_(.*)/) {
        my ($family) = $1;
        my ($rawid) = $2;
        my $acc;
        if ( $rawid=~/^gi\|/ ) {
            my @info = split(/\|/, $rawid); 
            if ($info[2] eq 'pdb') {
                $info[4]=~s/ .*$//;
                $acc=$info[3].'_'.$info[4];
            } else {
                $acc=$info[3]; 
            }
        } elsif ( $rawid=~/^([A-Z]{2,3}_?[0-9]+)/) {
            $acc=$1;
        } else {
            die "Not found pattern: $rawid";
        }
        
        $LOGGER->info("Getting $family\t$acc\n ...");

        my $cmd='esearch -db protein -query "'.$acc.'" | efetch -db protein -format fasta >> '.$outbasename.$family.'.fa';

        if (system("$cmd") ) {
            die "Error: Problem with command: $cmd";
            print STDERR $line;
        }

    } elsif ( $line=~/unpublished/) {
        warn 'Found Unpublished sequence!';
        next;
    } else {
        die "Not found pattern: $_";
    }     
}

close(IN);

# Subroutines

sub Usage {
    my ($msg) = @_;
	Readonly my $USAGE => <<"END_USAGE";
Daniel Guariz Pinheiro (dgpinheiro\@gmail.com)
(c)2019 Universidade Estadual Paulista "Júlio de Mesquita Filho"

Usage

        $0	[-h/--help] [-l/--level <LEVEL>]

Argument(s)

        -h      --help          Help
        -l      --level         Log level [Default: FATAL]
        -i      --infile        Input file (Line recognized pattern: <FAMILY NAME>_<ID> with or withou ">" starting the line)
                                The ID can be directly a GenBank Accession ID or as this pattern "gi|000000|gb|<GENBANK ACC>" 
        -o      --outbasename   Output basename (only a directory path, or a directory path and the file name prefix)

END_USAGE
    print STDERR "\nERR: $msg\n\n" if $msg;
    print STDERR qq[$0  ] . q[$Revision$] . qq[\n];
	print STDERR $USAGE;
    exit(1);
}

