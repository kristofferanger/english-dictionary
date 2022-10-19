//
//  DataManager.swift
//  dictionary
//
//  Created by Kristoffer Anger on 2022-10-18.
//

import Foundation

struct DictionarySection {
    let header: Character?
    var words: [String]
}

struct DataManager {
    
    private static let urlString = "https://github.com/dwyl/english-words/blob/master/words_alpha.txt?raw=true"
    private static let delimiter = "\r\n"
    static let alphabet = "abcdefghijklmnopqrstuvxyz"
    
    private var url: URL {
        return URL(string: DataManager.urlString)!
    }
    
    var filename: URL {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = documentsUrl.appendingPathComponent(url.lastPathComponent)
        return filename
    }
        
    func fetchData(succeded: @escaping (Bool) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            if let data = data {
                // write to disc
                do {
                    let text = String(decoding: data, as: UTF8.self)
                    try text.write(to: filename, atomically: false, encoding: .utf8)
                    DispatchQueue.main.async {
                        succeded(true)
                    }
                }
                catch {
                    DispatchQueue.main.async {
                        succeded(false)
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    succeded(false)
                }
            }
        }
        dataTask.resume()
    }
    
    func readFromDisc(result: @escaping ([String]?, Error?) -> Void) {
        DispatchQueue.global().async {
            // read from disc
            do {
                let textBlob = try String(contentsOf: filename, encoding: .utf8)
                let words = textBlob.trimmingCharacters(in: CharacterSet.newlines).components(separatedBy: DataManager.delimiter)
                
                DispatchQueue.main.async {
                    result(words, nil)
                }
            }
            catch {
                DispatchQueue.main.async {
                    result(nil, error)
                }
            }
        }
    }
    
    func prepareData(words: [String], result: @escaping ([DictionarySection]) -> Void ) {
        DispatchQueue.global().async {
            // make sorting and sectioning at the same time
            // and use prepared structure to keep O-number down
            var sectionStructure = DataManager.alphabet.map { DictionarySection(header: $0, words: []) }
            // sorting
            for word in words {
                // compare header char with first char in word
                //  + ignore one letter words
                if let index = sectionStructure.firstIndex(where: { word.count > 1 && $0.header == word[word.startIndex] }){
                    sectionStructure[index].words.append(word)
                }
            }
            DispatchQueue.main.async {
                result(sectionStructure)
            }

        }
    }
}
