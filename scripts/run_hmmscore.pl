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

use Cwd qw(abs_path getcwd);

use vars qw/$LOGGER/;

INIT {
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($FATAL);
    $LOGGER = Log::Log4perl->get_logger($0);
}

use threads;
use Capture::Tiny qw/capture_merged/;
use IO::File;
use IPC::Run qw/run/;
use autodie qw/open close/;
use FindBin qw/$RealBin/;


use File::Basename;

my ($level, $infile, $outdir, $bmoddir, $outprefix, $family);

Usage("Too few arguments") if $#ARGV < 0;
GetOptions( "h|?|help" => sub { &Usage(); },
            "l|level=s"=> \$level,
            "i|infile=s"=>\$infile,
            "o|outdir=s"=>\$outdir,
            "b|bmoddir=s"=>\$bmoddir,
            "p|prefix=s"=>\$outprefix,
            "f|family=s"=>\$family
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

$LOGGER->logdie("Missing input file.") unless ($infile);
$LOGGER->logdie("Wrong input file ($infile).") unless (-e $infile);

$LOGGER->logdie("Missing output directory.") unless ($outdir);
$LOGGER->logdie("Wrong output ($outdir).") unless (-e $outdir);

$LOGGER->logdie("Missing base directory for the family model directories.") unless ($bmoddir);
$LOGGER->logdie("Wrong base direcotry for the family model directories ($bmoddir).") unless (-e $bmoddir);

$LOGGER->logdie("Missing file prefix for results") unless ($outprefix);


opendir( DIR, $bmoddir ) or die $LOGGER->logdie($!);

my %allfam;
if ($family) {

    $LOGGER->logdie("Not found family ($family) directory ($bmoddir/$family)") unless (-d $bmoddir.'/'.$family);
            
    $LOGGER->info("Found $family family !");

    $allfam{$family} = undef;

} else {
    while ( my $famname = readdir(DIR) ) {
        my $f = $bmoddir.'/'.$famname;
        if ( -d $f) {
            next if ($famname =~ /^\.+$/);
            $LOGGER->info("Found $famname family !");
            $allfam{$famname} = undef;
        }        
    }
}
 
my %thread;
foreach my $family (keys %allfam) {
    my $absbmoddir=abs_path("$bmoddir");
    my $absinfile=abs_path("$infile");
    my $absoutdir=abs_path("$outdir");

    $thread{$family} = threads->create(\&hmmscore, $family, $absinfile, $absoutdir, $absbmoddir, $outprefix);
}

my $need_to_continue = 1;
while ($need_to_continue) {
    my $any_is_running= undef;
    foreach my $t (keys %thread) {
        if ($thread{$t}->is_running()) {
            $any_is_running=1;
            last;
        }
    }
    if ( $any_is_running ) {
        sleep 3;
    } else {
        $need_to_continue = 0;
    }
}

foreach my $t (keys %thread) {
    $LOGGER->info("Join family \"$t\" thread ...");
    $thread{$t}->join();
}

exit 0;

# Subroutines

sub hmmscore {
    my ($famname, $ifile, $odir, $mdir, $oprefix) = @_;

    chdir "$mdir/$famname";
    
    unlink("$odir/$oprefix.$famname.log.txt");
    
    open( my $LFH, ">", "$odir/$oprefix.$famname.log.txt" );

    capture_merged {
        system("$RealBin/run_hmmscore.sh $ifile $odir $mdir/$famname/hmms/parameters/ $oprefix $famname") == 0 or $LOGGER->logdie("Failed hmmscore");
    } stdout=>$LFH, stderr=>$LFH;
    
    close( $LFH );
}


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
        -i      --infile    Input protein fasta
        -o      --outdir    Output directory
        -b      --bmoddir   Base directory where the family Model directories resides.
                            The structure is: <MODDIR>/<FAMDIR>/hmms/parameters
                                * The <MODDIR>/<FAMDIR>/hmms directory must contains the *.mod files for the FAMILY <FAMDIR> and
                                * the <MODDIR>/<FAMDIR>/hmms/parameters must contains the *.mbli files for each .mod file.
        -p      --prefix    File prefix of output
        -f      --family    Family [Default: All families where considered]

END_USAGE
    print STDERR "\nERR: $msg\n\n" if $msg;
    print STDERR qq[$0  ] . q[$Revision$] . qq[\n];
	print STDERR $USAGE;
    exit(1);
}



