const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class NotificationRead extends Model {}

  NotificationRead.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    notification_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    read_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    sequelize,
    modelName: 'NotificationRead',
    tableName: 'notification_reads',
    timestamps: false
  });

  NotificationRead.associate = (models) => {
    NotificationRead.belongsTo(models.Notification, {
      foreignKey: 'notification_id',
      as: 'notification'
    });
    NotificationRead.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
  };

  return NotificationRead;
};
