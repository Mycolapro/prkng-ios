//
//  SearchFilterView.swift
//  prkng-ios
//
//  Created by Antonino Urbano on 2015-06-24.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit

class SearchFilterView: UIView, UITextFieldDelegate {

    private var searchFieldView : UIView
    private var searchField : UITextField
    
    private var searchImageView: UIImageView
    
    private var topLine: UIView
    private var bottomLine: UIView
    
    var delegate : SearchViewControllerDelegate?

    private var didsetupSubviews : Bool
    private var didSetupConstraints : Bool

    static var TOTAL_HEIGHT : CGFloat = 80

    override init(frame: CGRect) {
        
        searchFieldView = UIView()
        searchField = UITextField()
        
        searchImageView = UIImageView(image: UIImage(named: "icon_searchfield"))

        topLine = UIView()
        bottomLine = UIView()
        
        didsetupSubviews = false
        didSetupConstraints = true
        
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        if (!didsetupSubviews) {
            setupSubviews()
            self.setNeedsUpdateConstraints()
        }
        
        super.layoutSubviews()
    }
    
    override func updateConstraints() {
        if(!didSetupConstraints) {
            setupConstraints()
        }
        
        super.updateConstraints()
    }
    
    func setupSubviews () {
        
        self.clipsToBounds = true
        self.backgroundColor = Styles.Colors.midnight2
        
        searchFieldView.backgroundColor = Styles.Colors.midnight1
        self.addSubview(searchFieldView)

        let attributes = [NSFontAttributeName: Styles.FontFaces.light(17), NSForegroundColorAttributeName: Styles.Colors.cream1]
        
        searchField.clearButtonMode = UITextFieldViewMode.Never
        searchField.font = Styles.FontFaces.light(17)
        searchField.textColor = Styles.Colors.cream1
        searchField.textAlignment = NSTextAlignment.Natural
        searchField.attributedPlaceholder = NSAttributedString(string: "search_bar_text".localizedString, attributes: attributes)
        searchField.delegate = self
        searchField.keyboardAppearance = UIKeyboardAppearance.Default
        searchField.keyboardType = UIKeyboardType.Default
        searchField.autocorrectionType = UITextAutocorrectionType.No
        searchField.returnKeyType = UIReturnKeyType.Search
        searchField.modifyClearButtonWithImageNamed("icon_close")
        self.addSubview(searchField)
        
        searchImageView.contentMode = UIViewContentMode.Center
        self.addSubview(searchImageView)
        
        topLine.backgroundColor = Styles.Colors.transparentWhite
        self.addSubview(topLine)
        
        bottomLine.backgroundColor = Styles.Colors.transparentBlack
        self.addSubview(bottomLine)

        didsetupSubviews = true
        didSetupConstraints = false
    }
    
    func setupConstraints () {
        
        searchFieldView.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self).with.offset(12)
            make.right.equalTo(self).with.offset(-12)
            make.bottom.equalTo(self).with.offset(-10)
            make.height.equalTo(40)
        }
        
        searchField.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self.searchImageView.snp_right).with.offset(14)
            make.right.equalTo(self).with.offset(-12)
            make.bottom.equalTo(self).with.offset(-10)
            make.height.equalTo(40)
        }
        
        searchImageView.snp_makeConstraints { (make) -> () in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.centerY.equalTo(self.searchField)
            make.left.equalTo(self).with.offset(17 + 12)
        }
        
        topLine.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.top.equalTo(self)
            make.height.equalTo(0.5)
        }

        bottomLine.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }
        
    }

    
    // UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return self.searchFieldView.frame.size.width > 0
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let resultString = (textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string)
        if count(resultString) >= 2 {
            SearchOperations.searchWithInput(resultString, forAutocomplete: true, completion: { (results) -> Void in
                self.delegate?.didGetAutocompleteResults(results)
            })
        } else {
            self.delegate?.didGetAutocompleteResults([])
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.endEditing(true)
        SearchOperations.searchWithInput(textField.text, forAutocomplete: false, completion: { (results) -> Void in
            
            let today = DateUtil.dayIndexOfTheWeek()
            var date : NSDate = NSDate()
            
            self.delegate!.displaySearchResults(results, checkinTime : date)
            
        })
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text.isEmpty {
            endSearch(textField)
        } else {
            delegate?.didGetAutocompleteResults([])
        }
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if textField.text == "" {
            endSearch(textField)
        } else {
            clearSearch(textField)
        }
        return true
    }
    
    func clearSearch(textField: UITextField) {
        delegate?.clearSearchResults()
        delegate?.didGetAutocompleteResults([])
        textField.text = ""
    }

    func endSearch(textField: UITextField) {
        clearSearch(textField)
//        transformSearchFieldIntoButton()
        textField.endEditing(true)
    }

    //MARK- helper functions
    
    func makeActive() {
        searchField.becomeFirstResponder()
    }
    
    func makeInactive() {
        searchField.resignFirstResponder()
        delegate?.didGetAutocompleteResults([])
    }
    
    func setSearchResult(result: SearchResult) {
        self.searchField.text = result.title
//        textFieldShouldReturn(self.searchField)
        self.delegate!.displaySearchResults([result], checkinTime : NSDate())
    }

}
