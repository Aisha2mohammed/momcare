const { query } = require('../config/db');

/**
 * Risk Indicator Scoring Service
 * 
 * Computes a patient's risk level based on:
 * - Latest clinical records (doctor's assessment)
 * - Symptom severity from health logs
 * - Symptom frequency from health logs
 * - Overall trend
 * 
 * Returns: { riskLevel: 'low' | 'medium' | 'high', score: number, factors: string[] }
 */

const SYMPTOM_WEIGHTS = {
  'bleeding': 15,
  'severe_pain': 12,
  'high_fever': 10,
  'high_blood_pressure': 12,
  'swelling': 5,
  'headache': 4,
  'nausea': 3,
  'fatigue': 2,
  'dizziness': 5,
  'vision_changes': 10,
  'reduced_fetal_movement': 10,
  'contractions': 8,
  'back_pain': 3,
  'heartburn': 1,
};

const SEVERITY_MULTIPLIERS = {
  'mild': 1,
  'moderate': 2,
  'severe': 4,
  'critical': 6,
};

/**
 * Calculate risk indicator for a specific mother
 * @param {string} motherId - UUID of the mother
 * @returns {Promise<{riskLevel: string, score: number, factors: string[], clinicalRisk: string|null}>}
 */
const calculateRiskIndicator = async (motherId) => {
  const factors = [];
  let score = 0;

  // 1. Check latest clinical record
  const clinicalResult = await query(
    `SELECT risk_indicator, notes_text, created_at
     FROM clinical_records
     JOIN appointments ON clinical_records.appointment_id = appointments.id
     WHERE appointments.mother_id = $1 AND clinical_records.risk_indicator IS NOT NULL
     ORDER BY clinical_records.created_at DESC
     LIMIT 1`,
    [motherId]
  );

  let clinicalRisk = null;
  if (clinicalResult.rows.length > 0) {
    clinicalRisk = clinicalResult.rows[0].risk_indicator;
    const clinicalScore = clinicalRisk === 'high' ? 30 : clinicalRisk === 'medium' ? 15 : 0;
    score += clinicalScore;
    if (clinicalRisk !== 'low') {
      factors.push(`Clinical assessment: ${clinicalRisk} risk`);
    }
  }

  // 2. Analyze symptom frequency from health logs (last 30 days)
  const logsResult = await query(
    `SELECT symptoms_json, symptom_severity, log_date
     FROM user_health_logs
     WHERE mother_id = $1 AND log_date >= NOW() - INTERVAL '30 days'
     ORDER BY log_date DESC`,
    [motherId]
  );

  if (logsResult.rows.length > 0) {
    const symptomCount = logsResult.rows.length;
    const symptomFrequency = symptomCount / 30; // symptoms per day

    // Frequency scoring
    if (symptomFrequency > 0.7) {
      score += 15;
      factors.push(`High symptom frequency (${symptomCount} logs in 30 days)`);
    } else if (symptomFrequency > 0.3) {
      score += 7;
      factors.push(`Moderate symptom frequency (${symptomCount} logs in 30 days)`);
    }

    // Severity and symptom-type scoring
    for (const log of logsResult.rows) {
      const symptoms = typeof log.symptoms_json === 'string'
        ? JSON.parse(log.symptoms_json)
        : log.symptoms_json || [];

      const severity = log.symptom_severity || 'mild';
      const severityMult = SEVERITY_MULTIPLIERS[severity] || 1;

      for (const symptom of symptoms) {
        const symptomName = typeof symptom === 'string' ? symptom : symptom.name || symptom.symptom || '';
        if (symptomName) {
          const weight = SYMPTOM_WEIGHTS[symptomName] || 1;
          score += weight * severityMult * 0.1;
        }
      }
    }

    // Check for critical symptoms
    const allSymptoms = logsResult.rows.flatMap(log => {
      const symptoms = typeof log.symptoms_json === 'string'
        ? JSON.parse(log.symptoms_json)
        : log.symptoms_json || [];
      return symptoms.map(s => typeof s === 'string' ? s : s.name || s.symptom || '');
    });

    const criticalSymptoms = ['bleeding', 'severe_pain', 'high_blood_pressure', 'reduced_fetal_movement', 'vision_changes'];
    const foundCritical = criticalSymptoms.filter(s => allSymptoms.includes(s));
    if (foundCritical.length > 0) {
      score += 20;
      factors.push(`Critical symptoms reported: ${foundCritical.join(', ')}`);
    }
  } else {
    // No recent logs - could be good (no symptoms) or concerning (no tracking)
    factors.push('No health logs in the last 30 days');
  }

  // 3. Determine final risk level
  let riskLevel;
  if (score >= 30 || clinicalRisk === 'high') {
    riskLevel = 'high';
  } else if (score >= 15 || clinicalRisk === 'medium') {
    riskLevel = 'medium';
  } else {
    riskLevel = 'low';
  }

  // Round score
  score = Math.round(score * 10) / 10;

  return { riskLevel, score, factors, clinicalRisk };
};

/**
 * Get all patients sorted by risk indicator for a doctor
 * @param {string} doctorId - UUID of the doctor
 * @returns {Promise<Array>}
 */
const getPatientsByRisk = async (doctorId) => {
  // Get all mothers assigned to this doctor
  const mothersResult = await query(
    `SELECT u.id, u.name, u.phone, u.language, u.created_at,
            mp.lmp_date, mp.due_date, mp.gestational_week, mp.city
     FROM mother_profiles mp
     JOIN users u ON mp.user_id = u.id
     WHERE mp.assigned_doctor_id = $1 AND u.status = 'active'
     ORDER BY u.name`,
    [doctorId]
  );

  // Calculate risk for each mother
  const patients = await Promise.all(
    mothersResult.rows.map(async (mother) => {
      const risk = await calculateRiskIndicator(mother.id);
      return {
        ...mother,
        riskScore: risk.score,
        riskLevel: risk.riskLevel,
        riskFactors: risk.factors,
      };
    })
  );

  // Sort by risk score descending (highest risk first)
  patients.sort((a, b) => b.riskScore - a.riskScore);

  return patients;
};

module.exports = { calculateRiskIndicator, getPatientsByRisk };
