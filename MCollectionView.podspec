Pod::Spec.new do |s|
  s.name             = "MCollectionView"
  s.version          = "2.2.1"
  s.summary          = "A UIKit custom modal transition that simulates an elastic drag. Written in Swift."

  s.description      = <<-DESC
                        A UIKit custom modal transition that simulates an elastic drag. Written in Swift.
                        Best for side menu and navigation transition.

                        This is inspired by DGElasticPullToRefresh from gontovnik.
                       DESC

  s.homepage         = "https://github.com/lkzhao/MCollectionView"
  s.screenshots     = "https://github.com/lkzhao/MCollectionView/blob/master/imgs/demo.gif?raw=true"
  s.license          = 'MIT'
  s.author           = { "Luke" => "lzhaoyilun@gmail.com" }
  s.source           = { :git => "https://github.com/lkzhao/MCollectionView.git", :tag => s.version.to_s }
  
  s.ios.deployment_target  = '8.0'
  s.ios.frameworks         = 'UIKit', 'Foundation'

  s.requires_arc = true

  s.source_files = 'Sources/**/*.swift'

  s.dependency 'YetAnotherAnimationLibrary', '~> 1.1.0'
end
