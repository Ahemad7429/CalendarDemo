//
//  CalendarVC.swift
//  CalenderDemo
//
//  Created by AhemadAbbas Vagh on 17/11/18.
//  Copyright © 2018 AhemadAbbas Vagh. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CalendarVC: UIViewController {
    
    @IBAction func previousButton(_ sender: Any) {
        self.calendarView.scrollToSegment(.previous)
    }
    @IBAction func nextButton(_ sender: Any) {
        self.calendarView.scrollToSegment(.next)
    }
    
    @IBOutlet weak var monthLabel: UILabel!
    
    var todayDate: Date?
    var selectedDates = [Date]()
    
    var firstDate: Date?
    var lastDate: Date?
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    
    let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Calendar.current.locale
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.dateFormat = "yyyy MM dd"
        return dateFormatter
    }()
    
    var selected = Date()
    let outsideMonthColor = UIColor(hex: 0x584a66)
    let monthColor = UIColor.red
    
    override func viewDidLoad() {
        super.viewDidLoad()
        basicSetup()
        todayDate = Date()
        calendarView.selectDates([todayDate!])
        calendarView.scrollToDate(todayDate!)
        selectedDates.append(todayDate!)
        
        
        calendarView.visibleDates { (dateSegment) in
            self.dateSetup(dateSegment: dateSegment)
            
        }
    }
    
    func basicSetup() {
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        calendarView.isRangeSelectionUsed = true
        calendarView.allowsMultipleSelection = true
    }
    
    func dateSetup(dateSegment: DateSegmentInfo) {
        guard let date = dateSegment.monthDates.first?.date else { return }
        formatter.dateFormat = "MMM"
        monthLabel.text = formatter.string(from: date)
    }
    
    func configureCell(cell: JTAppleCell?, cellState: CellState) {
        
        guard let cell = cell as? CustomCell else {
            return
        }
        
        handleCellTextColor(cell: cell, cellState: cellState)
        handleCellVisibility(cell: cell, cellState: cellState)
        handleCellSelection(cell: cell, cellState: cellState)
    }
    
    func handleCellTextColor(cell: CustomCell, cellState: CellState) {
        cell.dateLabel.textColor = cell.isSelected ? UIColor.white : UIColor.black
    }
    
    func handleCellVisibility(cell: CustomCell, cellState: CellState) {
        cell.isHidden = cellState.dateBelongsTo == .thisMonth ? false : true
    }
    
    func handleCellSelection(cell: CustomCell, cellState: CellState) {
        
        if #available(iOS 11.0, *) {
            switch cellState.selectedPosition() {
            case .left:
                cell.selectedView.layer.cornerRadius = 20
                cell.selectedView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            case .middle:
                cell.selectedView.layer.cornerRadius = 0
                cell.selectedView.layer.maskedCorners = []
            case .right:
                cell.selectedView.layer.cornerRadius = 20
                cell.selectedView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            case .full:
                cell.selectedView.layer.cornerRadius = 20
                cell.selectedView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
            default: break
            }
        }
        
        cell.selectedView.isHidden = cellState.isSelected ? false : true
    }
    
    public func dateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var currentDate = startDate
        var endDate = endDate
        
        if startDate > endDate {
            currentDate = endDate
            endDate = startDate
        }
        var returnDates: [Date] = []
        
        while currentDate <= endDate {
            returnDates.append(currentDate)
            currentDate = Calendar.current.startOfDay(for: Calendar.current.date(
                byAdding: .day, value: 1, to: currentDate)!)
        }
        
        return returnDates
    }
    
}

extension CalendarVC: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let startDate = Date()
        let endDate = formatter.date(from: "2020 12 30")
        let params = ConfigurationParameters(startDate: startDate, endDate: endDate!)
        return params
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(cell: cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        configureCell(cell: cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        if firstDate != nil && date < firstDate! {
            calendar.selectDates(from: date, to: firstDate!, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
            firstDate = date
        } else if firstDate != nil && date > firstDate! {
            calendar.deselectAllDates()
            calendar.selectDates(from: firstDate!, to: date, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
        } else {
            firstDate = date
        }
        configureCell(cell: cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, shouldDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) -> Bool {
        
        let selectedDates = calendar.selectedDates
        
        if selectedDates.contains(date) {
            // remove dates from the last selected.
            if (selectedDates.count > 2 && selectedDates.first != date && selectedDates.last != date) {
                
                let indexOfDate = selectedDates.index(of: date)
                let dateBeforeDeselectedDate = selectedDates[indexOfDate!-1]
                calendar.deselectAllDates()
                calendar.selectDates(
                    from: selectedDates.first!,
                    to: dateBeforeDeselectedDate,
                    triggerSelectionDelegate: false,
                    keepSelectionIfMultiSelectionAllowed: true)
            }
        }
        
        return true
    }
    
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        
        guard let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomCell", for: indexPath) as? CustomCell else {return JTAppleCell()}
        cell.dateLabel.text = cellState.text
        configureCell(cell: cell, cellState: cellState)
        return cell
    }
    
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        dateSetup(dateSegment: visibleDates)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTAppleCollectionReusableView {
        guard let view = calendar.dequeueReusableJTAppleSupplementaryView(withReuseIdentifier: "header", for: indexPath) as? CalendarHeader else {return JTAppleCollectionReusableView() }
        return view
    }
    
    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize? {
        return MonthSize(defaultSize: 50.0)
    }
    
}


extension UIColor {
    
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hex & 0xFF)) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
