//
//  main.swift
//  makepsd
//
//  Created by Jared Updike on 4/11/24.
//

import Foundation

//print("welcome to makepsd")

let arguments = CommandLine.arguments.dropFirst()
var firstFile: String? = nil
for arg in arguments {
    print("got filename: \(arg)")
    if firstFile == nil {
        firstFile = arg
    }
}

if let first: String = firstFile {
    let ns = first as NSString
    let output = ns.deletingPathExtension.appending(".text") // will be .psd  very soon
    print("want to write output to: \(output)")
    let outputUrl = URL(fileURLWithPath: output)
    
    for fname in arguments {
        var contents: String? = nil
        do {
            try contents = String(contentsOf: URL(fileURLWithPath: fname))
        } catch {
            print("Problem trying to read contents of: \(fname)")
        }
        guard let str = contents else { continue }
        do {
            try str.write(to: outputUrl, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
}
