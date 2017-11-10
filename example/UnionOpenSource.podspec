Pod::Spec.new do |s|
  s.name         = 'UnionOpenSource'
  s.version      = '0.0.1'
  s.license      = {
:type => 'Proprietary',
:text => <<-LICENSE
      Copyright 2015 kingsoft Ltd. All rights reserved.
      LICENSE
  }
  s.homepage     = 'http://v.ksyun.com/doc.html'
  s.authors      = { 'ksyun' => 'zengfanping@kingsoft.com' }
  s.summary      = 'UnionMobileStreaming for stream live video from ios mobile devices.'
  s.description  = <<-DESC
    * publisher 
  DESC
  s.platform     = :ios, '8.0'
  s.ios.library = 'z', 'iconv', 'stdc++.6', 'bz2'
  s.ios.deployment_target = '8.0'
  s.source = { 
    :git => 'https://github.com/ksvc/UnionMobileStreaming.git',
    :tag => 'v'+s.version.to_s
  }
  s.requires_arc = true
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC -all_load' }

  s.subspec 'UnionPublisher' do |sub|
    sub.source_files = [
      '*.{h,c,m}',
      'UnionPublisher/*.{h,c,m}',
      'UnionPublisher/iOS/*.{h,c,m}',
      'UnionPublisher/librtmp/include/*.{h}'
    ]
    sub.vendored_library = ['UnionPublisher/librtmp/libs/*.a']
  end
end
