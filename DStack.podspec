#
# Be sure to run `pod lib lint FACoreData.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DStack"
  s.version          = "0.2.0"
  s.summary          = "A short description of DStack."
  s.description      = <<-DESC
                       An optional longer description of DStack

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/kildevaeld/DStack"

  s.license          = 'MIT'
  s.author           = { "Softshag & Me" => "admin@softshag.dk" }
  s.source           = { :git => "https://github.com/kildevaeld/DStack.git", :tag => 'v' + s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  s.frameworks = "CoreData"
  s.dependency 'XCGLogger', '~> 3.0'

end
