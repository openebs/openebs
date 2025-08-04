export default {
    rules: {
        'type-enum': [2, 'always', ['build', 'chore', 'ci', 'docs', 'feat', 'fix', 'perf', 'refactor', 'revert', 'style', 'test', 'example']],
        'code-review-rule': [2, 'always'],
        "body-max-line-length": [2, "always", 100],
        "footer-leading-blank": [1, "always"],
        "footer-max-line-length": [1, "always", 100],
        "header-max-length": [1, "always", 100],
        "header-trim": [1, "always"],
        "subject-case": [1, "never", ["sentence-case", "start-case", "pascal-case", "upper-case"]],
        'subject-empty': [2, 'never'],
        'subject-full-stop': [2, 'never', '.'],
        'subject-max-length': [2, 'always', 80],
        'subject-min-length': [2, 'always', 5],
        'scope-case': [2, 'always', 'lower-case'],
        'body-leading-blank': [2, 'always'],
    },
    defaultIgnores: false,
    ignores: [
        (message) => message.startsWith('chore(bors): merge pull request #'),
        (message) => message.startsWith('Merge pull request #'),
        (message) => message.startsWith('Merge #')
    ],
    plugins: [
        {
            rules: {
                'code-review-rule': ({subject}) => {
                    const REVIEW_COMMENTS = `Please don't merge code-review commits, instead squash them in the parent commit`;
                    if (subject.includes('code-review')) return [false, REVIEW_COMMENTS];
                    if (subject.includes('review comment')) return [false, REVIEW_COMMENTS];
                    if (subject.includes('address comment')) return [false, REVIEW_COMMENTS];
                    if (subject.includes('addressed comment')) return [false, REVIEW_COMMENTS];
                    return [true];
                },
            },
        },
    ],
}
