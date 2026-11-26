# typed: false
# frozen_string_literal: true

class Microsandbox < Formula
  desc "Spins up lightweight VMs in milliseconds from SDKs"
  homepage "https://microsandbox.dev"
  version "0.8.3"
  license "Apache-2.0"

  # libkrunfw ABI major used by the macOS dylib filename. On Linux the
  # versioned .so is discovered from the release bundle instead of pinned here.
  LIBKRUNFW_ABI = "5"

  on_macos do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "79dfef79d9933f029896bb961a2ea8f587f5315e3d40dc743435d8507a04d930"
    end

    on_intel do
      odie "microsandbox requires Apple Silicon (M1+). x86_64 macOS is not supported."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-aarch64.tar.gz"
      sha256 "6331b29e613b381b618d7969e24bd3fcc3d137ebaf2f95b029d38b97ef3027b9"
    end

    on_intel do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-x86_64.tar.gz"
      sha256 "aae2bec648890ee8a278fe060981c2b2dad313302529860b0d924ec487add12d"
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

    if OS.mac?
      # Tarball contains: libkrunfw.5.dylib
      libexec.install "libkrunfw.#{LIBKRUNFW_ABI}.dylib"
      libexec.install_symlink libexec/"libkrunfw.#{LIBKRUNFW_ABI}.dylib" => "libkrunfw.dylib"
    end

    if OS.linux?
      # Tarball contains a single versioned library, e.g. libkrunfw.so.5.6.1.
      # Discover it instead of pinning the version so bumps that change the
      # bundled libkrunfw don't break the formula (mirrors scripts/install.sh).
      libkrunfw = Dir["libkrunfw.so.*.*.*"]
      odie "release bundle must contain exactly one versioned libkrunfw shared library" if libkrunfw.length != 1
      libkrunfw = libkrunfw.first
      abi = libkrunfw.delete_prefix("libkrunfw.so.").split(".").first
      libexec.install libkrunfw
      libexec.install_symlink libexec/libkrunfw => "libkrunfw.so.#{abi}"
      libexec.install_symlink libexec/libkrunfw => "libkrunfw.so"
    end

    bin.mkpath
    File.write(bin/"msb", <<~SH)
      #!/bin/bash
      exec "#{libexec}/msb" "$@"
    SH
    chmod 0755, bin/"msb"

    generate_completions_from_executable(bin/"msb", "completion")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/msb --version")
  end
end
