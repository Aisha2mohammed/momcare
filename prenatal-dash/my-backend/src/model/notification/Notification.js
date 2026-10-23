const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class Notification extends Model {}

  Notification.init({
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
    title_so: {
      type: DataTypes.TEXT
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
    type: {
      type: DataTypes.STRING(50),
      defaultValue: 'reminder'
    },
    trimester: {
      type: DataTypes.INTEGER
    },
    week: {
      type: DataTypes.INTEGER
    },
    month: {
      type: DataTypes.INTEGER
    },
    target_group: {
      type: DataTypes.STRING(50),
      defaultValue: 'all'
    },
    target_user_id: {
      type: DataTypes.UUID
    },
    sent_by: {
      type: DataTypes.STRING(50),
      defaultValue: 'system'
    },
    scheduled_at: {
      type: DataTypes.DATE
    },
    sent_at: {
      type: DataTypes.DATE
    },
    open_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    sent_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'Notification',
    tableName: 'notifications',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  Notification.associate = (models) => {
    Notification.belongsTo(models.User, {
      foreignKey: 'target_user_id',
      as: 'targetUser'
    });
    Notification.hasMany(models.NotificationRead, {
      foreignKey: 'notification_id',
      as: 'reads'
    });
  };

  return Notification;
};
