const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class FetalTrackerContent extends Model {}

  FetalTrackerContent.init({
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
    size_comparison: {
      type: DataTypes.STRING(255)
    },
    milestone_am: {
      type: DataTypes.TEXT
    },
    milestone_or: {
      type: DataTypes.TEXT
    },
    milestone_en: {
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
    image_url: {
      type: DataTypes.STRING(500)
    }
  }, {
    sequelize,
    modelName: 'FetalTrackerContent',
    tableName: 'fetal_tracker_content',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return FetalTrackerContent;
};
