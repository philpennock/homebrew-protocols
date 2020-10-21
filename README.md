Homebrew: Protocols
===================

**WARNING: UNMAINTAINED**

_I no longer use macOS for a desktop/laptop OS, and do not use Homebrew on Linux, so am not in a position to test fixes to this repository._
_Please either fork this (I will link to a maintained fork) or provide patches: I will merge, untested, sane-looking fixes._

These formulae are for Homebrew, a package management system for MacOS.

Support for non-macOS Brew is limited to non-existent, for pragmatic reasons.
Note that `sieve-connect` is packaged for many OSes natively.


What is here
------------

Anything which catches my fancy but is too obscure for Homebrew, which I
suspect will involve dealing with miscellaneous protocols in various ways.

* `dumpasn1.rb`: Peter Gutmann's `dumpasn1` tool, useful for debugging
   various DER data structures;
  + `dumpasn1 =(openssl x509 -outform der -in cert.pem)`
  + (above example uses zsh-specific `=(...)` syntax)
* `sieve-connect.rb`: this is for my own sieve-connect tool, which is
   packaged for various OS distributions.  It speaks ManageSieve.


How do I install these formulae?
--------------------------------

Just `brew tap philpennock/protocols` and then `brew install <formula>`.

If the formula conflicts with one from mxcl/master or another tap, you can
`brew install philpennock/protocols/<formula>`.


