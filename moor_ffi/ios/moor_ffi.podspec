#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'moor_ffi'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  #s.source_files = 'Classes/**/*'
  #s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  # when we run on Dart 2.6, we should use this library and also use DynamicLibrary.executable()
  #  s.dependency 'sqlite3'

  s.ios.deployment_target = '8.0'
end