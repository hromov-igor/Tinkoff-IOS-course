import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    
    @IBOutlet weak var reloadButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var currencies = [""]
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        self.setCurrencies()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.label.text = " "

        self.pickerFrom.isHidden = true
        self.pickerTo.isHidden = true
        
        self.setCurrencies()

        
        self.pickerTo.dataSource = self
        self.pickerFrom.dataSource = self
        
        self.pickerFrom.delegate = self
        self.pickerTo.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func setCurrencies() {
        self.retrieveCurrencyList() {[weak self] (value) in
            DispatchQueue.main.sync(execute: {
                if let strongSelf = self {
                    strongSelf.currencies = value
                    if(strongSelf.currencies.count == 1) {
                        strongSelf.label.text = "Can't get data from server"
                        strongSelf.reloadButton.isHidden = false
                    } else {
                        strongSelf.label.text = " "
                        strongSelf.reloadButton.isHidden = true
                        strongSelf.pickerTo.reloadAllComponents()
                        strongSelf.pickerFrom.reloadAllComponents()
                        strongSelf.requestCurrentCurrencyRate()
                        strongSelf.pickerFrom.isHidden = false
                        strongSelf.pickerTo.isHidden = false
                    }
                }
            })
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == pickerTo {
            return self.currenciesExceptBase().count
        }
        
        return currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == pickerTo {
            return self.currenciesExceptBase()[row]
        }
        
        return currencies[row]
    }
    
    func currenciesExceptBase() -> [String] {
        var currenciesExceptBase = currencies
        currenciesExceptBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
        
        return currenciesExceptBase
    }
    
    
    func parseCurrencyResponse(data: Data?) -> [String] {
        var value : [String]
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                     value = [String](rates.keys)
                     value.append(parsedJSON["base"] as! String)
                } else {
                    value = ["No \"rates\" field found"]
                }
            } else {
                value = ["No JSON value parsed"]
            }
            
        } catch {
            value = [error.localizedDescription]
        }
        
        return value
        
    }
    
    func retrieveCurrencyList(completition: @escaping ([String]) -> Void) {
        self.requestСurrencies() { [weak self] (data, error) in
            var string = ["No data retrieved"]
            if let currentError = error {
                string = [currentError.localizedDescription]
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyResponse(data: data)
                }
            }
            
            completition(string)
        }
    }
    
    func requestСurrencies(parseHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest")!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataRecieved, response, error) in
            parseHandler(dataRecieved, error)
        }
        
        dataTask.resume()
    }
    
    
    func requestCurrentCurrencyRate() {
        
        self.activityIndicator.startAnimating()
        self.label.text = " "
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExceptBase()[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency) {[weak self] (value) in
            DispatchQueue.main.async(execute: {
                if let strongSelf = self {
                    strongSelf.label.text = "1 " + baseCurrency + " = " + value + " " + toCurrency
                    strongSelf.activityIndicator.stopAnimating()
                }
            })
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == pickerFrom {
            self.pickerTo.reloadAllComponents()
            self.pickerFrom.reloadAllComponents()

        }
        
        self.requestCurrentCurrencyRate()
    }
    
    func requestСurrencyRates(baseCurrency : String, parseHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataRecieved, response, error) in
            parseHandler(dataRecieved, error)
        }
        
        dataTask.resume()
    }

    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value : String = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    if let rate = rates[toCurrency] {
                        value = "\(rate)"
                    } else {
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                } else {
                    value = "No \"rates\" field found"
                }
            } else {
                value = "No JSON value parsed"
            }
            
        } catch {
            value = error.localizedDescription
        }
        
        return value
    }
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, completition: @escaping (String) -> Void) {
        self.requestСurrencyRates(baseCurrency: baseCurrency) { [weak self] (data, error) in
            var string = "No currency retrieved"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            completition(string)
        }
    }
    
}

