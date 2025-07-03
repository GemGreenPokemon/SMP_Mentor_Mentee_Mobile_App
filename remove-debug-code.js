#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const glob = require('glob');

// Configuration
const config = {
  // Directories to process
  includePaths: [
    'lib/**/*.dart',
    'test/**/*.dart',
    'integration_test/**/*.dart',
    'web/**/*.{js,html}',
    'android/**/*.{java,kt}',
    'ios/**/*.{swift,m}'
  ],
  
  // Directories to exclude
  excludePaths: [
    'functions/**/*',
    'node_modules/**/*',
    '.dart_tool/**/*',
    'build/**/*',
    '.git/**/*'
  ],
  
  // Patterns to remove
  debugPatterns: [
    // Dart debug patterns
    {
      // Remove if (kDebugMode) blocks
      pattern: /if\s*\(\s*kDebugMode\s*\)\s*\{[\s\S]*?\n\s*\}/g,
      replacement: ''
    },
    {
      // Remove single line if (kDebugMode) statements
      pattern: /if\s*\(\s*kDebugMode\s*\)\s+[^{].*?;/g,
      replacement: ''
    },
    {
      // Remove print statements
      pattern: /^\s*print\([^)]*\);?\s*$/gm,
      replacement: ''
    },
    {
      // Remove debugPrint statements
      pattern: /^\s*debugPrint\([^)]*\);?\s*$/gm,
      replacement: ''
    },
    {
      // Remove developer.log statements
      pattern: /^\s*(?:developer\.)?log\([^)]*\);?\s*$/gm,
      replacement: ''
    },
    {
      // Remove debug comments
      pattern: /\/\/\s*(?:DEBUG|TODO|FIXME|HACK|XXX|debug|Debug).*$/gm,
      replacement: ''
    },
    {
      // Remove console.log for web files
      pattern: /^\s*console\.log\([^)]*\);?\s*$/gm,
      replacement: ''
    },
    {
      // Remove console.debug/warn/error
      pattern: /^\s*console\.(debug|warn|error|info)\([^)]*\);?\s*$/gm,
      replacement: ''
    },
    {
      // Remove Flutter inspector statements
      pattern: /^\s*(?:flutter\.)?inspector\.\w+\([^)]*\);?\s*$/gm,
      replacement: ''
    },
    {
      // Remove assert statements (optional - uncomment if desired)
      // pattern: /^\s*assert\([^)]*\);?\s*$/gm,
      // replacement: ''
    }
  ],
  
  // Files to completely skip
  skipFiles: [
    'remove-debug-code.js',
    'debug_availability_widget.dart',
    'messaging_debug.dart',
    'test_mode_manager.dart'
  ],
  
  // Backup configuration
  createBackup: true,
  backupDir: 'debug-code-backup'
};

// Statistics
let stats = {
  filesProcessed: 0,
  filesModified: 0,
  patternsRemoved: 0,
  errors: []
};

// Create backup directory
function createBackupDirectory() {
  if (config.createBackup) {
    const backupPath = path.join(process.cwd(), config.backupDir);
    if (!fs.existsSync(backupPath)) {
      fs.mkdirSync(backupPath, { recursive: true });
      console.log(`✅ Created backup directory: ${backupPath}`);
    }
    return backupPath;
  }
  return null;
}

// Backup file
function backupFile(filePath, backupDir) {
  if (!backupDir) return;
  
  const relativePath = path.relative(process.cwd(), filePath);
  const backupPath = path.join(backupDir, relativePath);
  const backupFileDir = path.dirname(backupPath);
  
  // Create directory structure in backup
  if (!fs.existsSync(backupFileDir)) {
    fs.mkdirSync(backupFileDir, { recursive: true });
  }
  
  // Copy file to backup
  fs.copyFileSync(filePath, backupPath);
}

// Process single file
function processFile(filePath, backupDir) {
  try {
    // Check if file should be skipped
    const fileName = path.basename(filePath);
    if (config.skipFiles.includes(fileName)) {
      console.log(`⏭️  Skipping ${filePath}`);
      return;
    }
    
    // Read file content
    let content = fs.readFileSync(filePath, 'utf8');
    const originalContent = content;
    let modifications = 0;
    
    // Apply all debug patterns
    config.debugPatterns.forEach(({ pattern, replacement }) => {
      const matches = content.match(pattern);
      if (matches) {
        modifications += matches.length;
        content = content.replace(pattern, replacement);
      }
    });
    
    // Clean up multiple empty lines
    content = content.replace(/\n\s*\n\s*\n/g, '\n\n');
    
    // If file was modified, save it
    if (content !== originalContent) {
      // Backup original file
      backupFile(filePath, backupDir);
      
      // Write modified content
      fs.writeFileSync(filePath, content, 'utf8');
      
      stats.filesModified++;
      stats.patternsRemoved += modifications;
      
      console.log(`✏️  Modified ${filePath} (${modifications} patterns removed)`);
    }
    
    stats.filesProcessed++;
    
  } catch (error) {
    stats.errors.push({ file: filePath, error: error.message });
    console.error(`❌ Error processing ${filePath}: ${error.message}`);
  }
}

// Get all files to process
function getFilesToProcess() {
  const files = new Set();
  
  // Add files from include paths
  config.includePaths.forEach(pattern => {
    glob.sync(pattern, { nodir: true }).forEach(file => {
      files.add(file);
    });
  });
  
  // Remove files from exclude paths
  config.excludePaths.forEach(pattern => {
    glob.sync(pattern, { nodir: true }).forEach(file => {
      files.delete(file);
    });
  });
  
  return Array.from(files);
}

// Main function
function main() {
  console.log('🔍 Debug Code Removal Script');
  console.log('============================\n');
  
  // Check if glob is installed
  try {
    require('glob');
  } catch (e) {
    console.error('❌ Error: glob package not found.');
    console.log('Please install it by running: npm install glob');
    process.exit(1);
  }
  
  // Create backup directory
  const backupDir = createBackupDirectory();
  
  // Get files to process
  const files = getFilesToProcess();
  console.log(`📁 Found ${files.length} files to process\n`);
  
  // Process each file
  files.forEach(file => processFile(file, backupDir));
  
  // Print summary
  console.log('\n📊 Summary');
  console.log('==========');
  console.log(`Files processed: ${stats.filesProcessed}`);
  console.log(`Files modified: ${stats.filesModified}`);
  console.log(`Debug patterns removed: ${stats.patternsRemoved}`);
  
  if (stats.errors.length > 0) {
    console.log(`\n❌ Errors: ${stats.errors.length}`);
    stats.errors.forEach(({ file, error }) => {
      console.log(`  - ${file}: ${error}`);
    });
  }
  
  if (config.createBackup) {
    console.log(`\n💾 Backup created at: ${config.backupDir}`);
    console.log('   To restore: cp -r debug-code-backup/* .');
  }
  
  console.log('\n✅ Debug code removal complete!');
}

// Run the script
if (require.main === module) {
  main();
}

module.exports = { processFile, getFilesToProcess };