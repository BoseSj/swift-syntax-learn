import Testing
import SwiftSyntax
@testable import swift_syntax_learn

@Test func trivia_preserves_explicit_blank_lines_after_comments() {
    let original = Trivia(pieces: [
        .newlines(2),
        .lineComment("// keep me"),
        .newlines(2),
    ])

    let tidied = swift_syntax_learn().tidy(original, isFirst: false)

    #expect(tidied.pieces == [.newlines(1), .lineComment("// keep me"), .newlines(2)])
}

@Test func trivia_adds_only_missing_separator_before_comment_block() {
    let original = Trivia(pieces: [
        .newlines(2),
        .lineComment("// first"),
        .newlines(2),
    ])

    let tidied = swift_syntax_learn().tidy(original, isFirst: false)

    #expect(tidied.pieces == [.newlines(1), .lineComment("// first"), .newlines(2)])
}
