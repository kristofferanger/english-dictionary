//
//  MainViewController.swift
//  dictionary
//
//  Created by Kristoffer Anger on 2022-10-18.
//

import UIKit

enum LoadingState {
    case fetch, read, prepare, error(message: String), present(dictionary: [DictionarySection])
    
    init() {
        self = .fetch
    }
}

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var dataManager = DataManager()
    private var tableViewData = [DictionarySection]()
    private var filteredData: [DictionarySection]?
    private var allWords: [String]?

    private var state = LoadingState() {
        didSet {
            switch state {
            case .fetch:
                self.showSpinner(message: "Downloading data")
                dataManager.fetchData { [weak self] success in
                    if success {
                        self?.state = .read
                    }
                    else {
                        self?.state = .error(message: "Downloading failed")
                    }
                }
            case .read:
                self.showSpinner(message: "Reading data")
                dataManager.readFromDisc { [weak self] words, error in
                    if let words {
                        self?.allWords = words
                        self?.state = .prepare
                    }
                    else {
                        self?.state = .error(message: "Could not read data")
                    }
                }
                
            case .prepare:
                self.showSpinner(message: "Preparing dictionary")
                if let words = allWords {
                    dataManager.prepareData(words: words) { [weak self] dict in
                        self?.state = .present(dictionary: dict)
                    }
                }
                else {
                    self.state = .error(message: "Data is missing")
                }
            case .present(dictionary: let dictionary):
                hideSpinner()
                self.showContent(dictionary)
            case .error(message: let errorMessage):
                hideSpinner()
                self.showError(errorMessage)
                print(errorMessage)
            }
        }
    }
    
    private lazy var loadingView: UIView = {
        let backgroundView = UIView(frame: .zero)
        backgroundView.backgroundColor = .init(white: 0.3, alpha: 0.3)
        self.view.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        spinner.color = .white
        spinner.center = self.view.center
        backgroundView.addSubview(spinner)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.view.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            self.view.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        ])
        return backgroundView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // initial state can either be:
        // .fetch (no dictionary downloaded)
        // .read (dictionary downloaded, but not read and prepared)
        state = FileManager().fileExists(atPath: dataManager.filename.path) ? .read : .fetch
        
        self.title = "English dictionary"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .init(white: 0.95, alpha: 1)
        
        // search
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search for a word"
        navigationItem.searchController = search
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let selectedIndex = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndex, animated: true)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination as? DetailViewController, let cell = sender as? UITableViewCell {
            guard let word = cell.textLabel?.text else { return }
            detailViewController.word = word
            detailViewController.removeAction = {
                self.removeWord(word.lowercased())
            }
        }
    }

    
    // MARK: - UITableViewDataSource methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredData?.count ?? tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredData?[section].words.count ?? tableViewData[section].words.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let tableViewData = filteredData ?? tableViewData
        guard let character = tableViewData[section].header else { return nil }
        return String(character).uppercased()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewData = filteredData ?? tableViewData
        let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell", for: indexPath)
        cell.textLabel?.text = tableViewData[indexPath.section].words[indexPath.row].capitalized
        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard filteredData == nil else { return nil }
        return DataManager.alphabet.map{ String($0).uppercased() }
    }
    
    // MARK: - Actions
    
    func removeWord(_ word: String) {
        if let index = allWords?.firstIndex(of: word) {
            allWords?.remove(at: index)
            state = .prepare
        }
    }
    
    func showError(_ errorMessage: String) {
        print("WARNING - an error occured! \(errorMessage)")
    }
    
    func showContent(_ content: [DictionarySection]) {
        tableViewData = content
        tableView.reloadData()
    }
    
    func showSpinner(message: String) {
        loadingView.isHidden = false
    }
    
    func hideSpinner() {
        loadingView.isHidden = true
    }

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            DispatchQueue.global().async {
                let words = self.allWords ?? []
                let filteredWords = words.filter { word in
                    return word.range(of: searchText, options: .caseInsensitive) != nil
                }
                DispatchQueue.main.async {
                    self.filteredData = [DictionarySection(header: nil, words: filteredWords)]
                    self.tableView.reloadData()
                }
            }
        }
        else {
            filteredData = nil
            tableView.reloadData()
        }
    }
}
