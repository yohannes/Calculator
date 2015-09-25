//
//  ViewController.swift
//  Calculator
//
//  Created by Yohannes Wijaya on 8/29/15.
//  Copyright © 2015 Yohannes Wijaya. All rights reserved.
//
//

/*
todo: add pie operation

*/

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.floatingPointButton.enabled = false
        
        self.tapGestureToShowAllClearTipOnce = UITapGestureRecognizer(target: self, action: "alertAboutAllClearFunctionOnce")
        self.clearButton.addGestureRecognizer(tapGestureToShowAllClearTipOnce)
        
        self.longPressGestureToEmptyOperandOrOperatorStack = UILongPressGestureRecognizer(target: self, action: "emptyOperandOrOperatorStack:")
        self.longPressGestureToEmptyOperandOrOperatorStack.minimumPressDuration = 1.0
        self.clearButton.addGestureRecognizer(longPressGestureToEmptyOperandOrOperatorStack)
        
        self.customNumberFormatter = NSNumberFormatter()
        self.customNumberFormatter.maximumSignificantDigits = 4
    }
    
    // MARK: - Stored Properties
    
    var isUserInTheMiddleOfTyping = false
    var tapGestureToShowAllClearTipOnce: UITapGestureRecognizer!
    var longPressGestureToEmptyOperandOrOperatorStack: UILongPressGestureRecognizer!
    
    var customNumberFormatter: NSNumberFormatter!
    
    var calculatorModel = CalculatorModel()
    
    var calculationHistory = [String]()
    
    // MARK: - Computed Properties
    
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(self.displayLabel.text!)!.doubleValue ?? nil
        }
        set {
            guard newValue != nil else {
                self.displayLabel.text = "0"
                return
            }
            self.displayLabel.text = self.customNumberFormatter.stringFromNumber(NSNumber(double: newValue!))
            self.calculationHistory.append(self.displayLabel.text!)
            self.isUserInTheMiddleOfTyping = false
        }
    }
    
    // MARK: - IBOutlet Properties
    
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var historyDisplayLabel: UILabel!
    @IBOutlet weak var floatingPointButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    // MARK: - IBAction Properties
    
    @IBAction func appendDigitButton(sender: UIButton) {
        guard isUserInTheMiddleOfTyping else {
            self.displayLabel.text = sender.currentTitle!
            self.isUserInTheMiddleOfTyping = true
            self.floatingPointButton.enabled = true
            return
        }
        
        guard self.displayLabel.text!.characters.first == "0" else {
            if self.displayLabel.text!.characters.contains(".") {
                self.floatingPointButton.enabled = false
            }
            self.displayLabel.text! += sender.currentTitle!
            return
        }
        
        guard sender.currentTitle == "0" && self.displayLabel.text!.characters.contains(".") || self.displayLabel.text!.characters.contains(".") else {
            self.displayLabel.text = sender.currentTitle
            return
        }
        self.displayLabel.text! += sender.currentTitle!
    }
    
    @IBAction func appendFloatingPointButton(sender: UIButton) {
        self.displayLabel.text!.append("." as Character)
        self.floatingPointButton.enabled = false
    }

// move this dude to the model!
//    @IBAction func appendPieValue(sender: UIButton) {
//        if self.operandStack.count == 0 {
//            self.operandStack.append(self.displayValue!)
//            if self.operandStack.first == 0.0 {
//                self.operandStack.removeAtIndex(self.operandStack.count - 1)
//            }
//        }
//        self.displayValue = M_PI
//        self.enterButton()
//    }
    
    @IBAction func clearDisplayButton(sender: UIButton) {
        self.clearDisplay()
    }
    
    @IBAction func deleteButton(sender: UIButton) {
        guard self.displayLabel.text!.characters.count > 1 else {
            self.displayValue = nil
            self.isUserInTheMiddleOfTyping = false
            return
        }
        self.displayLabel.text = String(self.displayLabel.text!.characters.dropLast())
    }
    
    @IBAction func enterButton() {
        self.isUserInTheMiddleOfTyping = false
        self.floatingPointButton.enabled = false
        
        if let calculatedResult = self.calculatorModel.pushOperand(self.displayValue!) {
            self.displayValue = calculatedResult
        }
    }
    
    @IBAction func performMathOperationButton(sender: UIButton) {
        if self.isUserInTheMiddleOfTyping { self.enterButton() }
        if let mathOperatorSymbol = sender.currentTitle {
            if let calculatedResult = self.calculatorModel.pushMathOperator(mathOperatorSymbol) {
                self.displayValue = calculatedResult
            }
            self.showPastCalculations(sender)
        }
    }
    
    @IBAction func invertDigitButton(sender: UIButton) {
        guard self.displayValue != 0 else { return }
        self.displayValue! -= self.displayValue! * 2
    }
    
    
    // MARK: - Local Methods
    
    func alertAboutAllClearFunctionOnce() {
        let alertController = UIAlertController(title: "Tip: ", message: "If you tap & hold C, you can erase all memories instead.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "I got it", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: { [unowned self] () -> Void in
            self.clearButton.removeGestureRecognizer(self.tapGestureToShowAllClearTipOnce)
        })
    }
    
    func clearDisplay() {
        self.floatingPointButton.enabled = false
        self.displayValue = nil
        self.historyDisplayLabel.text = ""
        self.isUserInTheMiddleOfTyping = false
    }

    func emptyOperandOrOperatorStack(longPressGestureRecognizer: UIGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.Began {
            let alertController = UIAlertController(title: "Erase All Memories?", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Erase", style: UIAlertActionStyle.Default, handler: { [unowned self] (alertAction) -> Void in
                self.calculatorModel.emptyoperandOrOperatorStack()
                self.clearDisplay()
                self.calculationHistory = []
            }))
            alertController.addAction(UIAlertAction(title: "Don't erase", style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func showPastCalculations(mathOperatorButton: UIButton) {
        guard self.calculationHistory.count > 0 else { return }
        let index = self.calculationHistory.count
        
        switch mathOperatorButton.currentTitle! {
            case "+", "−", "×", "÷":
                guard index >= 3 else { break }
                self.historyDisplayLabel.text! += self.calculationHistory[index - 3] + mathOperatorButton.currentTitle! + self.calculationHistory[index - 2] + "=" + "\(self.displayValue!), "
            case "sin", "cos", "tan", "√":
                guard index >= 2 else { break }
                self.historyDisplayLabel.text! += mathOperatorButton.currentTitle! + self.calculationHistory[index - 2] + "=" + "\(self.displayValue!), "
            default: break
        }
    }
}