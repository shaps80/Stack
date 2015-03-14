Pod::Spec.new do |s|
  s.name             = "Stack"
  s.version          = "0.3.0"
  s.summary          = "A fresh, safer approach to CoreData"
  s.description      = <<-DESC
                       Stack provides a safer implementation for working with CoreData
                       DESC
  s.homepage         = "https://github.com/shaps80/Stack"
  s.license          = 'MIT'
  s.author           = { "Shaps Mohsenin" => "shapsuk@me.com" }
  s.source           = { :git => "https://github.com/shaps80/Stack.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/shaps'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'SPXDefines'
end
