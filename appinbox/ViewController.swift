import UIKit
import CleverTapSDK

class ViewController: UIViewController {
    
    var tableView: UITableView!
    var unreadBadge: UILabel!
    var inboxMessages: [CleverTapInboxMessage] = []
    var cleverTapInstance: CleverTap?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get CleverTap instance from AppDelegate
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            cleverTapInstance = appDelegate.cleverTapAdditionalInstance
        }
        
        setupUI()
        setupTableView()
        registerInboxUpdates()
        
        // Initialize inbox and wait for completion
        initializeCleverTapInbox()
    }
    
    // MARK: - Setup UI
    func setupUI() {
        view.backgroundColor = UIColor.white
        title = "App Inbox"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Create unread badge
        unreadBadge = UILabel()
        unreadBadge.layer.cornerRadius = 12
        unreadBadge.backgroundColor = UIColor.systemRed
        unreadBadge.textColor = UIColor.white
        unreadBadge.font = UIFont.boldSystemFont(ofSize: 12)
        unreadBadge.textAlignment = .center
        unreadBadge.clipsToBounds = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: unreadBadge)
        
        // Constraints for badge
        unreadBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            unreadBadge.widthAnchor.constraint(equalToConstant: 24),
            unreadBadge.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Setup TableView
    func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(InboxMessageCell.self, forCellReuseIdentifier: "InboxCell")
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Initialize CleverTap Inbox
    func initializeCleverTapInbox() {
        cleverTapInstance?.initializeInbox { [weak self] success in
            if success {
                print("✅ App Inbox initialized successfully")
                let count = self?.cleverTapInstance?.getInboxMessageCount() ?? 0
                let unread = self?.cleverTapInstance?.getInboxMessageUnreadCount() ?? 0
                print("📬 Total Messages: \(count), Unread: \(unread)")
                self?.loadInboxMessages()
            } else {
                print("❌ App Inbox initialization failed")
            }
        }
    }
    
    // MARK: - Load Messages
    func loadInboxMessages() {
        DispatchQueue.main.async { [weak self] in
            if let messages = self?.cleverTapInstance?.getAllInboxMessages() {
                self?.inboxMessages = messages
                self?.updateUnreadBadge()
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Register for Inbox Updates
    func registerInboxUpdates() {
        cleverTapInstance?.registerInboxUpdatedBlock { [weak self] in
            self?.loadInboxMessages()
        }
    }
    
    // MARK: - Update Unread Badge
    func updateUnreadBadge() {
        DispatchQueue.main.async { [weak self] in
            let unreadCount = self?.cleverTapInstance?.getInboxMessageUnreadCount() ?? 0
            self?.unreadBadge.text = String(unreadCount)
            self?.unreadBadge.isHidden = unreadCount == 0
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InboxCell", for: indexPath) as! InboxMessageCell
        let message = inboxMessages[indexPath.row]
        cell.configure(with: message)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let message = inboxMessages[indexPath.row]
        
        // Mark as read
        cleverTapInstance?.markRead(message)
        
        // Record viewed event
        cleverTapInstance?.recordInboxNotificationViewedEvent(forID: message.messageId!)
        
        // Show message detail
        showMessageDetail(message, at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let message = inboxMessages[indexPath.row]
            cleverTapInstance?.delete(message)
            inboxMessages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - Show Message Detail
    func showMessageDetail(_ message: CleverTapInboxMessage, at index: Int) {
        let detailVC = MessageDetailViewController(message: message, index: index)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Custom TableViewCell
class InboxMessageCell: UITableViewCell {
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let unreadIndicator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        containerView.layer.cornerRadius = 8
        contentView.addSubview(containerView)
        
        unreadIndicator.backgroundColor = UIColor.systemBlue
        unreadIndicator.layer.cornerRadius = 5
        containerView.addSubview(unreadIndicator)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor.black
        titleLabel.numberOfLines = 1
        containerView.addSubview(titleLabel)
        
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = UIColor.darkGray
        messageLabel.numberOfLines = 2
        containerView.addSubview(messageLabel)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            unreadIndicator.widthAnchor.constraint(equalToConstant: 10),
            unreadIndicator.heightAnchor.constraint(equalToConstant: 10),
            unreadIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            unreadIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: unreadIndicator.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: CleverTapInboxMessage) {
        if let content = message.content as? [CleverTapInboxMessageContent], let firstContent = content.first {
            titleLabel.text = firstContent.title ?? "No Title"
            messageLabel.text = firstContent.message ?? "No Message"
        }
        unreadIndicator.isHidden = message.isRead
    }
}

// MARK: - Message Detail View Controller
class MessageDetailViewController: UIViewController {
    
    let message: CleverTapInboxMessage
    let index: Int
    let scrollView = UIScrollView()
    let contentView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let deleteButton = UIButton()
    
    init(message: CleverTapInboxMessage, index: Int) {
        self.message = message
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "Message Details"
        setupUI()
        recordMessageViewed()
    }
    
    func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        if let content = message.content as? [CleverTapInboxMessageContent], let firstContent = content.first {
            titleLabel.text = firstContent.title ?? "No Title"
            messageLabel.text = firstContent.message ?? "No Message"
        }
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        
        deleteButton.setTitle("Delete Message", for: .normal)
        deleteButton.backgroundColor = UIColor.systemRed
        deleteButton.setTitleColor(UIColor.white, for: .normal)
        deleteButton.layer.cornerRadius = 8
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteMessage), for: .touchUpInside)
        contentView.addSubview(deleteButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            deleteButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc func deleteMessage() {
        CleverTap.sharedInstance()?.delete(message)
        CleverTap.sharedInstance()?.recordInboxNotificationClickedEvent(forID: message.messageId!)
        navigationController?.popViewController(animated: true)
    }
    
    func recordMessageViewed() {
        CleverTap.sharedInstance()?.recordInboxNotificationViewedEvent(forID: message.messageId!)
    }
}
