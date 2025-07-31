module.exports = {
  transform: {
    '^.+\\.(js|jsx)$': 'babel-jest'
  },
  moduleNameMapper: {
    '\\.(svg)$': '<rootDir>/__mocks__/fileMock.js'
  }
};