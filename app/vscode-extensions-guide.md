# 🔌 VSCode Extensions Guide - Productivity Boosters

## 1. ✨ Error Lens - Highlight Error Inline
**ID:** `usernamehw.errorlens`

### 📌 Fungsi Utama
Menampilkan error, warning, dan info **langsung di samping baris kode** tanpa perlu hover atau scroll ke panel Problems.

### 🎯 Kegunaan
- ✅ **Instant Feedback** - Lihat error tanpa hover
- ✅ **Inline Messages** - Pesan error muncul di ujung baris
- ✅ **Color Coding** - Merah (error), Kuning (warning), Biru (info)
- ✅ **Diagnostic Count** - Lihat jumlah error di status bar

### 📸 Visual Comparison

**SEBELUM (Tanpa Error Lens):**
```dart
void calculateTotal(int price) {
  int total = price * quantity; // Error tersembunyi, harus hover
}
```

**SESUDAH (Dengan Error Lens):**
```dart
void calculateTotal(int price) {
  int total = price * quantity; // ❌ Undefined name 'quantity'. Try correcting the name to one that is defined
}
```

### ⚙️ Cara Penggunaan

#### Install
```bash
code --install-extension usernamehw.errorlens
```

#### Konfigurasi (settings.json)
```json
{
  // Enable/disable Error Lens
  "errorLens.enabled": true,
  
  // Show inline error messages
  "errorLens.messageEnabled": true,
  
  // Highlight entire line
  "errorLens.gutterIconsEnabled": true,
  
  // Customize colors
  "errorLens.errorBackground": "rgba(255,0,0,0.1)",
  "errorLens.warningBackground": "rgba(255,255,0,0.1)",
  
  // Font styling
  "errorLens.fontStyle": "italic",
  "errorLens.fontSize": "0.9em",
  
  // Delay before showing (ms)
  "errorLens.delay": 0,
  
  // Exclude specific languages
  "errorLens.excludeBySource": ["cSpell"]
}
```

### 🎨 Customization Commands
- `Ctrl+Shift+P` → `Error Lens: Toggle Error`
- `Ctrl+Shift+P` → `Error Lens: Toggle Warning`
- `Ctrl+Shift+P` → `Error Lens: Toggle Info`

### 💡 Tips
```dart
// Example 1: Dart/Flutter
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(undefinedVar), // ❌ Error Lens shows: Undefined name 'undefinedVar'
    );
  }
}

// Example 2: PHP
function getUserData($id) {
  return $data; // ❌ Error Lens shows: Undefined variable: data
}
```

---

## 2. ✨ TODO Highlight - Highlight TODO/FIXME
**ID:** `wayou.vscode-todo-highlight`

### 📌 Fungsi Utama
Memberi **highlight warna** pada keyword khusus seperti TODO, FIXME, NOTE dalam komentar kode.

### 🎯 Kegunaan
- ✅ **Visual Reminder** - Todo terlihat jelas dengan warna
- ✅ **Quick Navigation** - Jump ke todo list
- ✅ **Custom Keywords** - Tambah keyword sendiri
- ✅ **Multi-Language** - Support semua bahasa

### 📸 Visual Example

```dart
// TODO: Implement delivery validation
// FIXME: Bug pada calculation
// NOTE: Perlu review dengan team
// HACK: Temporary solution
// XXX: Harus diperbaiki segera

void processDelivery() {
  // TODO: Add error handling
  calculateTotal();
  
  // FIXME: Memory leak di sini
  fetchData();
}
```

**Hasil Visual:**
- `TODO:` → Background kuning terang
- `FIXME:` → Background merah
- `NOTE:` → Background hijau
- `HACK:` → Background oranye

### ⚙️ Cara Penggunaan

#### Install
```bash
code --install-extension wayou.vscode-todo-highlight
```

