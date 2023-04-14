require 'formula'

class Dumpasn1 < Formula
  # I originally took checksums from FreeBSD Ports;
  # warning: there's no versioning on master site.
  homepage 'https://www.cs.auckland.ac.nz/~pgut001/'

  # When upstream changes the cfg file without changing the .c file
  revision 1

  # 2023-04-14: files self-identify as, and last-mod-timestamp-on-server:
  #   dumpasn1.c    20210422  2022-09-16T03:01:46Z (unchanged)
  #   dumpasn1.cfg  20230207  2023-03-22T23:12:43Z
  #
  # SHA256 match against <https://aur.archlinux.org/packages/dumpasn1/>
  #
  # MAINTAINER NOTE: SEE PRIVATE GIT REPO archive/tracking/dumpasn1 FOR COMPARING HISTORICAL CODE
  version '20210422'
  url 'https://www.cs.auckland.ac.nz/~pgut001/dumpasn1.c'
  sha256 '8ce8fdbf2e9b11d410b0ab4e44a6b3f89c27080113f051ec1054d230e050a0b8'
  resource 'cfg' do
    version '20230207'
    url 'https://www.cs.auckland.ac.nz/~pgut001/dumpasn1.cfg'
    sha256 'ed1eaafb0ad865b97738dfe0b0e5d602c76dc0cde4c0cee4cdcdd11c28f480e5'
  end

  def install
    # We use libexec because we force-download updates and embed the path, so
    # anything using the /usr/local/share path directly would be an error and
    # I can't see how to have a share file which is not symlinked in.

    # Not sure how the FreeBSD -DCONFIG_NAME works, given the code logic; instead,
    # we hack the source to update configPaths; inserting a string into a list,
    # and the string must end with a / because it's not implicit.
    inreplace 'dumpasn1.c' do |s|
      s.gsub! /(configPaths\[\].*[[:space:]])(\s*#ifndef DEBIAN)/, "\\1\"#{libexec}/\",\n\\2"
    end

    system ENV.cc, '-o', 'dumpasn1', 'dumpasn1.c'
    bin.install 'dumpasn1'
    libexec.install resource('cfg')
  end
end
