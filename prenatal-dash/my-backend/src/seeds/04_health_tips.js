/**
 * Seed the emergency / warning-sign health tips table.
 *
 * Schema (health_tips): title_am/_or/_en, warning_signs_am/_or/_en,
 *                       first_aid_am/_or/_en, created_at, updated_at.
 * Used by GET /health-tips and the mobile Health Tips screen.
 */
exports.seed = async function (knex) {
  console.log('🌱 Seeding health tips (04_health_tips)...');

  await knex('health_tips').del();

  const tips = [
    {
      title_en: 'Severe Headache or Blurred Vision',
      title_am: 'ከባድ ራስ ምታት ወይም ደብዘዝ ያለ እይታ',
      title_or: 'Mata Dhukkubsachuu Cimaa yoki Ijji Dukkanaa\'aa',
      warning_signs_en: 'A severe, persistent headache, blurred vision, flashing lights, swelling of the face or hands, or sudden weight gain.',
      warning_signs_am: 'ከባድ እና የማያቋርጥ ራስ ምታት፣ ደብዘዝ ያለ እይታ፣ ብልጭ የሚሉ ብርሃኖች፣ የፊት ወይም የእጅ እብጠት።',
      warning_signs_or: 'Mata dhukkubbii cimaa hin dhaabbatu, ijji dukkanaa\'aa, ibsaa calaqqisaa, fuula yoki harka iitawuu.',
      first_aid_en: 'Check your blood pressure if possible, lie on your left side in a quiet, dim room, and contact your provider or go to the nearest health facility immediately. Do not wait if symptoms worsen.',
      first_aid_am: 'የደም ግፊትዎን ካለ ይመልከቱ፣ በግራ ጎንዎ ዝም ብለው ያረፉ፣ ከዚያ ወዲያውኑ ከሀኪምዎ ጋር ይወያዩ ወይም ወደ ቅርብ የጤና ተቋም ይሂዱ።',
      first_aid_or: 'Yoo danda\'ame dhagaa dhiigaa kee ilaali, cinaacha bitaatiin bakka cal\'isaa tokkotti ciisi, hakanne yeroo hatattamaa ogeessa fayyaa bira ga\'i.',
    },
    {
      title_en: 'Vaginal Bleeding',
      title_am: 'የሴት ብልት ደም መፍሰስ',
      title_or: 'Dhiigni Kutee Saalaa Irraa Ba\'uu',
      warning_signs_en: 'Any vaginal bleeding during pregnancy, especially with pain or cramping, or passing tissue or clots.',
      warning_signs_am: 'በእርግዝና ወቅት ማንኛውም የደም መፍሰስ፣ በተለይም ከህመም ጋር፣ ወይም የቲሹ መውጣት።',
      warning_signs_or: 'Yeroo ulfaa dhiigni kutee saalaa irraa ba\'u kamiyyuu, keessumaa dhukkuba waliin.',
      first_aid_en: 'Use a clean pad (not a tampon), lie down and rest, avoid intercourse, and seek emergency care right away.',
      first_aid_am: 'ንጹህ ፓድ ይጠቀሙ (ታምፖን አይጠቀሙ)፣ ተኝተው ያረፉ፣ ወዲያውኑ የአደጋ ጊዜ ህክምና ይፈልጉ።',
      first_aid_or: 'Paadii qulqulluu fayyadami (taampoonii hin fayyadamne), ciisi boqodhu, hatattamaan gargaarsa ariifachiisaa barbaadi.',
    },
    {
      title_en: 'Reduced or No Baby Movement',
      title_am: 'የልጅ እንቅስቃሴ መቀነስ ወይም መቆም',
      title_or: 'Sochii Daa\'imaa Hir\'achuu yoki Dhaabbachuu',
      warning_signs_en: 'Fewer than 10 movements in 2 hours, or a clear change from your baby\'s normal movement pattern after 28 weeks.',
      warning_signs_am: 'በ2 ሰዓት ውስጥ ከ10 በታች እንቅስቃሴ፣ ወይም ከ28 ሳምንት በኋላ የልጅዎ እንቅስቃሴ ሲቀየር።',
      warning_signs_or: 'Sa\'aatii 2 keessatti sochii 10 gadi, yoki torban 28 booda sochii daa\'imaa jijjiiramuu.',
      first_aid_en: 'Drink cold water, lie on your left side and count kicks for 2 hours. If movement does not return to normal, go to the health facility immediately.',
      first_aid_am: 'ቀዝቃዛ ውሃ ይጠጡ፣ በግራ ጎንዎ ተኝተው ለ2 ሰዓት እንቅስቃሴ ይቁጠሩ። ካልተመለሰ ወዲያውኑ ወደ ጤና ተቋም ይሂዱ።',
      first_aid_or: 'Bishaan qabbanaa dhugi, cinaacha bitaatiin ciisi sa\'aatii 2 sochii lakkaa\'i. Yoo deebi\'e hin argamne hatattamaan dhaqabi.',
    },
    {
      title_en: 'High Fever or Chills',
      title_am: 'ከፍተኛ ትኩሳት ወይም ብርድ ብርድ',
      title_or: 'Ho\'a Qaamaa Ol\'aanaa yoki Qorra',
      warning_signs_en: 'Temperature above 38°C (100.4°F) with chills, shivering, or feeling very unwell.',
      warning_signs_am: 'ከ38°C በላይ ትኩሳት ከብርድ ብርድ ጋር፣ ወይም በጣም የመታመም ስሜት።',
      warning_signs_or: 'Ho\'a qaamaa 38°C ol, qorra waliin, yoki bay\'ee dhukkubsachuu.',
      first_aid_en: 'Take paracetamol as advised, drink plenty of fluids, use a lukewarm compress, and see a provider the same day — fever in pregnancy needs review.',
      first_aid_am: 'በተመከረው መሰረት ፓራሲታሞል ይውሰዱ፣ ብዙ ፈሳሽ ይጠጡ፣ ያለ ጥብቅ ውሃ ማድረግ ይሞክሩ እና በዚያው ቀን ሀኪም ያማክሩ።',
      first_aid_or: 'Parasitamool akka gorfame fayyadami, dhangala\'aa baay\'ee dhugi, guyyaa sanuma ogeessa fayyaa ilaali.',
    },
    {
      title_en: 'Severe Abdominal Pain',
      title_am: 'ከባድ የሆድ ህመም',
      title_or: 'Dhukkubbii Garaa Cimaa',
      warning_signs_en: 'Severe or constant abdominal pain, a hard or tender belly, or pain that does not go away with rest.',
      warning_signs_am: 'ከባድ ወይም የማያቋርጥ የሆድ ህመም፣ ደረቅ ወይም የሚያመች ሆድ።',
      warning_signs_or: 'Dhukkubbii garaa cimaa yoki hin dhaabbatu, garaa jabaa yoki tuquun dhukkubbii.',
      first_aid_en: 'Stop eating heavy food, lie down, do not take painkillers blindly, and go to the health facility urgently.',
      first_aid_am: 'ከባድ ምግብ አይብሉ፣ ያረፉ፣ ያለ ሀኪም ምክር ህመም ማስታገሻ አይውሰዱ እና ወዲያውኑ ወደ ጤና ተቋም ይሂዱ።',
      first_aid_or: 'Nyaata ulfaataa hin nyaatin, ciisi, qoricha dhukkubbii hayyama malee hin fudhatin, hatattamaan dhaqabi.',
    },
    {
      title_en: 'Difficulty Breathing or Chest Pain',
      title_am: 'የመተንፈስ ችግር ወይም የደረት ህመም',
      title_or: 'Afuura Baafachuu Dadhabuu yoki Dhukkubbii Qomaa',
      warning_signs_en: 'Shortness of breath at rest, chest pain, a racing heartbeat, or fainting.',
      warning_signs_am: 'በእረፍት ወቅት የመተንፈስ ችግር፣ የደረት ህመም፣ ፈጣን የልብ ምት ወይም ማቃጠል።',
      warning_signs_or: 'Yeroo boqonnaa afuura baafachuu dadhabuu, dhukkubbii qomaa, onnee saffisaa, yoki kufaatii.',
      first_aid_en: 'Sit upright, loosen tight clothing, open a window for fresh air, and call for emergency help immediately.',
      first_aid_am: 'ቀጥ ብለው ይቀመጡ፣ ጠባብ ልብስ ይፍቱ፣ መስኮት ከፍተው አየር ያስገቡ እና ወዲያውኑ የአደጋ ጊዜ እርዳታ ይጠሩ።',
      first_aid_or: 'Sirritti taa\'i, uffata cimaa hiiki, foddaa banii qilleensa galchi, hatattamaan gargaarsa bilbilaa gaafadhu.',
    },
  ];

  await knex('health_tips').insert(tips);
  console.log(`  ✅ Inserted ${tips.length} health tips.`);
};
