<?php
// api/deepseek/chat_v3.php - Version 3 (Working Model)
header('Content-Type: application/json');

ini_set('display_errors', 1);
ini_set('log_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/helpers.php';

// Define only if not already defined
if (!function_exists('error_response')) {
    function error_response($message, $code = 400) {
        http_response_code($code);
        echo json_encode([
            'success' => false, 
            'message' => $message,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        exit;
    }
}

if (!function_exists('success_response')) {
    function success_response($data) {
        echo json_encode(['success' => true, 'data' => $data]);
        exit;
    }
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        error_response('Method not allowed', 405);
    }

    $input_raw = file_get_contents('php://input');
    $input = json_decode($input_raw, true);
    
    if (!$input) {
        error_response('Invalid JSON', 400);
    }

    if (!isset($input['message']) || empty(trim($input['message']))) {
        error_response('Message is required');
    }

    $message = trim($input['message']);
    $user_id = $input['user_id'] ?? 'guest';
    $session_id = $input['session_id'] ?? uniqid('chat_', true);

    // Validate context
    if (!isValidContext($message)) {
        success_response([
            'reply' => "Maaf, saya hanya dapat membantu dengan informasi terkait:\n\n📋 Update Job\n🚜 Unit Assets\n📦 Delivery\n📙 Penarikan\n⚡ Charger & Charging\n🔋 Battery & Kesehatan Battery\n⚠️ Error Codes & Troubleshooting\n\nApakah ada yang bisa saya bantu?",
            'session_id' => $session_id,
            'in_scope' => false
        ]);
    }

    $start_time = microtime(true);
    
    try {
        $context = getSmartContext($pdo, $message, $user_id);
    } catch (Exception $e) {
        $context = [
            'scope' => ['general'],
            'data' => [],
            'summary' => []
        ];
    }

    $system_prompt = buildSystemPrompt($context);

    // OpenRouter API
    $api_url = 'https://openrouter.ai/api/v1/chat/completions';
    $api_key = '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';

    // ✅ MODEL: Google Gemini 2.0 Flash (Free & Reliable)
    $model = 'meta-llama/llama-3.3-70b-instruct:free';  // Llama 3.3 - Very reliable

    $payload = [
        'model' => $model,
        'messages' => [
            ['role' => 'system', 'content' => $system_prompt],
            ['role' => 'user', 'content' => $message]
        ],
        'temperature' => 0.7,
        'max_tokens' => 1000
    ];

    $ch = curl_init($api_url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $api_key,
            'HTTP-Referer: https://drr.exprosa.com',
            'X-Title: DRR SAKTI Assistant'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_TIMEOUT => 60,
        CURLOPT_SSL_VERIFYPEER => true
    ]);

    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curl_error = curl_error($ch);
    curl_close($ch);

    $response_time = round((microtime(true) - $start_time) * 1000);

    if ($response === false) {
        error_response("Connection failed: $curl_error", 503);
    }

    $ai_response = json_decode($response, true);

    if ($http_code !== 200) {
        $error_msg = $ai_response['error']['message'] ?? 'Unknown error';
        
        if ($http_code == 404) {
            error_response("Model not found. Try: deepseek/deepseek-chat-v3.1:free", 500);
        } elseif ($http_code == 401) {
            error_response("Invalid API key", 500);
        } elseif ($http_code == 429) {
            error_response("Rate limited. Try again later.", 429);
        }
        
        error_response("API Error ($http_code): $error_msg", 500);
    }

    if (!isset($ai_response['choices'][0]['message']['content'])) {
        error_response('Invalid response from AI', 500);
    }

    $ai_reply = $ai_response['choices'][0]['message']['content'];
    $tokens_used = $ai_response['usage']['total_tokens'] ?? 0;

    success_response([
        'reply' => $ai_reply,
        'session_id' => $session_id,
        'in_scope' => true,
        'context_used' => $context['scope'] ?? [],
        'tokens_used' => $tokens_used,
        'response_time_ms' => $response_time,
        'data_summary' => $context['summary'] ?? [],
        'debug_info' => [
            'model' => $model,
            'context_data_points' => count($context['data'] ?? [])
        ]
    ]);

} catch (Exception $e) {
    error_response("Server Error: " . $e->getMessage(), 500);
}
?>