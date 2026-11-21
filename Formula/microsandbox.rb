# typed: false
# frozen_string_literal: true

class Microsandbox < Formula
  desc "Spins up lightweight VMs in milliseconds from SDKs"
  homepage "https://microsandbox.dev"
  version "0.7.16"
  license "Apache-2.0"

  # libkrunfw ABI major used by the macOS dylib filename. On Linux the
  # versioned .so is discovered from the release bundle instead of pinned here.
  LIBKRUNFW_ABI = "5"

  on_macos do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "b9341df7cc9a197fb1788c5b3dd7b32cf7036615f7f1a0f7d31685fd9e385ad1"
    end

    on_intel do
      odie "microsandbox requires Apple Silicon (M1+). x86_64 macOS is not supported."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-aarch64.tar.gz"
      sha256 "47e2e3238f31d914eba2a7e7ce328848da4673a1457ef2222f71589fe1da6f83"
    end

    on_intel do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-x86_64.tar.gz"
      sha256 "1f09ec7057bfcccb70e1713eb61061f15fa759b45e147759eb0b30aa7f5cb3bd"
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
