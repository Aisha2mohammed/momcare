const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class ChatMessage extends Model {}

  ChatMessage.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    mother_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    doctor_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    sender_role: {
      type: DataTypes.STRING(20),
      allowNull: false
    },
    message_text: {
      type: DataTypes.TEXT
    },
    attachment_url: {
      type: DataTypes.STRING(500)
    },
    is_read: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    sequelize,
    modelName: 'ChatMessage',
    tableName: 'chat_messages',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  ChatMessage.associate = (models) => {
    ChatMessage.belongsTo(models.User, {
      foreignKey: 'mother_id',
      as: 'mother'
    });
    ChatMessage.belongsTo(models.User, {
      foreignKey: 'doctor_id',
      as: 'doctor'
    });
  };

  return ChatMessage;
};
