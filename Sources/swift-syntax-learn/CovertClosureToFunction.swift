import Foundation
import SwiftSyntax
import SwiftParser


/// Converts an eligible closure expression into a function declaration.
///
/// Production-readiness checklist:
/// [ ] Return transformed source instead of printing debug output
/// [ ] Replace the original closure through a SyntaxRewriter
/// [ ] Define a function-name strategy instead of using an editor placeholder
/// [ ] Preserve parameter labels, attributes, and effects
/// [ ] Reject or explicitly handle closures with captured local values
/// [ ] Reject unresolved shorthand parameter and inferred return types
/// [ ] Preserve comments and relevant source trivia
/// [ ] Report unsupported syntax and parser diagnostics
/// [ ] Add unit and integration tests for supported and rejected cases
///
class ConvertClosureToFunction {
    private func parseParameters(from clause: ClosureSignatureSyntax.ParameterClause?) -> [FunctionParameterSyntax] {
        guard let clause else { 
            return []
        }

        return switch clause {
        case let .parameterClause(syntax):
            syntax
                .parameters.compactMap({ syt in
                    if let type = syt.type {
                        let trailingComma: TokenSyntax? =
                            if syntax.parameters.last != syt {
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
        case let .simpleInput(syntax):
            syntax.map({ syt in
                let trailingComma: TokenSyntax? =
                    if syntax.last != syt {
                        .commaToken(trailingTrivia: .space)
                    } else {
                        nil
                    }
                    
                return FunctionParameterSyntax(
                    firstName: syt.name,
                    colon: .colonToken(trailingTrivia: .space),
                    type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("<#Type#>"))),
                    trailingComma: trailingComma
                )
            })
        }
    }
    
    func parse(_ closure: ClosureExprSyntax) -> FunctionDeclSyntax {
        let parameters = self.parseParameters(
            from: closure.signature?.parameterClause
        )
        
        let returnType = closure.signature?.returnClause?.type ?? TypeSyntax(IdentifierTypeSyntax(name: .identifier("<#returnType#>")))

        return FunctionDeclSyntax(
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
    }
}
