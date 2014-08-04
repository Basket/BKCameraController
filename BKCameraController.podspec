Pod::Spec.new do |s|
  s.name             = "BKCameraController"
  s.version          = "0.0.1"
  s.summary          = "A class to simplify the process of capturing photos and make testing in the simulator less of a hassle for photo-based apps."
  s.homepage         = "https://github.com/Basket/BKCameraController"
  s.license          = 'MIT'
  s.author           = { "Andrew Toulouse" => "andrew@atoulou.se" }
  s.source           = { :git => "https://github.com/Basket/BKCameraController.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'BKCameraController/*.{h,m}'
  s.frameworks = 'AssetsLibrary', 'AVFoundation', 'CoreMedia', 'ImageIO', 'UIKit'
end
