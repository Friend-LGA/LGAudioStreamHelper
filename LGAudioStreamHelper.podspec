Pod::Spec.new do |s|

    s.name = 'LGAudioStreamHelper'
    s.version = '1.0.1'
    s.platform = :ios, '6.0'
    s.license = 'MIT'
    s.homepage = 'https://github.com/Friend-LGA/LGAudioStreamHelper'
    s.author = { 'Grigory Lutkov' => 'Friend.LGA@gmail.com' }
    s.source = { :git => 'https://github.com/Friend-LGA/LGAudioStreamHelper.git', :tag => s.version }
    s.summary = 'iOS helper for easy recording audio stream, getting metadata and type of stream'

    s.requires_arc = true

    s.source_files = 'LGAudioStreamHelper/*.{h,m}'
    s.source_files = 'LGAudioStreamHelper/**/*.{h,m}'

end
