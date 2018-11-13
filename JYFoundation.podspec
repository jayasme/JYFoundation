Pod::Spec.new do |s|
    s.name = 'JYFoundation'
    s.version = '0.0.3'
    s.license = 'MIT'
    s.summary = 'A private foundation only for jayasme.'
    s.homepage = 'https://github.com/jayasme/JYFoundation'
    # s.social_media_url = ''
    s.authors = { 'jayasme' => 'sunshine121981@126.com' }
    s.source = { :git => "https://github.com/jayasme/JYFoundation.git", :tag => s.version }
    # s.documentation_url = ''

    s.ios.deployment_target = '9.0'

    s.swift_version = "4.2"
    s.source_files = 'Source/*.swift'

    s.dependency "Alamofire", "~>4.7"
    s.dependency "PromiseKit/CorePromise", "~>6.2"
    s.dependency "SDWebImage", "~>4.3"
    s.dependency "HandyJSON", "~>4.1"

end
