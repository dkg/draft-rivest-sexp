---
v: 3
docname: draft-rivest-sexp-02
cat: info
submissiontype: IETF
lang: en
title: S-Expressions
area: Applications and Real Time
wg: Network Working Group
kw: Sexp
author:
- ins: R. Rivest
  name: Ronald L. Rivest
  org: MIT CSAIL
  street: 32 Vassar Street, Room 32-G692
  city: Cambridge
  region: Massachusetts
  code: '02139'
  country: USA
  email: rivest@mit.edu
  uri: https://www.csail.mit.edu/person/ronald-l-rivest
- ins: D. Eastlake
  name: Donald E. Eastlake 3rd
  org: Futurewei Technologies
  street: 2386 Panoramic Circle
  city: Apopka
  region: Florida
  code: '32703'
  country: US
  phone: "+1-508-333-2270"
  email: d3e3e3@gmail.com
contributor:
- name: Marc Petit-Huguenin
  org: Impedance Mismatch LLC
  email: marc@petit-huguenin.org
normative:
  RFC4648:
  RFC5234:
informative:
  RFC2046:
  RFC2692:
  RFC2693:
  BERN:
    target: https://www.ietf.org/archive/id/draft-bernstein-netstrings-02.txt
    title: Netstrings
    author:
    - ins: D. Bernstein
      name: Daniel J. Bernstein
      org: ''
    date: '1997-2-1'
    seriesinfo:
      Work in: progress
  Libgcrypt:
    target: https://www.gnupg.org/documentation/manuals/gcrypt/
    title: The Libgcrypt Library
    author:
    - org: GnuPG
    date: '2023-4-6'
    seriesinfo:
      Libgcrypt version: 1.10.2
  LISP:
    title: LISP 1.5 Programmer's Manual
    author:
    - ins: M. Levin
      name: Michael I. Levin
      org: The Computer Center and Research Laboratory of Electronics, Massachusetts
        Institute of Technology
    - ins: J. McCarthy
      name: John McCarthy
      org: ''
    date: 1962-08-15
    seriesinfo:
      ISBN-13: 978-0-262-12011-0
      ISBN-10: '0262130114'
  SDSI:
    target: https://people.csail.mit.edu/rivest/pubs/RL96.ver-1.1.html
    title: A Simple Distributed Security Architecture
    author:
    - ins: R. Rivest
      name: Ronald L. Rivest
      org: ''
    - ins: B. Lampson
      name: Butler Lampson
      org: ''
    date: 1996-10-2
    seriesinfo:
      working: document
      SDSI version: '1.1'
  SexpCode:
    target: https://github.com/jpmalkiewicz/rivest-sexp
    title: SEXP---(S-expressions)
    author:
    - ins: J. Malkiewicz
      name: J. P. Malkiewicz
      org: ''
    date: 2015-06-10
  SPKI:
    target: http://www.clark.net/pub/cme/html/spki.html
    title: SPKI--A Simple Public Key Infrastructure
    author:
    - org: ''
    date: false
--- abstract

This memo describes a data structure called "S-expressions" that are suitable for representing arbitrary, complex data structures.
We make precise the encodings of S-expressions: we give a "canonical form" for S-expressions, described two "transport" representations, and also describe an "advanced" format for display to people.

--- middle

# Introduction

S-expressions are data structures for representing complex data.
They are either byte-strings ("octet-strings") or lists of simpler S-expressions.
Here is a sample S-expression:

