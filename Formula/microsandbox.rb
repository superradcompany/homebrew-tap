# typed: false
# frozen_string_literal: true

class Microsandbox < Formula
  desc "Spins up lightweight VMs in milliseconds from SDKs"
  homepage "https://microsandbox.dev"
  license "Apache-2.0"
  version "0.3.12"

  # libkrunfw versioned filenames (must match the build)
  LIBKRUNFW_VERSION = "5.2.1"
  LIBKRUNFW_ABI = "5"

  on_macos do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "1134aa2f57d29dec0f516ba001aa796c27331b553826a7c5a8effc1a947d86a4"
    end

    on_intel do
      odie "microsandbox requires Apple Silicon (M1+). x86_64 macOS is not supported."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-aarch64.tar.gz"
      sha256 "108dce727c350f17b2925bbdde00056af6760809d332963913757d9aaae942b7"
    end

    on_intel do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-x86_64.tar.gz"
      sha256 "bd0eb76a91e4a0dcdd7c16a3525f35435727422a43c4470f31d3aec1c6b56902"
    end
  end

  def install
    bin.install "msb"

    on_macos do
      # Tarball contains: libkrunfw.5.dylib
      # Install with versioned name and create symlinks
      lib.install "libkrunfw.#{LIBKRUNFW_ABI}.dylib"
      lib.install_symlink "libkrunfw.#{LIBKRUNFW_ABI}.dylib" => "libkrunfw.dylib"

      # Update the binary's rpath so it can find the library in the Homebrew prefix
      system "install_name_tool", "-add_rpath", lib.to_s, bin/"msb"
    end

    on_linux do
      # Tarball contains: libkrunfw.so.5.2.1
      # Install with versioned name and create symlinks
      lib.install "libkrunfw.so.#{LIBKRUNFW_VERSION}"
      lib.install_symlink "libkrunfw.so.#{LIBKRUNFW_VERSION}" => "libkrunfw.so.#{LIBKRUNFW_ABI}"
      lib.install_symlink "libkrunfw.so.#{LIBKRUNFW_VERSION}" => "libkrunfw.so"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/msb --version")
  end
end
