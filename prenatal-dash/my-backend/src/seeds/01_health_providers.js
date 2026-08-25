exports.seed = async function (knex) {
  await knex('health_providers').del();
  return knex('health_providers').insert([
    { id: knex.raw('gen_random_uuid()'), name: 'Tikur Anbessa Hospital', location: 'Addis Ababa', contact: '+251-111-234567', service_description: 'General hospital with maternity ward and emergency services. Full obstetrics and gynecology department.', status: 'active' },
    { id: knex.raw('gen_random_uuid()'), name: 'St. Paul\'s Hospital Millennium Medical College', location: 'Addis Ababa', contact: '+251-111-456789', service_description: 'Teaching hospital offering comprehensive maternal health services, high-risk pregnancy care.', status: 'active' },
    { id: knex.raw('gen_random_uuid()'), name: 'Adama General Hospital', location: 'Adama', contact: '+251-221-123456', service_description: 'Regional hospital with maternity services, prenatal and postnatal care.', status: 'active' },
    { id: knex.raw('gen_random_uuid()'), name: 'Jimma Medical Center', location: 'Jimma', contact: '+251-471-123456', service_description: 'University hospital providing maternal health services and community outreach.', status: 'active' },
    { id: knex.raw('gen_random_uuid()'), name: 'Gandhi Memorial Hospital', location: 'Addis Ababa', contact: '+251-111-789012', service_description: 'Specialized maternity hospital with NICU and high-risk pregnancy management.', status: 'active' },
  ]);
};
