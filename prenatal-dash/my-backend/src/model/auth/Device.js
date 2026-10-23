const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class Device extends Model {}

  Device.init({
    fcm_token: {
      type: DataTypes.STRING(500),
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    platform: {
      type: DataTypes.STRING(50)
    }
  }, {
    sequelize,
    modelName: 'Device',
    tableName: 'devices',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  Device.associate = (models) => {
    Device.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
  };

  return Device;
};