#### Konfigurasi (settings.json)
```json
{
  "todohighlight.isEnable": true,
  
  // Default keywords dengan styling
  "todohighlight.keywords": [
    {
      "text": "TODO:",
      "color": "#000",
      "backgroundColor": "#ffeb3b",
      "overviewRulerColor": "#ffeb3b"
    },
    {
      "text": "FIXME:",
      "color": "#fff",
      "backgroundColor": "#f44336",
      "overviewRulerColor": "#f44336"
    },
    {
      "text": "NOTE:",
      "color": "#fff",
      "backgroundColor": "#4caf50"
    },
    {
      "text": "HACK:",
      "color": "#000",
      "backgroundColor": "#ff9800"
    },
    {
      "text": "XXX:",
      "color": "#fff",
      "backgroundColor": "#9c27b0"
    }
  ],
  
  // Include files
  "todohighlight.include": [
    "**/*.dart",
    "**/*.php",
    "**/*.js",
    "**/*.ts"
  ],
  
  // Exclude files
  "todohighlight.exclude": [
    "**/node_modules/**",
    "**/build/**",
    "**/vendor/**"
  ]
}
```

### 🎨 Commands
- `Ctrl+Shift+P` → `List highlighted annotations`
- `Ctrl+Shift+P` → `Toggle highlights`

### 💡 Best Practices
```dart
// ✅ GOOD - Specific and actionable
// TODO: Add input validation for customer name field
// FIXME: Replace deprecated showSnackBar() with ScaffoldMessenger

// ❌ BAD - Too vague
// TODO: Fix this
// FIXME: Check later
```

---

## 3. ✨ Better Comments - Enhanced Comment Styling
**ID:** `aaron-bond.better-comments`

### 📌 Fungsi Utama
Memberi **warna berbeda** pada tipe komentar berbeda untuk readability lebih baik.

### 🎯 Kegunaan
- ✅ **Color-Coded Comments** - Warna berdasarkan prefix
- ✅ **Visual Hierarchy** - Penting vs biasa terlihat jelas
- ✅ **Better Documentation** - Komentar lebih terorganisir
- ✅ **Team Communication** - Standarisasi komentar

### 📸 Visual Example

```dart
// * Important information highlighted
// ! Warning or deprecated code
// ? Question or need clarification
// TODO: Task to be done
// // Commented out code (strikethrough)

class DeliveryService {
  // * Core function - DO NOT MODIFY without review
  void createDelivery() {
    // ! This method is deprecated, use createDeliveryV2()
    
    // ? Should we add validation here?
    
    // TODO: Implement error handling
    
    // // Old implementation
    // // return oldMethod();
    
    return newMethod();
  }
}
```

**Hasil Visual:**
- `// *` → **Hijau** (Important/Highlight)
- `// !` → **Merah** (Alert/Warning)
- `// ?` → **Biru** (Question)
- `// TODO:` → **Oranye** (Task)
- `// //` → **Abu-abu** dengan strikethrough

### ⚙️ Cara Penggunaan

#### Install
```bash
code --install-extension aaron-bond.better-comments
```

#### Konfigurasi (settings.json)
```json
{
  "better-comments.tags": [
    {
      "tag": "!",
      "color": "#FF2D00",
      "strikethrough": false,
      "underline": false,
      "backgroundColor": "transparent",
      "bold": false,
      "italic": false
    },
    {
      "tag": "?",
      "color": "#3498DB",
      "strikethrough": false,
      "underline": false,
      "backgroundColor": "transparent",
      "bold": false,
      "italic": false
    },
    {
      "tag": "//",
      "color": "#474747",
      "strikethrough": true,
      "underline": false,
      "backgroundColor": "transparent",
      "bold": false,
      "italic": false
    },
    {
      "tag": "todo",
      "color": "#FF8C00",
      "strikethrough": false,
      "underline": false,
      "backgroundColor": "transparent",
      "bold": false,
      "italic": false
    },
    {
      "tag": "*",
      "color": "#98C379",
      "strikethrough": false,
      "underline": false,
      "backgroundColor": "transparent",
      "bold": true,
      "italic": false
    }
  ],
  
  // Multi-line comments
  "better-comments.multilineComments": true,
  
  // Language-specific
  "better-comments.highlightPlainText": false
}
```

### 💡 Usage Examples

#### Flutter/Dart
```dart
class DeliveryForm extends StatefulWidget {
  // * IMPORTANT: This form handles user input validation
  
  // ! DEPRECATED: Use DeliveryFormV2 instead
  // ! Will be removed in version 3.0
  
  // ? TODO: Should we add auto-save feature?
  
  // Regular comment without prefix
  void submitForm() {
    // // Old validation logic
    // // if (oldValidation()) { ... }
    
    if (newValidation()) {
      // * Critical: Always call this after validation
      saveDelivery();
    }
  }
}
```

