/**
 * FUG Migrations - Colored Logger
 *
 * Provides beautiful, colored console output for migration operations.
 */

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',

  // Text colors
  black: '\x1b[30m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',

  // Background colors
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
  bgMagenta: '\x1b[45m',
  bgCyan: '\x1b[46m',
};

// Symbols for better UX
const symbols = {
  success: '\u2714', // ✔
  error: '\u2718',   // ✘
  warning: '\u26A0', // ⚠
  info: '\u2139',    // ℹ
  arrow: '\u2192',   // →
  bullet: '\u2022',  // •
  pending: '\u25CB', // ○
  done: '\u25CF',    // ●
};

/**
 * Format a timestamp
 */
function timestamp() {
  return new Date().toISOString().replace('T', ' ').substring(0, 19);
}

/**
 * Create a logger instance
 */
export function createLogger(options = {}) {
  const { silent = false, verbose = false } = options;

  const log = (message) => {
    if (!silent) {
      console.log(message);
    }
  };

  return {
    /**
     * Log an info message (blue)
     */
    info(message) {
      log(`${colors.blue}${symbols.info}${colors.reset} ${message}`);
    },

    /**
     * Log a success message (green)
     */
    success(message) {
      log(`${colors.green}${symbols.success}${colors.reset} ${message}`);
    },

    /**
     * Log an error message (red)
     */
    error(message) {
      log(`${colors.red}${symbols.error}${colors.reset} ${colors.red}${message}${colors.reset}`);
    },

    /**
     * Log a warning message (yellow)
     */
    warn(message) {
      log(`${colors.yellow}${symbols.warning}${colors.reset} ${colors.yellow}${message}${colors.reset}`);
    },

    /**
     * Log a debug message (dim, only in verbose mode)
     */
    debug(message) {
      if (verbose) {
        log(`${colors.dim}  [debug] ${message}${colors.reset}`);
      }
    },

    /**
     * Log a step in a process
     */
    step(message) {
      log(`${colors.cyan}${symbols.arrow}${colors.reset} ${message}`);
    },

    /**
     * Log a migration being applied
     */
    migration(name, direction = 'up') {
      const arrow = direction === 'up' ? '\u2191' : '\u2193'; // ↑ or ↓
      const color = direction === 'up' ? colors.green : colors.yellow;
      log(`${color}${arrow}${colors.reset} ${colors.bold}${name}${colors.reset}`);
    },

    /**
     * Print a header/title
     */
    header(title) {
      const line = '─'.repeat(50);
      log('');
      log(`${colors.cyan}${line}${colors.reset}`);
      log(`${colors.cyan}${colors.bold}  ${title}${colors.reset}`);
      log(`${colors.cyan}${line}${colors.reset}`);
      log('');
    },

    /**
     * Print a section divider
     */
    divider() {
      log(`${colors.dim}${'─'.repeat(50)}${colors.reset}`);
    },

    /**
     * Print environment info
     */
    environment(env, endpoint, projectId) {
      log(`${colors.dim}Environment:${colors.reset} ${colors.bold}${env}${colors.reset}`);
      log(`${colors.dim}Endpoint:${colors.reset}    ${endpoint}`);
      log(`${colors.dim}Project:${colors.reset}     ${projectId}`);
      log('');
    },

    /**
     * Print a status table for migrations
     */
    statusTable(migrations) {
      if (migrations.length === 0) {
        this.info('No migrations found.');
        return;
      }

      log('');
      log(`${colors.bold}  Status    │ Migration${colors.reset}`);
      log(`${colors.dim}────────────┼${'─'.repeat(40)}${colors.reset}`);

      for (const m of migrations) {
        const status = m.applied
          ? `${colors.green}${symbols.done} Applied${colors.reset}`
          : `${colors.yellow}${symbols.pending} Pending${colors.reset}`;
        const batch = m.batch ? ` ${colors.dim}(batch ${m.batch})${colors.reset}` : '';
        log(`  ${status}  │ ${m.name}${batch}`);
      }
      log('');
    },

    /**
     * Print a summary after migration
     */
    summary(applied, failed, skipped) {
      log('');
      this.divider();
      log(`${colors.bold}Summary:${colors.reset}`);
      if (applied > 0) {
        log(`  ${colors.green}${symbols.success} ${applied} migration(s) applied${colors.reset}`);
      }
      if (failed > 0) {
        log(`  ${colors.red}${symbols.error} ${failed} migration(s) failed${colors.reset}`);
      }
      if (skipped > 0) {
        log(`  ${colors.yellow}${symbols.warning} ${skipped} migration(s) skipped${colors.reset}`);
      }
      if (applied === 0 && failed === 0 && skipped === 0) {
        log(`  ${colors.dim}Nothing to migrate${colors.reset}`);
      }
      log('');
    },

    /**
     * Print a confirmation prompt (returns the question)
     */
    confirmPrompt(message) {
      return `${colors.yellow}${symbols.warning}${colors.reset} ${colors.bold}${message}${colors.reset} ${colors.dim}(y/N)${colors.reset} `;
    },

    /**
     * Print elapsed time
     */
    elapsed(ms) {
      const seconds = (ms / 1000).toFixed(2);
      log(`${colors.dim}Completed in ${seconds}s${colors.reset}`);
    },

    /**
     * Print a dry-run notice
     */
    dryRun() {
      log(`${colors.bgYellow}${colors.black} DRY RUN ${colors.reset} ${colors.yellow}No changes will be made${colors.reset}`);
      log('');
    },

    /**
     * Print a locked notice
     */
    locked() {
      log(`${colors.bgRed}${colors.white} LOCKED ${colors.reset} ${colors.red}Another migration is in progress${colors.reset}`);
    },

    /**
     * Raw log without formatting
     */
    raw(message) {
      log(message);
    },

    /**
     * Blank line
     */
    blank() {
      log('');
    },
  };
}

// Default logger instance
export const logger = createLogger();

export default logger;
