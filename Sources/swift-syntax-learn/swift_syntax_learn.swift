// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Here we are going to create a cli based refactor action, which helps us put all the import declaration in a single place, on top of the file.
/// For that we need the file
/// Contents of the file
/// Parse the file using SwiftParser
/// Separate declaration based on statement type

import Foundation
import SwiftParser
import SwiftSyntax

@main
struct swift_syntax_learn {
    static func main() {
        func doSome(clos: (Int) -> Int) {
            let num = clos(1)
            print(num)
        }

        doSome(clos: { num in
            num + 1
        })

        guard CommandLine.arguments.count == 2 else {
            print("not enough arguments")
            return
        }

        let filePath = CommandLine.arguments[1]
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("file not found")
            return
        }
        guard let contents = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            print("File at path isn't readable: \(filePath)")
            return
        }

        let formatted = Self().convertClosueToFunction(contents)
        print(formatted)
    }

    /// Function Syntax Structure
    /// [x] Detecting Functionc all expressions
    /// [x] Detecting trailing Closure expression
    /// [ ] Get paramete names and types
    ///     [x] Done for ClosureParameterList, eg. ... (num: Int, decinum: Float) in ...
    ///     [ ] Need to do for ClosureShorthandParameterList, eg. ...  num, decinum in ...
    /// [ ] Get body
    /// [ ] Get return type
    func convertClosueToFunction(_ contents: String) -> SourceFileSyntax {
        let parsed = Parser.parse(source: contents)
        let functionCodes = parsed
            .statements
            .filter { statement in
                if case let .expr(expr) = statement.item,
                    expr.as(FunctionCallExprSyntax.self) != nil
                {
                    return true
                } else {
                    return false
                }
            }
        self.parseFunctionExpression(expr: functionCodes)

        return
            parsed
            .with(\.statements, functionCodes)
    }

    func parseFunctionExpression(expr: CodeBlockItemListSyntax) {
        let functions =
            expr
            .compactMap { statement in
                if case let .expr(expr) = statement.item,
                    let call = expr.as(FunctionCallExprSyntax.self)
                {
                    return call
                } else {
                    return nil
                }
            }

        // if let returnType = functions.first?.trailingClosure?.signature?.returnClause?.type {
        //     print("returnType")
        //     print(returnType)
        // }

        if let closure = functions.first?
            .trailingClosure,
            let parameterClause = closure
                .signature?
                .parameterClause
        {
            // print("parameterClause")
            // print(parameterClause)

            switch parameterClause {
            case let .parameterClause(syntax):
                // print("parameterClause type: \(syntax)")
                // syntax.parameters.forEach { param in
                //     print("param firstName")
                //     print(param.firstName)
                //     if let type = param.type {
                //         print("param.type")
                //         print(type)
                //     }
                //     print()
                // }

                let parameters = syntax
                .parameters.compactMap({ syt in
                        if let type = syt.type {
                            let trailingComma: TokenSyntax? =  if syntax.parameters.last != syt {
                                .commaToken(trailingTrivia: .space)
                            } else {
                                nil
                            }

                            return FunctionParameterSyntax(
                                    firstName: syt.firstName, 
                                    colon: .colonToken(trailingTrivia: .space), type: type,
                                    trailingComma: trailingComma
                            )
                        } else {
                            return nil
                        }
                })

                guard let returnType = closure.signature?.returnClause?.type else {
                    fatalError("return type not found")
                }
                let newFunction = FunctionDeclSyntax(
                    name: .identifier(" <#name#>"),
                    signature: FunctionSignatureSyntax(
                        parameterClause: FunctionParameterClauseSyntax(
                            parameters: FunctionParameterListSyntax(parameters)
                        ),
                        effectSpecifiers: FunctionEffectSpecifiersSyntax(),
                        returnClause: ReturnClauseSyntax(
                            arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
                            type: returnType)
                    ),
                    body: CodeBlockSyntax(
                        leftBrace: .leftBraceToken(leadingTrivia: .space),
                        statements: closure.statements,
                        rightBrace: .rightBraceToken(leadingTrivia: .newline)
                    )
                )
                print("newFunction")
                print(newFunction)
            case let .simpleInput(syntax):
                print("simpleInput: \(syntax)")
                print(syntax.id)

            }
        }

        
    }

    func format(_ contents: String) -> SourceFileSyntax {
        let parsed = Parser.parse(source: contents)
        var statements = self.classify(code: parsed)

        /// Now we get all the coding block with their type
        /// We can proceed on formatting them
        let pivot =
            statements
            .partition(by: { item in
                switch item {
                case .import: false
                case .other: true
                }
            })

        /// Now we sort the import statements based on their size
        statements[..<pivot]
            .sort(by: { code1, code2 in
                guard case let .import(_, codeItem1) = code1,
                    case let .import(_, codeItem2) = code2
                else {
                    fatalError("must be import statement")
                }

                return codeItem1.description > codeItem2.description
            })

        /// Lets finally get all the formatted code
        let formatted =
            statements
            .enumerated()
            .map { (offset, item) in
                switch item {
                case let .import(_, code):
                    return
                        code
                        .with(\.leadingTrivia, tidy(code.leadingTrivia, isFirst: offset == 0))
                        .with(\.trailingTrivia, [])
                case let .other(code):
                    return code
                }
            }

        return parsed.with(\.statements, CodeBlockItemListSyntax(formatted))
    }

    func tidy(_ trivia: Trivia, isFirst: Bool) -> Trivia {
        var normalized = trivia.pieces.filter { piece in
            switch piece {
            case .spaces, .tabs:
                return false
            default:
                return true
            }
        }

        while let first = normalized.first, first.isNewline {
            normalized.removeFirst()
        }

        if !normalized.isEmpty && !isFirst {
            normalized.insert(.newlines(1), at: 0)
        }

        if !isFirst && normalized.isEmpty {
            normalized = [.newlines(1)]
        }

        return Trivia(pieces: normalized)
    }

    enum Item {
        case `import`(ImportDeclSyntax, CodeBlockItemSyntax)
        case other(CodeBlockItemSyntax)
    }

    func classify(code: SourceFileSyntax) -> [Item] {
        code
            .statements
            .map { statement in
                if case let .decl(decl) = statement.item,
                    let syntax = decl.as(ImportDeclSyntax.self)
                {
                    return .import(syntax, statement)
                } else {
                    return .other(statement)
                }
            }
    }
}
