# typed: false
# frozen_string_literal: true

class Microsandbox < Formula
  desc "Spins up lightweight VMs in milliseconds from SDKs"
  homepage "https://microsandbox.dev"
  version "0.7.14"
  license "Apache-2.0"

  # libkrunfw ABI major used by the macOS dylib filename. On Linux the
  # versioned .so is discovered from the release bundle instead of pinned here.
  LIBKRUNFW_ABI = "5"

  on_macos do
    depends_on arch: :arm64

    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "9cc2bd2874cc1aa98cb139429a9482830b1e64b48255aa9f40a25b8979a23a9f"
    end

    on_intel do
      # The architecture requirement blocks installation before Homebrew fetches this ARM archive.
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "5eb53ca1d6beb36caa64d19602284b9ce37872eff340a8db0542ab91b5808c96"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-aarch64.tar.gz"
      sha256 "a0c54cd06bea4d2a5bd3fc291063f8f2f5e073232db78f6860c527922ec71906"
    end

    on_intel do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-x86_64.tar.gz"
      sha256 "34d49a7388685f0ea24bfbeecf6864a44718959b57087f1d7481775672db9585"
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
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/msb --version")
  end
end
