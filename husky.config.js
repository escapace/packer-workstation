module.exports = {
  hooks: {
    'commit-msg': 'commitlint -E HUSKY_GIT_PARAMS',
    'pre-commit': 'ls-lint &&  packer validate -syntax-only workstation.json'
  }
}
