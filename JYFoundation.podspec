Pod::Spec.new do |s|
    s.name = 'JYFoundation'
    s.version = '0.4.5'
    s.license = 'MIT'
    s.summary = 'A multi usages foundation library for iOS Swift.'
    s.homepage = 'https://github.com/jayasme/JYFoundation'
    # s.social_media_url = ''
    s.authors = { 'jayasme' => 'sunshine121981@126.com' }
    s.source = { :git => "https://github.com/jayasme/JYFoundation.git", :tag => s.version }
    # s.documentation_url = ''

    s.ios.deployment_target = '13.0'

    s.swift_version = "5.0"

    s.dependency "PromiseKit/CorePromise"
    s.dependency "SDWebImage"
    
    s.source_files = 'JYFoundation/**/*.{h,m,swift}'

end
