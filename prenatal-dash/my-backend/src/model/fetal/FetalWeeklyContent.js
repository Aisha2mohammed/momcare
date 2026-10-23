const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class FetalWeeklyContent extends Model {}

  FetalWeeklyContent.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    week_number: {
      type: DataTypes.INTEGER,
      allowNull: false,
      unique: true
    },
    title_en: {
      type: DataTypes.STRING(500)
    },
    title_am: {
      type: DataTypes.STRING(500)
    },
    title_om: {
      type: DataTypes.STRING(500)
    },
    title_so: {
      type: DataTypes.STRING(500)
    },
    image_url: {
      type: DataTypes.STRING(500)
    },
    image_alt_en: {
      type: DataTypes.STRING(500)
    },
    image_alt_am: {
      type: DataTypes.STRING(500)
    },
    image_alt_om: {
      type: DataTypes.STRING(500)
    },
    image_alt_so: {
      type: DataTypes.STRING(500)
    },
    summary_en: {
      type: DataTypes.TEXT
    },
    summary_am: {
      type: DataTypes.TEXT
    },
    summary_om: {
      type: DataTypes.TEXT
    },
    summary_so: {
      type: DataTypes.TEXT
    },
    baby_length_cm: {
      type: DataTypes.DECIMAL(6, 2)
    },
    baby_weight_g: {
      type: DataTypes.DECIMAL(8, 2)
    },
    days_remaining: {
      type: DataTypes.INTEGER
    },
    heart_rate: {
      type: DataTypes.INTEGER
    },
    size_comparison_en: {
      type: DataTypes.STRING(500)
    },
    size_comparison_am: {
      type: DataTypes.STRING(500)
    },
    size_comparison_om: {
      type: DataTypes.STRING(500)
    },
    size_comparison_so: {
      type: DataTypes.STRING(500)
    },
    milestone_en: {
      type: DataTypes.TEXT
    },
    milestone_am: {
      type: DataTypes.TEXT
    },
    milestone_om: {
      type: DataTypes.TEXT
    },
    milestone_so: {
      type: DataTypes.TEXT
    },
    physical_development_en: {
      type: DataTypes.TEXT
    },
    physical_development_am: {
      type: DataTypes.TEXT
    },
    physical_development_om: {
      type: DataTypes.TEXT
    },
    physical_development_so: {
      type: DataTypes.TEXT
    },
    brain_dev_en: {
      type: DataTypes.TEXT
    },
    brain_dev_am: {
      type: DataTypes.TEXT
    },
    brain_dev_om: {
      type: DataTypes.TEXT
    },
    brain_dev_so: {
      type: DataTypes.TEXT
    },
    heart_dev_en: {
      type: DataTypes.TEXT
    },
    heart_dev_am: {
      type: DataTypes.TEXT
    },
    heart_dev_om: {
      type: DataTypes.TEXT
    },
    heart_dev_so: {
      type: DataTypes.TEXT
    },
    organ_dev_en: {
      type: DataTypes.TEXT
    },
    organ_dev_am: {
      type: DataTypes.TEXT
    },
    organ_dev_om: {
      type: DataTypes.TEXT
    },
    organ_dev_so: {
      type: DataTypes.TEXT
    },
    bone_muscle_dev_en: {
      type: DataTypes.TEXT
    },
    bone_muscle_dev_am: {
      type: DataTypes.TEXT
    },
    bone_muscle_dev_om: {
      type: DataTypes.TEXT
    },
    bone_muscle_dev_so: {
      type: DataTypes.TEXT
    },
    movement_en: {
      type: DataTypes.TEXT
    },
    movement_am: {
      type: DataTypes.TEXT
    },
    movement_om: {
      type: DataTypes.TEXT
    },
    movement_so: {
      type: DataTypes.TEXT
    },
    senses: {
      type: DataTypes.JSONB,
      defaultValue: []
    },
    maternal_changes_en: {
      type: DataTypes.TEXT
    },
    maternal_changes_am: {
      type: DataTypes.TEXT
    },
    maternal_changes_om: {
      type: DataTypes.TEXT
    },
    maternal_changes_so: {
      type: DataTypes.TEXT
    },
    common_symptoms_en: {
      type: DataTypes.TEXT
    },
    common_symptoms_am: {
      type: DataTypes.TEXT
    },
    common_symptoms_om: {
      type: DataTypes.TEXT
    },
    common_symptoms_so: {
      type: DataTypes.TEXT
    },
    health_tip_en: {
      type: DataTypes.TEXT
    },
    health_tip_am: {
      type: DataTypes.TEXT
    },
    health_tip_om: {
      type: DataTypes.TEXT
    },
    health_tip_so: {
      type: DataTypes.TEXT
    },
    antenatal_care_en: {
      type: DataTypes.TEXT
    },
    antenatal_care_am: {
      type: DataTypes.TEXT
    },
    antenatal_care_om: {
      type: DataTypes.TEXT
    },
    antenatal_care_so: {
      type: DataTypes.TEXT
    },
    screening_information_en: {
      type: DataTypes.TEXT
    },
    screening_information_am: {
      type: DataTypes.TEXT
    },
    screening_information_om: {
      type: DataTypes.TEXT
    },
    screening_information_so: {
      type: DataTypes.TEXT
    },
    bonding_activity_title_en: {
      type: DataTypes.STRING(500)
    },
    bonding_activity_title_am: {
      type: DataTypes.STRING(500)
    },
    bonding_activity_title_om: {
      type: DataTypes.STRING(500)
    },
    bonding_activity_title_so: {
      type: DataTypes.STRING(500)
    },
    bonding_activity_description_en: {
      type: DataTypes.TEXT
    },
    bonding_activity_description_am: {
      type: DataTypes.TEXT
    },
    bonding_activity_description_om: {
      type: DataTypes.TEXT
    },
    bonding_activity_description_so: {
      type: DataTypes.TEXT
    },
    emotional_message_en: {
      type: DataTypes.TEXT
    },
    emotional_message_am: {
      type: DataTypes.TEXT
    },
    emotional_message_om: {
      type: DataTypes.TEXT
    },
    emotional_message_so: {
      type: DataTypes.TEXT
    },
    diary_prompt_en: {
      type: DataTypes.TEXT
    },
    diary_prompt_am: {
      type: DataTypes.TEXT
    },
    diary_prompt_om: {
      type: DataTypes.TEXT
    },
    diary_prompt_so: {
      type: DataTypes.TEXT
    },
    warning_signs_en: {
      type: DataTypes.TEXT
    },
    warning_signs_am: {
      type: DataTypes.TEXT
    },
    warning_signs_om: {
      type: DataTypes.TEXT
    },
    warning_signs_so: {
      type: DataTypes.TEXT
    },
    when_to_contact_provider_en: {
      type: DataTypes.TEXT
    },
    when_to_contact_provider_am: {
      type: DataTypes.TEXT
    },
    when_to_contact_provider_om: {
      type: DataTypes.TEXT
    },
    when_to_contact_provider_so: {
      type: DataTypes.TEXT
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    created_by: {
      type: DataTypes.UUID
    },
    reviewed_by: {
      type: DataTypes.UUID
    }
  }, {
    sequelize,
    modelName: 'FetalWeeklyContent',
    tableName: 'fetal_weekly_content',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  FetalWeeklyContent.associate = (models) => {
    FetalWeeklyContent.hasMany(models.FetalDevelopmentItem, {
      foreignKey: 'week_id',
      as: 'developmentItems'
    });
    FetalWeeklyContent.hasMany(models.FetalChecklistItem, {
      foreignKey: 'week_id',
      as: 'checklistItems'
    });
  };

  return FetalWeeklyContent;
};
