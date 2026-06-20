# Decompose an integer into prime factors using Lenstra's algorithm on Edwards curves

## Needed packages

* Math::NumberTheory (for `gcd`, `is-prime` etc.)
* Slang::Lambda (I prefer to write lambda as `λ`, not as `-->` as the inventor told us to)

## First version: edwards-oo.raku

* everything is done with classes for readybility
* this was used for experimenting with the algorithm
* the code contains a few functions that aren't used anymore

## working version: edwards.raku

* I removed all OO overhead and recursion, the code is as "spaghetti" as needed for speed
  * I don't exect anyone to understand it at first reading, that's what the other file is for
* x=k*x is performed as follows
  * p=x; r=0
  * while (k>0):  if k odd: r+=p else p+=p; finally x=r
* failure and success are currently handled using `die`, this needs improvement

## Experience so far

* Option `-p` seems to improve the speed (I did only a few experiments so far)
  * this uses primorials instead of factorials in the algorithm that is
    essentialls `p-1`
* Option `-s` allows to run it in parallel on several machines with
  different `srand` starts
* largest number decomposed so far: 61 digits, factors have 31 digits
  each, runtime about 4 days
  * the first factor was randomly typed manuelly, the second generated
    using `next-prime`

```
3713861533984091096228219613851442975523116003494232964981669 ==
1927138172001190758476714506133 * 1927138172001190758476714506193
```

* command line used:

```
raku edwards.raku -f=50000 -t=10000 -s=77 -p -n=3713861533984091096228219613851442975523116003494232964981669
```
