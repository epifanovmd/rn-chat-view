Pod::Spec.new do |s|
  s.name         = "IOSChatView"
  s.version      = "1.0.0"
  s.summary      = "Production-ready iOS chat UI component library"
  s.description  = <<-DESC
    A fully customizable, high-performance chat UI library for iOS.
    Built with UIKit + DiffableDataSource. Supports text, images, video, voice messages,
    polls, files, reactions, replies, forwarded messages, and custom content types.
    Designed for integration with React Native via bridge.
  DESC

  s.homepage     = "https://github.com/epifanovmd/rn-chat-view"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Andrei Epifanov" => "epifanovmd@gmail.com" }

  s.platform     = :ios, "15.1"
  s.swift_version = "5.9"

  s.source       = { :git => "https://github.com/epifanovmd/rn-chat-view.git", :tag => s.version.to_s }
  s.source_files = "Sources/IOSChatView/**/*.swift"

  s.frameworks   = "UIKit", "AVFoundation", "AudioToolbox"

  s.dependency "DifferenceKit", "~> 1.3"
end
