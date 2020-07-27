require 'formula'

class Dumpasn1 < Formula
  # I originally took checksums from FreeBSD Ports;
  # warning: there's no versioning on master site.
  homepage 'https://www.cs.auckland.ac.nz/~pgut001/'

  # When upstream changes the cfg file without changing the .c file
  #revision 1

  # Originally: FreeBSD defines as 20130805
  # Diffed and reviewed since then.

  # 2018-08-14 note: report of checksum failures, dumpasn1.c still claims to be
  # 20170309 but has lost extraneous line-trailing whitespace and inserted one
  # other name into the credits list relative to the version I had cached.
  #
  # Since dumpasn1.cfg had its first update in years from 20140417 to 20180611
  # and any future update to dumpasn1.c will have a newer datestamp, reuse the
  # .cfg datestamp as the version for .c here.  They were _probably_ updated on
  # the web-server at the same time and even if they weren't, this is "good
  # enough given the alternatives".
  #
  # dumpasn1.cfg's changes were substantive; mostly additions, but also some
  # nit fixes for GOST entries.
  #
  # 2018-10-24 note: report of checksum failure, the .cfg file still claims
  # 20180611 but had a modified OID arc; webserver claims last modified
  # 20180614 so that is what we'll use.
  #
  version "20191022"
  url 'https://www.cs.auckland.ac.nz/~pgut001/dumpasn1.c'
  sha256 'ba379c34d73ebf063081b760bc68b797091ec5e6b1c00052614a271119582e97'
  resource 'cfg' do
    version "20191022"
    url 'https://www.cs.auckland.ac.nz/~pgut001/dumpasn1.cfg'
    sha256 '917f48e2e1f539c8cc9c1eb08ca4cfc9680a04ad194d47a16d89dd42551cc972'
  end

  def install
    # We use libexec because we force-download updates and embed the path, so
    # anything using the /usr/local/share path directly would be an error and
    # I can't see how to have a share file which is not symlinked in.

    # Not sure how the FreeBSD -DCONFIG_NAME works, given the code logic; instead,
    # we hack the source to update configPaths; inserting a string into a list,
    # and the string must end with a / because it's not implicit.
    inreplace "dumpasn1.c" do |s|
      s.gsub! /(configPaths\[\].*[[:space:]])(\s*#ifndef DEBIAN)/, "\\1\"#{libexec}/\",\n\\2"
    end

    system ENV.cc, "-o", "dumpasn1", "dumpasn1.c"
    bin.install "dumpasn1"
    libexec.install resource('cfg')
  end
end
