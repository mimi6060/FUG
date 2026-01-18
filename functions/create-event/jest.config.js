/**
 * Jest Configuration for create-event function
 */
export default {
  testEnvironment: 'node',
  transform: {},
  testMatch: ['**/test/**/*.test.js'],
  moduleFileExtensions: ['js', 'json'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.d.js'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  verbose: true,
  testTimeout: 10000,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1'
  }
};
