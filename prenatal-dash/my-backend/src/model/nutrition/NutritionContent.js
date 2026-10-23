const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class NutritionContent extends Model {}

  NutritionContent.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    trimester: {
      type: DataTypes.INTEGER
    },
    title_am: {
      type: DataTypes.STRING(500)
    },
    title_or: {
      type: DataTypes.STRING(500)
    },
    title_en: {
      type: DataTypes.STRING(500)
    },
    title_so: {
      type: DataTypes.STRING(500)
    },
    body_am: {
      type: DataTypes.TEXT
    },
    body_or: {
      type: DataTypes.TEXT
    },
    body_en: {
      type: DataTypes.TEXT
    },
    body_so: {
      type: DataTypes.TEXT
    },
    image_url: {
      type: DataTypes.STRING(500)
    },
    is_published: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    type: {
      type: DataTypes.STRING(20),
      defaultValue: 'eat'
    },
    emoji: {
      type: DataTypes.STRING(10),
      defaultValue: '🥗'
    },
    nutrient_type: {
      type: DataTypes.STRING(255),
      defaultValue: ''
    },
    week: {
      type: DataTypes.INTEGER
    },
    video_url: {
      type: DataTypes.STRING(500)
    },
    video_title: {
      type: DataTypes.STRING(500)
    },
    reason_am: {
      type: DataTypes.TEXT
    },
    reason_or: {
      type: DataTypes.TEXT
    },
    reason_en: {
      type: DataTypes.TEXT
    },
    reason_so: {
      type: DataTypes.TEXT
    },
    foods_json: {
      type: DataTypes.JSONB
    },
    nutrient_sections_json: {
      type: DataTypes.JSONB
    },
    why_important_am: {
      type: DataTypes.TEXT
    },
    why_important_or: {
      type: DataTypes.TEXT
    },
    why_important_en: {
      type: DataTypes.TEXT
    },
    why_important_so: {
      type: DataTypes.TEXT
    },
    hydration_am: {
      type: DataTypes.TEXT
    },
    hydration_or: {
      type: DataTypes.TEXT
    },
    hydration_en: {
      type: DataTypes.TEXT
    },
    hydration_so: {
      type: DataTypes.TEXT
    },
    pdf_url: {
      type: DataTypes.STRING(500)
    }
  }, {
    sequelize,
    modelName: 'NutritionContent',
    tableName: 'nutrition_content',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return NutritionContent;
};