#### PHP
```php
<?php
// * Main delivery API endpoint
function createDelivery($data) {
    // ! Security: Always validate input
    if (!validateInput($data)) {
        return false;
    }
    
    // ? Should we log this action?
    
    // TODO: Add rate limiting
    
    // // Old implementation
    // // return insertOldWay($data);
    
    return insertNewWay($data);
}
?>
```

---

## 4. ✨ TODO Tree - TODO Management
**ID:** `gruntfuggly.todo-tree`

### 📌 Fungsi Utama
Menampilkan **semua TODO** dalam project dalam bentuk **tree view** di sidebar untuk navigasi mudah.

### 🎯 Kegunaan
- ✅ **Centralized View** - Semua TODO di satu tempat
- ✅ **File Navigation** - Click untuk jump ke kode
- ✅ **Filtering** - Filter by keyword, file, atau folder
- ✅ **Statistics** - Lihat total TODO per kategori
- ✅ **Export** - Export TODO list ke file

### 📸 Visual Example

**Sidebar TODO Tree View:**
```
📁 TODO TREE
  📁 lib/screens/delivery (3)
    ├── 📄 delivery_form.dart
    │   ├── ⚠️ TODO: Add validation (line 45)
    │   └── 🔴 FIXME: Memory leak (line 89)
    ├── 📄 delivery_screen.dart
    │   └── ⚠️ TODO: Implement search (line 120)
  📁 api/delivery (2)
    └── 📄 delivery_units.php
        ├── ⚠️ TODO: Add rate limiting (line 67)
        └── 🔵 NOTE: Review security (line 102)
```

### ⚙️ Cara Penggunaan

#### Install
```bash
code --install-extension gruntfuggly.todo-tree
```

#### Konfigurasi (settings.json)
```json
{
  // General settings
  "todo-tree.general.tags": [
    "TODO",
    "FIXME",
    "NOTE",
    "HACK",
    "XXX",
    "BUG",
    "REVIEW"
  ],
  
  // Highlight in editor
  "todo-tree.highlights.enabled": true,
  
  // Custom colors per tag
  "todo-tree.highlights.customHighlight": {
    "TODO": {
      "icon": "check",
      "iconColour": "#ffeb3b",
      "foreground": "#000",
      "background": "#ffeb3b"
    },
    "FIXME": {
      "icon": "alert",
      "iconColour": "#f44336",
      "foreground": "#fff",
      "background": "#f44336"
    },
    "NOTE": {
      "icon": "note",
      "iconColour": "#4caf50",
      "foreground": "#fff",
      "background": "#4caf50"
    },
    "HACK": {
      "icon": "tools",
      "iconColour": "#ff9800"
    },
    "BUG": {
      "icon": "bug",
      "iconColour": "#e91e63"
    }
  },
  
  // Regex patterns
  "todo-tree.regex.regex": "(//|#|<!--|;|/\\*|^|^\\s*(-|\\d+.))\\s*($TAGS)",
  
  // Files to scan
  "todo-tree.filtering.includeGlobs": [
    "**/*.dart",
    "**/*.php",
    "**/*.js",
    "**/*.ts"
  ],
  
  // Files to exclude
  "todo-tree.filtering.excludeGlobs": [
    "**/node_modules/**",
    "**/build/**",
    "**/vendor/**",
    "**/.git/**"
  ],
  
  // Tree view settings
  "todo-tree.tree.groupedByTag": true,
  "todo-tree.tree.showCountsInTree": true,
  "todo-tree.tree.expanded": true,
  
  // Sort order
  "todo-tree.tree.sort": true,
  "todo-tree.tree.sortTagsOnlyViewAlphabetically": true
}
```

### 🎨 Commands & Shortcuts

| Command | Shortcut | Fungsi |
|---------|----------|--------|
| `Todo Tree: Focus on View` | - | Buka sidebar TODO Tree |
| `Todo Tree: Refresh` | - | Refresh TODO list |
| `Todo Tree: Expand All` | - | Expand semua folders |
| `Todo Tree: Collapse All` | - | Collapse semua folders |
| `Todo Tree: Filter` | - | Filter by keyword |
| `Todo Tree: Group By Tag` | - | Group berdasarkan tag |

### 💡 Advanced Usage

