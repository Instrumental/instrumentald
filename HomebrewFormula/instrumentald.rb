class Instrumentald < Formula
  head "https://github.com/Instrumental/instrumentald.git"
  desc "A server agent that provides system monitoring and service monitoring. It's fast, reliable, runs on anything *nix, is simple to configure and deploy, and has a small memory footprint."
  homepage "https://github.com/Instrumental/instrumentald"
  url "https://github.com/Instrumental/instrumentald/releases/download/0.0.5/instrumentald_0.0.5_osx.tar.gz"
  version "0.0.5"
  sha256 "1c6eb9516c9a99d8ba55d1ab3a99d744c442f1aafbe2ded220302b76288c6023"

  def install
    inreplace "opt/instrumentald/instrumentald" do |s|
      s.gsub! /SELFDIR=.*/, "SELFDIR=\"#{bin}\""
    end

    bin.install Dir["opt/instrumentald/*"]
  end

  def post_install
    FileUtils.chmod 0666, "#{bin}/lib/vendor/Gemfile.lock"
    ohai "instrumentald is ready to go! More info about getting started at https://instrumentalapp.com/docs/isd/getting-started"
  end
end
