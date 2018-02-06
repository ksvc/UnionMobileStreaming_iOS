Pod::Spec.new do |s|
  s.name         = 'UnionOpenSource'
  s.version      = '1.0.0'
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

  s.subspec 'UnionCommon' do |sub|
    sub.source_files = ['example/*.{h,c,m}']
  end
  s.subspec 'UnionPublisher' do |sub|
    sub.source_files = [
      'example/thirdparty/include/librtmp/*.{h,c,m}',
      'example/UnionPublisher/*.{h,c,m}',
      'example/UnionPublisher/iOS/*.{h,c,m}',
    ]
    sub.vendored_library = [
      'example/thirdparty/libs/librtmp.a',
      'example/thirdparty/libs/libssl.a',
      'example/thirdparty/libs/libcrypto.a'
    ]
  end
  s.subspec 'UnionEncoderX264' do |sub|
    sub.source_files = [
      'example/thirdparty/include/x264/*.{h,c,m}',
      'example/UnionEncoderX264/*.{h,c,m}',
      'example/UnionEncoderX264/iOS/*.{h,c,m}',
    ]
    sub.vendored_library = ['example/thirdparty/libs/libx264.a']
  end

  s.subspec 'UnionEncoderFDKAAC' do |sub|
    sub.source_files = 'example/UnionEncoderFDKAAC/iOS/*.{h,c,m}'
  end
  s.subspec 'libfdk-aac' do |sub|
    sub.source_files = [
      'example/thirdparty/include/fdk-aac/*.h',
      'example/UnionEncoderFDKAAC/*.{h,c,m}',
    ]
    sub.header_mappings_dir = 'example/thirdparty/include/'
    sub.vendored_library = ['example/thirdparty/libs/libfdk-aac.a']
  end
end
