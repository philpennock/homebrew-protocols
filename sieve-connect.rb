require 'formula'

class SieveConnect < Formula
  # no dedicated homepage for it (yet), just a mention on a list of software
  # from the author (me)
  homepage 'https://people.spodhuis.org/phil.pennock/software/'
  url 'https://people.spodhuis.org/phil.pennock/software/sieve-connect-0.89.tar.bz2'
  mirror 'https://github.com/philpennock/sieve-connect/releases/download/v0.89/sieve-connect-0.89.tar.bz2'
  sha256 '6d8962516458a27d4d904cfb370db01ca7e495e61c966f236ba6b65f5b4caa5f'
  head 'https://github.com/philpennock/sieve-connect.git'

  option 'enable-gssapi', 'Allow use of GSSAPI Perl modules (crashes Perl on MacOS)'
  option 'disable-readline', 'Avoid readline dependency'
  option 'unbundle-publicsuffix', 'Do not pull in our own copy of Mozilla::PublicSuffix'

  resource 'Term::ReadLine::Gnu' do
    url 'https://www.cpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.35.tar.gz'
    sha256 '575d32d4ab67cd656f314e8d0ee3d45d2491078f3b2421e520c4273e92eb9125'
  end if not build.include? 'disable-readline'

  resource 'Mozilla::PublicSuffix' do
    url 'https://www.cpan.org/authors/id/R/RS/RSIMOES/Mozilla-PublicSuffix-v1.0.0.tar.gz'
    sha256 '8185ca687ad1c51e18cb472831f80160d6432376a06a19f864d617147b003dee'
  end if not build.include? 'unbundle-publicsuffix'

  depends_on 'Readline' if not build.include? "disable-readline"

  depends_on 'Authen::SASL' => :perl
  depends_on 'IO::Socket::INET6' => :perl
  depends_on 'IO::Socket::SSL' => :perl
  depends_on 'Net::DNS' => :perl
  depends_on 'Term::ReadKey' => :perl

  # I wanted: depends_on 'Mozilla::PublicSuffix' => [:perl, :recommended]
  # We could let the user install this outside of Homebrew, but unfortunately
  # :perl and :recommended do not play together and it becomes a hard error.
  # Better to just bundle it ourselves.  If the user unbundles, we'll still
  # use it if available at runtime.

  # For Term::ReadLine::Gnu, it won't install by default because it
  # fails against the replacement libedit sourced libraries provided as
  # part of MacOS base.  Thus we explicitly depend upon 'Readline' above
  # and install the Perl as a resource, so that Homebrew can find the
  # dependencies for us.

  def install
    resource('Mozilla::PublicSuffix').stage do
      system "sh", "-c", "PERL_MM_USE_DEFAULT=t perl Build.PL --install_base=#{libexec}"
      system "./Build"
      system "./Build", "test"
      system "./Build", "install"
    end if not build.include? 'unbundle-publicsuffix'

    resource('Term::ReadLine::Gnu').stage do
      # At some point, the keg for readline from brew got built "x86_64"-only, not dual x86_64/i386,
      # which breaks the build here
      system "env", "ARCHFLAGS=-arch x86_64", "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
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
    if build.head? then
      system "ln", "-s", "/Library/Caches/Homebrew/sieve-connect--git/.git", ".git"
      system "git", "fetch", "--depth=20"
      system "make", "sieve-connect.pl", "man"
    end

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
    system "#{bin}/sieve-connect", "--version" end
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

