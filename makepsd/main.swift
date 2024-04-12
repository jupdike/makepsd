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

func main() {
    let arguments: Array<String> = Array<String>(CommandLine.arguments.dropFirst())
    var firstFile: String? = nil
    for arg in arguments {
        print("got filename: \(arg)")
        if firstFile == nil {
            firstFile = arg
            break
        }
    }

    if let first: String = firstFile {
        let ns = first as NSString
        let output = ns.deletingPathExtension.appending(".psd")
        print("want to write output to: \(output)")
        let outputUrl = URL(fileURLWithPath: output)
        
//        for fname in arguments {
//            var contents: String? = nil
//            do {
//                try contents = String(contentsOf: URL(fileURLWithPath: fname))
//            } catch {
//                print("Problem trying to read contents of: \(fname)")
//            }
//            guard let str = contents else { continue }
//            do {
//                try str.write(to: outputUrl, atomically: true, encoding: String.Encoding.utf8)
//            } catch {
//                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
//            }
//        }
        writeImageFilePathsToPSD(files: arguments, outputUrl: outputUrl)
    }
}

main()
