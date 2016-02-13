Pod::Spec.new do |s|
  s.name             = "Stack"
  s.version          = "2.0.0"
  s.summary          = "A Type-Safe, Thread-Safe-ish approach to CoreData in Swift"
  s.homepage         = "https://github.com/shaps80/Stack"
  s.license          = 'MIT'
  s.author           = { "Shaps Mohsenin" => "shapsuk@me.com" }
  s.source           = { :git => "https://github.com/shaps80/Stack.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/shaps'
  s.platforms     = { :ios => "8.0", :osx => "10.10" }
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*.swift'
  s.frameworks   = 'Foundation', 'CoreData'
end
