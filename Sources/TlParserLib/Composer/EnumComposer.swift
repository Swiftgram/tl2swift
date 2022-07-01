//
//  EnumComposer.swift
//  tl_parser_lib
//
//  Created by Anton Glezman on 15/09/2019.
//

import Foundation

final class EnumComposer: Composer {
    
    // MARK: - Private properties
    
    private let enumInfo: EnumInfo
    private let schema: Schema
    
    // MARK: - Init
    
    init(enumInfo: EnumInfo, schema: Schema) {
        self.enumInfo = enumInfo
        self.schema = schema
    }
    
    
    // MARK: - Override
    
    override public func composeUtilitySourceCode() throws -> String {
        let indirect = isIndirect(enumInfo.enumType) ? "indirect " : ""
        let cases = composeCaseItems(enumInfo)
        let kinds = composeKindItems(enumInfo)
        let decoder = composeDecoder(enumInfo)
        let encoder = composeEncoder(enumInfo)
        let structs = try composeAssociatedStructs()
        
        return ""
            .addLine("/// \(enumInfo.description)")
            .addLine("public \(indirect)enum \(enumInfo.enumType): Codable, Equatable {")
            .addBlankLine()
            .append(cases.indent())
            .addBlankLine()
            .append(kinds.indent())
            .addBlankLine()
            .append(decoder.indent())
            .addBlankLine()
            .append(encoder.indent())
            .addLine("}")
            .addBlankLine()
            .append(structs)
    }
    
    
    // MARK: - Private methods
    
    private func makeCase(for item: EnumItem, typeName: String) -> String {
        let index = item.name.index(
            item.name.startIndex,
            offsetBy: typeName.replacingOccurrences(of: "Content", with: "").count)
        var caseName = item.name.suffix(from: index)
        // Make the string camelCase again
        caseName = caseName.prefix(1).lowercased() + caseName.dropFirst()
        return String(caseName)
    }
    
    private func composeCaseItems(_ info: EnumInfo) -> String {
        var result = ""
        for item in info.items {
            result = result.addLine("/// \(item.description)")
            let caseName = makeCase(for: item, typeName: info.enumType)
            if let assocClass = item.associatedClassName {
                result = result.addLine("case \(caseName)(\(assocClass))")
            } else {
                result = result.addLine("case \(caseName)")
            }
            result = result.addBlankLine()
        }
        return result
    }
    
    private func composeKindItems(_ info: EnumInfo) -> String {
        let cases = info.items.reduce("", { $0.addLine("case \($1.name)".indent()) })
        return ""
            .addLine("private enum Kind: String, Codable {")
            .append(cases)
            .addLine("}")
    }
    
    private func composeDecoder(_ info: EnumInfo) -> String {
        let cases = composeDecoderCases(info)
        return ""
            .addLine("public init(from decoder: Decoder) throws {")
            .addLine("let container = try decoder.container(keyedBy: DtoCodingKeys.self)".indent())
            .addLine("let type = try container.decode(Kind.self, forKey: .type)".indent())
            .addLine("switch type {".indent())
            .append(cases.indent())
            .addLine("}".indent())
            .addLine("}")
    }
    
    private func composeDecoderCases(_ info: EnumInfo) -> String {
        var result = ""
        for item in info.items {
            result = result.addLine("case .\(item.name):")
            let caseName = makeCase(for: item, typeName: info.enumType)
            if let assocStruct = item.associatedClassName {
                result = result.addLine("let value = try \(assocStruct)(from: decoder)".indent())
                result = result.addLine("self = .\(caseName)(value)".indent())
            } else {
                result = result.addLine("self = .\(caseName)".indent())
            }
        }
        return result
    }
    
    private func composeEncoder(_ info: EnumInfo) -> String {
        let cases = composeEncoderCases(info)
        return ""
            .addLine("public func encode(to encoder: Encoder) throws {")
            .addLine("var container = encoder.container(keyedBy: DtoCodingKeys.self)".indent())
            .addLine("switch self {".indent())
            .append(cases.indent())
            .addLine("}".indent())
            .addLine("}")
    }
    
    private func composeEncoderCases(_ info: EnumInfo) -> String {
        var result = ""
        for item in info.items {
            let caseName = makeCase(for: item, typeName: info.enumType)
            if item.associatedClassName != nil {
                result = result.addLine("case .\(caseName)(let value):")
                result = result.addLine("try container.encode(Kind.\(item.name), forKey: .type)".indent())
                result = result.addLine("try value.encode(to: encoder)".indent())
            } else {
                result = result.addLine("case .\(caseName):")
                result = result.addLine("try container.encode(Kind.\(item.name), forKey: .type)".indent())
            }
        }
        return result
    }
    
    private func composeAssociatedStructs() throws -> String {
        var result = ""
        let assocStructs = enumInfo.items.compactMap { $0.associatedClassName }
        try assocStructs.forEach { name in
            if let info = schema.classInfoes.first(where: { $0.name.lowercased() == name.lowercased() }) {
                let composer = StructComposer(classInfo: info)
                let structs = try composer.composeUtilitySourceCode()
                result = result.append(structs)
            }
        }
        return result
    }
    
    private func isIndirect(_ name: String) -> Bool {
        // TODO: check enum recursion
        let indirectEnums = ["RichText", "PageBlock", "InternalLinkType"]
        return indirectEnums.contains(name)
    }
}
