import * as functions from 'firebase-functions';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';

const execAsync = promisify(exec);

interface TestRunRequest {
  testPath: string;
  timeout?: number;
  showDetailedLogs?: boolean;
}

interface TestRunResult {
  passed: number;
  failed: number;
  skipped: number;
  duration: number;
  logs: string;
  error?: string;
}

/**
 * Cloud function to run Flutter unit tests
 * Only accessible to users with super_admin role
 */
export const runUnitTest = functions.https.onCall(async (data: TestRunRequest, context) => {
  // Verify super_admin role
  if (context.auth?.token?.role !== 'super_admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Super admin access required to run tests'
    );
  }

  const { testPath, timeout = 60000, showDetailedLogs = true } = data;

  // Validate test path
  if (!testPath || typeof testPath !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Test path is required'
    );
  }

  // Security: Ensure test path is within allowed directories
  const allowedTestPaths = [
    'test/features/mentee_registration/',
    'test/unit/',
    'test/widget/',
    'test/integration/'
  ];

  const isAllowedPath = allowedTestPaths.some(allowed => testPath.startsWith(allowed));
  if (!isAllowedPath) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Test path must be within allowed test directories'
    );
  }

  try {
    const result = await executeFlutterTest(testPath, timeout, showDetailedLogs);
    return result;
  } catch (error: any) {
    console.error('Test execution failed:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to execute tests',
      error.message
    );
  }
});

/**
 * Execute Flutter test command and parse results
 */
async function executeFlutterTest(
  testPath: string,
  timeout: number,
  showDetailedLogs: boolean
): Promise<TestRunResult> {
  const startTime = Date.now();
  
  // Build flutter test command
  const command = `flutter test ${testPath} --reporter json${showDetailedLogs ? ' -v' : ''}`;
  
  try {
    const { stdout, stderr } = await execAsync(command, {
      timeout,
      cwd: path.resolve(__dirname, '../../..'), // Navigate to project root (from functions/src/testing to project root)
    });

    const duration = Date.now() - startTime;
    
    // Parse test results from JSON output
    const result = parseTestOutput(stdout, stderr);
    
    return {
      ...result,
      duration,
      logs: showDetailedLogs ? formatLogs(stdout, stderr) : result.logs,
    };
  } catch (error: any) {
    const duration = Date.now() - startTime;
    
    // Handle timeout
    if (error.code === 'ETIMEDOUT') {
      return {
        passed: 0,
        failed: 0,
        skipped: 0,
        duration,
        logs: `Test execution timed out after ${timeout}ms`,
        error: 'timeout',
      };
    }

    // Parse failed test output
    const result = parseTestOutput(error.stdout || '', error.stderr || '');
    
    return {
      ...result,
      duration,
      logs: formatLogs(error.stdout || '', error.stderr || ''),
      error: error.message,
    };
  }
}

/**
 * Parse test output to extract pass/fail counts
 */
function parseTestOutput(stdout: string, stderr: string): Omit<TestRunResult, 'duration'> {
  let passed = 0;
  let failed = 0;
  let skipped = 0;
  const logs: string[] = [];

  // Parse JSON reporter output
  const lines = stdout.split('\n');
  for (const line of lines) {
    if (line.trim().startsWith('{')) {
      try {
        const event = JSON.parse(line);
        
        if (event.type === 'testDone') {
          if (event.result === 'success') {
            passed++;
          } else if (event.result === 'failure' || event.result === 'error') {
            failed++;
            if (event.error) {
              logs.push(`FAILED: ${event.name}`);
              logs.push(`  ${event.error}`);
            }
          } else if (event.skipped) {
            skipped++;
          }
        } else if (event.type === 'print' && event.message) {
          logs.push(event.message);
        }
      } catch (e) {
        // Not JSON, skip
      }
    }
  }

  // Fallback: Parse standard output if no JSON results found
  if (passed === 0 && failed === 0) {
    const summaryMatch = stdout.match(/(\d+) tests? passed/);
    const failMatch = stdout.match(/(\d+) tests? failed/);
    
    if (summaryMatch) {
      passed = parseInt(summaryMatch[1], 10);
    }
    if (failMatch) {
      failed = parseInt(failMatch[1], 10);
    }
  }

  // Include stderr in logs if present
  if (stderr) {
    logs.push('--- STDERR ---');
    logs.push(stderr);
  }

  return {
    passed,
    failed,
    skipped,
    logs: logs.join('\n'),
  };
}

/**
 * Format logs for display
 */
function formatLogs(stdout: string, stderr: string): string {
  const logs: string[] = [];
  
  // Add timestamp
  logs.push(`Test run started at: ${new Date().toISOString()}`);
  logs.push('='.repeat(50));
  
  // Add stdout
  if (stdout) {
    logs.push('STDOUT:');
    logs.push(stdout);
  }
  
  // Add stderr if present
  if (stderr) {
    logs.push('\n--- STDERR ---');
    logs.push(stderr);
  }
  
  return logs.join('\n');
}

/**
 * Run all tests in a test suite
 */
export const runTestSuite = functions.https.onCall(async (data: { suite: string }, context) => {
  // Verify super_admin role
  if (context.auth?.token?.role !== 'super_admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Super admin access required'
    );
  }

  const testSuites: Record<string, string[]> = {
    'mentee_registration': [
      'test/features/mentee_registration/unit/services/auth_service_test.dart',
      'test/features/mentee_registration/unit/controllers/acknowledgment_controller_test.dart',
      'test/features/mentee_registration/widget/auth_wrapper_test.dart',
      'test/features/mentee_registration/widget/acknowledgment_screen_test.dart',
    ],
    'all': [
      'test/',
    ],
  };

  const suite = testSuites[data.suite];
  if (!suite) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Unknown test suite: ${data.suite}`
    );
  }

  const results: Record<string, TestRunResult> = {};
  
  for (const testPath of suite) {
    try {
      results[testPath] = await executeFlutterTest(testPath, 120000, true);
    } catch (error: any) {
      results[testPath] = {
        passed: 0,
        failed: 1,
        skipped: 0,
        duration: 0,
        logs: `Failed to run test: ${error.message}`,
        error: error.message,
      };
    }
  }

  return results;
});