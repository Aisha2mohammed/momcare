const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class HealthTip extends Model {}

  HealthTip.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
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
    warning_signs_am: {
      type: DataTypes.TEXT
    },
    warning_signs_or: {
      type: DataTypes.TEXT
    },
    warning_signs_en: {
      type: DataTypes.TEXT
    },
    first_aid_am: {
      type: DataTypes.TEXT
    },
    first_aid_or: {
      type: DataTypes.TEXT
    },
    first_aid_en: {
      type: DataTypes.TEXT
    }
  }, {
    sequelize,
    modelName: 'HealthTip',
    tableName: 'health_tips',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return HealthTip;
};
