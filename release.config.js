const GITHUB_REPOSITORY = process.env.GITHUB_REPOSITORY
const NAME = GITHUB_REPOSITORY.match('(?:escapace/)(.+)')[1]

module.exports = {
  branches: ['trunk'],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    [
      '@semantic-release/exec',
      {
        shell: true,
        publishCmd: [
          'packer build -machine-readable -var "version=${nextRelease.version}" workstation.json'
        ]
          .map((string) =>
            string
              .replace(/GITHUB_REPOSITORY/g, GITHUB_REPOSITORY)
              .replace(/NAME/g, NAME)
          )
          .join(' && \\\n')
      }
    ]
  ]
}
