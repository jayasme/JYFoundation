Pod::Spec.new do |s|
    s.name = 'JYFoundation'
    s.version = '0.0.7'
    s.license = 'MIT'
    s.summary = 'A multi usages foundation library for iOS Swift.'
    s.homepage = 'https://github.com/jayasme/JYFoundation'
    # s.social_media_url = ''
    s.authors = { 'jayasme' => 'sunshine121981@126.com' }
    s.source = { :git => "https://github.com/jayasme/JYFoundation.git", :tag => s.version }
    # s.documentation_url = ''

    s.ios.deployment_target = '10.0'

    s.swift_version = "5.0"

    s.dependency "Alamofire"
    s.dependency "PromiseKit/CorePromise"
    s.dependency "SDWebImage"
    s.dependency "HandyJSON"
    
    s.source_files = 'JYFoundation/**/*.{h,m,swift}'

end
