require 'formula'

class Dumpasn1 < Formula
  # Taking checksums from FreeBSD Ports; warning: there's no versioning on
  # master site.
  # Current: FreeBSD defines as 20130805
  homepage 'http://www.cs.auckland.ac.nz/~pgut001/'

  version "20170309"
  url 'http://www.cs.auckland.ac.nz/~pgut001/dumpasn1.c'
  sha256 '4b7c7d92c9593ee58c81019b2c3b7a7ee7450b733d38f196ce7560ee0e34d6b1'
  resource 'cfg' do
    version "20140417"
    url 'http://www.cs.auckland.ac.nz/~pgut001/dumpasn1.cfg'
    sha256 '8b0c25bb3a4608b4678d25c56965e26e7780c73715032e447a506514a0815201'
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
