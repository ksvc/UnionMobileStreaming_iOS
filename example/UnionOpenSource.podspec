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

  s.subspec 'UnionCommon' do |sub|
    sub.source_files = ['*.{h,c,m}']
  end
  s.subspec 'UnionPublisher' do |sub|
    sub.source_files = [
      'thirdparty/include/librtmp/*.{h,c,m}',
      'UnionPublisher/*.{h,c,m}',
      'UnionPublisher/iOS/*.{h,c,m}',
    ]
    sub.vendored_library = [
      'thirdparty/libs/librtmp.a',
      'thirdparty/libs/libssl.a',
      'thirdparty/libs/libcrypto.a'
    ]
  end
  s.subspec 'UnionEncoderX264' do |sub|
    sub.source_files = [
      'thirdparty/include/x264/*.{h,c,m}',
      'UnionEncoderX264/*.{h,c,m}',
      'UnionEncoderX264/iOS/*.{h,c,m}',
    ]
    sub.vendored_library = ['thirdparty/libs/libx264.a']
  end

  s.subspec 'UnionEncoderFDKAAC' do |sub|
    sub.source_files = 'UnionEncoderFDKAAC/iOS/*.{h,c,m}'
  end
  s.subspec 'libfdk-aac' do |sub|
    sub.source_files = [
      'thirdparty/include/fdk-aac/*.h',
      'UnionEncoderFDKAAC/*.{h,c,m}',
    ]
    sub.header_mappings_dir = 'thirdparty/include/'
    sub.vendored_library = ['thirdparty/libs/libfdk-aac.a']
  end
end
