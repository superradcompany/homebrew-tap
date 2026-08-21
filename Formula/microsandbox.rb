# typed: false
# frozen_string_literal: true

class Microsandbox < Formula
  desc "Spins up lightweight VMs in milliseconds from SDKs"
  homepage "https://microsandbox.dev"
  license "Apache-2.0"
  version "0.6.13"

  # libkrunfw versioned filenames (must match the build)
  LIBKRUNFW_VERSION = "5.2.1"
  LIBKRUNFW_ABI = "5"

  on_macos do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-darwin-aarch64.tar.gz"
      sha256 "5637d407d57e76d44f4a7dab1951052a73b85fe1ece3014d5dda0fd0039eebe3"
    end

    on_intel do
      odie "microsandbox requires Apple Silicon (M1+). x86_64 macOS is not supported."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-aarch64.tar.gz"
      sha256 "04380b543786867e8efb552f4e1208142625cb15a135a78c2da5ce7be17a4278"
    end

    on_intel do
      url "https://github.com/superradcompany/microsandbox/releases/download/v#{version}/microsandbox-linux-x86_64.tar.gz"
      sha256 "7a9f5a664730028189e51c057dcaa9119cd11d006fbe6093e18bc244dab6fd45"
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
