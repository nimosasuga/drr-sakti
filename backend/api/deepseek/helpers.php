<?php
// api/deepseek/helpers.php (FIXED FOR VARIABLE LENGTH ERROR CODES)
require_once __DIR__ . '/../config.php';

/**
 * Check if question is within allowed context
 */
function isValidContext($message) {
    $allowed_keywords = [
        'update job', 'job', 'pekerjaan', 'tugas',
        'unit', 'asset', 'aset', 'forklift', 'alat',
        'delivery', 'pengiriman', 'kirim',
        'penarikan', 'tarik', 'pickup',
        'charger', 'pengisian', 'charge', 'cas',
        'battery', 'baterai', 'aki',
        'error', 'kesalahan', 'fault', 'masalah', 'trouble',
        'kode', 'code',
        'status', 'kondisi', 'info', 'data', 'laporan', 'halo', 'hai', 'help'
    ];
    
    $message_lower = strtolower($message);
    
    foreach ($allowed_keywords as $keyword) {
        if (strpos($message_lower, $keyword) !== false) {
            return true;
        }
    }
    
    return false;
}

/**
 * Check if table exists
 */
function tableExists($pdo, $tableName) {
    try {
        $stmt = $pdo->query("SHOW TABLES LIKE '$tableName'");
        return $stmt->rowCount() > 0;
    } catch (PDOException $e) {
        return false;
    }
}

/**
 * Parse error code with variable length support (FIXED FOR FLEXIBLE S VALUES)
 * Format: F E XX S
 * - F: 1 digit/char
 * - E: 1 digit/char
 * - XX: 2 digits (bisa lebih jika S tidak ada, harus di-check)
 * - S: Variabel (bisa kosong, 1-3 digits)
 */
