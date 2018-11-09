//
//  JYProgressHUD.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/12.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit


public enum JYProgressHUDStatus: Int {
    case none = 0
    case pending = 1
    case success = 2
    case failure = 3
    case error = 4
}


public class JYProgressHUD : UIView {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var foregroundView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var pendingIndicator: UIActivityIndicatorView!
    
    private static let successImage = UIImage(named: "hud_check", in: JYProgressHUD.defaultBundle(), compatibleWith: UITraitCollection(displayScale: UIScreen.main.scale))
    private static let failureImage = UIImage(named: "hud_cross", in: JYProgressHUD.defaultBundle(), compatibleWith: UITraitCollection(displayScale: UIScreen.main.scale))
    private var dismissToken: Int = 0
    
    
    @discardableResult
    open static func successHud(successText: String?, autoDismissInterval: TimeInterval = 2) -> JYProgressHUD {
        if let hud = JYProgressHUD.defaultBundle().loadNibNamed("JYProgressHUD", owner: self, options: nil)?.first as? JYProgressHUD {
            hud.set(with: successText, for: .success)
            hud.status = .success
            hud.autoDismissInterval = autoDismissInterval            
            return hud
        } else {
            fatalError("JYProgressHUD initialized failure.")
        }
    }
    
    @discardableResult
    open static func failureHud(failureText: String?, autoDismissInterval: TimeInterval = 2) -> JYProgressHUD {
        if let hud = JYProgressHUD.defaultBundle().loadNibNamed("JYProgressHUD", owner: self, options: nil)?.first as? JYProgressHUD {
            hud.set(with: failureText, for: .failure)
            hud.status = .failure
            hud.autoDismissInterval = autoDismissInterval
            return hud
        } else {
            fatalError("JYProgressHUD initialized failure.")
        }
    }
    
    @discardableResult
    open static func errorHud(errorText: String?, autoDismissInterval: TimeInterval = 2) -> JYProgressHUD {
        if let hud = JYProgressHUD.defaultBundle().loadNibNamed("JYProgressHUD", owner: self, options: nil)?.first as? JYProgressHUD {
            hud.set(with:errorText, for: .error)
            hud.status = .error
            hud.autoDismissInterval = autoDismissInterval
            return hud
        } else {
            fatalError("JYProgressHUD initialized failure.")
        }
    }
    
    open static func hud(pendingText: String?, successText: String?, failureText: String?) -> JYProgressHUD {
        return hud(pendingText: pendingText, successText: successText, failureText: failureText, errorText: failureText)
    }

    
    open static func hud(pendingText: String?, successText: String?, failureText: String?, errorText: String?) -> JYProgressHUD {
        if let hud = JYProgressHUD.defaultBundle().loadNibNamed("JYProgressHUD", owner: self, options: nil)?.first as? JYProgressHUD {
            hud.set(with: pendingText, for: .pending)
            hud.set(with: successText, for: .success)
            hud.set(with: failureText, for: .failure)
            hud.set(with: errorText, for: .error)
            return hud
        } else {
            fatalError("JYProgressHUD initialized failure.")
        }
    }

    
    open var status: JYProgressHUDStatus = .none {
        didSet {
            if status == .none {
                dismiss()
            } else {
                if let text = _statusMapping[status] {
                    textLabel.text = text
                    
                    switch status {
                    case .none:
                        dismiss()
                        break
                        
                    case .pending:
                        iconImageView.isVisible = false
                        pendingIndicator.isVisible = true
                        pendingIndicator.startAnimating()
                        show()
                        // +1 to avoid auto dismiss
                        dismissToken += 1
                        break
                        
                    case .success:
                        iconImageView.image = JYProgressHUD.successImage
                        iconImageView.isVisible = true
                        pendingIndicator.isVisible = false
                        pendingIndicator.stopAnimating()
                        show()
                        autoDismiss()
                        break
                        
                    case .failure:
                        iconImageView.image = JYProgressHUD.failureImage
                        iconImageView.isVisible = true
                        pendingIndicator.isVisible = false
                        pendingIndicator.stopAnimating()
                        show()
                        autoDismiss()
                        break
                        
                    case .error:
                        iconImageView.image = JYProgressHUD.failureImage
                        iconImageView.isVisible = true
                        pendingIndicator.isVisible = false
                        pendingIndicator.stopAnimating()
                        show()
                        autoDismiss()
                        break
                    }
                } else {
                    dismiss()
                }
            }
        }
    }
    
    public var autoDismissInterval: TimeInterval = 1.2
    
    private var _statusMapping: [JYProgressHUDStatus : String] = [:]
    
    public func set(with text: String?, for status: JYProgressHUDStatus) {
        _statusMapping[status] = text
    }
    
    
    private func show() {
        guard superview == nil else { return }
        guard let window = UIApplication.shared.keyWindow else { return }
        
        window.addSubview(self)
        window.bringSubview(toFront: self)
        frame = window.bounds

        backgroundView.fadeIn(duration: 0.2, delay: 0)
        foregroundView.fadeIn(duration: 0.2, delay: 0.02)
    }
    
    private func autoDismiss() {
        dismissToken += 1
        let _dismissToken = dismissToken
        _ = DispatchQueue.main.jy_delay(time: autoDismissInterval)
        .done {[weak self] in
            if let strongSelf = self, _dismissToken == strongSelf.dismissToken {
                strongSelf.dismiss()
            }
        }
    }
    
    private func dismiss() {
        guard superview != nil else { return }

        _ = foregroundView.fadeOut(duration: 0.2, delay: 0)
        .then {[weak self] _ -> Promise<Void> in
            guard let strongSelf = self else {
                return Promise.value(())
            }
            return strongSelf.backgroundView.fadeOut(duration: 0.2, delay: 0.1)
        }.done {[weak self] _ in
            self?.removeFromSuperview()
        }
    }
}
