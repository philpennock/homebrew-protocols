require 'formula'

class Dumpasn1 < Formula
  # Taking checksums from FreeBSD Ports; warning: there's no versioning on
  # master site.
  # Current: FreeBSD defines as 20130805
  homepage 'http://www.cs.auckland.ac.nz/~pgut001/'

  version "20140805"
  url 'http://www.cs.auckland.ac.nz/~pgut001/dumpasn1.c'
  sha256 'd95b0af449e403ac3b4d95df61d5330e324a3076f973569a83ffd1fc0bd095e3'
  resource 'cfg' do
    version "20140805"
    url 'http://www.cs.auckland.ac.nz/~pgut001/dumpasn1.cfg'
    sha256 'd368f8c14f8ca9df5151ca2ed550793393c0a7a0f78fe160c886a7aad9cdd75b'
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
