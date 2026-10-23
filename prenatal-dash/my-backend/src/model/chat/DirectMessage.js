const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class DirectMessage extends Model {}

  DirectMessage.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    sender_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    receiver_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    message_text: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    is_read: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    is_edited: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    sequelize,
    modelName: 'DirectMessage',
    tableName: 'direct_messages',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  DirectMessage.associate = (models) => {
    DirectMessage.belongsTo(models.User, {
      foreignKey: 'sender_id',
      as: 'sender'
    });
    DirectMessage.belongsTo(models.User, {
      foreignKey: 'receiver_id',
      as: 'receiver'
    });
  };

  return DirectMessage;
};
