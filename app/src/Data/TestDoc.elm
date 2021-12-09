module Data.TestDoc exposing (..)


text1 =
    """
one
  two
    three!
    aaaaa
    b
"""


text =
    """



| heading 1
L0 Examples

The examples are illustrative, not exhaustive.

| heading 2
Inline constructions

| heading 3
Usual markup stuff

I [i thought] that this would be a [b good] idea, but I was [red sadly mistaken!].

Note that inline elements can [i [b be composed.]] That was italic
bold. Let's not be boring: we can also do colors:
[blue blue stuff] and [red red stuff].  Of course, colors compose also: [i  [b [red Merry Christmas!]]]


This is code: `a[0] = 1`; so is this: `$stuff$` and `[x]`

[image https://ichef.bbci.co.uk/news/976/cpsprodpb/4FB7/production/_116970402_a20-20sahas20barve20-20parrotbill_chavan.jpg]





| heading 3
Inline math

This is math: $a^2 + b^2 = c^2$


| heading 2
Block constructions


| heading 3
Math

[i Display math using pipes:]



|| math
\\int_0^1 x^n dx = \\frac{1}{n+1}

[i Display math using dollar signs:]

$$
\\int_0^\\infty e^{-x} dx = 1

| heading 3
Code

|| code
  a[0] = 1
    b[0] = |3|
       c[0] = b[0]
    || x = a + b + c ||

| heading 3
Ordinary blocks


[i An "indent" block:]

| indent
Pythagoras said that if $a$, $b$, $c$ are the altitude, base, and
hypotenuse of a right triangle, then $a^2 + b^2 = c^2$.



[i Blocks can be nested:]

| indent
An indented block:
roses are [red red]
violets are [blue blue]

  | indent
  This poem is by
  Mr. J. X. Anonymous

    | indent
    Let's throw in some math just for kicks:


    || math
    \\int_0^1 x^n dx = \\frac{1}{n+1}


  | indent
  Хватит этого!





| heading 2
Handling Errors

| heading 3
Inline errors

This line will have an [i incomplete italic element.

This line does not have a closing bracket: [blue blue sky

This line has too many right brackets: [blue blue sky]]

Here is an incomplete math element: $ a^2 + b^2 = c^2 . [i Oops!
I forgot a closing dollar sign. Bad!!]


| heading 3
Blocks errors

[i An unknown block name:]

|| foo bar
la di dah
do day!

[i An incomplete block name:]

| inden
Pythagoras said that if $a$, $b$, $c$ are the altitude, base, and
hypotenuse of a right triangle, then $a^2 + b^2 = c^2$.

[i A missing block name:

|
Pythagoras said that if $a$, $b$, $c$ are the altitude, base, and
hypotenuse of a right triangle, then $a^2 + b^2 = c^2$.




"""
