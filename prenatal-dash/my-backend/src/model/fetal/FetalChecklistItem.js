const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class FetalChecklistItem extends Model {}

  FetalChecklistItem.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    week_id: {
      type: DataTypes.UUID,
      allowNull: false
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
    display_order: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'FetalChecklistItem',
    tableName: 'fetal_checklist_items',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  FetalChecklistItem.associate = (models) => {
    FetalChecklistItem.belongsTo(models.FetalWeeklyContent, {
      foreignKey: 'week_id',
      as: 'weeklyContent'
    });
  };

  return FetalChecklistItem;
};
