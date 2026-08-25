const { query } = require('../config/db');
const { sendSuccess, sendError } = require('../utils/apiResponse');

// ── POST /api/v1/chatbot/ask ──────────────────────────────────────────
exports.ask = async (req, res, next) => {
  try {
    const { message } = req.body;
    const userId = req.user.id;

    if (!message) {
      return sendError(res, 400, 'Message is required.');
    }

    // Get user's language preference for context-aware response
    const userResult = await query('SELECT language, role FROM users WHERE id = $1', [userId]);
    const language = userResult.rows[0]?.language || 'am';
    const role = userResult.rows[0]?.role || 'mother';

    // Get pregnancy context if mother
    let pregnancyContext = {};
    if (role === 'mother') {
      const profileResult = await query(
        'SELECT lmp_date, due_date, gestational_week FROM mother_profiles WHERE user_id = $1',
        [userId]
      );
      if (profileResult.rows.length > 0) {
        pregnancyContext = profileResult.rows[0];
      }
    }

    // Build system prompt
    const systemPrompt = buildSystemPrompt(role, language, pregnancyContext);

    // In production: call external LLM API (OpenAI, Anthropic, etc.)
    // For now, simulate a response
    const response = await simulateLLMResponse(message, systemPrompt, language);

    return sendSuccess(res, 200, 'Response generated', {
      message,
      response,
      language,
    });
  } catch (err) {
    next(err);
  }
};

function buildSystemPrompt(role, language, context) {
  let prompt = `You are MaternaAI, a pregnancy health assistant for the MaternaLink app. `;
  prompt += `Respond in a caring, empathetic, and medically responsible manner. `;
  prompt += `Always remind users to consult their healthcare provider for medical advice. `;

  if (role === 'mother' && context.gestational_week) {
    prompt += `The user is a pregnant mother at week ${context.gestational_week} of pregnancy. `;
    if (context.due_date) {
      prompt += `Her estimated due date is ${new Date(context.due_date).toLocaleDateString()}. `;
    }
  } else if (role === 'doctor') {
    prompt += `The user is a healthcare professional/doctor. `;
  }

  prompt += `Language preference: ${language === 'am' ? 'Amharic (አማርኛ)' : language === 'or' ? 'Oromo (Afaan Oromoo)' : 'English'}. `;
  prompt += `If the user asks in their preferred language, respond in the same language. `;

  return prompt;
}

async function simulateLLMResponse(message, systemPrompt, language) {
  // This is a placeholder - in production, integrate with OpenAI/Anthropic/Cohere APIs
  const responses = {
    am: {
      greeting: 'ሰላም! እንዴት ልረዳህ/ሽ እችላለሁ? ስለ እርግዝናዎ ጥያቄ አለዎት?',
      default: 'ለጥያቄዎ ምስጋና ይሁንልዎ። እባክዎ ለትክክለኛ የህክምና ምክር ዶክተርዎን ያማክሩ።',
    },
    or: {
      greeting: 'Akkam! Akkan sii gargaaru? Gaaffii waa\'ee ulfaa qabdaa?',
      default: 'Galatoomi gaaffii keetiif. Mee ogeessa fayyaa keessan gorsa fayyaa sirrii ta\'eef gaafadhaa.',
    },
    en: {
      greeting: 'Hello! How can I help you? Do you have any questions about your pregnancy?',
      default: 'Thank you for your question. Please consult your doctor for accurate medical advice.',
    },
  };

  const lang = language === 'or' ? 'or' : language === 'en' ? 'en' : 'am';

  // Simple keyword-based response simulation
  if (message.toLowerCase().includes('hello') || message.toLowerCase().includes('hi') || message.toLowerCase().includes('ሰላም') || message.toLowerCase().includes('akkam')) {
    return responses[lang].greeting;
  }

  return responses[lang].default + ` (Context: ${systemPrompt.substring(0, 100)}...)`;
}
