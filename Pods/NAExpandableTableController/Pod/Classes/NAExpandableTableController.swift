//
//  NAExpandableTableView.swift
//
//  Created by Nicholas Arciero on 3/5/16.
//

import UIKit

@objc public protocol NAExpandableTableViewDataSource {
    /// Number of sections
    func numberOfSectionsInExpandableTableView(_ tableView: UITableView) -> Int
    
    /// Number of rows in section at index
    func expandableTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    
    /// Equivalent to UITableView's cellForRowAtIndexPath - called for all cells except the section title cell (the one that toggles expansion)
    func expandableTableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell
    
    /// Equivalent to UITableView's cellForRowAtIndexPath - called only for section title cell (the one that toggles expansion)
    func expandableTableView(_ tableView: UITableView, titleCellForSection section: Int, expanded: Bool) -> UITableViewCell
    
    /// Indicates whether `section` is expandable or not.
    @objc optional func expandableTableView(_ tableView: UITableView, isExpandableSection section: Int) -> Bool
    
    /// The height of cells within an expandable section
    @objc optional func expandableTableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    
    /// The height of the expandable section title cell
    @objc optional func expandableTableView(_ tableView: UITableView, heightForTitleCellInSection section: Int) -> CGFloat
}

@objc public protocol NAExpandableTableViewDelegate {
    
    /// Equivalent to UITableView didSelectRowAtIndexPath delegate method. Called whenever a cell within a section is selected. This is NOT called when a section title cell is selected.
    @objc optional func expandableTableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath)
    
    /// Called when a section title cell is selected
    @objc optional func expandableTableView(_ tableView: UITableView, didSelectTitleCellInSection section: Int)
    
    /**
     Called when a section is expanded/collapsed.
     - Parameter section: Index of section being expanded/collapsed
     - Parameter expanded: True if section is being expanded, false if being collapsed
     */
    @objc optional func expandableTableView(_ tableView: UITableView, didExpandSection section: Int, expanded: Bool)
}

open class NAExpandableTableController: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    /// Default height to use for all cells (44)
    open var defaultRowHeight: CGFloat = 44
    
    /// Determines if multiple sections can be expanded at the same time. If set to `true`, then only one section can be expanded at a time. If a section is expanded and you try to expand another section, the first one will be collapsed.
    open var exclusiveExpand: Bool = false
    
    open weak var dataSource: NAExpandableTableViewDataSource?
    open weak var delegate: NAExpandableTableViewDelegate?
    
    /// Keeps track of which section indices are expanded
    fileprivate var expandDict = [Int: Bool]()
    
    public init(dataSource: NAExpandableTableViewDataSource? = nil, delegate: NAExpandableTableViewDelegate? = nil) {
        super.init()
        self.dataSource = dataSource
        self.delegate = delegate
    }
    
    // MARK: - UITableViewDataSource
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource?.numberOfSectionsInExpandableTableView(tableView) ?? 0
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).row == 0 {
            return dataSource?.expandableTableView?(tableView, heightForTitleCellInSection: (indexPath as NSIndexPath).section) ?? defaultRowHeight
        }
        
        return dataSource?.expandableTableView?(tableView, heightForRowAtIndexPath: indexPath) ?? defaultRowHeight
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hide headers
        return 0
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView(frame: CGRect.zero)
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if expandDict[section] ?? false {
            return 1 + (dataSource?.expandableTableView(tableView, numberOfRowsInSection: section) ?? 0)
        }
        
        return 1
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let dataSource = self.dataSource else {
            return UITableViewCell()
        }
        
        let expandable = dataSource.expandableTableView?(tableView, isExpandableSection: (indexPath as NSIndexPath).section) ?? true
        if (indexPath as NSIndexPath).row == 0 && expandable {
            return dataSource.expandableTableView(tableView, titleCellForSection: (indexPath as NSIndexPath).section, expanded: expandDict[(indexPath as NSIndexPath).section] ?? false)
        }
        
        let rowIndexPath = expandable ? IndexPath(row: (indexPath as NSIndexPath).row - 1, section: (indexPath as NSIndexPath).section) : indexPath
        return dataSource.expandableTableView(tableView, cellForRowAtIndexPath: rowIndexPath)
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Check if the first cell in the section
        let expandable = dataSource?.expandableTableView?(tableView, isExpandableSection: (indexPath as NSIndexPath).section) ?? true
        if (indexPath as NSIndexPath).row == 0 && expandable {
            // Check if this section is already expanded, if so then collapse it
            if expandDict[(indexPath as NSIndexPath).section] ?? false {
                collapseSection(tableView, section: (indexPath as NSIndexPath).section)
            } else {
                // If exclusiveExpand is true, then collapse any expanded sections
                if exclusiveExpand {
                    for (section, expanded) in expandDict where expanded {
                        collapseSection(tableView, section: section)
                    }
                }
                expandSection(tableView, section: (indexPath as NSIndexPath).section)
            }
            
            delegate?.expandableTableView?(tableView, didSelectTitleCellInSection: (indexPath as NSIndexPath).section)
        } else {
            // Need to decrement indexPath.row by 1 because the first row is the title cell
            let rowIndexPath = IndexPath(row: (indexPath as NSIndexPath).row - 1, section: (indexPath as NSIndexPath).section)
            delegate?.expandableTableView?(tableView, didSelectRowAtIndexPath: rowIndexPath)
        }
    }
    
    internal func expandSection(_ tableView: UITableView, section: Int) {
        expandDict[section] = true
        tableView.beginUpdates()
        
        var indexPaths = [IndexPath]()
        if let rows = dataSource?.expandableTableView(tableView, numberOfRowsInSection: section) {
            for rowIndex in 1...rows {
                indexPaths.append(IndexPath(row: rowIndex, section: section))
            }
        }
        
        tableView.insertRows(at: indexPaths, with: .none)
        tableView.endUpdates()
        
        delegate?.expandableTableView?(tableView, didExpandSection: section, expanded: true)
    }
    
    internal func collapseSection(_ tableView: UITableView, section: Int) {
        expandDict[section] = false
        tableView.beginUpdates()
        
        var indexPaths = [IndexPath]()
        if let rows = dataSource?.expandableTableView(tableView, numberOfRowsInSection: section) {
            for rowIndex in 1...rows {
                indexPaths.append(IndexPath(row: rowIndex, section: section))
            }
        }
        
        tableView.deleteRows(at: indexPaths, with: .none)
        tableView.endUpdates()
        
        delegate?.expandableTableView?(tableView, didExpandSection: section, expanded: false)
    }
}