function parseErrorCode($error_code_str, $pdo) {
    $error_code_str = trim($error_code_str);
    
    // Remove any non-digit characters except for formatting dashes/spaces
    $clean_code = preg_replace('/[^0-9]/', '', $error_code_str);
    
    // Minimal 3 digit (F, E, dan minimal 1 digit XX)
    if (strlen($clean_code) < 3) {
        return null;
    }
    
    // Ambil F dan E sebagai string
    $f = $clean_code[0]; 
    $e = $clean_code[1]; 
    
    // Sisa string untuk XX dan S
    $remaining = substr($clean_code, 2); 
    
    // Cari kombinasi yang valid di database
    // Logika: Coba berbagai kemungkinan panjang XX (minimal 1 digit, maksimal 4 digit)
    // dan sisanya sebagai S (bisa kosong)
    if (tableExists($pdo, 'data_error')) {
        // Coba dulu dengan XX 2 digit (paling umum)
        if (strlen($remaining) >= 2) {
            $xx = substr($remaining, 0, 2);
            $s = substr($remaining, 2);
            
            // Cek di database dengan S kosong atau NULL (untuk kasus seperti 2304)
            $check_query = "SELECT COUNT(*) as cnt FROM data_error 
                            WHERE F = ? AND E = ? AND XX = ? 
                            AND (S IS NULL OR S = ? OR S = ?) 
                            LIMIT 1";
            $stmt = $pdo->prepare($check_query);
            
            // Coba dengan S kosong
            $stmt->execute([$f, $e, $xx, '', $s]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($result['cnt'] > 0) {
                return [
                    'f' => $f,
                    'e' => $e,
                    'xx' => $xx,
                    's' => $s, // Bisa kosong
                    'original' => $error_code_str,
                    'clean_code' => $clean_code
                ];
            }
            
            // Jika tidak ditemukan dengan S kosong, coba dengan S yang ada isinya
            if ($s !== '') {
                $check_query_s = "SELECT COUNT(*) as cnt FROM data_error 
                                  WHERE F = ? AND E = ? AND XX = ? AND S = ? 
                                  LIMIT 1";
                $stmt_s = $pdo->prepare($check_query_s);
                $stmt_s->execute([$f, $e, $xx, $s]);
                $result_s = $stmt_s->fetch(PDO::FETCH_ASSOC);
                
                if ($result_s['cnt'] > 0) {
                    return [
                        'f' => $f,
                        'e' => $e,
                        'xx' => $xx,
                        's' => $s,
                        'original' => $error_code_str,
                        'clean_code' => $clean_code
                    ];
                }
            }
        }
        
        // Coba dengan berbagai panjang XX
        for ($xx_len = 1; $xx_len <= min(4, strlen($remaining)); $xx_len++) {
            $xx = substr($remaining, 0, $xx_len);
            $s = substr($remaining, $xx_len);
            
            // Cek di database
            if ($s === '') {
                $check_query = "SELECT COUNT(*) as cnt FROM data_error 
                                WHERE F = ? AND E = ? AND XX = ? 
                                AND (S IS NULL OR S = '') 
                                LIMIT 1";
                $stmt = $pdo->prepare($check_query);
                $stmt->execute([$f, $e, $xx]);
            } else {
                // Coba dulu dengan S sebagai string lengkap
                $check_query = "SELECT COUNT(*) as cnt FROM data_error 
                                WHERE F = ? AND E = ? AND XX = ? AND S = ? 
                                LIMIT 1";
                $stmt = $pdo->prepare($check_query);
                $stmt->execute([$f, $e, $xx, $s]);
            }
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($result['cnt'] > 0) {
                return [
                    'f' => $f,
                    'e' => $e,
                    'xx' => $xx,
                    's' => $s,
                    'original' => $error_code_str,
                    'clean_code' => $clean_code
                ];
            }
        }
    }
    
    // Fallback: Jika tidak ketemu di DB, gunakan logika parsing sederhana
    // Default: XX = 2 digit pertama, sisanya S
    $fallback_xx = (strlen($remaining) >= 2) ? substr($remaining, 0, 2) : $remaining;
    $fallback_s = substr($remaining, strlen($fallback_xx));
    
    return [
        'f' => $f,
        'e' => $e,
        'xx' => $fallback_xx,
        's' => $fallback_s,
        'original' => $error_code_str,
        'clean_code' => $clean_code,
        'note' => 'Parsed using fallback logic (not found in database)'
    ];
}

/**
 * Get lightweight context data based on question (IMPROVED ERROR CODE DETECTION)
 */
function getSmartContext($pdo, $message, $user_id = null) {
    $context = [
        'scope' => [],
        'data' => [],
        'summary' => []
    ];
    
    $message_lower = strtolower($message);
    
    // Detect what data is needed
    $needs_jobs = preg_match('/(job|pekerjaan|tugas|update)/i', $message);
    $needs_units = preg_match('/(unit|asset|forklift|alat)/i', $message);
    $needs_delivery = preg_match('/(delivery|pengiriman|kirim)/i', $message);
    $needs_penarikan = preg_match('/(penarikan|tarik|pickup)/i', $message);
    $needs_charger = preg_match('/(charger|pengisian|charge|cas)/i', $message);
    $needs_battery = preg_match('/(battery|baterai|aki)/i', $message);
    
    // IMPROVED ERROR DETECTION REGEX - menangkap berbagai format
    // Contoh: "2304", "error 2304", "2304?", "1203120", "1-2-03-120"
    $needs_error = preg_match('/(?:error|kode|code|fault|err|kesalahan)?\s*[:\-]?\s*(\d{3,8})(?:\b|\D|$)/i', $message, $matches);
    
    try {
        // 1. Update Jobs
        if ($needs_jobs && tableExists($pdo, 'update_jobs')) {
            try {
                $query = "SELECT id, serial_number, unit_type, job_type, status_unit, 
                          customer, location, problem, action,
                          DATE_FORMAT(date, '%Y-%m-%d') as date,
                          DATE_FORMAT(problem_date, '%Y-%m-%d') as problem_date,
                          DATE_FORMAT(rfu_date, '%Y-%m-%d') as rfu_date,
                          pic
                          FROM update_jobs 
                          ORDER BY date DESC LIMIT 1000";
                $stmt = $pdo->query($query);
                $jobs = $stmt->fetchAll();
                
                if ($jobs) {
                    $context['data']['update_jobs'] = $jobs;
                    $context['scope'][] = 'update_jobs';
                    $context['summary']['total_jobs'] = count($jobs);
                }
            } catch (PDOException $e) {
                error_log("Update Jobs Query Error: " . $e->getMessage());
            }
        }
        
        // 2. Unit Assets
        if ($needs_units && tableExists($pdo, 'unit_assets')) {
            try {
                $query = "SELECT serial_number, unit_type, customer, location, 
                          status, year, branch, jenis_unit
                          FROM unit_assets 
                          ORDER BY serial_number LIMIT 1000";
                $stmt = $pdo->query($query);
                $units = $stmt->fetchAll();
                
                if ($units) {
                    $context['data']['units'] = $units;
                    $context['scope'][] = 'units';
                    $context['summary']['total_units'] = count($units);
                    
                    $status_count = [];
                    foreach ($units as $unit) {
                        $status = $unit['status'] ?? 'unknown';
                        $status_count[$status] = ($status_count[$status] ?? 0) + 1;
                    }
                    $context['summary']['status_breakdown'] = $status_count;
                }
            } catch (PDOException $e) {
                error_log("Units Query Error: " . $e->getMessage());
            }
        }
        
        // 3. Delivery
        if ($needs_delivery && tableExists($pdo, 'delivery_units')) {
            try {
                $query = "SELECT id, serial_number, unit_type, customer, location, 
                          status_unit, job_type, battery_sn, charger_sn,
                          DATE_FORMAT(date, '%Y-%m-%d') as date,
                          pic, note
                          FROM delivery_units 
                          ORDER BY date DESC LIMIT 150";
                $stmt = $pdo->query($query);
                $deliveries = $stmt->fetchAll();
                
                if ($deliveries) {
                    $context['data']['deliveries'] = $deliveries;
                    $context['scope'][] = 'deliveries';
                    $context['summary']['total_deliveries'] = count($deliveries);
                }
            } catch (PDOException $e) {
                error_log("Deliveries Query Error: " . $e->getMessage());
            }
        }
        
        // 4. Penarikan
        if ($needs_penarikan && tableExists($pdo, 'penarikan_units')) {
            try {
                $query = "SELECT id, serial_number, unit_type, customer, location, 
                          status_unit, job_type, battery_sn, charger_sn,
                          DATE_FORMAT(date, '%Y-%m-%d') as date,
                          pic, note
                          FROM penarikan_units 
                          ORDER BY date DESC LIMIT 150";
                $stmt = $pdo->query($query);
                $penarikan = $stmt->fetchAll();
                
                if ($penarikan) {
                    $context['data']['penarikan'] = $penarikan;
                    $context['scope'][] = 'penarikan';
                    $context['summary']['total_penarikan'] = count($penarikan);
                }
            } catch (PDOException $e) {
                error_log("Penarikan Query Error: " . $e->getMessage());
            }
        }
        
        // 5. Charger
        if ($needs_charger && tableExists($pdo, 'charger')) {
            try {
                $query = "SELECT id, sn_charger, charger_type, serial_number as unit_sn,
                          unit_type, status_unit, customer, location,
                          DATE_FORMAT(date, '%Y-%m-%d') as date,
                          problem, action, pic
                          FROM charger 
                          WHERE status_unit IN ('RFU', 'MONITORING', 'BREAKDOWN')
                          ORDER BY date DESC LIMIT 1000";
                $stmt = $pdo->query($query);
                $chargers = $stmt->fetchAll();
                
                if ($chargers) {
                    $context['data']['chargers'] = $chargers;
                    $context['scope'][] = 'chargers';
                    $context['summary']['total_charger_records'] = count($chargers);
                }
            } catch (PDOException $e) {
                error_log("Chargers Query Error: " . $e->getMessage());
            }
        }
        
        // 6. Battery
        if ($needs_battery && tableExists($pdo, 'battery')) {
            try {
                $query = "SELECT id, sn_battery, battery_type, serial_number as unit_sn,
                          unit_type, status_unit, customer, location,
                          DATE_FORMAT(date, '%Y-%m-%d') as date,
                          problem, action, pic
                          FROM battery 
                          WHERE status_unit IN ('RFU', 'MONITORING', 'BREAKDOWN')
                          ORDER BY date DESC LIMIT 15";
                $stmt = $pdo->query($query);
                $batteries = $stmt->fetchAll();
                
                if ($batteries) {
                    $context['data']['batteries'] = $batteries;
                    $context['scope'][] = 'batteries';
                    $context['summary']['total_battery_records'] = count($batteries);
                }
            } catch (PDOException $e) {
                error_log("Battery Query Error: " . $e->getMessage());
            }
        }
        
        // 7. Error Reference (FIXED FOR VARIABLE LENGTH CODES)
        if ($needs_error && !empty($matches[1])) {
            $error_code = $matches[1]; // Ambil digit yang tertangkap regex
            
            // Validasi panjang minimal
            if (strlen($error_code) >= 3) {
                $parsed = parseErrorCode($error_code, $pdo);
                
                if ($parsed) {
                    $f = $parsed['f'];
                    $e = $parsed['e'];
                    $xx = $parsed['xx'];
                    $s = $parsed['s']; // Bisa kosong string atau NULL
                    
                    if (tableExists($pdo, 'data_error') && tableExists($pdo, 'function_group') && tableExists($pdo, 'event_group')) {
                        try {
                            // Construct query berdasarkan kondisi S
                            if ($s === '' || $s === null) {
                                // Kasus S kosong atau NULL
                                $error_query = "SELECT 
                                                fg.F, fg.Deskripsi as function_desc, fg.Contoh as function_example,
                                                eg.E, eg.Deskripsi as event_desc, eg.Contoh as event_example,
                                                de.XX, de.S, de.Kondisi, de.Deskripsi as error_desc, 
                                                de.Penyebab, de.Tindakan
                                                FROM data_error de
                                                LEFT JOIN function_group fg ON fg.F = ?
                                                LEFT JOIN event_group eg ON eg.E = ?
                                                WHERE de.F = ? AND de.E = ? AND de.XX = ? 
                                                AND (de.S IS NULL OR de.S = '')
                                                LIMIT 1";
                                $params = [$f, $e, $f, $e, $xx];
                            } else {
                                // Kasus S ada isi
                                $error_query = "SELECT 
                                                fg.F, fg.Deskripsi as function_desc, fg.Contoh as function_example,
                                                eg.E, eg.Deskripsi as event_desc, eg.Contoh as event_example,
                                                de.XX, de.S, de.Kondisi, de.Deskripsi as error_desc, 
                                                de.Penyebab, de.Tindakan
                                                FROM data_error de
                                                LEFT JOIN function_group fg ON fg.F = ?
                                                LEFT JOIN event_group eg ON eg.E = ?
                                                WHERE de.F = ? AND de.E = ? AND de.XX = ? AND de.S = ?
                                                LIMIT 1";
                                $params = [$f, $e, $f, $e, $xx, $s];
                            }
                            
                            $error_stmt = $pdo->prepare($error_query);
                            $error_stmt->execute($params);
                            $error_detail = $error_stmt->fetch(PDO::FETCH_ASSOC);
                            
                            if ($error_detail) {
                                $context['data']['error_lookup'] = [
                                    'found' => true,
                                    'input_code' => $error_code,
                                    'parsed' => $parsed,
                                    'detail' => $error_detail
                                ];
                                $context['scope'][] = 'error_code';
                            } else {
                                // Jika tidak ditemukan, cari dengan XX saja (abaikan S)
                                $fallback_query = "SELECT 
                                                    fg.F, fg.Deskripsi as function_desc, fg.Contoh as function_example,
                                                    eg.E, eg.Deskripsi as event_desc, eg.Contoh as event_example,
                                                    de.XX, de.S, de.Kondisi, de.Deskripsi as error_desc, 
                                                    de.Penyebab, de.Tindakan
                                                    FROM data_error de
                                                    LEFT JOIN function_group fg ON fg.F = ?
                                                    LEFT JOIN event_group eg ON eg.E = ?
                                                    WHERE de.F = ? AND de.E = ? AND de.XX = ?
                                                    LIMIT 5";
                                $fallback_stmt = $pdo->prepare($fallback_query);
                                $fallback_stmt->execute([$f, $e, $f, $e, $xx]);
                                $fallback_results = $fallback_stmt->fetchAll(PDO::FETCH_ASSOC);
                                
                                if ($fallback_results) {
                                    $context['data']['error_lookup'] = [
                                        'found' => 'partial',
                                        'input_code' => $error_code,
                                        'parsed' => $parsed,
                                        'message' => "Kode error ditemukan dengan beberapa variasi S:",
                                        'matches' => $fallback_results
                                    ];
                                    $context['scope'][] = 'error_code';
                                } else {
                                    $context['data']['error_lookup'] = [
                                        'found' => false,
                                        'input_code' => $error_code,
                                        'parsed' => $parsed,
                                        'message' => "Kode error tidak ditemukan di database."
                                    ];
                                }
                            }
                        } catch (PDOException $ex) {
                            error_log("❌ Error Code Query Error: " . $ex->getMessage());
                            $context['data']['error_lookup'] = [
                                'found' => 'error',
                                'input_code' => $error_code,
                                'message' => "Terjadi kesalahan saat mencari kode error: " . $ex->getMessage()
                            ];
                        }
                    }
                }
            }
        }
        
        // Add metadata
        $context['metadata'] = [
            'timestamp' => date('Y-m-d H:i:s'),
            'user_id' => $user_id,
            'total_data_points' => array_sum(array_map('count', $context['data']))
        ];
        
    } catch (PDOException $e) {
        error_log("Context Error: " . $e->getMessage());
        $context['error'] = 'Database query failed';
    }
    
    return $context;
}

/**
 * Format context for AI prompt
 */
function formatContextForAI($context) {
    $formatted = "=== DATA CONTEXT ===\n\n";
    
    if (!empty($context['data'])) {
        foreach ($context['data'] as $key => $data) {
            $formatted .= strtoupper(str_replace('_', ' ', $key)) . ":\n";
            
            // Format khusus untuk error lookup
            if ($key === 'error_lookup') {
                if (isset($data['found']) && $data['found'] === true) {
                    $formatted .= "Kode Error Ditemukan:\n";
                    $formatted .= "- Input: " . ($data['input_code'] ?? 'N/A') . "\n";
                    $formatted .= "- Parsed: F=" . ($data['parsed']['f'] ?? '') . 
                                  ", E=" . ($data['parsed']['e'] ?? '') . 
                                  ", XX=" . ($data['parsed']['xx'] ?? '') . 
                                  ", S=" . ($data['parsed']['s'] ?? '-') . "\n";
                    
                    if (isset($data['detail'])) {
                        $formatted .= "- Function Group: " . ($data['detail']['function_desc'] ?? 'N/A') . "\n";
                        $formatted .= "- Event Group: " . ($data['detail']['event_desc'] ?? 'N/A') . "\n";
                        $formatted .= "- Kondisi: " . ($data['detail']['Kondisi'] ?? 'N/A') . "\n";
                        $formatted .= "- Deskripsi: " . ($data['detail']['error_desc'] ?? 'N/A') . "\n";
                        $formatted .= "- Penyebab: " . ($data['detail']['Penyebab'] ?? 'N/A') . "\n";
                        $formatted .= "- Tindakan: " . ($data['detail']['Tindakan'] ?? 'N/A') . "\n";
                    }
                } elseif (isset($data['found']) && $data['found'] === 'partial') {
                    $formatted .= "Kode Error Ditemukan dengan beberapa variasi:\n";
                    $formatted .= "- Input: " . ($data['input_code'] ?? 'N/A') . "\n";
                    $formatted .= "- Parsed: F=" . ($data['parsed']['f'] ?? '') . 
                                  ", E=" . ($data['parsed']['e'] ?? '') . 
                                  ", XX=" . ($data['parsed']['xx'] ?? '') . 
                                  ", S=" . ($data['parsed']['s'] ?? '-') . "\n";
                    
                    if (!empty($data['matches'])) {
                        $formatted .= "Variasi yang ditemukan:\n";
                        foreach ($data['matches'] as $index => $match) {
                            $formatted .= "  " . ($index + 1) . ". S=" . ($match['S'] ?? '-') . 
                                        " - " . ($match['error_desc'] ?? 'N/A') . "\n";
                        }
                    }
                } else {
                    $formatted .= json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
                }
            } else {
                $formatted .= json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
            }
            
            $formatted .= "\n";
        }
    } else {
        $formatted .= "No specific data available at the moment.\n\n";
    }
    
    if (!empty($context['summary'])) {
        $formatted .= "=== SUMMARY ===\n";
        foreach ($context['summary'] as $key => $value) {
            $formatted .= "- " . ucwords(str_replace('_', ' ', $key)) . ": " . $value . "\n";
        }
    }
    
    return $formatted;
}

/**
 * Build system prompt
 */
function buildSystemPrompt($context) {
    $prompt = "Anda adalah AI Assistant untuk aplikasi DRR SAKTI.

**SCOPE ANDA:**
1. Update Job
2. Unit Assets
3. Delivery
4. Penarikan
5. Charger
6. Battery
7. Error Codes (Format: F-E-XX-S)

**FORMAT ERROR CODE:**
- Format: F E XX S (contoh: 1-2-03-120)
- F: 1 digit (Function Group)
- E: 1 digit (Event Group)  
- XX: 2 digit (bisa lebih)
- S: Variabel (bisa kosong, 1-3 digit)
- Contoh: 
  * 2304 = F:2, E:3, XX:04, S: (kosong)
  * 1203120 = F:1, E:2, XX:03, S:120

**INSTRUKSI ERROR CODE:**
- Jika user menyebutkan kode error (misal: 2304, 1203120, error 2304?), analisa berdasarkan data 'error_lookup'.
- S bisa tidak ditampilkan dalam pesan error forklift.
- S bisa berupa 3 digit seperti 120.
- Jika kode tidak ditemukan persis, berikan saran berdasarkan kode terdekat.

**DATA TERSEDIA:**
";
    
    if (!empty($context['summary'])) {
        foreach ($context['summary'] as $key => $value) {
            $prompt .= "- " . ucwords(str_replace('_', ' ', $key)) . ": " . $value . "\n";
        }
    }
    
    $prompt .= "\n" . formatContextForAI($context);
    
    return $prompt;
}

/**
 * Save conversation
 */
function saveConversation($pdo, $user_id, $session_id, $user_message, $ai_response, $context, $tokens, $response_time) {
    if (!tableExists($pdo, 'ai_conversations')) {
        return false;
    }
    
    try {
        $query = "INSERT INTO ai_conversations 
                  (user_id, session_id, user_message, ai_response, context_used, tokens_used, response_time_ms)
                  VALUES (?, ?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($query);
        $stmt->execute([
            $user_id,
            $session_id,
            $user_message,
            $ai_response,
            json_encode($context['scope'] ?? []),
            $tokens,
            $response_time
        ]);
        return true;
    } catch (PDOException $e) {
        error_log("Save Conversation Error: " . $e->getMessage());
        return false;
    }
}
?>