# Homebrew formula for installing OPHD on macOS
class Outposthd < Formula
  desc "Open source remake of Sierra On-Line's Outpost"
  homepage "https://github.com/OutpostUniverse/OPHD"
  url "https://github.com/OutpostUniverse/OPHD.git", branch: "main"
  version "head"
  license "BSD-3-Clause"
  head "https://github.com/OutpostUniverse/OPHD.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "sdl2"
  depends_on "sdl2_image"
  depends_on "sdl2_mixer"
  depends_on "sdl2_ttf"
  depends_on "glew"

  def install
    system "git", "submodule", "update", "--init", "--recursive" if build.head?
    system "make"

    # OPHD expects the data directory alongside the binary
    prefix.install Dir[".build/*_appOPHD/ophd"].first => "outposthd"
    prefix.install "data"
    prefix.install Dir["*.md"]

    # Use a wrapper script to exec the binary so it can find the data dir
    bin.write_exec_script prefix/"outposthd"

    if OS.mac?
      # Generate the macOS .icns from the .ico file
      # TODO: this only extracts the largest icon, we need to add a dep on imagemagick or similar to extract all icons
      mkdir_p "OutpostHD.iconset"
      system "sips", "-s", "format", "png", "appOPHD/outpost.ico", "--out", "OutpostHD.iconset/icon_256x256.png"
      system "iconutil", "-c", "icns", "OutpostHD.iconset"

      # Create an .app bundle wrapping a symlink to the binary, so a launcher can be manually copied to /Applications
      # TODO: create self contained app that contains all the dependencies?
      app_dir = (prefix/"OutpostHD.app/Contents")
      mkdir_p [app_dir/"MacOS", app_dir/"Resources"]
      cp "OutpostHD.icns", app_dir/"Resources/"
      (app_dir/"Info.plist").write <<~EOS
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>CFBundleExecutable</key>
          <string>outposthd</string>
          <key>CFBundleIconFile</key>
          <string>OutpostHD.icns</string>
          <key>CFBundleIdentifier</key>
          <string>com.outpost2.OutpostHD</string>
          <key>CFBundleInfoDictionaryVersion</key>
          <string>6.0</string>
          <key>CFBundleName</key>
          <string>OutpostHD</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
        </dict>
        </plist>
      EOS
      (app_dir/"MacOS").install_symlink bin/"outposthd"
    end
  end

  if OS.mac?
    # TODO: use cask to handle symlinking the app outside the sandbox
    def caveats
      <<~EOS
        Run `outposthd` in a terminal to launch OPHD.
        To put a launcher in your Applications folder, run:

          ln -s #{prefix}/OutpostHD.app /Applications/OutpostHD.app

      EOS
    end
  end
end

