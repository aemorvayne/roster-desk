export default [{
  files: ['public/app.js'],
  languageOptions: { ecmaVersion: 'latest', sourceType: 'module' },
  rules: {
    'no-undef': 'error',
    'no-unused-vars': 'error',
    'eqeqeq': 'error',
    'max-lines-per-function': ['error', { max: 7, skipBlankLines: false, skipComments: false }]
  }
}];
