import UIKit

open class JYTableViewCell : UITableViewCell, JYThemeful {
    
    private(set) open var viewModel: ITableCellViewModel! {
        didSet {
            // update signalBlock
            viewModel.signalBlock = signal
            viewModel.cell = self
        }
    }
    private(set) var isDisplayed: Bool = false
    
    private var _contentView: JYThemeView!
    public override var contentView: JYThemeView {
        get {
            super.contentView.removeFromSuperview()
            if (self._contentView == nil) {
                self._contentView = JYThemeView(frame: self.bounds)
                self.addSubview(_contentView)
            }
            return self._contentView
        }
    }
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    open func updateViewModel(viewModel: ITableCellViewModel) {
        self.viewModel = viewModel
    }
    
    public func willDisappear() {
        isDisplayed = false
    }
    
    public func willDisplay() {
        isDisplayed = true
    }
    
    open func commonInit() {
        // do nothing
    }
    
    private func signal() {
        updateViewModel(viewModel: self.viewModel)
    }
    
    // MARK: JYThemeful
    
    public var themes: [JYTheme] = [] {
        didSet {
            self.applyThemes()
            self.passthroughThemes()
        }
    }
    
    public var styleSheet: JYStyleSheet? = nil {
        didSet {
            self.applyThemes()
        }
    }
    
    open func applyThemes() {
        self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
    }
    
    private func passthroughThemes() {
        for subview in self.subviews {
            guard let subview = subview as? JYThemeful else {
                break
            }
            subview.themes = self.themes
        }
    }
    
    override open func addSubview(_ view: UIView) {
        super.addSubview(view)
        guard let view = view as? JYThemeful else {
            return
        }
        view.themes = self.themes
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = self.bounds
    }
}
