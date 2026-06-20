#!/usr/bin/perl6

use Slang::Lambda;
use Math::NumberTheory;

my $tinyprimes= (1 .. 10000).grep({ is-prime $_ })

#| x^2+y^2=1+dx^2y^2, neutral point is (0,1)
class Curve {
    has Int $.modulus;
    # has Int $.a; # twist (not yet implemented)
    has Int $.d; # factor on the rhs
};

class Point {
    has Curve $.E;
    has Int $.x;
    has Int $.y;
}

#| Abbreviations
multi infix:<⊓> (Int $x, Int $y) { return $x gcd $y; }
multi infix:<⊔> (Int $x, Int $y) { return $x lcm $y; }

multi sub mi(Int $thing, Int $modulus --> Int) {
    #say "mi_Int: thing $thing of ", $thing.^name, " modulus $modulus of ", $modulus.^name;
    my $th1=$thing % $modulus;
    if ($th1 == 0) { die 'QR'; }
    my $res;
    $res=modular-inverse($th1, $modulus);
    if ($res.^name ne "Int") {
        # die "modular-inverse $th1 $modulus returned ",$res.raku,' of ', $res.^name;
        my $g=$th1 ⊓ $modulus;
        #Exception.new(payload => 'MI ' ~ $res.^name ~ ' ' ~ $g.Str).throw;
        die 'MI ' ~ $res.^name ~ ' ' ~ $g.Str;
    }
    return $res.Int;
}

sub create_curve_with_point(Int $n) {
    my $x=(1+($n-1)*rand).Int;
    my $y=(1+($n-1)*rand).Int;
    my $x2=($x*$x) % $n;
    my $y2=($y*$y) % $n;
    my $d=( ($x2+$y2-1) * mi($x2*$y2,$n) ) % $n;
    my $E=Curve.new(modulus => $n, d => $d);
    return Point.new(x => $x, y => $y, E => $E);
}

my $QR=Exception.new(payload => 'QR');

multi infix:<+> (Point $P, Point $Q --> Point) {
    die "points $P and $Q are not on the same curve" unless $P.E === $Q.E;
    my Int $n=$P.E.modulus;
    my Int $d=$P.E.d;
    my Int $e=$P.x;
    my Int $f=$P.y;
    my Int $g=$Q.x;
    my Int $h=$Q.y;
    my Int $defgh=$d*$e*$f*$g*$h;
    #say "n=$n d=$d e=$e f=$f g=$g h=$h defgh=$defgh";
    #say 'eh=',$e*$h,' fg=',$f*$g, ' fh=', $f*$h, ' gh=', $g*$h;
    ### TODO: error handling in modular-inverse
    my $p1=(1+$defgh) % $n;
    my $m1=(1-$defgh) % $n;
    if ($p1==0 || $m1==0) { $QR.throw; }
    my $gp1=$p1 ⊓ $n;
    if ($gp1 != 1) { Exception.new(payload => "FF $gp1").throw; }
    my $gm1=$m1 ⊓ $n;
    if ($gm1 != 1) { Exception.new(payload => "FF $gm1").throw; }
    my $x; my $y;
    try {
        $x=( ($e*$h+$f*$g) * mi(1+$defgh,$n) ) % $n;
        $y=( ($f*$h-$e*$g) * mi(1-$defgh,$n) ) % $n;
        CATCH {
            say $*ERR;
        }
    }
    #say "x= $x y= $y";
    return Point.new(E => $P.E, x => $x, y => $y);
}

multi infix:<*> (Int $m, Point $P --> Point) {
    my $E=$P.E;
    if ($m==0) { return Point.new(E=>$E, x=>0, y=>1); }
    if ($m == 1) { return $P; }
    if ($m < 0) { return (-$m) * Point.new(E=>$E, x => (-$P.x) % $E.modulus, y => $P.y); }
    if ($m %% 2) {
        return ($m/2).Int * ($P+$P);
    } else {
        return $P + ( ($m-1) * $P );
    }
}

sub order_of_point(Point $P) {
    if ($P.x==0) {
        if ($P.y==1) { return 0; }
        if ($P.y== -1) { return 2; }
    }
    if ($P.y==0) && ($P.x==0) { return 4; }
    my $Q=Point.new(E => $P.E, x => 0, y => 1);
    for (1 .. 1000000000) λ $v {
        try {
            $Q=$Q+$P;
        }
        CATCH {
            'addition failed: ', $P, $Q;
        }
        if ($Q.x==0 && $Q.y==1) {
            return $v;
        } else {
            if ($v %% 100000) { print '.'; }
        }
    }
}

sub legendre_symbol(Int $a, Int $p) {
    # only for odd primes
    if ($p %% 2) { die "arg $p must be odd"; }
    #unless (is-prime($p)) { die "arg $p must be prime"; }
    return power-mod($a,(($p-1)/2).Int,$p);
}

sub MAIN(Int :n(:$number)) {
    my $sr=7;
    srand $sr;
    my $P=create_curve_with_point $number.Int;;
    say 'P= ', $P;
    #for (0 .. 4000000) λ $v { say $v, ' ', $v*$P if $v %% 10000; }
    say order_of_point($P);
}
