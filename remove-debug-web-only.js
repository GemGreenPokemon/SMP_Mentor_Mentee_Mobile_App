#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const glob = require('glob');

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run') || args.includes('-d');
const isVerbose = args.includes('--verbose') || args.includes('-v');
const showHelp = args.includes('--help') || args.includes('-h');

if (showHelp) {
  console.log(`
Web-Only Debug Code Removal Script
==================================

This script removes debug code ONLY from web-related files,
preserving all mobile debug code for development.

Usage: node remove-debug-web-only.js [options]

Options:
  -d, --dry-run    Show what would be removed without making changes
  -v, --verbose    Show detailed information about removals
  -h, --help       Show this help message

Example:
  node remove-debug-web-only.js --dry-run    # Preview changes
  node remove-debug-web-only.js              # Remove debug code from web files
`);
  process.exit(0);
}

// Configuration
const config = {
  // Only process web-related Dart files
  includePaths: [
    'lib/screens/web/**/*.dart',
    'lib/services/**/*.dart',           // Services are used by both
    'lib/models/**/*.dart',             // Models are shared
    'lib/utils/**/*.dart',              // Utils are shared
    'lib/widgets/**/*.dart',            // Some widgets might be shared
    'lib/main.dart',                    // Main entry point
    'lib/firebase_options.dart'         // Firebase config
  ],
  
  // Exclude mobile-specific files and debug utilities
  excludePaths: [
    'functions/**/*',
    'node_modules/**/*',
    '.dart_tool/**/*',
    'build/**/*',
    '.git/**/*',
    'lib/screens/mobile/**/*',          // Exclude ALL mobile screens
    'lib/utils/messaging_debug.dart',
    'lib/utils/test_mode_manager.dart',
    'lib/debug_availability_widget.dart',
    'lib/test_availability_setup.dart',
    'lib/widgets/auth_wrapper.dart'     // Often has important debug for auth flow
  ],
  
  // Conservative patterns - only remove obvious debug code
  debugPatterns: [
    {
      name: 'kDebugMode conditional blocks',
      pattern: /if\s*\(\s*kDebugMode\s*\)\s*\{\s*\n([^\}]|\n)*?\s*print\([^)]*\);\s*\n([^\}]|\n)*?\}/gm,
      replacement: '',
      description: 'Remove if(kDebugMode) blocks containing print statements'
    },
    {
      name: 'Single line debug prints',
      pattern: /^\s*if\s*\(\s*kDebugMode\s*\)\s*print\([^)]*\);\s*$/gm,
      replacement: '',
      description: 'Remove single line if(kDebugMode) print statements'
    },
    {
      name: 'Debug print statements with emojis',
      pattern: /^\s*print\(['"][🔍🔧🔥🔐📧🔑✅❌⚠️💾📊🔄🎯📍🔔🚀💡📝🔨🛠️⚡🎨🌟💬📌🔗📈📉🏷️🔖🎭🎪🎬🎮🎯🎲].*?['"]\);\s*$/gm,
      replacement: '',
      description: 'Remove print statements with emoji prefixes'
    },
    {
      name: 'Debug print statements with prefixes',
      pattern: /^\s*print\(['"](=== |>>> |<<< |\[DEBUG\]|\[INFO\]|\[WARN\]|\[ERROR\]|\[WEB\]).*?['"]\);\s*$/gm,
      replacement: '',
      description: 'Remove print statements with debug prefixes'
    },
    {
      name: 'Web-specific debug logs',
      pattern: /^\s*print\(['"].*?(Dashboard|dashboard|WEB|Web|web_|WebMentor|WebMentee|WebCoordinator).*?['"]\);\s*$/gm,
      replacement: '',
      description: 'Remove web-specific debug prints'
    }
  ],
  
  // Create backup
  createBackup: !isDryRun,
  backupDir: `web-debug-backup-${new Date().toISOString().slice(0,10).replace(/-/g,'')}`
};

// Statistics
let stats = {
  filesProcessed: 0,
  filesModified: 0,
  webFilesProcessed: 0,
  mobileFilesSkipped: 0,
  totalRemovals: {},
  fileDetails: []
};

// Initialize removal counts
config.debugPatterns.forEach(pattern => {
  stats.totalRemovals[pattern.name] = 0;
});

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
  if (!backupDir || isDryRun) return;
  
  const relativePath = path.relative(process.cwd(), filePath);
  const backupPath = path.join(backupDir, relativePath);
  const backupFileDir = path.dirname(backupPath);
  
  if (!fs.existsSync(backupFileDir)) {
    fs.mkdirSync(backupFileDir, { recursive: true });
  }
  
  fs.copyFileSync(filePath, backupPath);
}

// Check if file is web-related
function isWebFile(filePath) {
  // Check if it's in web screens
  if (filePath.includes('lib/screens/web/')) {
    stats.webFilesProcessed++;
    return true;
  }
  
  // Check if it's a mobile screen (skip these)
  if (filePath.includes('lib/screens/mobile/')) {
    stats.mobileFilesSkipped++;
    return false;
  }
  
  // For other files (services, models, etc.), include them
  return true;
}

// Process single file
function processFile(filePath, backupDir) {
  try {
    // Skip mobile files
    if (!isWebFile(filePath)) {
      if (isVerbose) {
        console.log(`⏭️  Skipping mobile file: ${filePath}`);
      }
      return;
    }
    
    // Read file content
    let content = fs.readFileSync(filePath, 'utf8');
    const originalContent = content;
    let fileModifications = {};
    let totalModifications = 0;
    
    // Apply debug patterns
    config.debugPatterns.forEach(({ name, pattern, replacement }) => {
      const matches = content.match(pattern);
      if (matches) {
        fileModifications[name] = matches.length;
        totalModifications += matches.length;
        stats.totalRemovals[name] += matches.length;
        
        if (isVerbose && matches.length > 0) {
          console.log(`\n📍 In ${filePath}:`);
          console.log(`   Found ${matches.length} instances of "${name}"`);
          if (isDryRun) {
            matches.slice(0, 3).forEach(match => {
              console.log(`   Example: ${match.trim()}`);
            });
            if (matches.length > 3) {
              console.log(`   ... and ${matches.length - 3} more`);
            }
          }
        }
        
        if (!isDryRun) {
          content = content.replace(pattern, replacement);
        }
      }
    });
    
    // Clean up multiple empty lines (only if modifications were made)
    if (totalModifications > 0 && !isDryRun) {
      content = content.replace(/\n\s*\n\s*\n/g, '\n\n');
    }
    
    // If file was modified
    if (totalModifications > 0) {
      if (!isDryRun) {
        // Backup original file
        backupFile(filePath, backupDir);
        
        // Write modified content
        fs.writeFileSync(filePath, content, 'utf8');
      }
      
      stats.filesModified++;
      stats.fileDetails.push({
        file: filePath,
        modifications: fileModifications,
        total: totalModifications
      });
      
      if (!isVerbose) {
        console.log(`${isDryRun ? '🔍' : '✏️'}  ${isDryRun ? 'Would modify' : 'Modified'} ${filePath} (${totalModifications} removals)`);
      }
    }
    
    stats.filesProcessed++;
    
  } catch (error) {
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
  
  // Remove excluded files
  config.excludePaths.forEach(pattern => {
    glob.sync(pattern, { nodir: true }).forEach(file => {
      files.delete(file);
    });
  });
  
  return Array.from(files);
}

// Main function
function main() {
  console.log('🌐 Web-Only Debug Code Removal Script');
  console.log('=====================================\n');
  
  if (isDryRun) {
    console.log('🚨 DRY RUN MODE - No files will be modified\n');
  }
  
  console.log('📱 Mobile debug code will be PRESERVED');
  console.log('🌐 Only web-related debug code will be removed\n');
  
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
  console.log(`📁 Found ${files.length} files to scan\n`);
  
  // Process each file
  files.forEach(file => processFile(file, backupDir));
  
  // Print summary
  console.log('\n📊 Summary');
  console.log('==========');
  console.log(`Total files scanned: ${stats.filesProcessed}`);
  console.log(`Web files processed: ${stats.webFilesProcessed}`);
  console.log(`Mobile files skipped: ${stats.mobileFilesSkipped}`);
  console.log(`Files ${isDryRun ? 'to be modified' : 'modified'}: ${stats.filesModified}`);
  
  console.log('\nRemovals by type:');
  Object.entries(stats.totalRemovals).forEach(([name, count]) => {
    if (count > 0) {
      console.log(`  ${name}: ${count}`);
    }
  });
  
  // Show top modified files
  if (stats.fileDetails.length > 0 && !isVerbose) {
    console.log('\nTop modified files:');
    stats.fileDetails
      .sort((a, b) => b.total - a.total)
      .slice(0, 5)
      .forEach(({ file, total }) => {
        console.log(`  ${path.relative(process.cwd(), file)}: ${total} removals`);
      });
  }
  
  if (!isDryRun && config.createBackup) {
    console.log(`\n💾 Backup created at: ${config.backupDir}/`);
    console.log('   To restore: cp -r ' + config.backupDir + '/* .');
  }
  
  if (isDryRun && stats.filesModified > 0) {
    console.log('\n💡 To apply these changes, run without --dry-run:');
    console.log('   node remove-debug-web-only.js');
  }
  
  console.log('\n✅ ' + (isDryRun ? 'Dry run' : 'Web debug removal') + ' complete!');
  console.log('📱 Mobile debug code remains intact for development.');
}

// Run the script
if (require.main === module) {
  main();
}