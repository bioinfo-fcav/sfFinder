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
use FileHandle;
use File::Basename;

use vars qw/$LOGGER/;

INIT {
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($FATAL);
    $LOGGER = Log::Log4perl->get_logger($0);
}

my ($level, $infile, $outfile, $dbdir);

Usage("Too few arguments") if $#ARGV < 0;
GetOptions( "h|?|help" => sub { &Usage(); },
            "i|infile=s"=>\$infile,
            "o|outfile=s"=>\$outfile,
            "d|dbdir=s"=>\$dbdir,
            "l|level=s"=> \$level
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

$LOGGER->logdie("Missing DataBase directory") unless ($dbdir);
$LOGGER->logdie("Wrong DataBase directory ($dbdir)") unless (-d $dbdir);
$LOGGER->logdie("Wrong DataBase directory ($dbdir). Not found $dbdir/subfamily.") unless (-d "$dbdir/subfamily");

my $fhout;

if ($outfile) {
    $fhout = FileHandle->new;
    $fhout->open(">$outfile");
} else {
    $fhout = \*STDOUT;
}

my %db;
foreach my $famdir (glob("$dbdir/subfamily/*")) {
    if (-d $famdir) {
        my $famname=basename($famdir);
        $LOGGER->info("Found $famname family and subfamilies ...");
        $LOGGER->logdie("Not found tree information for $famname in $famdir/treeinfo/$famname.treeinfo.txt") unless (-e "$famdir/treeinfo/$famname.treeinfo.txt");
        open(DB, "<", "$famdir/treeinfo/$famname.treeinfo.txt") or $LOGGER->logdie($!);
        while(<DB>) {
            chomp;
            next if ($_=~/^#/);
            my ($id, $desc, $subfam, $taxon, $tax_id) = split(/\t/, $_);
            $LOGGER->logdie("Not found information for $id in $famname.treeinfo.txt") unless ($subfam);

            $db{$famname}->{$subfam}->{$tax_id} = undef;
        }
        close(DB);
    }
}

my %lca;

foreach my $fam (keys %db) {
    foreach my $subfam (keys %{ $db{$fam} }) {
        my @tax_id = keys %{ $db{$fam}->{$subfam} };
        my $getlca_cmd='echo "'.join(' ', @tax_id).'" | GetLCA.pl';
        my $lcatax_id=`$getlca_cmd`;
        chomp($lcatax_id);
        $LOGGER->logdie("Cannot get an LCA from $fam.$subfam information on $fam.treeinfo.txt") unless ($lcatax_id);
        $LOGGER->logdie("LCA taxonomy information was already got for $fam.$subfam") if (exists $lca{ $fam }->{ $subfam });

        my $gettaxinfo=`GetTaxInfo.pl $lcatax_id | tail -1`;
        chomp($gettaxinfo);

        my ($lcarank, $lcaname) = (split(/\t/, $gettaxinfo))[3,4];

        $LOGGER->logdie("Cannot get the TaxInfo for $lcatax_id, identified as LCA from $fam.$subfam") unless ($lcaname);

        $lca{ $fam }->{ $subfam } = {   'tax_id'=> $lcatax_id,
                                        'tax_rank'=> $lcarank,
                                        'tax_name'=> $lcaname   };
    }
}


open(IN, "<", $infile) or $LOGGER->logdie($!);

while(<IN>) {
    chomp;
    if ($_=~/^#/) {
        print { $fhout } join("\t",$_, 'Tax_rank', 'Tax_name', 'Tax_id'),"\n";
    } else {
        my ($qid, $fname, $sfname) = split(/\t/, $_);
        print { $fhout } join("\t",$qid, $fname, $sfname, @{$lca{$fname}->{$sfname}}{'tax_rank', 'tax_name','tax_id'}),"\n";
    }
}    

close(IN);

$fhout->autoflush();


# Subroutines

sub Usage {
    my ($msg) = @_;
	Readonly my $USAGE => <<"END_USAGE";
Daniel Guariz Pinheiro (dgpinheiro\@gmail.com)
(c)2019 Universidade Estadual Paulista "Júlio de Mesquita Filho"

Usage

        $0	[-h/--help] [-l/--level <LEVEL>]

Argument(s)

        -h      --help      Help
        -l      --level     Log level [Default: FATAL]
        -i      --infile    Input file (preliminary result of sfMapper.sh)
        -d      --dbdir     DataBase directory (output directrory of mkFProfiles.sh)
        -o      --outfile   Output file [Default: STDOUT]

END_USAGE
    print STDERR "\nERR: $msg\n\n" if $msg;
    print STDERR qq[$0  ] . q[$Revision$] . qq[\n];
	print STDERR $USAGE;
    exit(1);
}

