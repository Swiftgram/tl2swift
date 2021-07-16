import Foundation
import TlParserLib

let args = ProcessInfo.processInfo.arguments

if args.count == 1 || args[1] == "--help" || args[1] == "-h" {
    print("Usage: \n\ttl2swift api.tl output_dir")
    exit(0)
}

let inFile = URL(fileURLWithPath: args[1])
let outPath = args.count > 2 ? URL(fileURLWithPath: args[2]) : URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let data = try! Data(contentsOf: inFile)
let tl = String(data: data, encoding: .utf8)!

let parser = Parser(tl: tl)
guard let schema = parser.parse() else {
    print("Can't parse")
    exit(1)
}

let app = Application(schema: schema, outputDir: outPath)
exit(app.run())
