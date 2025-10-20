class Transito < Formula
  desc "HLS downloader CLI tool"
  homepage "https://github.com/yourusername/transito"
  url "https://github.com/yourusername/transito/archive/v0.2.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  
  depends_on "python@3.14"
  depends_on "ffmpeg"
  
  def install
    # Install the core CLI tool
    bin.install "packages/core/transito"
  end
  
  test do
    # Test that the CLI tool works
    system "#{bin}/transito", "--help"
  end
end
