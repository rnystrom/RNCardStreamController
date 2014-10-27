Pod::Spec.new do |s|

  s.name         = "RNCardStreamController"
  s.version      = "0.0.2"
  s.summary      = "A vertical section and cell navigation control inspired by Facebook Paper."

  s.description  = <<-DESC
                   A vertical section and cell navigation control inspired by Facebook Paper.

                   This control was inspired by a Dribbble from Ed Chao at
				   https://dribbble.com/shots/1650047-CardStream-Interactions. His animation
				   is a take on Facebook Paper but with a vertical navigation instead of
				   horizontal.
                   DESC

  s.homepage     = "https://github.com/rnystrom/RNCardStreamController"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Ryan Nystrom" => "rnystrom@whoisryannystrom.com" }
  s.social_media_url   = "http://twitter.com/_ryannystrom"

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/rnystrom/RNCardStreamController.git", :tag => "0.0.2" }
  s.source_files = "RNCardStreamController.{h,m}"

  s.dependency	'pop'

end