#### Example Project Structure
```dart
// lib/screens/delivery/delivery_form.dart
class DeliveryForm extends StatefulWidget {
  @override
  _DeliveryFormState createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<DeliveryForm> {
  // TODO: Add form validation
  // Priority: High
  // Estimated: 2 hours
  void _validateForm() {
    // Implementation
  }
  
  // FIXME: Race condition when submitting multiple times
  // Bug ID: #1234
  // Assigned: John Doe
  Future<void> _submitForm() async {
    // Implementation
  }
  
  // NOTE: This method is called from parent widget
  // Related: delivery_screen.dart line 45
  void _resetForm() {
    // Implementation
  }
  
  // BUG: Memory leak on dispose
  // Severity: Critical
  // Reported: 2025-11-15
  @override
  void dispose() {
    super.dispose();
  }
}
```

#### PHP Example
```php
<?php
// api/delivery/delivery_units.php

// TODO: Implement caching
// Estimated: 4 hours
// Dependencies: Redis extension
function fetchDeliveries($branch) {
    // Implementation
}

// FIXME: SQL injection vulnerability
// Security Issue: Critical
// Ticket: SEC-456
function createDelivery($data) {
    // Implementation
}

// REVIEW: Performance optimization needed
// Current: 2.5s average
// Target: < 500ms
function processLargeDelivery($data) {
    // Implementation
}
?>
```

### 📊 Statistics View

TODO Tree can show:
- **Total TODOs:** 15
- **By Category:**
  - TODO: 8
  - FIXME: 4
  - NOTE: 2
  - BUG: 1
- **By File:**
  - delivery_form.dart: 6
  - delivery_screen.dart: 4
  - delivery_units.php: 5

---

## 🎯 WORKFLOW COMBINATION

### Scenario: Development Flow

```dart
// 1. Error Lens shows instant feedback
class DeliveryService {
  void createDelivery(String id) {
    // ❌ Error Lens: Undefined name 'branch'
    final delivery = Delivery(id: id, branch: branch);
  }
}

// 2. Better Comments for documentation
// * IMPORTANT: Core delivery logic
// ! WARNING: Do not modify without review
// ? QUESTION: Should we add retry logic?
class DeliveryManager {
  // 3. TODO Highlight shows what needs to be done
  // TODO: Implement retry mechanism
  // FIXME: Handle network errors
  
  Future<void> processDelivery() async {
    // Implementation
  }
}

// 4. TODO Tree shows all tasks in sidebar
// Navigate quickly to any TODO in project
```

---

## 📋 QUICK REFERENCE

### Keyboard Shortcuts
```
Error Lens:
- Toggle: Ctrl+Shift+P → "Error Lens: Toggle"

TODO Highlight:
- List All: Ctrl+Shift+P → "List highlighted"

Better Comments:
- No specific shortcuts (works automatically)

TODO Tree:
- Focus View: Ctrl+Shift+P → "Todo Tree: Focus"
- Refresh: Click refresh icon in TODO Tree view
```

### Best Practices Checklist
```
✅ Use Error Lens for immediate error detection
✅ Add TODO comments for future tasks
✅ Use FIXME for bugs that need fixing
✅ Use NOTE for important information
✅ Check TODO Tree sidebar daily
✅ Clean up completed TODOs regularly
✅ Use Better Comments for code reviews
✅ Document WHY, not just WHAT
```

---

## 🚀 INSTALLATION ONE-LINER

```bash
# Install semua sekaligus
code --install-extension usernamehw.errorlens && \
code --install-extension wayou.vscode-todo-highlight && \
code --install-extension aaron-bond.better-comments && \
code --install-extension gruntfuggly.todo-tree
```

---

## 💡 PRO TIPS

### 1. Combine with Git Workflow
```dart
// Before commit, check TODO Tree
// - Ensure no FIXME in production code
// - Document all TODOs with ticket numbers
// - Review all ! warnings

// TODO: [JIRA-123] Add email validation
// FIXME: [BUG-456] Fix memory leak before v2.3
```

### 2. Team Standards
```dart
// Establish team conventions
// TODO: [Priority:High] [Assignee:John] Task description
// FIXME: [Bug:#123] [Severity:Critical] Bug description
// NOTE: [Date:2025-11-16] Important note
```

### 3. Code Review Helper
```dart
// Use Better Comments during reviews
// * APPROVED: This logic is correct
// ! CONCERN: This needs refactoring
// ? CLARIFY: Is this the intended behavior?
```

---

**🎊 SELAMAT! Extensions siap digunakan untuk boost productivity! 🚀**