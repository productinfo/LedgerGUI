//
//  RegisterViewController.swift
//  LedgerGUI
//
//  Created by Chris Eidhof on 04/07/16.
//  Copyright © 2016 objc.io. All rights reserved.
//

import Cocoa

extension NSView {
    func constrainEdges(toMarginOf otherView: NSView) {
        translatesAutoresizingMaskIntoConstraints = false

        topAnchor.constraint(equalTo: otherView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: otherView.bottomAnchor).isActive = true
        leftAnchor.constraint(equalTo: otherView.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: otherView.rightAnchor).isActive = true
    }
}

class RegisterViewController: NSViewController {
    let delegate = RegisterDelegate()
    var tableView: NSTableView?
    
    override func viewDidLoad() {
        let tableView = NSTableView()
        let column = NSTableColumn(identifier: "first")
        tableView.addTableColumn(column)
        tableView.dataSource = delegate
        tableView.delegate = delegate
        let nib = NSNib(nibNamed: "RegisterCell", bundle: nil)
        tableView.register(nib, forIdentifier: "Cell")
        
        let scrollView = NSScrollView()
        let clipView = NSClipView()
        
        clipView.documentView = tableView
        scrollView.contentView = clipView
        
        view.addSubview(scrollView)
        scrollView.constrainEdges(toMarginOf: view)
        scrollView.hasVerticalScroller = true
        
        self.tableView = tableView

        loadData()
    }
    
    func loadData() {
        let contents = try! String(contentsOfFile: "/Users/chris/objc.io/LedgerGUI/sample.txt")
        var state = State()
        let statements = parse(string: contents)
        for statement in statements {
            try! state.apply(statement)
        }
        delegate.transactions = state.evaluatedTransactions
        tableView?.reloadData()
    }
}

class RegisterDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    var transactions: [EvaluatedTransaction] = []
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "Cell", owner: self)! as! RegisterCell
        let transaction = transactions[row]
        cell.title = transaction.title
        
        cell.setPostings(postings: transaction.postings.map { posting in
            (posting.account, posting.amount)
        })
        let calendar = Calendar.current()
        cell.set(date: calendar.date(from: transaction.date.components)!)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let postings = transactions[row].postings
        return 54 + CGFloat(postings.count) * (17+8)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return transactions.count
    }
}

class PostingView: NSView {
    @IBOutlet weak var account: NSTextField!
    @IBOutlet weak var amount: NSTextField!
}

class RegisterCell: NSView {
    static let postingNib = NSNib(nibNamed: "Posting", bundle: nil)!
    
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet private weak var titleLabel: NSTextField!
    
    var title: String {
        get {
            return titleLabel.stringValue
        }
        set {
            titleLabel.stringValue = newValue
        }
    }

    func set(date: Foundation.Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .shortStyle
        formatter.timeStyle = .noStyle
        dateLabel.stringValue = formatter.string(from: date)
    }
    
    func setPostings(postings: [(account: String, amount: Amount)]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for posting in postings {
            var objects: NSArray = NSArray()
            guard RegisterCell.postingNib.instantiate(withOwner: nil, topLevelObjects: &objects) else {
                fatalError("Couldn't instantiate")
            }
            let postingView = objects.flatMap { $0 as? PostingView }.first!
            postingView.account.stringValue = posting.account
            postingView.amount.stringValue = posting.amount.displayValue
            postingView.amount.textColor = posting.amount.color
            stackView.addArrangedSubview(postingView)
        }
    }
}

extension Amount {
    var displayValue: String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = commodity.value
        formatter.numberStyle = .currencyAccounting
        return formatter.string(from: number.value) ?? ""
    }
    
    var color: NSColor {
        return isNegative ? .red() : .black()
    }
}
