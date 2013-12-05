require 'formula'

class SieveConnect < Formula
  # no dedicated homepage for it (yet), just a mention on a list of software
  # from the author (me)
  homepage 'http://people.spodhuis.org/phil.pennock/software/'
  url 'http://people.spodhuis.org/phil.pennock/software/sieve-connect-0.87.tar.bz2'
  mirror 'https://github.com/philpennock/sieve-connect/releases/download/v0.87/sieve-connect-0.87.tar.bz2'
  sha1 'b52235d21202dfa1300b32000308c7233f4f63c2'
  head 'https://github.com/philpennock/sieve-connect.git'

  option 'enable-gssapi', 'Allow use of GSSAPI Perl modules (crashes Perl on MacOS)'
  option 'disable-readline', 'Avoid readline dependency'

  resource 'Term::ReadLine::Gnu' do
    url 'http://www.cpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.20.tar.gz'
    sha1 '23f2562c436c09e0d6ca85e135727d73bfdb18ea'
  end if not build.include? 'disable-readline'

  depends_on 'Readline' if not build.include? "disable-readline"

  depends_on 'Authen::SASL' => :perl
  depends_on 'IO::Socket::INET6' => :perl
  depends_on 'IO::Socket::SSL' => :perl
  depends_on 'Net::DNS' => :perl
  depends_on 'Term::ReadKey' => :perl

  # We let the user install this outside of Homebrew
  depends_on 'Mozilla::PublicSuffix' => [:perl, :recommended]

  # but for Term::ReadLine::Gnu, it won't install by default because it
  # fails against the replacement libedit sourced libraries provided as
  # part of MacOS base.  Thus we explicitly depend upon 'Readline' above
  # and install the Perl as a resource, so that Homebrew can find the
  # dependencies for us.

  def install
    resource('Term::ReadLine::Gnu').stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
      system "make"
      system "make", "install"
    end if not build.include? 'disable-readline'

    inreplace "sieve-connect.pl",
      /(# No user-serviceable parts below)/,
      '\1'"\nuse lib '#{libexec}/lib/perl5';"

    system "mkdir", "-p", bin, man1
    system "make", "PREFIX=#{prefix}", "MANDIR=share/man", "install"
  end

  def patches
    DATA if not build.include? "enable-gssapi"
  end

  def caveats
    s = ""
    s += "GSSAPI modules can cause Perl interpreter crashes" if build.include? "enable-gssapi"
    s
  end

  test do
    # We are a Perl script, but a full test requires a server.
    # So settle for checking that dependencies are met.
    system "#{bin}/sieve-connect", "--version"
  end
end

__END__
--- a/sieve-connect.pl	2013-12-04 18:55:18.000000000 -0500
+++ b/sieve-connect.pl	2013-12-04 18:55:40.000000000 -0500
@@ -55,7 +55,7 @@
 # Add a key to this to blacklist that authentication mechanism.  Might be
 # useful on some platforms with broken libraries.  Make sure the key is
 # upper-case!
-my %blacklist_auth_mechanisms = ();
+my %blacklist_auth_mechanisms = ( GSSAPI => 1, SPNEGO => 1 );
 # my %blacklist_auth_mechanisms = ( GSSAPI => 1, SPNEGO => 1 );
 
 # This says "go ahead and use SRV records and local hostname to figure out

