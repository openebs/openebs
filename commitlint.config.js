module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['oep', 'build', 'chore', 'ci', 'docs', 'feat', 'fix', 'perf', 'refactor', 'revert', 'style', 'test', 'example', 'security']],
    'code-review-rule': [0, 'always'],
  },
  defaultIgnores: false,
  ignores: [
      (message) => message.startsWith('chore(bors): merge pull request #'),
      (message) => message.startsWith('Merge #')
  ],
  plugins: [
    {
      rules: {
        'code-review-rule': ({subject}) => {
          const REVIEW_COMMENTS = `Please don't merge code-review commits, instead squash them in the parent commit`;
          if (subject.includes('code-review')) return [ false, REVIEW_COMMENTS ];
          if (subject.includes('review comment')) return [ false, REVIEW_COMMENTS ];
          if (subject.includes('address comment')) return [ false, REVIEW_COMMENTS ];
          if (subject.includes('addressed comment')) return [ false, REVIEW_COMMENTS ];
          return [ true ];
        },
      },
    },
  ],
}
