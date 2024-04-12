//
//  main.swift
//  makepsd
//
//  Created by Jared Updike on 4/11/24.
//

// NOTE that the PSDWriter parts are Copyright (C) 2013-2014 Ben Gotow and Mark Fleming
// https://github.com/bengotow/PSDWriter/

import Foundation
import AppKit

extension String {
  /*
   Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
   - Parameter length: Desired maximum lengths of a string
   - Parameter trailing: A 'String' that will be appended after the truncation.
    
   - Returns: 'String' object.
  */
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
}

//print("welcome to makepsd")

// must be < 256 bytes, lets say < 200 chars, and only filename not folders
func ensureShortStr(_ fileName: String) -> String {
    let piece: String = ((fileName as NSString).lastPathComponent as NSString).deletingPathExtension
    return piece.trunc(length: 200)
}

func writeImageFilePathsToPSD(files: [String], outputUrl: URL) {
    var writer: PSDWriter? = nil // will be initialized once we know size of original file

    for file in files {
        let layerMaybe = NSImage(contentsOfFile: file)
        guard let layer = layerMaybe else {
            print("Error trying to load image file: \(file)")
            continue
        }
        if writer == nil {
            writer = PSDWriter(documentSize: CGSize(width: layer.size.width, height: layer.size.height))
        }
        guard let w = writer else {
            print("Error trying to create PSDWriter")
            return
        }
        let cgImageUnman: Unmanaged<CGImage> = newCGImageForNSImage(layer)
        let cgImage = cgImageUnman.takeRetainedValue() as? CGImage
        w.addLayer(with: cgImage as! CGImage, andName: ensureShortStr(file), andOpacity: 1.0, andOffset: CGPoint(x: 0, y: 0))
        //cgImageUnman.release()
    }
    
    let psd: Data = writer!.createPSDData()
    do {
        try psd.write(to: outputUrl)
    } catch {
        print("Failed to write PSD to \(outputUrl.absoluteString)")
    }
}

let enders = [".png", ".jpg", ".jpeg"]
func doesEndWithImageExt(_ str: String) -> Bool {
    let lower = str.lowercased()
    for end in enders {
        if lower.hasSuffix(end) {
            return true
        }
    }
    return false
}

func main() {
    let wordArguments: Array<String> = Array<String>(CommandLine.arguments.dropFirst())
        
    // There is some sort of shortcoming in macOS Shortcuts when trying to pass filenames with spaces
    // to work around this, we find the file extensions and use those as implicit delimiters to piece the
    // long filenames back together. Terrible in theory, fine in practice. ONLY WORKS WITH .png .jpg and .jpeg (case-insensitive)
    // also, assumes no double spaces(?!)
    var args: [String] = []
    var lastGroup: [String] = []

    // OK we are finally ready to use the file path arguments
    for word in wordArguments {
        lastGroup.append(word)
        if(doesEndWithImageExt(word)) {
            let reconstitued = lastGroup.joined(separator: " ")
            args.append(reconstitued)
            lastGroup = []
        }
    }
    guard lastGroup.count == 0 else {
        print("Could not completely combine input words input full filename, had extra words with no file extension: \(lastGroup)")
        return
    }

    var firstFile: String? = nil
    for arg in args {
        //print("got filename: \(arg)")
        if firstFile == nil {
            firstFile = arg
            break
        }
    }
    if let first: String = firstFile {
        let ns = first as NSString
        let output = ns.deletingPathExtension.appending(".psd")
        //print("want to write output to: \(output)")
        let outputUrl = URL(fileURLWithPath: output)
//        for fname in args {
//            print("INPUT FNAME: \(fname)")
//        }
        writeImageFilePathsToPSD(files: args, outputUrl: outputUrl)
    }
}

main()
