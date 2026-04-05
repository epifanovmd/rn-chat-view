import UIKit

public final class LoadingCell: UICollectionViewCell {
    static let reuseID = "LoadingCell"
    private let spinner = UIActivityIndicatorView(style: .medium)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        contentView.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    public required init?(coder: NSCoder) { fatalError() }

    func startAnimating() { spinner.startAnimating() }

    public override func prepareForReuse() {
        super.prepareForReuse()
        spinner.stopAnimating()
    }
}
