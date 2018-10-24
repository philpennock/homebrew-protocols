require 'formula'

class Dumpasn1 < Formula
  # I originally took checksums from FreeBSD Ports;
  # warning: there's no versioning on master site.
  homepage 'http://www.cs.auckland.ac.nz/~pgut001/'

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
  version "20180611"
  url 'http://www.cs.auckland.ac.nz/~pgut001/dumpasn1.c'
  sha256 'd42b7fb8457b9282ee341429baaaaf0ef7b2310cb28fcf2fc41914e07e8b1370'
  resource 'cfg' do
    version "20180611"
    url 'http://www.cs.auckland.ac.nz/~pgut001/dumpasn1.cfg'
    sha256 '94245ed185e2bdb94b00ba031bb67ab83980748626f532ee4565df886468f196'
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
