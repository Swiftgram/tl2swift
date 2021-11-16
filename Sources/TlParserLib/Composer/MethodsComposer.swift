//
//  File.swift
//  
//
//  Created by Anton Glezman on 15/09/2019.
//

import Foundation

final class MethodsComposer: Composer {
    
    // MARK: - Private properties
    
    private let classInfoes: [ClassInfo]
    private let swiftAsync: Bool
    
    
    // MARK: - Init
    
    init(classInfoes: [ClassInfo], swiftAsync: Bool = false) {
        self.classInfoes = classInfoes
        self.swiftAsync = swiftAsync
    }
    
    
    // MARK: - Override
    
    override func composeUtilitySourceCode() throws -> String {
        let methods = composeMethods(classInfoes: classInfoes)
        let executeFunc = composeExecuteFunc()

        let classPrefix = swiftAsync ? "Async" : ""
        return ""
            .addLine("public final class \(classPrefix)TdApi {")
            .addBlankLine()
            .addLine("public let client: \(classPrefix)TdClient".indent())
            .addLine("public let encoder = JSONEncoder()".indent())
            .addLine("public let decoder = JSONDecoder()".indent())
            .addBlankLine()
            .addLine("public init(client: \(classPrefix)TdClient) {".indent())
            .addLine("self.client = client".indent().indent())
            .addLine("self.encoder.keyEncodingStrategy = .convertToSnakeCase".indent().indent())
            .addLine("self.decoder.keyDecodingStrategy = .convertFromSnakeCase".indent().indent())
            .addLine("}".indent())
            .addBlankLine()
            .addBlankLine()
            .append(methods.indent())
            .addBlankLine()
            .append(executeFunc.indent())
            .addLine("}")
    }
    
    
    // MARK: - Private methods
    
    private func composeMethods(classInfoes: [ClassInfo]) -> String {
        var result = ""
        for info in classInfoes where info.isFunction {
            result = result.append(composeMethod(info))
        }
        return result
    }
    
    private func composeMethod(_ info: ClassInfo) -> String {
        var paramsList = [String]()
        let propertiesCount = info.properties.count
        for (index, param) in info.properties.enumerated() {
            let type = TypesHelper.getType(param.type, optional: param.optional)
            let paramName = TypesHelper.maskSwiftKeyword(param.name.underscoreToCamelCase())
            let trailingComma = index + 1 == propertiesCount ? "" : ","
            paramsList.append("\(paramName): \(type)\(trailingComma)")
        }
        if !swiftAsync {
            paramsList.append("completion: @escaping (Result<\(info.rootName), Swift.Error>) -> \(info.rootName)")
        }
        
        var result = composeComment(info)
        if paramsList.count > 1 {
            let params = paramsList.reduce("", { $0.addLine("\($1)".indent()) })
            result = result
                .addLine("public func \(info.name)(")
                .append(params)
            if swiftAsync {
                result = result.addLine(") async throws -> \(info.rootName) {")
            } else {
                result = result.addLine(") throws {")
            }
        } else {
            if swiftAsync {
                result = result.addLine("public func \(info.name)(\(paramsList.first ?? "")) async throws -> \(info.rootName) {")
            } else {
                result = result.addLine("public func \(info.name)(\(paramsList.first ?? "")) throws {")
            }
        }
        
        let impl = composeMethodImpl(info)
        result = result
            .append(impl.indent())
            .addLine("}")
            .addBlankLine()
        
        return result
    }
    
    private func composeComment(_ info: ClassInfo) -> String {
        var result = "/// \(info.description)\n"
        for param in info.properties {
            let paramName = TypesHelper.maskSwiftKeyword(param.name.underscoreToCamelCase())
            result = result.addLine("/// - Parameter \(paramName): \(param.description ?? "")")
        }
        return result
    }
    
    private func composeMethodImpl(_ info: ClassInfo) -> String  {
        let structName = info.name.capitalizedFirstLetter
        var result = ""
        if info.properties.isEmpty {
            result = result.addLine("let query = \(structName)()")
        } else {
            result = result.addLine("let query = \(structName)(")
            for param in info.properties {
                let paramName = param.name.underscoreToCamelCase()
                let paramValue = TypesHelper.maskSwiftKeyword(param.name.underscoreToCamelCase())
                result = result.addLine("\(paramName): \(paramValue),".indent())
            }
            result = String(result.dropLast().dropLast())
            result = result.addBlankLine().addLine(")")
        }

        if swiftAsync {
            return result.addLine("return try await execute(query: query)")
        } else {
            return result.addLine("execute(query: query, completion: completion)")
        }
    }
    
    private func composeExecuteFunc() -> String {
        if swiftAsync {
            return ""
                .addLine("private func execute<Q, R>(query: Q) async throws -> R where Q: Codable, R: Codable {")
                .addLine("    let dto = DTO(query, encoder: self.encoder)")
                .addLine("    let result = try await client.send(query: dto)")
                .addBlankLine()
                .addLine("    if let error = try? self.decoder.decode(DTO<Error>.self, from: result) {")
                .addLine("        throw error.payload")
                .addLine("    }")
                .addLine("    let response = self.decoder.tryDecode(DTO<R>.self, from: result)")
                .addLine("    switch response {")
                .addLine("        case .success(let data):")
                .addLine("            return data.payload")
                .addLine("        case .failure(let error):")
                .addLine("            throw error")
                .addLine("    }")
                .addLine("}")
        } else {
            return ""
                .addLine("private func execute<Q, R>(")
                .addLine("    query: Q,")
                .addLine("    completion: @escaping (Result<R, Swift.Error>) -> Void)")
                .addLine("    where Q: Codable, R: Codable {")
                .addBlankLine()
                .addLine("    let dto = DTO(query, encoder: self.encoder)")
                .addLine("    client.send(query: dto) { [weak self] result in")
                .addLine("        guard let self = self else { return }")
                .addLine("        if let error = try? self.decoder.decode(DTO<Error>.self, from: result) {")
                .addLine("            completion(.failure(error.payload))")
                .addLine("        }")
                .addLine("        let response = self.decoder.tryDecode(DTO<R>.self, from: result)")
                .addLine("        completion(response.map { $0.payload })")
                .addLine("    }")
                .addLine("}")
        }
    }
}
