#!/usr/bin/perl6

use Slang::Lambda;
use Math::NumberTheory;

multi infix:<⊓> (Int $x, Int $y) { return $x gcd $y; }
my $tinyprimes= (1 .. *).grep({ is-prime $_ });

sub MAIN(Int :n($n), Int :s(:$srandbase)=7, Int :f(:$maxfactor), Int :t(:$trials)=1, Bool :p(:$use_primorial)=False  ) {
    srand $srandbase;
    for (0 .. $trials-1) λ $t {
        # create point and curve
        say "trial $t of $trials";
        my $x=(1+($n-1)*rand).Int;
        my $y=(1+($n-1)*rand).Int;
        my $d;
        {   # keep names x2, y2 hidden
            my $x2=($x*$x) % $n;
            my $y2=($y*$y) % $n;
            if (($x2*$y2 % $n) == 0) { die "cannot make curve"; }
            my $c=($x*$y ⊓ $n);
            if ($c != 1) { die "found factor $c when making curve"; }
            $d=( ($x2+$y2-1) * modular-inverse($x2*$y2,$n) ) % $n;
        }
        # start applying primorial to P=(x,y) until sth happens
        my $f=1;
        for (1 .. $maxfactor) λ $m {
            #say "f=$f";
            if ($use_primorial) {
                $f = $tinyprimes[$m];
            } else {
                $f=$m+1;
            }
            # nonrecursive ECC multiplication
            my $rx=0;
            my $ry=1;
            # x,y: initial values or result from last multiplication
            my $px=$x; # aux value, will be doubled periodically
            my $py=$y;
            my $k=$f;
            while ($k>0) {
                if ($k +& 1) {
                    # compute r=r+p
                    my $x1x2 = ($rx*$px) % $n;
                    my $y1y2 = ($ry*$py) % $n;
                    my $x1y2 = ($rx*$py) % $n;
                    my $y1x2 = ($ry*$px) % $n;
                    my $denx = (1 + $d*$x1x2*$y1y2) %$n;
                    my $deny = (1 - $d*$x1x2*$y1y2) %$n;
                    if ($denx==0 || $deny==0) { die "denominator==0"; }
                    my $cx=$denx ⊓ $n; if ($cx != 1) { die "found factor in add x: $cx"; }
                    my $cy=$deny ⊓ $n; if ($cy != 1) { die "found factor in add y: $cy"; }
                    my $invdenx=modular-inverse($denx,$n);
                    #if ($invdenx.^name ne 'Int') { die "$denx not invertible"; }
                    my $invdeny=modular-inverse($deny,$n);
                    #if ($invdeny.^name ne 'Int') { die "$deny not invertible"; }
                    ($rx,$ry) = ( (($x1y2+$y1x2)*$invdenx) % $n, (($y1y2-$x1x2)*$invdeny) %$n);
                }
                $k +>= 1;
                if ($k>0) {
                    # compute p=2*p
                    my $xx=($px*$px) % $n;
                    my $yy=($py*$py) % $n;
                    my $xy=($px*$py) % $n;
                    my $denx=(1+$d*$xx*$yy) % $n;
                    my $deny=(1-$d*$xx*$yy) % $n;
                    if ($denx==0 || $deny==0) { die "denominator==0"; }
                    my $cx=$denx ⊓ $n; if ($cx != 1) { die "found factor in double x: $cx"; }
                    my $cy=$deny ⊓ $n; if ($cy != 1) { die "found factor in double y: $cy"; }
                    my $invdenx=modular-inverse($denx,$n);
                    my $invdeny=modular-inverse($deny,$n);
                    ($px,$py) =  ( ((2*$xy)*$invdenx) % $n, (($yy-$xx)*$invdeny) % $n);
                }
            }
            # now (rx,ry) is f*(px,py)
            ($x,$y)=($rx,$ry);
        }
    }
}

