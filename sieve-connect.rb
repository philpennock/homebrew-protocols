require "formula"

class SieveConnect < Formula
  # no dedicated homepage for it (yet), just a mention on a list of software
  # from the author (me)
  desc "Client for ManageSieve protocol for mail server Sieve scripts"
  homepage "https://people.spodhuis.org/phil.pennock/software/"
  url "https://people.spodhuis.org/phil.pennock/software/sieve-connect-0.89.tar.bz2"
  mirror "https://github.com/philpennock/sieve-connect/releases/download/v0.89/sieve-connect-0.89.tar.bz2"
  sha256 "6d8962516458a27d4d904cfb370db01ca7e495e61c966f236ba6b65f5b4caa5f"
  revision 1

  head "https://github.com/philpennock/sieve-connect.git"

  # The crashing comes from bugs in the GSSAPI code; there's a fix in the
  # bug-tracker for the project, but there's been no release in a few years.
  # If you locally fix the GSSAPI module, then you can have stable GSSAPI in
  # Perl on macOS, but that's not the default.
  option "with-gssapi", "Allow use of GSSAPI Perl modules (can crash Perl on MacOS)"
  option "without-readline", "Avoid readline dependency"
  option "without-bundled-publicsuffix", "Do not pull in our own copy of Mozilla::PublicSuffix"

  deprecated_option "enable-gssapi" => "with-gssapi"
  deprecated_option "disable-readline" => "without-readline"
  deprecated_option "unbundle-publicsuffix" => "without-bundled-publicsuffix"

  if build.with? "readline"
    resource "Term::ReadLine::Gnu" do
      url "https://www.cpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.35.tar.gz"
      sha256 "575d32d4ab67cd656f314e8d0ee3d45d2491078f3b2421e520c4273e92eb9125"
    end
  end

  if build.with? "bundled-publicsuffix"
    resource "Mozilla::PublicSuffix" do
      url "https://www.cpan.org/authors/id/R/RS/RSIMOES/Mozilla-PublicSuffix-v1.0.0.tar.gz"
      sha256 "8185ca687ad1c51e18cb472831f80160d6432376a06a19f864d617147b003dee"
    end
  end

  # Want fixed OpenSSL with SNI support
  depends_on "openssl"

  depends_on "Readline" if build.with? "readline"

  # These digests just from a download locally, source not verified.
  # Net::SSLeay first, so IO::Socket::SSL finds it; need our own to actually
  # link against the Brew OpenSSL.
  resource "Net::SSLeay" do
    url "https://www.cpan.org/authors/id/M/MI/MIKEM/Net-SSLeay-1.84.tar.gz"
    sha256 "823ec3cbb428309d6a9e56f362a9300693ce3215b7fede109adb7be361fff177"
  end
  #
  resource "Authen::SASL" do
    url "https://www.cpan.org/authors/id/G/GB/GBARR/Authen-SASL-2.16.tar.gz"
    sha256 "6614fa7518f094f853741b63c73f3627168c5d3aca89b1d02b1016dc32854e09"
  end
  resource "IO::Socket::INET6" do
    url "https://www.cpan.org/authors/id/S/SH/SHLOMIF/IO-Socket-INET6-2.72.tar.gz"
    sha256 "85e020fa179284125fc1d08e60a9022af3ec1271077fe14b133c1785cdbf1ebb"
  end
  resource "IO::Socket::SSL" do
    url "https://www.cpan.org/authors/id/S/SU/SULLR/IO-Socket-SSL-2.052.tar.gz"
    sha256 "e4897a9b17cb18a3c44aa683980d52cef534cdfcb8063d6877c879bfa2f26673"
  end
  resource "Net::DNS" do
    url "https://www.cpan.org/authors/id/N/NL/NLNETLABS/Net-DNS-1.14.tar.gz"
    sha256 "83c38a594eeb2c85d66e60047a0f5b403f34bd92a5d13606f02e828d450299fc"
  end
  resource "Term::ReadKey" do
    url "https://www.cpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.37.tar.gz"
    sha256 "4a9383cf2e0e0194668fe2bd546e894ffad41d556b41d2f2f577c8db682db241"
  end

  # For Term::ReadLine::Gnu, it won't install by default because it
  # fails against the replacement libedit sourced libraries provided as
  # part of MacOS base.  Thus we explicitly depend upon 'Readline' above
  # and install the Perl as a resource, so that Homebrew can find the
  # dependencies for us.

  def install
    # The approach to vendoring of Perl modules used here is that
    # described by @ilovezfs in a comment 2017-08-26 in:
    # https://github.com/Homebrew/homebrew-science/issues/6213

    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"
    ENV.prepend_path "PERL5LIB", libexec/"lib"

    mkdir_p man1
    mkdir_p (libexec/"bin")
    mkdir_p bin

    resources.each do |res|
      res.stage do
        case res.name

        when "Mozilla::PublicSuffix"
          if build.with? "bundled-publicsuffix"
            system "sh", "-c", "PERL_MM_USE_DEFAULT=t perl Build.PL --install_base=#{libexec}"
            system "./Build"
            system "./Build", "test"
            system "./Build", "install"
          end

        when "Term::ReadLine::Gnu"
          if build.with? "readline"
            # At some point, the keg for readline from brew got built "x86_64"-only, not dual x86_64/i386,
            # which breaks the build here
            system "env", "ARCHFLAGS=-arch x86_64", "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
            system "make"
            system "make", "install"
          end

        when "Net::SSLeay"
          # Prompts for network testing, only env-control knobs accept defaults,
          # but the default is to do the testing.  So echo no into it.
          Open3.pipeline(["echo", "no"], ["perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"])
          system "make", "PERL5LIB=#{ENV["PERL5LIB"]}"
          system "make", "install"

        else # res.name switch

          if File.exist? "Makefile.PL"
            system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
            system "make", "PERL5LIB=#{ENV["PERL5LIB"]}"
            system "make", "install"
          else
            system "perl", "Build.PL", "--install_base", libexec
            system "./Build", "PERL5LIB=#{ENV["PERL5LIB"]}"
            system "./Build", "install"
          end

        end
      end
    end

    inreplace "sieve-connect.pl",
      /(# No user-serviceable parts below)/,
      '\1'"\nuse lib '#{libexec}/lib/perl5';"

    #before = (libexec/"bin").children
    system "make", "PERL5LIB=#{ENV["PERL5LIB"]}", "PREFIX=#{prefix}", "MANDIR=share/man", "install"
    #after = (libexec/"bin").children

    #bin_to_link = after - before
    #bin.install bin_to_link
    bin.env_script_all_files(libexec/"bin", :PERL5LIB => ENV["PERL5LIB"])
  end

  def patches
    if build.head?
      ln_s "/Library/Caches/Homebrew/sieve-connect--git/.git", ".git"
      system "git", "fetch", "--depth=20"
      system "make", "sieve-connect.pl", "man"
    end

    DATA if build.without? "gssapi"
  end

  def caveats
    s = ""
    s += "Last-published GSSAPI module can cause Perl interpreter crashes" if build.with? "gssapi"
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

