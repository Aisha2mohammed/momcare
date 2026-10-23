const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class Reminder extends Model {}

  Reminder.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    type: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    message: {
      type: DataTypes.TEXT
    },
    scheduled_at: {
      type: DataTypes.DATE
    },
    sent_at: {
      type: DataTypes.DATE
    }
  }, {
    sequelize,
    modelName: 'Reminder',
    tableName: 'reminders',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  Reminder.associate = (models) => {
    Reminder.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
  };

  return Reminder;
};
