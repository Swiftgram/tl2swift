//
//  ClientProtocolComposer.swift
//  tl_parser_lib
//
//  Created by Anton Glezman on 22/09/2019.
//

import Foundation

/// Generates protocol for TDClient
final class ClientProtocolComposer: Composer {
    
    override func composeUtilitySourceCode() throws -> String {
        return ""
            .addLine("/// Basic protocol for communicate with TdLib.")
            .addLine("public protocol TdClient {")
            .addBlankLine()
            .addLine("    /// Receives incoming updates and request responses from the TDLib client")
            .addLine("    func run(updateHandler: @escaping (Data) -> Void)")
            .addBlankLine()
            .addLine("    /// Sends request to the TDLib client.")
            .addLine("    func send(query: TdQuery, completion: ((Data) -> Void)?)")
            .addBlankLine()
            .addLine("    /// Synchronously executes TDLib request. Only a few requests can be executed synchronously.")
            .addLine("    func execute(query: TdQuery) -> Result<[String:Any]?, Swift.Error>")
            .addBlankLine()
            .addLine("    /// Close connection with TDLib.")
            .addLine("    func close()")
            .addBlankLine()
            .addLine("}")
            .addBlankLine()
            .addBlankLine()
            .addLine("/// Basic Async protocol for communicate with TdLib.")
            .addLine("@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)")
            .addLine("public protocol AsyncTdClient {")
            .addBlankLine()
            .addLine("    /// Creates client and starts updates poller to work with async requests")
            .addLine("    func run(updateHandler: @escaping (Data) -> Void)")
            .addBlankLine()
            .addLine("    /// Continuously listen for updates and asynchronously process them via provided updateHandler")
            .addLine("    func run(updateHandler: @escaping (Data) -> Void)")
            .addBlankLine()
            .addLine("    /// Asynchronously Sends request to the TDLib client.")
            .addLine("    func send(query: TdQuery) async throws -> Data")
            .addBlankLine()
            .addLine("    /// Synchronously executes TDLib request.")
            .addLine("    func execute(query: TdQuery) throws -> [String:Any]?")
            .addBlankLine()
            .addLine("    /// Close connection with TDLib and stop updates polling.")
            .addLine("    func close()")
            .addBlankLine()
            .addLine("}")
            .addBlankLine()
            .addBlankLine()
            .addLine("public protocol TdQuery {")
            .addBlankLine()
            .addLine("    func make(with extra: String?) throws -> Data")
            .addBlankLine()
            .addLine("}")
    }
}
