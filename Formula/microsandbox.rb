# typed: false
# frozen_string_literal: true

class Microsandbox < Formula
  desc "Spins up lightweight VMs in milliseconds from SDKs"
  homepage "https://microsandbox.dev"
  license "Apache-2.0"
  version "0.6.10"

  # libkrunfw versioned filenames (must match the build)
  LIBKRUNFW_VERSION = "5.2.1"
  LIBKRUNFW_ABI = "5"

  on_macos do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "a1742728676bbdfa3850e59df4b85b9df7dabcfd7e1c270876725aecdd3e992c"
    end

    on_intel do
      odie "microsandbox requires Apple Silicon (M1+). x86_64 macOS is not supported."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-aarch64.tar.gz"
      sha256 "b248700b9760a8955e6785676f1a5738df225743427defacfad5f42f8db57b6b"
    end

    on_intel do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-x86_64.tar.gz"
      sha256 "53e632e80cb4f2efa753f8a3848acd840d0ab130062df02afcb33aa71c260c48"
    end
  end

  def install
    # Keep msb and its private libkrunfw together in libexec, then expose msb on
    # PATH through a wrapper script. The binary already carries an
    # @executable_path rpath, so it finds the library sitting beside it without
    # any install_name_tool edit. That matters on macOS: modifying the binary
    # would invalidate its code signature, and the release binary is signed with
    # the com.apple.security.hypervisor and disable-library-validation
    # entitlements it needs to boot VMs. Leaving the binary untouched preserves
    # the signature and those entitlements; a modified binary would be killed on
    # launch or lose the entitlements.
    libexec.install "msb"

    on_macos do
      # Tarball contains: libkrunfw.5.dylib
      libexec.install "libkrunfw.#{LIBKRUNFW_ABI}.dylib"
      libexec.install_symlink "libkrunfw.#{LIBKRUNFW_ABI}.dylib" => "libkrunfw.dylib"
    end

    on_linux do
      # Tarball contains: libkrunfw.so.5.2.1
      libexec.install "libkrunfw.so.#{LIBKRUNFW_VERSION}"
      libexec.install_symlink "libkrunfw.so.#{LIBKRUNFW_VERSION}" => "libkrunfw.so.#{LIBKRUNFW_ABI}"
      libexec.install_symlink "libkrunfw.so.#{LIBKRUNFW_VERSION}" => "libkrunfw.so"
    end

    bin.write_exec_script libexec/"msb"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/msb --version")
  end
end