~~~
(snicker "abc" (#03# |YWJj|))
~~~

It is a list of length three:

- the octet-string "snicker"

- the octet-string "abc"

- a sub-list containing two elements: the hexadecimal constant #03# and the base-64 constant \|YWJj\| (which is the same as "abc")

This note gives a specific proposal for constructing and utilizing S-expressions.
The proposal is independent of any particular application.

Here are the design goals for S-expressions:

generality:
: S-expressions should be good at representing arbitrary data.

readability:
: it should be easy for someone to examine and understand the structure of an S-expression.

economy:
: S-expressions should represent data compactly.

transportability:
: S-expressions should be easy to transport over communication media (such as email) that are known to be less than perfect.

flexibility:
: S-expressions should make it relatively simple to modify and extend data structures.

canonicalization:
: it should be easy to produce a unique "canonical" form of an S-expression, for digital signature purposes.

efficiency:
: S-expressions should admit in-memory representations that allow efficient processing.

The Sections of this document cover material as follows:

- Section 2 gives an introduction to S-expressions.

- Section 3 discusses the character sets used.

- Section 4 presents the various representations of octet-strings.

- Section 5 describes how to represent lists.

- Section 6 discusses how S-expressions are represented for various uses.

- Section 7 gives an ABNF syntax for S-expressions.

- Section 8 talks about how S-expressions might be represented in memory.

- Section 9 briefly describes implementations for handling S-expressions.

- Section 10 discusses how applications might utilize S-expressions.

## Historical Notes

The S-expression technology described here was originally developed for "SDSI" (the Simple Distributed Security Infrastructure by Lampson and Rivest {{SDSI}}) in 1996, although the origins clearly date back to McCarthy's {{LISP}} programming language.
It was further refined and improved during the merger of SDSI and SPKI {{SPKI}} {{RFC2692}} {{RFC2693}} during the first half of 1997.
S-expressions are similar to, but more readable and flexible than, Bernstein's "net-strings" {{BERN}}.

Although made publicly available as a file named draft-rivest-sexp-00.txt on 4 May 1997, this document was not actually submitted to the IETF as that time.
Version -00 of this document was a modernized version of that file.
Version -01 had some further polishing and corrections.
The further significant changes made in this document were changing the original BNF notation to ABNF {{RFC5234}} (see {{ABNF}}) and changing the default character set in {{DisplayHint}} to UTF-8 {{RFC4648}}.

## Conventions Used in This Document

{::boilerplate bcp14-tagged}

# S-expressions -- informal introduction

Informally, an S-expression is either:

- an octet-string, or

- a finite list of simpler S-expressions.

An octet-string is a finite sequence of eight-bit octets.
There may be many different but equivalent ways of representing an octet-string

~~~
abc         -- as a token
"abc"       -- as a quoted string
#616263#    -- as a hexadecimal string
3:abc       -- as a length-prefixed "verbatim" encoding
{MzphYmM=}  -- as a base-64 encoding of the verbatim
                 encoding (that is, an encoding of "3:abc")
|YWJj|      -- as a base-64 encoding of the octet-string
                 "abc"
~~~

The above encodings are all equivalent; they all denote the same octet string.

We will give details of these encodings later on, and also describe how to give a "display type" to a simple string.

A list is a finite sequence of zero or more simpler S-expressions.
A list is represented by using parentheses to surround the sequence of encodings of its elements, as in:

~~~
(abc (de #6667#) "ghi jkl")
~~~

As we see, there is variability possible in the encoding of an S-expression.
In some cases, it is desirable to standardize or restrict the encodings; in other cases it is desirable to have no restrictions.
The following are the target cases we aim to handle:

- a "transport" or "basic" encoding for transporting the S-expression between computers.

- a "canonical" encoding, used when signing the S-expression.

- an "advanced" encoding used for input/output to people.

- an "in-memory" encoding used for processing the S-expression in the computer.

These need not be different; in this proposal the canonical encoding is the same as the transport encoding, for example.
In this note we propose (related) encoding techniques for each of these uses.

# Character set

We will be describing encodings of S-expressions.
Except when giving "verbatim" encodings, the character set used is limited to the following characters in US-ASCII:

Alphabetic:

~~~
A B ... Z a b ... z
~~~

numeric:

~~~
0 1 ... 9
~~~

whitespace:

~~~
space, horizontal tab, vertical tab, form-feed
carriage-return, line-feed
~~~

The following graphics characters, which we call "pseudo-alphabetic":

~~~
- hyphen or minus
. period
/ slash
_ underscore
: colon
* asterisk
+ plus
= equal
~~~

The following graphics characters, which are "reserved punctuation":

~~~
( left parenthesis
) right parenthesis
[ left bracket
] right bracket
{ left brace
} right brace
| vertical bar
# number sign
" double quote
& ampersand
\ backslash
~~~

The following characters are unused and unavailable, except in "verbatim" and "quoted string" encodings:

~~~
! exclamation point
% percent
^ circumflex
~ tilde
; semicolon
' apostrophe
, comma
< less than
> greater than
? question mark
~~~

# Octet string representations

This section describes in detail the ways in which an octet-string may be represented.

We recall that an octet-string is any finite sequence of octets, and that the octet-string may have length zero.

## Verbatim representation

A verbatim encoding of an octet string consists of three parts:

- the length (number of octets) of the octet-string, given in decimal, most significant digit first, with no leading zeros.

- a colon ":"

- the octet string itself, verbatim.

There are no blanks or whitespace separating the parts.
No "escape sequences" are interpreted in the octet string.
This encoding is also called a "binary" or "raw" encoding.

Here are some sample verbatim encodings:

~~~
3:abc
7:subject
4:::::
12:hello world!
10:abcdefghij
0:
~~~

## Quoted-string representation

The quoted-string representation of an octet-string consists of:

- an optional decimal length field

- an initial double-quote (")

- the octet string with "C" escape conventions (\n, etc)

- a final double-quote (")

The specified length is the length of the resulting string after any escape sequences have been handled.
The string does not have any "terminating NULL" that C includes, and the length does not count such a character.

The length is optional.

The escape conventions within the quoted string are as follows (these follow the "C" programming language conventions, with an extension for ignoring line terminators of just LF or CRLF and more restrictive octal and hexadecimal value formats):

~~~
\a     -- audible alert (bell)
\b     -- backspace
\t     -- horizontal tab
\v     -- vertical tab
\n     -- new-line
\f     -- form-feed
\r     -- carriage-return
\"     -- double-quote
\'     -- single-quote
\?     -- question mark
\\     -- back-slash
\ooo   -- character with octal value ooo (all three
          digits MUST be present)
\xhh   -- character with hexadecimal value hh (both
          digits MUST be present)
\<carriage-return>   -- causes carriage-return
          to be ignored.
\<line-feed>         -- causes linefeed to be
          ignored.
\<carriage-return><line-feed>   -- causes
          CRLF to be ignored.
\<line-feed><carriage-return>   -- causes
          LFCR to be ignored.
~~~

Here are some examples of quoted-string encodings:

~~~
"subject"
"hi there"
7"subject"
3"\n\n\n"
"This has\n two lines."
"This has \
 one."
""
~~~

## Token representation

An octet string that meets the following conditions may be given directly as a "token".

- it does not begin with a digit

- it contains only characters that are: alphabetic (upper or lower case); numeric; or one of the eight "pseudo-alphabetic" punctuation marks:

~~~
    -   .   /   _   :  *  +  =
~~~

(Note: upper and lower case are not equivalent.)

(Note: A token may begin with punctuation, including ":").

Here are some examples of token representations:

~~~
subject
not-before
class-of-1997
//microsoft.com/names/smith
*
~~~

## Hexadecimal representation

An octet-string may be represented with a hexadecimal encoding consisting of:


- an (optional) decimal length of the octet string

- a sharp-sign "#"

- a hexadecimal encoding of the octet string, with each octet represented with two hexadecimal digits, most significant digit first.
  There MUST be an even number of such digits.

- a sharp-sign "#"

There may be whitespace inserted in the midst of the hexadecimal encoding arbitrarily; it is ignored.
It is an error to have characters other than whitespace and hexadecimal digits.

Here are some examples of hexadecimal encodings:

~~~
#616263#    -- represents "abc"
3#616263#   -- also represents "abc"
# 616
  263 #     -- also represents "abc"
~~~


## Base-64 representation

An octet-string may be represented in a base-64 coding {{RFC4648}} consisting of:

- an (optional) decimal length of the octet string

- a vertical bar "\|"

- the base-64 {{RFC4648}} encoding of the octet string.

- a final vertical bar "\|"

The base-64 encoding uses only the characters

~~~
A-Z  a-z  0-9  +  /  =
~~~

It produces four characters of output for each three octets of input.
If the input has one or two left-over octets of input, it produces an output block of length four ending in two or one equals signs, respectively.
Output routines compliant with this standard MUST output the equals signs as specified.
Input routines MAY accept inputs where the equals signs are dropped.

There may be whitespace inserted in the midst of the base-64 encoding arbitrarily; it is ignored.
It is an error to have characters other than whitespace and base-64 characters.

Here are some examples of base-64 encodings:

~~~
|YWJj|       -- represents "abc"
| Y W
  J j |      -- also represents "abc"
3|YWJj|      -- also represents "abc"
|YWJjZA==|   -- represents "abcd"
|YWJjZA|     -- also represents "abcd"
~~~

## Display hint {#DisplayHint}

Any octet string may be preceded by a single "display hint".

The purposes of the display hint is to provide information on how to display the octet string to a user.
It has no other function.
Many of the MIME {{RFC2046}} types work here.

A display-hint is an octet string surrounded by square brackets.
There may be whitespace separating the octet string from the surrounding brackets.
Any of the legal formats may be used for the octet string.

Here are some examples of display-hints:

~~~
[image/gif]
[URI]
[charset=unicode-1-1]
[text/richtext]
[application/postscript]
[audio/basic]
["http://abc.com/display-types/funky.html"]
~~~

In applications an octet-string that is untyped may be considered to have a pre-specified "default" MIME {{RFC2046}} type.
The MIME type

~~~
"text/plain; charset=utf-8"
~~~

is the standard default.

## Equality of octet-strings

Two octet strings are considered to be "equal" if and only if they have the same display hint and the same data octet strings.

Note that octet-strings are "case-sensitive"; the octet-string "abc" is not equal to the octet-string "ABC".

An untyped octet-string can be compared to another octet-string (typed or not) by considering it as a typed octet-string with the default mime-type specified in {{DisplayHint}} .

# Lists

Just as with octet-strings, there are several ways to represent an S-expression.
Whitespace may be used to separate list elements, but they are only required to separate two octet strings when otherwise the two octet strings might be interpreted as one, as when one token follows another.
Also, whitespace may follow the initial left parenthesis, or precede the final right parenthesis.

Here are some examples of encodings of lists:

~~~
(a b c)

( a ( b c ) ( ( d e ) ( e f ) )  )

(11:certificate(6:issuer3:bob)(7:subject5:alice))

({ODpFeGFtcGxlIQ==} "1997" murphy 3:XC+)
~~~

# Representation types

There are three "types" of representations:

- canonical

- basic transport

- advanced transport

The first two MUST be supported by any implementation; the last is
OPTIONAL.

## Canonical representation {#canonical}

This canonical representation is used for digital signature purposes, transmission, etc.
It is uniquely defined for each S-expression.
It is not particularly readable, but that is not the point.
It is intended to be very easy to parse, to be reasonably economical, and to be unique for any S-expression.

The "canonical" form of an S-expression represents each octet-string in verbatim mode, and represents each list with no blanks separating elements from each other or from the surrounding parentheses.

Here are some examples of canonical representations of S-expressions:

~~~
(6:issuer3:bob)

(4:icon[12:image/bitmap]9:xxxxxxxxx)

(7:subject(3:ref5:alice6:mother))
~~~

## Basic transport representation

There are two forms of the "basic transport" representation:

- the canonical representation

- an {{RFC4648}} base-64 representation of the canonical representation, surrounded by braces.

The transport mechanism is intended to provide a universal means of representing S-expressions for transport from one machine to another.

Here are some examples of an S-expression represented in basic transport mode:

~~~
(1:a1:b1:c)

{KDE6YTE6YjE6YykK}
~~~

The second example above is the same S-expression as the first encoded in base-64.

There is a difference between the brace notation for base-64 used here and the \|\| notation for base-64'd octet-strings described above.
Here the base-64 contents are converted to octets, and then re-scanned as if they were given originally as octets.
With the \|\| notation, the contents are just turned into an octet-string.

## Advanced transport representation

The "advanced transport" representation is intended to provide more flexible and readable notations for documentation, design, debugging, and (in some cases) user interface.

The advanced transport representation allows all of the representation forms described above in Section 4, include quoted strings, base-64 and hexadecimal representation of strings, tokens, representations of strings with omitted lengths, and so on.

# ABNF for syntax {#ABNF}

ABNF is the Augmented Backus-Naur Form for syntax specifications as defined in {{RFC5234}}.
We give separate ABNF's for canonical, basic, and advanced forms of S-expressions.
The rules below in all caps are defined in Appendix A of {{RFC5234}}.

For canonical transport:

~~~
sexp     =  raw / ("(" *sexp ")")

raw      =  decimal ":" *OCTET
               ; the length followed by a colon and the exact
               ;  number of OCTET indicated by the length

decimal  =  %x30 / (%x31-39 *DIGIT)
~~~

For basic transport:

~~~
sexp           =  canonical / base-64-raw

canonical      =  raw / ("(" *canonical ")")

raw            =  decimal ":" *OCTET
                     ; the length followed by a colon and the exact
                     ;  number of OCTET indicated by the length

decimal        =  %x30 / (%x31-39 *DIGIT)

base-64-raw    =  "{" 3*base-64-char "}"

base-64-char   =  ALPHA / DIGIT / "+" / "/" / "="
~~~

For advanced transport:

~~~
sexp           =  *whitespace value *whitespace

whitespace     =  SP / HTAB / vtab / CR / LF / ff

vtab           =  %x0B   ; vertical tab

ff             =  %x0C   ; form feed

value          =  string / ("(" *(value / whitespace) ")")

string         =  [display] *whitespace simple-string

display        =  "[" *whitespace simple-string *whitespace "]"

simple-string  =  raw / token / base-64 / base-64-raw /
                        hexadecimal / quoted-string

raw            =  decimal ":" *OCTET
                     ; the length followed by a colon and the exact
                     ;  number of OCTET indicated by the length

decimal        =  %x30 / (%x31-39 *DIGIT)

token          =  (ALPHA / simple-punc) *(ALPHA / DIGIT /
                     simple-punc)

simple-punc    =  "-" / "." / "/" / "_" / ":" / "*" / "+" / "="

base-64        =  [decimal] "|" *(base-64-char / whitespace) "|"

base-64-char   =  ALPHA / DIGIT / "+" / "/" / "="

base-64-raw    =  [decimal] "{" 1*(base-64-char / whitespace) "}"
                     ; at least 3 base-64-char

hexadecimal    =  [decimal] "#" *(HEXDIG / whitespace) "#"
                     ; even number of hexadecimal digits

quoted-string  =  [decimal] DQUOTE *(printable / escaped) DQUOTE

escaped        =  backslash (%x3F / %x61 / %x62 / %x66 / %x6E /
                  %x72 / %x74 / %x76 / DQUOTE / quote / backslash /
                  3(%x30-37) / (%x78 2HEXDIG) / CR / LF /
                  (CR LF) / (LF CR))

backslash      =  %x5C

printable      =  %x21-26 / %x28-7E

quote          =  %x27   ; single quote
~~~


# In-memory representations

For processing, the S-expression would typically be parsed and
represented in memory in a way that is more amenable to efficient
processing.  We suggest two alternatives:


- "list-structure"

- "array-layout"

We only sketch these here, as they are only suggestive.  The code
referenced below illustrates these styles in more detail.

## List-structure memory representation

Here there are separate records for simple-strings, strings, and
lists.  An S-expression of the form ("abc" "de") would require two
records for the simple strings, two for the strings, and two for the
list elements.  This is a fairly conventional representation, and
details are omitted here.


## Array-layout memory representation

Here each S-expression is represented as a contiguous array of bytes.
The first byte codes the "type" of the S-expression:

~~~
01   octet-string

02   octet-string with display-hint

03   beginning of list (and 00 is used for "end of list")
~~~

Each of the three types is immediately followed by a k-byte integer
indicating the size (in bytes) of the following representation.  Here
k is an integer that depends on the implementation, it might be
anywhere from 2 to 8, but would be fixed for a given implementation;
it determines the size of the objects that can be handled.  The
transport and canonical representations are independent of the choice
of k made by the implementation.

Although the length of lists are not given in the usual
S-expression notations, it is easy to fill them in when parsing; when
you reach a right-parenthesis you know how long the list
representation was, and where to go back to fill in the missing
length.

### Octet string

This is represented as follows:

~~~
01 <length> <octet-string>
~~~

For example (here k = 2)

~~~
01 0003 a b c
~~~


### Octet-string with display-hint

This is represented as follows:

~~~
02 <length>
  01 <length> <octet-string>    /* for display-type */
  01 <length> <octet-string>    /* for octet-string */
~~~

For example, the S-expression

~~~
[gif] #61626364#
~~~

would be represented as (with k = 2)

~~~
02 000d
  01 0003  g  i  f
  01 0004 61 62 63 64
~~~


### List

This is represented as

~~~
03 <length> <item1> <item2> <item3> ... <itemn> 00
~~~

For example, the list (abc \[d]ef (g)) is represented in memory as
(with k=2)

~~~
03 001b
  01 0003 a b c
  02 0009
    01 0001 d
    01 0002 e f
  03 0005
    01 0001 g
  00
00
~~~




# Code {#Code}

At this time there is code available that is intended to read and parse
some or all of the various S-expression formats specified here. In
particular, see the following likely incomplete list:

- Project GNU's {{Libgcrypt}}.

- Github project of J. P. Malkiewicz {{SexpCode}}.

# Utilization of S-expressions

S-expressions are used in {{SPKI}} specified in {{RFC2693}}.

This note has described S-expressions in general form.
Application writers may wish to restrict their use of S-expressions in various ways.
Here are some possible restrictions that might be considered:

- no display-hints

- no lengths on hexadecimal, quoted-strings, or base-64 encodings

- no empty lists

- no empty octet-strings

- no lists having another list as its first element

- no base-64 or hexadecimal encodings

- fixed limits on the size of octet-strings

# IANA Considerations

This document requires no IANA actions.

# Security Considerations

As a pure data representation format, there are few security considerations to S-expressions.
A canonical form is required for the reliable verification of digital signatures and this is provided in {{canonical}}.

--- back

# Change History

RFC Editor Note: Please delete this section before publication.

## -00 Changes

This sub-section summarizes significant changes between the original 1997 -00 version of this document and the 2023 version submitted to the IETF.

- Convert to XML v3.

- Update Ron Rivest author information and, with his permission, add Donald Eastlake as an author.

- Add minimal "IANA Considerations" and "Security Considerations" sections.

- Since implementation requirements terminology is used, add the usual paragraph about it as a sub-section of Section 1 and add references to {{RFC2119}} and {{RFC8174}}.

- Divide references into Normative and Informational and update base-64 reference to be to {{RFC4648}}.

- Add a couple of sentence to the "Historical note" section about the history of -00 versions of the draft.

## Changes from -00 to -01

- Fix glitches and errors in the BNF.

- Add Acknowledgements section to list Marc Petit-Huguenin (who provided BNF improvements) and John Klensin.

- Update code references in {{Code}} and add to Informative References section. Note: The code in the Malkiewicz github repository may be the code that was originally at http://theory.lcs.mit.edu/~rivest/sexp.html

- Add this Change History Appendix.

- Move "Historical Notes" which were formerly a separate section at the end of the document up to be a sub-section of Section 1.

- Add references to {{LISP}}, {{RFC2692}}, and {{RFC2693}}.

- Add simple security considerations.

- Minor editorial fixes/improvements.

## Changes from -01 to -02

- Change default MIME Type in {{DisplayHint}} to have charset=utf-8 {{RFC4648}}.

- Change BNF to ABNF and add reference to {{RFC5234}}.

- Move Marc Petit-Huguenin to a Contributors section for his work on the ABNF.

# Acknowledgements {#Acknowledgements}
{: numbered="false"}

The comments and suggestions of the following are gratefully acknowledged: John Klensin.

--- contributor

Special thanks to the following contributor:
