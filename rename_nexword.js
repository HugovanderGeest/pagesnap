const fs = require('fs');
const path = require('path');

function replaceInFile(filePath) {
  if (!fs.existsSync(filePath)) {
    console.log('Not found: ' + filePath);
    return;
  }
  let content = fs.readFileSync(filePath, 'utf8');
  const initial = content;
  content = content.replace(/NexWord/g, 'Peruse');
  content = content.replace(/Nexword/g, 'Peruse');
  content = content.replace(/nexword/g, 'peruse');
  content = content.replace(/NEXWORD/g, 'PERUSE');
  if (initial !== content) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Updated ' + filePath);
  } else {
    console.log('No changes needed in ' + filePath);
  }
}

const files = [
  'src/app/page.tsx',
  'src/app/layout.tsx',
  'pagesnap_flutter/web/manifest.json',
  'pagesnap_flutter/web/index.html',
  'pagesnap_flutter/macos/Runner/Configs/AppInfo.xcconfig',
  'pagesnap_flutter/ios/Runner/Info.plist',
  'pagesnap_flutter/android/app/src/main/AndroidManifest.xml',
  'pagesnap_flutter/lib/main.dart',
  'pagesnap_flutter/lib/screens/auth_screen.dart'
];

files.forEach(f => replaceInFile(path.join(__dirname, f)));
