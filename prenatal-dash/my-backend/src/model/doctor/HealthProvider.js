const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class HealthProvider extends Model {}

  HealthProvider.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    location: {
      type: DataTypes.STRING(500)
    },
    contact: {
      type: DataTypes.STRING(100)
    },
    service_description: {
      type: DataTypes.TEXT
    },
    status: {
      type: DataTypes.STRING(20),
      defaultValue: 'active'
    }
  }, {
    sequelize,
    modelName: 'HealthProvider',
    tableName: 'health_providers',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  HealthProvider.associate = (models) => {
    HealthProvider.hasMany(models.DoctorProfile, {
      foreignKey: 'health_provider_id',
      as: 'doctors'
    });
  };

  return HealthProvider;
};
