const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class ExerciseContent extends Model {}

  ExerciseContent.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    name_am: {
      type: DataTypes.STRING(500)
    },
    name_or: {
      type: DataTypes.STRING(500)
    },
    name_en: {
      type: DataTypes.STRING(500)
    },
    name_so: {
      type: DataTypes.STRING(500)
    },
    trimester_flags: {
      type: DataTypes.JSONB
    },
    duration_min: {
      type: DataTypes.INTEGER
    },
    safety_notes_am: {
      type: DataTypes.TEXT
    },
    safety_notes_or: {
      type: DataTypes.TEXT
    },
    safety_notes_en: {
      type: DataTypes.TEXT
    },
    safety_notes_so: {
      type: DataTypes.TEXT
    },
    media_url: {
      type: DataTypes.STRING(500)
    },
    is_published: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    week: {
      type: DataTypes.INTEGER
    },
    month: {
      type: DataTypes.INTEGER
    },
    type: {
      type: DataTypes.STRING(50),
      defaultValue: 'generic'
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
    tips_am: {
      type: DataTypes.TEXT
    },
    tips_or: {
      type: DataTypes.TEXT
    },
    tips_en: {
      type: DataTypes.TEXT
    },
    tips_so: {
      type: DataTypes.TEXT
    },
    sections_json: {
      type: DataTypes.JSONB
    }
  }, {
    sequelize,
    modelName: 'ExerciseContent',
    tableName: 'exercise_content',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return ExerciseContent;
};
